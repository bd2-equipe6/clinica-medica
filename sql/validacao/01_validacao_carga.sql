
WITH status_no_dw AS (
    SELECT DISTINCT a.statusatendimento AS status
    FROM public.atendimento a
    WHERE a.id IN (SELECT atendimento_id FROM dw.fato_atendimento)
),
esperado AS (
    SELECT COUNT(*)                                   AS itens,
           COUNT(DISTINCT i.atendimento_id)           AS atendimentos,
           COALESCE(SUM(i.quantidade), 0)             AS quantidade,
           COALESCE(SUM(i.quantidade * i.valor_unitario), 0) AS valor_bruto,
           COALESCE(SUM(COALESCE(i.desconto, 0)), 0)  AS desconto,
           COALESCE(SUM(i.quantidade * i.valor_unitario - COALESCE(i.desconto, 0)), 0) AS valor_liquido
    FROM public.item_atendimento i
    INNER JOIN public.atendimento a ON a.id = i.atendimento_id
    WHERE a.statusatendimento IN (SELECT status FROM status_no_dw)
),
carregado AS (
    SELECT COUNT(*)                         AS itens,
           COUNT(DISTINCT atendimento_id)   AS atendimentos,
           COALESCE(SUM(quantidade), 0)     AS quantidade,
           COALESCE(SUM(valor_bruto), 0)    AS valor_bruto,
           COALESCE(SUM(desconto), 0)       AS desconto,
           COALESCE(SUM(valor_liquido), 0)  AS valor_liquido
    FROM dw.fato_atendimento
),
comparacoes AS (
    SELECT 1 AS n, 'Itens (linhas da fato)' AS verificacao, e.itens AS esperado, d.itens AS encontrado FROM esperado e, carregado d
    UNION ALL SELECT 2, 'Atendimentos distintos', e.atendimentos, d.atendimentos FROM esperado e, carregado d
    UNION ALL SELECT 3, 'Soma da quantidade', e.quantidade, d.quantidade FROM esperado e, carregado d
    UNION ALL SELECT 4, 'Soma do valor bruto', e.valor_bruto, d.valor_bruto FROM esperado e, carregado d
    UNION ALL SELECT 5, 'Soma do desconto', e.desconto, d.desconto FROM esperado e, carregado d
    UNION ALL SELECT 6, 'Soma do valor líquido', e.valor_liquido, d.valor_liquido FROM esperado e, carregado d
    UNION ALL SELECT 7, 'Unidades (OLTP x dim_unidade)',
           (SELECT COUNT(*) FROM public.unidade),
           (SELECT COUNT(DISTINCT unidade_id) FROM dw.dim_unidade)
    UNION ALL SELECT 8, 'Médicos (OLTP x dim_medico)',
           (SELECT COUNT(*) FROM public.medico),
           (SELECT COUNT(DISTINCT medico_id) FROM dw.dim_medico)
    UNION ALL SELECT 9, 'Procedimentos (OLTP x dim_procedimento)',
           (SELECT COUNT(*) FROM public.procedimento),
           (SELECT COUNT(DISTINCT procedimento_id) FROM dw.dim_procedimento)
    UNION ALL SELECT 10, 'Pacientes (OLTP x dim_paciente)',
           (SELECT COUNT(*) FROM public.paciente),
           (SELECT COUNT(DISTINCT paciente_id) FROM dw.dim_paciente)
),
deve_ser_zero AS (
    SELECT 11 AS n, 'DW vazio (0 = tem linhas na fato)' AS verificacao,
           CASE WHEN (SELECT COUNT(*) FROM dw.fato_atendimento) = 0 THEN 1 ELSE 0 END AS qtd
    UNION ALL SELECT 12, 'Atendimentos REALIZADOS sem nenhum item no DW',
           (SELECT COUNT(*)
            FROM public.atendimento a
            WHERE a.statusatendimento = 'REALIZADO'
              AND EXISTS (SELECT 1 FROM public.item_atendimento i WHERE i.atendimento_id = a.id)
              AND NOT EXISTS (SELECT 1 FROM dw.fato_atendimento f WHERE f.atendimento_id = a.id))
    UNION ALL SELECT 13, 'Atendimentos CANCELADOS que entraram no DW',
           (SELECT COUNT(*)
            FROM public.atendimento a
            WHERE a.statusatendimento = 'CANCELADO'
              AND a.id IN (SELECT atendimento_id FROM dw.fato_atendimento))
    UNION ALL SELECT 14, 'Atendimentos do DW que não existem no OLTP',
           (SELECT COUNT(DISTINCT f.atendimento_id)
            FROM dw.fato_atendimento f
            WHERE f.atendimento_id NOT IN (SELECT id FROM public.atendimento))
    UNION ALL SELECT 15, 'Atendimentos com número de itens ou valor líquido diferente',
           (SELECT COUNT(*)
            FROM (SELECT atendimento_id, COUNT(*) AS itens, SUM(valor_liquido) AS liquido
                  FROM dw.fato_atendimento GROUP BY atendimento_id) d
            INNER JOIN (SELECT atendimento_id, COUNT(*) AS itens,
                               SUM(quantidade * valor_unitario - COALESCE(desconto, 0)) AS liquido
                        FROM public.item_atendimento GROUP BY atendimento_id) o
                    ON o.atendimento_id = d.atendimento_id
            WHERE o.itens <> d.itens OR ROUND(o.liquido, 2) <> ROUND(d.liquido, 2))
    UNION ALL SELECT 16, 'Pares atendimento x procedimento diferentes entre OLTP e DW',
           (SELECT COUNT(*) FROM (
                SELECT i.atendimento_id, i.procedimento_id FROM public.item_atendimento i
                WHERE i.atendimento_id IN (SELECT atendimento_id FROM dw.fato_atendimento)
                EXCEPT
                SELECT f.atendimento_id, p.procedimento_id
                FROM dw.fato_atendimento f
                INNER JOIN dw.dim_procedimento p ON p.sk_procedimento = f.sk_procedimento) x1)
           +
           (SELECT COUNT(*) FROM (
                SELECT f.atendimento_id, p.procedimento_id
                FROM dw.fato_atendimento f
                INNER JOIN dw.dim_procedimento p ON p.sk_procedimento = f.sk_procedimento
                EXCEPT
                SELECT i.atendimento_id, i.procedimento_id FROM public.item_atendimento i) x2)
    UNION ALL SELECT 17, 'Fato com paciente, médico ou unidade diferente do atendimento no OLTP',
           (SELECT COUNT(*)
            FROM dw.fato_atendimento f
            INNER JOIN public.atendimento a   ON a.id = f.atendimento_id
            INNER JOIN dw.dim_paciente dp     ON dp.sk_paciente = f.sk_paciente
            INNER JOIN dw.dim_medico dm       ON dm.sk_medico = f.sk_medico
            INNER JOIN dw.dim_unidade du      ON du.sk_unidade = f.sk_unidade
            WHERE dp.paciente_id <> a.paciente_id
               OR dm.medico_id <> a.medico_id
               OR du.unidade_id <> a.unidade_id)
    UNION ALL SELECT 18, 'Fato com data diferente da data do atendimento no OLTP',
           (SELECT COUNT(*)
            FROM dw.fato_atendimento f
            INNER JOIN public.atendimento a ON a.id = f.atendimento_id
            INNER JOIN dw.dim_tempo t       ON t.sk_tempo = f.sk_tempo
            WHERE t.data <> DATE(a.datahora))
    UNION ALL SELECT 19, 'Linhas da fato com chave de dimensão inexistente',
           (SELECT COUNT(*) FROM dw.fato_atendimento f
            WHERE f.sk_paciente NOT IN (SELECT sk_paciente FROM dw.dim_paciente)
               OR f.sk_medico NOT IN (SELECT sk_medico FROM dw.dim_medico)
               OR f.sk_unidade NOT IN (SELECT sk_unidade FROM dw.dim_unidade)
               OR f.sk_tempo NOT IN (SELECT sk_tempo FROM dw.dim_tempo)
               OR f.sk_procedimento NOT IN (SELECT sk_procedimento FROM dw.dim_procedimento))
    UNION ALL SELECT 20, 'Linhas em que valor líquido <> valor bruto - desconto',
           (SELECT COUNT(*) FROM dw.fato_atendimento
            WHERE ROUND(valor_liquido, 2) <> ROUND(valor_bruto - desconto, 2))
    UNION ALL SELECT 21, 'Linhas com quantidade <= 0 ou valor negativo',
           (SELECT COUNT(*) FROM dw.fato_atendimento
            WHERE quantidade <= 0 OR valor_bruto < 0 OR desconto < 0 OR valor_liquido < 0)
    UNION ALL SELECT 22, 'Linhas da dim_tempo com mês, trimestre, semestre ou ano que não batem com a data',
           (SELECT COUNT(*) FROM dw.dim_tempo t
            WHERE t.mes <> EXTRACT(MONTH FROM t.data)
               OR t.ano <> EXTRACT(YEAR FROM t.data)
               OR t.dia <> EXTRACT(DAY FROM t.data)
               OR t.trimestre <> (t.mes + 2) / 3
               OR t.semestre <> (t.mes + 5) / 6)
)
SELECT n, verificacao,
       CAST(esperado AS TEXT)   AS esperado,
       CAST(encontrado AS TEXT) AS encontrado,
       CASE WHEN ROUND(esperado, 2) = ROUND(encontrado, 2) THEN 'OK' ELSE 'ERRO' END AS resultado
FROM comparacoes
UNION ALL
SELECT n, verificacao, '0', CAST(qtd AS TEXT),
       CASE WHEN qtd = 0 THEN 'OK' ELSE 'ERRO' END
FROM deve_ser_zero
ORDER BY n;

SELECT a.statusatendimento AS status,
       COUNT(*) AS atendimentos_oltp,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM public.item_atendimento i WHERE i.atendimento_id = a.id)
                THEN 1 ELSE 0 END) AS com_itens,
       SUM(CASE WHEN EXISTS (SELECT 1 FROM dw.fato_atendimento f WHERE f.atendimento_id = a.id)
                THEN 1 ELSE 0 END) AS no_dw
FROM public.atendimento a
GROUP BY a.statusatendimento
ORDER BY a.statusatendimento;

WITH status_no_dw AS (
    SELECT DISTINCT a.statusatendimento AS status
    FROM public.atendimento a
    WHERE a.id IN (SELECT atendimento_id FROM dw.fato_atendimento)
),
do_oltp AS (
    SELECT CAST(EXTRACT(YEAR FROM a.datahora) AS INTEGER)  AS ano,
           CAST(EXTRACT(MONTH FROM a.datahora) AS INTEGER) AS mes,
           COUNT(*) AS itens,
           SUM(i.quantidade * i.valor_unitario - COALESCE(i.desconto, 0)) AS valor_liquido
    FROM public.item_atendimento i
    INNER JOIN public.atendimento a ON a.id = i.atendimento_id
    WHERE a.statusatendimento IN (SELECT status FROM status_no_dw)
    GROUP BY 1, 2
),
do_dw AS (
    SELECT t.ano, t.mes, COUNT(*) AS itens, SUM(f.valor_liquido) AS valor_liquido
    FROM dw.fato_atendimento f
    INNER JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_tempo
    GROUP BY t.ano, t.mes
)
SELECT COALESCE(o.ano, d.ano) AS ano,
       COALESCE(o.mes, d.mes) AS mes,
       o.itens AS itens_oltp,
       d.itens AS itens_dw,
       o.valor_liquido AS liquido_oltp,
       d.valor_liquido AS liquido_dw
FROM do_oltp o
FULL OUTER JOIN do_dw d ON d.ano = o.ano AND d.mes = o.mes
WHERE o.itens IS NULL OR d.itens IS NULL
   OR o.itens <> d.itens
   OR ROUND(o.valor_liquido, 2) <> ROUND(d.valor_liquido, 2)
ORDER BY 1, 2;

SELECT o.atendimento_id,
       o.itens AS itens_oltp, d.itens AS itens_dw,
       o.liquido AS liquido_oltp, d.liquido AS liquido_dw
FROM (SELECT atendimento_id, COUNT(*) AS itens,
             SUM(quantidade * valor_unitario - COALESCE(desconto, 0)) AS liquido
      FROM public.item_atendimento GROUP BY atendimento_id) o
INNER JOIN (SELECT atendimento_id, COUNT(*) AS itens, SUM(valor_liquido) AS liquido
            FROM dw.fato_atendimento GROUP BY atendimento_id) d
        ON d.atendimento_id = o.atendimento_id
WHERE o.itens <> d.itens OR ROUND(o.liquido, 2) <> ROUND(d.liquido, 2)
ORDER BY o.atendimento_id
LIMIT 20;
