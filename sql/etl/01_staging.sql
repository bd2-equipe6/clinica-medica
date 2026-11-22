-- ETL - passo 01: área de staging e extração do OLTP
--
-- Cria o esquema staging, as tabelas de staging, o log de contagens e a
-- função staging.extrair_oltp(), que copia os dados do OLTP (esquema public)
-- já limpos e padronizados.
--
-- O staging é uma "foto" do OLTP: a cada execução ele é esvaziado e
-- recarregado. O que decide o que é novo é a carga das dimensões e da fato,
-- que comparam o staging com o que já está no DW.
--
-- Os scripts do ETL só LEEM o esquema public, nunca alteram.

CREATE SCHEMA IF NOT EXISTS staging;


-- Tabelas de staging (temporárias por natureza: podem ser recriadas)

DROP TABLE IF EXISTS staging.stg_paciente;
CREATE TABLE staging.stg_paciente (
    paciente_id   BIGINT PRIMARY KEY,
    nome          VARCHAR(120) NOT NULL,
    cidade        VARCHAR(80)  NOT NULL,
    uf            CHAR(2)      NOT NULL,
    convenio      VARCHAR(80)  NOT NULL,
    data_cadastro DATE
);

DROP TABLE IF EXISTS staging.stg_medico;
CREATE TABLE staging.stg_medico (
    medico_id BIGINT PRIMARY KEY,
    nome      VARCHAR(120) NOT NULL,
    crm       VARCHAR(50)  NOT NULL
);

DROP TABLE IF EXISTS staging.stg_unidade;
CREATE TABLE staging.stg_unidade (
    unidade_id BIGINT PRIMARY KEY,
    nome       VARCHAR(80) NOT NULL,
    cidade     VARCHAR(80) NOT NULL,
    uf         CHAR(2)     NOT NULL
);

DROP TABLE IF EXISTS staging.stg_procedimento;
CREATE TABLE staging.stg_procedimento (
    procedimento_id BIGINT PRIMARY KEY,
    codigo          VARCHAR(30)  NOT NULL,
    nome            VARCHAR(120) NOT NULL,
    categoria_id    BIGINT       NOT NULL,
    categoria       VARCHAR(80)  NOT NULL
);

-- Uma linha por procedimento realizado em um atendimento
-- (mesma granularidade da tabela fato).
DROP TABLE IF EXISTS staging.stg_item_atendimento;
CREATE TABLE staging.stg_item_atendimento (
    item_atendimento_id BIGINT PRIMARY KEY,
    atendimento_id      BIGINT        NOT NULL,
    data                DATE          NOT NULL,
    paciente_id         BIGINT        NOT NULL,
    medico_id           BIGINT        NOT NULL,
    unidade_id          BIGINT        NOT NULL,
    procedimento_id     BIGINT        NOT NULL,
    quantidade          INT           NOT NULL,
    valor_unitario      NUMERIC(12,2) NOT NULL,
    desconto            NUMERIC(12,2) NOT NULL,
    valor_bruto         NUMERIC(12,2) NOT NULL,
    valor_liquido       NUMERIC(12,2) NOT NULL
);


-- Log das contagens de linhas antes e depois de cada execução do ETL.
-- Este NÃO é recriado: guarda o histórico de todas as execuções.

CREATE SEQUENCE IF NOT EXISTS staging.seq_execucao_etl;

CREATE TABLE IF NOT EXISTS staging.log_carga (
    id            SERIAL PRIMARY KEY,
    execucao_id   INT         NOT NULL,
    executado_em  TIMESTAMP   NOT NULL DEFAULT now(),
    tabela        VARCHAR(60) NOT NULL,
    linhas_antes  BIGINT      NOT NULL,
    linhas_depois BIGINT
);


-- Padronização de textos: tira espaços das pontas, junta espaços repetidos,
-- passa para maiúsculas e troca nulo ou vazio pelo valor padrão.
-- Ex.: '  goiânia  ' -> 'GOIÂNIA';  NULL -> 'NAO INFORMADO'

CREATE OR REPLACE FUNCTION staging.padronizar(p_texto TEXT, p_padrao TEXT DEFAULT 'NAO INFORMADO')
RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT COALESCE(NULLIF(UPPER(regexp_replace(TRIM(p_texto), '\s+', ' ', 'g')), ''), p_padrao);
$$;


-- Conta as linhas de uma tabela pelo nome (usada no log de contagens).

CREATE OR REPLACE FUNCTION staging.contar_linhas(p_tabela TEXT)
RETURNS BIGINT
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    EXECUTE format('SELECT COUNT(*) FROM %s', p_tabela::regclass) INTO v_total;
    RETURN v_total;
END;
$$;


-- Extração: esvazia o staging e copia o OLTP com limpeza e padronização.

CREATE OR REPLACE FUNCTION staging.extrair_oltp()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    TRUNCATE staging.stg_paciente, staging.stg_medico, staging.stg_unidade,
             staging.stg_procedimento, staging.stg_item_atendimento;

    -- Paciente: herança JOINED, então os dados comuns estão em pessoa.
    -- Sem convênio = particular.
    INSERT INTO staging.stg_paciente (paciente_id, nome, cidade, uf, convenio, data_cadastro)
    SELECT pa.id,
           staging.padronizar(pe.nome),
           staging.padronizar(pe.cidade),
           staging.padronizar(pe.uf, 'NI'),
           staging.padronizar(c.nome, 'PARTICULAR'),
           pa.data_cadastro
    FROM public.paciente pa
    INNER JOIN public.pessoa pe ON pe.id = pa.id
    LEFT JOIN public.convenio c ON c.id = pa.convenio_id;

    INSERT INTO staging.stg_medico (medico_id, nome, crm)
    SELECT m.id,
           staging.padronizar(pe.nome),
           staging.padronizar(m.crm)
    FROM public.medico m
    INNER JOIN public.pessoa pe ON pe.id = m.id;

    INSERT INTO staging.stg_unidade (unidade_id, nome, cidade, uf)
    SELECT u.id,
           staging.padronizar(u.nome),
           staging.padronizar(u.cidade),
           staging.padronizar(u.uf, 'NI')
    FROM public.unidade u;

    INSERT INTO staging.stg_procedimento (procedimento_id, codigo, nome, categoria_id, categoria)
    SELECT p.id,
           staging.padronizar(p.codigo),
           staging.padronizar(p.nome),
           c.id,
           staging.padronizar(c.nome)
    FROM public.procedimento p
    INNER JOIN public.categoria_procedimento c ON c.id = p.categoria_id;

    -- Itens: só de atendimentos REALIZADOS (cancelados não têm itens e os
    -- agendados ainda não aconteceram). Aqui também entram o tratamento de
    -- nulos das medidas e o cálculo das medidas derivadas:
    --   valor_bruto   = quantidade x valor unitário
    --   valor_liquido = valor_bruto - desconto
    INSERT INTO staging.stg_item_atendimento
          (item_atendimento_id, atendimento_id, data, paciente_id, medico_id, unidade_id,
           procedimento_id, quantidade, valor_unitario, desconto, valor_bruto, valor_liquido)
    SELECT x.item_atendimento_id, x.atendimento_id, x.data, x.paciente_id, x.medico_id,
           x.unidade_id, x.procedimento_id, x.quantidade, x.valor_unitario, x.desconto,
           x.quantidade * x.valor_unitario,
           x.quantidade * x.valor_unitario - x.desconto
    FROM (
        SELECT i.id                                          AS item_atendimento_id,
               a.id                                          AS atendimento_id,
               a.datahora::date                              AS data,
               a.paciente_id,
               a.medico_id,
               a.unidade_id,
               i.procedimento_id,
               i.quantidade,
               COALESCE(i.valor_unitario, pr.valor_base, 0)  AS valor_unitario,
               COALESCE(i.desconto, 0)                       AS desconto
        FROM public.item_atendimento i
        INNER JOIN public.atendimento a   ON a.id  = i.atendimento_id
        INNER JOIN public.procedimento pr ON pr.id = i.procedimento_id
        WHERE a.statusatendimento = 'REALIZADO'
    ) x;
END;
$$;
