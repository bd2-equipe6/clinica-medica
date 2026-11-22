-- Precisa da coluna item_atendimento_id na fato ( ela que identifica cada item).
-- Se não existir ainda Edson precisa acrescentar no DDL antes.

CREATE SCHEMA IF NOT EXISTS validacao;

CREATE TABLE IF NOT EXISTS validacao.foto_carga (
    id SERIAL PRIMARY KEY,
    momento TIMESTAMP NOT NULL DEFAULT NOW(),
    itens_oltp INTEGER NOT NULL,
    itens_dw INTEGER NOT NULL,
    linhas_fato INTEGER NOT NULL,
    liquido_oltp NUMERIC(14,2),
    liquido_dw NUMERIC(14,2),
    duplicados INTEGER NOT NULL
);

INSERT INTO validacao.foto_carga (itens_oltp, itens_dw, linhas_fato, liquido_oltp, liquido_dw, duplicados)
SELECT (SELECT COUNT(*)
        FROM public.item_atendimento i
        INNER JOIN public.atendimento a ON a.id = i.atendimento_id
        WHERE a.statusatendimento = 'REALIZADO'),
       (SELECT COUNT(*)
        FROM dw.fato_atendimento f
        INNER JOIN public.atendimento a ON a.id = f.atendimento_id
        WHERE a.statusatendimento = 'REALIZADO'),
       (SELECT COUNT(*) FROM dw.fato_atendimento),
       (SELECT SUM(i.quantidade * i.valor_unitario - COALESCE(i.desconto, 0))
        FROM public.item_atendimento i
        INNER JOIN public.atendimento a ON a.id = i.atendimento_id
        WHERE a.statusatendimento = 'REALIZADO'),
       (SELECT SUM(f.valor_liquido)
        FROM dw.fato_atendimento f
        INNER JOIN public.atendimento a ON a.id = f.atendimento_id
        WHERE a.statusatendimento = 'REALIZADO'),
       (SELECT COUNT(*)
        FROM (SELECT item_atendimento_id
              FROM dw.fato_atendimento
              GROUP BY item_atendimento_id
              HAVING COUNT(*) > 1) d);

SELECT id AS foto,
       momento,
       itens_oltp,
       itens_dw,
       itens_oltp - itens_dw AS pendentes,
       itens_dw - LAG(itens_dw) OVER (ORDER BY id) AS entrou_no_dw,
       itens_oltp - LAG(itens_oltp) OVER (ORDER BY id) AS entrou_no_oltp,
       duplicados,
       CASE WHEN duplicados > 0 THEN 'ERRO: item duplicado na fato'
            WHEN itens_oltp = itens_dw AND ROUND(liquido_oltp, 2) = ROUND(liquido_dw, 2) THEN 'OK: DW em dia com o OLTP'
            WHEN itens_oltp > itens_dw THEN 'Há itens ainda não carregados (normal antes de rodar o ETL)'
            WHEN itens_oltp = itens_dw THEN 'ERRO: mesma quantidade de itens, mas o valor líquido é diferente'
            ELSE 'ERRO: o DW tem mais itens que o OLTP'
       END AS resultado
FROM validacao.foto_carga
ORDER BY id;

WITH deve_ser_zero AS (
    SELECT 1 AS n, 'Itens REALIZADOS do OLTP que não estão na fato' AS verificacao,
           (SELECT COUNT(*)
            FROM public.item_atendimento i
            INNER JOIN public.atendimento a ON a.id = i.atendimento_id
            WHERE a.statusatendimento = 'REALIZADO'
              AND NOT EXISTS (SELECT 1 FROM dw.fato_atendimento f WHERE f.item_atendimento_id = i.id)) AS qtd
    UNION ALL SELECT 2, 'Itens da fato que não existem no OLTP',
           (SELECT COUNT(*) FROM dw.fato_atendimento f
            WHERE f.item_atendimento_id NOT IN (SELECT id FROM public.item_atendimento))
    UNION ALL SELECT 3, 'Itens repetidos na fato',
           (SELECT COUNT(*)
            FROM (SELECT item_atendimento_id FROM dw.fato_atendimento
                  GROUP BY item_atendimento_id HAVING COUNT(*) > 1) d)
    UNION ALL SELECT 4, 'Itens com quantidade, valor ou atendimento diferente do OLTP',
           (SELECT COUNT(*)
            FROM dw.fato_atendimento f
            INNER JOIN public.item_atendimento i ON i.id = f.item_atendimento_id
            WHERE f.quantidade <> i.quantidade
               OR f.atendimento_id <> i.atendimento_id
               OR ROUND(f.valor_liquido, 2) <> ROUND(i.quantidade * i.valor_unitario - COALESCE(i.desconto, 0), 2))
)
SELECT n, verificacao, '0' AS esperado, CAST(qtd AS TEXT) AS encontrado,
       CASE WHEN qtd = 0 THEN 'OK' ELSE 'ERRO' END AS resultado
FROM deve_ser_zero
ORDER BY n;
