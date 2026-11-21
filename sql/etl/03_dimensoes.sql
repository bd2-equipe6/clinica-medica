-- ETL - passo 03: carga das dimensões médico, unidade e procedimento
--
-- Chaves substitutas: cada dimensão tem sua própria chave (sk_*, SERIAL),
-- gerada pelo DW. A chave do OLTP fica guardada em *_id (chave natural) só
-- para o ETL saber qual linha do DW corresponde a qual registro do OLTP.
--
-- Estas dimensões são SCD tipo 1: se um atributo muda no OLTP (ex.: nome da
-- unidade), a linha do DW é sobrescrita e o histórico não é guardado.
-- A única dimensão com histórico (SCD tipo 2) é a de paciente (passo 04).
--
-- Cada carga faz duas coisas: atualiza o que mudou e insere o que é novo.
-- Rodar de novo sem mudanças no OLTP não altera nada.


-- Médico: a tabela é idêntica nos dois modelos, então uma função serve aos dois.

CREATE OR REPLACE FUNCTION staging.carregar_dim_medico(p_esquema TEXT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format($sql$
        UPDATE %I.dim_medico d
           SET nome = s.nome, crm = s.crm
        FROM staging.stg_medico s
        WHERE d.medico_id = s.medico_id
          AND (d.nome, d.crm) IS DISTINCT FROM (s.nome, s.crm)
    $sql$, p_esquema);

    EXECUTE format($sql$
        INSERT INTO %I.dim_medico (medico_id, nome, crm)
        SELECT s.medico_id, s.nome, s.crm
        FROM staging.stg_medico s
        WHERE NOT EXISTS (SELECT 1 FROM %I.dim_medico d WHERE d.medico_id = s.medico_id)
        ORDER BY s.medico_id
    $sql$, p_esquema, p_esquema);
END;
$$;


-- Modelo estrela: unidade e procedimento desnormalizados
-- (cidade/uf dentro da unidade, categoria dentro do procedimento).

CREATE OR REPLACE FUNCTION staging.carregar_dimensoes_estrela()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM staging.carregar_dim_medico('dw');

    UPDATE dw.dim_unidade d
       SET nome = s.nome, cidade = s.cidade, uf = s.uf
    FROM staging.stg_unidade s
    WHERE d.unidade_id = s.unidade_id
      AND (d.nome, d.cidade, d.uf) IS DISTINCT FROM (s.nome, s.cidade, s.uf);

    INSERT INTO dw.dim_unidade (unidade_id, nome, cidade, uf)
    SELECT s.unidade_id, s.nome, s.cidade, s.uf
    FROM staging.stg_unidade s
    WHERE NOT EXISTS (SELECT 1 FROM dw.dim_unidade d WHERE d.unidade_id = s.unidade_id)
    ORDER BY s.unidade_id;

    UPDATE dw.dim_procedimento d
       SET codigo = s.codigo, nome = s.nome, categoria = s.categoria
    FROM staging.stg_procedimento s
    WHERE d.procedimento_id = s.procedimento_id
      AND (d.codigo, d.nome, d.categoria) IS DISTINCT FROM (s.codigo, s.nome, s.categoria);

    INSERT INTO dw.dim_procedimento (procedimento_id, codigo, nome, categoria)
    SELECT s.procedimento_id, s.codigo, s.nome, s.categoria
    FROM staging.stg_procedimento s
    WHERE NOT EXISTS (SELECT 1 FROM dw.dim_procedimento d WHERE d.procedimento_id = s.procedimento_id)
    ORDER BY s.procedimento_id;
END;
$$;


-- Modelo floco de neve: as hierarquias viram tabelas próprias
--   unidade -> cidade -> estado
--   procedimento -> categoria
-- Os níveis de cima precisam ser carregados antes, porque os de baixo
-- guardam a chave substituta deles.

CREATE OR REPLACE FUNCTION staging.carregar_dimensoes_floco()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM staging.carregar_dim_medico('dw_floco');

    -- Estado: o OLTP só guarda a sigla; o nome vem desta tabela de referência.
    INSERT INTO dw_floco.dim_estado (uf, nome)
    SELECT DISTINCT s.uf, COALESCE(e.nome, 'NAO INFORMADO')
    FROM staging.stg_unidade s
    LEFT JOIN (VALUES
        ('AC','ACRE'), ('AL','ALAGOAS'), ('AP','AMAPA'), ('AM','AMAZONAS'), ('BA','BAHIA'),
        ('CE','CEARA'), ('DF','DISTRITO FEDERAL'), ('ES','ESPIRITO SANTO'), ('GO','GOIAS'),
        ('MA','MARANHAO'), ('MT','MATO GROSSO'), ('MS','MATO GROSSO DO SUL'),
        ('MG','MINAS GERAIS'), ('PA','PARA'), ('PB','PARAIBA'), ('PR','PARANA'),
        ('PE','PERNAMBUCO'), ('PI','PIAUI'), ('RJ','RIO DE JANEIRO'),
        ('RN','RIO GRANDE DO NORTE'), ('RS','RIO GRANDE DO SUL'), ('RO','RONDONIA'),
        ('RR','RORAIMA'), ('SC','SANTA CATARINA'), ('SP','SAO PAULO'), ('SE','SERGIPE'),
        ('TO','TOCANTINS')
    ) AS e(uf, nome) ON e.uf = s.uf
    WHERE NOT EXISTS (SELECT 1 FROM dw_floco.dim_estado d WHERE d.uf = s.uf);

    -- Cidade: o DDL não tem UNIQUE (nome, sk_estado), então quem evita
    -- duplicata é este NOT EXISTS.
    INSERT INTO dw_floco.dim_cidade (nome, sk_estado)
    SELECT DISTINCT s.cidade, e.sk_estado
    FROM staging.stg_unidade s
    INNER JOIN dw_floco.dim_estado e ON e.uf = s.uf
    WHERE NOT EXISTS (SELECT 1 FROM dw_floco.dim_cidade c
                      WHERE c.nome = s.cidade AND c.sk_estado = e.sk_estado);

    -- Unidade, apontando para a cidade.
    UPDATE dw_floco.dim_unidade d
       SET nome = s.nome, sk_cidade = c.sk_cidade
    FROM staging.stg_unidade s
    INNER JOIN dw_floco.dim_estado e ON e.uf = s.uf
    INNER JOIN dw_floco.dim_cidade c ON c.nome = s.cidade AND c.sk_estado = e.sk_estado
    WHERE d.unidade_id = s.unidade_id
      AND (d.nome, d.sk_cidade) IS DISTINCT FROM (s.nome, c.sk_cidade);

    INSERT INTO dw_floco.dim_unidade (unidade_id, nome, sk_cidade)
    SELECT s.unidade_id, s.nome, c.sk_cidade
    FROM staging.stg_unidade s
    INNER JOIN dw_floco.dim_estado e ON e.uf = s.uf
    INNER JOIN dw_floco.dim_cidade c ON c.nome = s.cidade AND c.sk_estado = e.sk_estado
    WHERE NOT EXISTS (SELECT 1 FROM dw_floco.dim_unidade d WHERE d.unidade_id = s.unidade_id)
    ORDER BY s.unidade_id;

    -- Categoria do procedimento.
    UPDATE dw_floco.dim_categoria d
       SET nome = s.categoria
    FROM (SELECT DISTINCT categoria_id, categoria FROM staging.stg_procedimento) s
    WHERE d.categoria_id = s.categoria_id
      AND d.nome IS DISTINCT FROM s.categoria;

    INSERT INTO dw_floco.dim_categoria (categoria_id, nome)
    SELECT DISTINCT s.categoria_id, s.categoria
    FROM staging.stg_procedimento s
    WHERE NOT EXISTS (SELECT 1 FROM dw_floco.dim_categoria d WHERE d.categoria_id = s.categoria_id);

    -- Procedimento, apontando para a categoria.
    UPDATE dw_floco.dim_procedimento d
       SET codigo = s.codigo, nome = s.nome, sk_categoria = c.sk_categoria
    FROM staging.stg_procedimento s
    INNER JOIN dw_floco.dim_categoria c ON c.categoria_id = s.categoria_id
    WHERE d.procedimento_id = s.procedimento_id
      AND (d.codigo, d.nome, d.sk_categoria) IS DISTINCT FROM (s.codigo, s.nome, c.sk_categoria);

    INSERT INTO dw_floco.dim_procedimento (procedimento_id, codigo, nome, sk_categoria)
    SELECT s.procedimento_id, s.codigo, s.nome, c.sk_categoria
    FROM staging.stg_procedimento s
    INNER JOIN dw_floco.dim_categoria c ON c.categoria_id = s.categoria_id
    WHERE NOT EXISTS (SELECT 1 FROM dw_floco.dim_procedimento d WHERE d.procedimento_id = s.procedimento_id)
    ORDER BY s.procedimento_id;
END;
$$;
