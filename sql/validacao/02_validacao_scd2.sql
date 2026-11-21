
WITH versoes AS (
    SELECT paciente_id, sk_paciente, cidade, uf, data_inicio, data_fim, registro_atual,
           LAG(sk_paciente) OVER (PARTITION BY paciente_id ORDER BY data_inicio, sk_paciente) AS sk_anterior,
           LAG(data_fim)    OVER (PARTITION BY paciente_id ORDER BY data_inicio, sk_paciente) AS fim_anterior,
           LAG(cidade)      OVER (PARTITION BY paciente_id ORDER BY data_inicio, sk_paciente) AS cidade_anterior,
           LAG(uf)          OVER (PARTITION BY paciente_id ORDER BY data_inicio, sk_paciente) AS uf_anterior
    FROM dw.dim_paciente
),
atuais AS (
    SELECT paciente_id, COUNT(*) AS qtd_atuais
    FROM dw.dim_paciente
    WHERE registro_atual = TRUE
    GROUP BY paciente_id
),
deve_ser_zero AS (
    SELECT 1 AS n, 'Pacientes do OLTP sem nenhuma versão na dim_paciente' AS verificacao,
           (SELECT COUNT(*) FROM public.paciente p
            WHERE p.id NOT IN (SELECT paciente_id FROM dw.dim_paciente)) AS qtd
    UNION ALL SELECT 2, 'Pacientes sem versão atual (registro_atual = true)',
           (SELECT COUNT(DISTINCT paciente_id) FROM dw.dim_paciente
            WHERE paciente_id NOT IN (SELECT paciente_id FROM atuais))
    UNION ALL SELECT 3, 'Pacientes com mais de uma versão atual',
           (SELECT COUNT(*) FROM atuais WHERE qtd_atuais > 1)
    UNION ALL SELECT 4, 'Versão atual com data_fim preenchida',
           (SELECT COUNT(*) FROM dw.dim_paciente WHERE registro_atual = TRUE AND data_fim IS NOT NULL)
    UNION ALL SELECT 5, 'Versão antiga sem data_fim',
           (SELECT COUNT(*) FROM dw.dim_paciente WHERE registro_atual = FALSE AND data_fim IS NULL)
    UNION ALL SELECT 6, 'Versão com data_fim antes da data_inicio',
           (SELECT COUNT(*) FROM dw.dim_paciente WHERE data_fim IS NOT NULL AND data_fim < data_inicio)
    UNION ALL SELECT 7, 'Versões sobrepostas ou com a anterior ainda aberta',
           (SELECT COUNT(*) FROM versoes
            WHERE sk_anterior IS NOT NULL
              AND (fim_anterior IS NULL OR data_inicio < fim_anterior))
    UNION ALL SELECT 8, 'Nova versão sem mudança de cidade ou UF (versão desnecessária)',
           (SELECT COUNT(*) FROM versoes
            WHERE sk_anterior IS NOT NULL
              AND COALESCE(cidade, '') = COALESCE(cidade_anterior, '')
              AND COALESCE(uf, '') = COALESCE(uf_anterior, ''))
    UNION ALL SELECT 9, 'Versão atual com cidade ou UF diferente do OLTP',
           (SELECT COUNT(*)
            FROM dw.dim_paciente d
            INNER JOIN public.pessoa p ON p.id = d.paciente_id
            WHERE d.registro_atual = TRUE
              AND (COALESCE(d.cidade, '') <> COALESCE(p.cidade, '')
                   OR COALESCE(d.uf, '') <> COALESCE(p.uf, '')))
)
SELECT n, verificacao, '0' AS esperado, CAST(qtd AS TEXT) AS encontrado,
       CASE WHEN qtd = 0 THEN 'OK' ELSE 'ERRO' END AS resultado
FROM deve_ser_zero
UNION ALL
SELECT 10, 'Total de versões na dim_paciente (anotar antes e depois do teste)',
       '-', CAST(COUNT(*) AS TEXT), 'INFO'
FROM dw.dim_paciente
UNION ALL
SELECT 11, 'Pacientes com mais de uma versão (o SCD 2 funcionou se for >= 1)',
       '>= 1', CAST(COUNT(*) AS TEXT),
       CASE WHEN COUNT(*) >= 1 THEN 'OK' ELSE 'ERRO: nenhuma mudança registrada' END
FROM (SELECT paciente_id FROM dw.dim_paciente GROUP BY paciente_id HAVING COUNT(*) > 1) m
ORDER BY n;

-- Os fatos antigos devem continuar na versão antiga e os novos na versão atual.

SELECT d.paciente_id,
       d.sk_paciente,
       d.cidade,
       d.uf,
       d.data_inicio,
       d.data_fim,
       d.registro_atual,
       (SELECT COUNT(*) FROM dw.fato_atendimento f WHERE f.sk_paciente = d.sk_paciente) AS linhas_na_fato
FROM dw.dim_paciente d
WHERE d.paciente_id IN (SELECT paciente_id FROM dw.dim_paciente GROUP BY paciente_id HAVING COUNT(*) > 1)
ORDER BY d.paciente_id, d.data_inicio, d.sk_paciente;

SELECT d.paciente_id, d.sk_paciente,
       d.cidade AS cidade_dw, p.cidade AS cidade_oltp,
       d.uf AS uf_dw, p.uf AS uf_oltp
FROM dw.dim_paciente d
INNER JOIN public.pessoa p ON p.id = d.paciente_id
WHERE d.registro_atual = TRUE
  AND (COALESCE(d.cidade, '') <> COALESCE(p.cidade, '')
       OR COALESCE(d.uf, '') <> COALESCE(p.uf, ''))
ORDER BY d.paciente_id
LIMIT 20;
