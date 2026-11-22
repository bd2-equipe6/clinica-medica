
-- ===================== ROLL-UP =====================

-- Roll-up 1: receita sobe do mês para trimestre, semestre, ano e total geral
SELECT CASE GROUPING(t.ano, t.semestre, t.trimestre, t.mes)
            WHEN 0 THEN 'mês'
            WHEN 1 THEN 'trimestre'
            WHEN 3 THEN 'semestre'
            WHEN 7 THEN 'ano'
            ELSE 'total geral'
       END AS nivel,
       t.ano, t.semestre, t.trimestre, t.mes,
       COUNT(DISTINCT f.atendimento_id) AS atendimentos,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_tempo
GROUP BY ROLLUP (t.ano, t.semestre, t.trimestre, t.mes)
ORDER BY t.ano, t.semestre, t.trimestre, t.mes;

-- Roll-up 2: receita sobe da unidade para a cidade, o estado e o total geral
SELECT CASE GROUPING(u.uf, u.cidade, u.nome)
            WHEN 0 THEN 'unidade'
            WHEN 1 THEN 'cidade'
            WHEN 3 THEN 'estado'
            ELSE 'total geral'
       END AS nivel,
       u.uf, u.cidade, u.nome AS unidade,
       COUNT(DISTINCT f.atendimento_id) AS atendimentos,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_unidade u ON u.sk_unidade = f.sk_unidade
GROUP BY ROLLUP (u.uf, u.cidade, u.nome)
ORDER BY u.uf, u.cidade, u.nome;

-- ===================== DRILL-DOWN =====================

-- Drill-down 1 (tempo), passo 1: receita por ano
SELECT t.ano,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_tempo
GROUP BY t.ano
ORDER BY t.ano;

-- Drill-down 1, passo 2: detalhando 2025 por trimestre
SELECT t.ano, t.trimestre,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_tempo
WHERE t.ano = 2025
GROUP BY t.ano, t.trimestre
ORDER BY t.trimestre;

-- Drill-down 1, passo 3: detalhando o 2º trimestre de 2025 por mês
SELECT t.ano, t.trimestre, t.mes, t.nome_mes,
       COUNT(DISTINCT f.atendimento_id) AS atendimentos,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t ON t.sk_tempo = f.sk_tempo
WHERE t.ano = 2025 AND t.trimestre = 2
GROUP BY t.ano, t.trimestre, t.mes, t.nome_mes
ORDER BY t.mes;

-- Drill-down 2 (procedimento), passo 1: receita por categoria
SELECT p.categoria,
       SUM(f.quantidade) AS procedimentos_realizados,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_procedimento p ON p.sk_procedimento = f.sk_procedimento
GROUP BY p.categoria
ORDER BY receita_liquida DESC;

-- Drill-down 2, passo 2: detalhando a categoria "Exames de imagem" por procedimento
SELECT p.categoria, p.codigo, p.nome AS procedimento,
       SUM(f.quantidade) AS procedimentos_realizados,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_procedimento p ON p.sk_procedimento = f.sk_procedimento
WHERE p.categoria = 'Exames de imagem'
GROUP BY p.categoria, p.codigo, p.nome
ORDER BY receita_liquida DESC;

-- ===================== SLICE =====================

-- Slice 1: só a unidade de Goiânia, receita por categoria
SELECT u.nome AS unidade, p.categoria,
       COUNT(DISTINCT f.atendimento_id) AS atendimentos,
       SUM(f.valor_liquido) AS receita_liquida,
       ROUND(SUM(f.valor_liquido) / COUNT(DISTINCT f.atendimento_id), 2) AS ticket_medio
FROM dw.fato_atendimento f
INNER JOIN dw.dim_unidade u       ON u.sk_unidade = f.sk_unidade
INNER JOIN dw.dim_procedimento p  ON p.sk_procedimento = f.sk_procedimento
WHERE u.nome = 'Clínica Vida - Goiânia'
GROUP BY u.nome, p.categoria
ORDER BY receita_liquida DESC;


-- Slice 2: só o ano de 2025, receita por unidade
SELECT t.ano, u.nome AS unidade,
       COUNT(DISTINCT f.atendimento_id) AS atendimentos,
       SUM(f.valor_bruto) AS receita_bruta,
       SUM(f.desconto) AS descontos,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t    ON t.sk_tempo = f.sk_tempo
INNER JOIN dw.dim_unidade u  ON u.sk_unidade = f.sk_unidade
WHERE t.ano = 2025
GROUP BY t.ano, u.nome
ORDER BY receita_liquida DESC;

-- ===================== DICE =====================

-- Dice 1: anos 2025 e 2026, unidades de Goiânia e Anápolis, categorias Consultas e Exames de imagem
SELECT t.ano, u.nome AS unidade, p.categoria,
       COUNT(DISTINCT f.atendimento_id) AS atendimentos,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t         ON t.sk_tempo = f.sk_tempo
INNER JOIN dw.dim_unidade u       ON u.sk_unidade = f.sk_unidade
INNER JOIN dw.dim_procedimento p  ON p.sk_procedimento = f.sk_procedimento
WHERE t.ano IN (2025, 2026)
  AND u.nome IN ('Clínica Vida - Goiânia', 'Clínica Vida - Anápolis')
  AND p.categoria IN ('Consultas', 'Exames de imagem')
GROUP BY t.ano, u.nome, p.categoria
ORDER BY t.ano, u.nome, p.categoria;

-- Dice 2: 1º semestre, categorias Terapias e Vacinas, pacientes de Unimed, Amil e Bradesco Saúde
SELECT pac.convenio, p.categoria,
       SUM(f.quantidade) AS procedimentos_realizados,
       SUM(f.valor_bruto) AS receita_bruta,
       SUM(f.desconto) AS descontos,
       SUM(f.valor_liquido) AS receita_liquida
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t         ON t.sk_tempo = f.sk_tempo
INNER JOIN dw.dim_procedimento p  ON p.sk_procedimento = f.sk_procedimento
INNER JOIN dw.dim_paciente pac    ON pac.sk_paciente = f.sk_paciente
WHERE t.semestre = 1
  AND p.categoria IN ('Terapias', 'Vacinas')
  AND pac.convenio IN ('Unimed', 'Amil', 'Bradesco Saúde')
GROUP BY pac.convenio, p.categoria
ORDER BY pac.convenio, p.categoria;

-- ===================== PIVOT =====================

-- Pivot 1: unidades nas linhas e trimestres de 2025 nas colunas (receita líquida)
SELECT u.nome AS unidade,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.trimestre = 1), 0) AS trimestre_1,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.trimestre = 2), 0) AS trimestre_2,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.trimestre = 3), 0) AS trimestre_3,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.trimestre = 4), 0) AS trimestre_4,
       SUM(f.valor_liquido) AS total_2025
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t    ON t.sk_tempo = f.sk_tempo
INNER JOIN dw.dim_unidade u  ON u.sk_unidade = f.sk_unidade
WHERE t.ano = 2025
GROUP BY u.nome
ORDER BY u.nome;

-- Pivot 2: categorias nas linhas e anos nas colunas (receita líquida)
SELECT p.categoria,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.ano = 2024), 0) AS ano_2024,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.ano = 2025), 0) AS ano_2025,
       COALESCE(SUM(f.valor_liquido) FILTER (WHERE t.ano = 2026), 0) AS ano_2026,
       SUM(f.valor_liquido) AS total
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t         ON t.sk_tempo = f.sk_tempo
INNER JOIN dw.dim_procedimento p  ON p.sk_procedimento = f.sk_procedimento
GROUP BY p.categoria
ORDER BY total DESC;
