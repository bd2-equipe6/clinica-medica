-- Teste do fluxo completo OLTP -> DW (passo 3 de 3)
--
-- 1. Rodar a classe TesteFluxoCompleto (cadastra um atendimento novo pela aplicação).
-- 2. Rodar o ETL (scripts de sql/etl/).
-- 3. Rodar este script no banco clinica.
--
-- O atendimento conferido é o último atendimento cadastrado no OLTP,
-- que é o que a classe TesteFluxoCompleto acabou de criar.


-- 1) O atendimento no OLTP

SELECT a.id               AS atendimento_id,
       i.id               AS item_id,
       a.datahora,
       a.statusatendimento,
       pe.nome            AS paciente,
       pr.nome            AS procedimento,
       i.quantidade,
       i.valor_unitario,
       i.desconto,
       i.quantidade * i.valor_unitario              AS valor_bruto,
       i.quantidade * i.valor_unitario - i.desconto AS valor_liquido
FROM public.atendimento a
INNER JOIN public.item_atendimento i ON i.atendimento_id = a.id
INNER JOIN public.pessoa pe          ON pe.id = a.paciente_id
INNER JOIN public.procedimento pr    ON pr.id = i.procedimento_id
WHERE a.id = (SELECT MAX(id) FROM public.atendimento);


-- 2) O mesmo atendimento no DW (modelo estrela)

SELECT f.atendimento_id,
       t.data,
       t.dia_semana,
       p.nome             AS paciente,
       p.cidade           AS cidade_paciente,
       m.nome             AS medico,
       u.nome             AS unidade,
       pr.nome            AS procedimento,
       pr.categoria,
       f.quantidade,
       f.valor_bruto,
       f.desconto,
       f.valor_liquido
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t        ON t.sk_tempo        = f.sk_tempo
INNER JOIN dw.dim_paciente p     ON p.sk_paciente     = f.sk_paciente
INNER JOIN dw.dim_medico m       ON m.sk_medico       = f.sk_medico
INNER JOIN dw.dim_unidade u      ON u.sk_unidade      = f.sk_unidade
INNER JOIN dw.dim_procedimento pr ON pr.sk_procedimento = f.sk_procedimento
WHERE f.atendimento_id = (SELECT MAX(id) FROM public.atendimento);


-- 3) Resultado do teste

WITH oltp AS (
    SELECT COUNT(*)                                        AS itens,
           SUM(i.quantidade)                               AS quantidade,
           SUM(i.quantidade * i.valor_unitario)            AS valor_bruto,
           SUM(i.quantidade * i.valor_unitario - i.desconto) AS valor_liquido
    FROM public.item_atendimento i
    WHERE i.atendimento_id = (SELECT MAX(id) FROM public.atendimento)
),
dw AS (
    SELECT COUNT(*)           AS itens,
           SUM(quantidade)    AS quantidade,
           SUM(valor_bruto)   AS valor_bruto,
           SUM(valor_liquido) AS valor_liquido
    FROM dw.fato_atendimento
    WHERE atendimento_id = (SELECT MAX(id) FROM public.atendimento)
)
SELECT oltp.itens         AS itens_oltp,
       dw.itens           AS itens_dw,
       oltp.valor_liquido AS valor_liquido_oltp,
       dw.valor_liquido   AS valor_liquido_dw,
       CASE
           WHEN dw.itens = 0 THEN 'ERRO: o atendimento não chegou no DW. Rodou o ETL?'
           WHEN oltp.itens = dw.itens
            AND oltp.quantidade = dw.quantidade
            AND oltp.valor_bruto = dw.valor_bruto
            AND oltp.valor_liquido = dw.valor_liquido THEN 'OK: o atendimento chegou no DW com os mesmos valores'
           ELSE 'ERRO: o atendimento chegou no DW, mas com valores diferentes'
       END AS resultado
FROM oltp, dw;


-- 4) Contagens gerais OLTP x DW
-- Atendimentos cancelados não têm itens. Se o ETL carregar só os REALIZADOS,
-- a linha que tem que bater com o DW é a "itens de atendimentos realizados".

SELECT 'itens no OLTP (todos)' AS origem,
       COUNT(*) AS linhas,
       SUM(i.quantidade * i.valor_unitario - i.desconto) AS valor_liquido
FROM public.item_atendimento i
UNION ALL
SELECT 'itens de atendimentos realizados',
       COUNT(*),
       SUM(i.quantidade * i.valor_unitario - i.desconto)
FROM public.item_atendimento i
INNER JOIN public.atendimento a ON a.id = i.atendimento_id
WHERE a.statusatendimento = 'REALIZADO'
UNION ALL
SELECT 'linhas na fato do DW',
       COUNT(*),
       SUM(valor_liquido)
FROM dw.fato_atendimento;
