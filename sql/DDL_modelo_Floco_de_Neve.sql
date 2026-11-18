DROP SCHEMA IF EXISTS dw_floco CASCADE;
CREATE SCHEMA dw_floco;

CREATE TABLE dw_floco.dim_estado(
    sk_estado SERIAL PRIMARY KEY,
    uf CHAR(2) NOT NULL UNIQUE,
    nome VARCHAR(50)
);

CREATE TABLE dw_floco.dim_cidade(
    sk_cidade SERIAL PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    sk_estado INTEGER NOT NULL,

    CONSTRAINT fk_dim_estado
    FOREIGN KEY (sk_estado)
    REFERENCES dw_floco.dim_estado(sk_estado)
);

CREATE TABLE dw_floco.dim_categoria(
sk_categoria SERIAL PRIMARY KEY,
categoria_id BIGINT NOT NULL,
nome VARCHAR(120)
);

CREATE TABLE dw_floco.dim_tempo(
sk_tempo SERIAL PRIMARY KEY,
data  DATE UNIQUE NOT NULL,
dia INTEGER NOT NULL,
mes INTEGER NOT NULL,
trimestre INTEGER NOT NULL,
semestre INTEGER NOT NULL,
ano INTEGER NOT NULL,
nome_mes VARCHAR (30) NOT NULL,
dia_semana VARCHAR (30) NOT NULL
);

CREATE TABLE dw_floco.dim_procedimento(
sk_procedimento SERIAL PRIMARY KEY,
procedimento_id BIGINT NOT NULL,
codigo VARCHAR(30) NOT NULL,
nome VARCHAR(120) NOT NULL,
sk_categoria INTEGER NOT NULL,

CONSTRAINT fk_dim_categoria
FOREIGN KEY (sk_categoria)
REFERENCES dw_floco.dim_categoria(sk_categoria)

);

CREATE TABLE dw_floco.dim_medico(
sk_medico SERIAL PRIMARY KEY,
medico_id BIGINT NOT NULL,
nome VARCHAR(120) NOT NULL,
crm VARCHAR(50)NOT NULL
);

CREATE TABLE dw_floco.dim_unidade(
sk_unidade SERIAL PRIMARY KEY,
unidade_id BIGINT NOT NULL,
nome VARCHAR(80) NOT NULL,
sk_cidade INTEGER NOT NULL,

CONSTRAINT fk_dim_cidade
FOREIGN KEY (sk_cidade)
REFERENCES dw_floco.dim_cidade(sk_cidade)   
);

CREATE TABLE dw_floco.dim_paciente(
    sk_paciente SERIAL PRIMARY KEY,
    paciente_id BIGINT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    cidade VARCHAR(80),
    uf CHAR(2),
    convenio VARCHAR(80),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    registro_atual BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE dw_floco.fato_atendimento(
sk_fato SERIAL PRIMARY KEY,
quantidade INT NOT NULL,
valor_bruto NUMERIC(12,2) NOT NULL,
desconto NUMERIC(12,2) NOT NULL,
valor_liquido NUMERIC(12,2) NOT NULL,
atendimento_id BIGINT NOT NULL,
sk_paciente INTEGER NOT NULL,
sk_medico INTEGER NOT NULL,
sk_unidade INTEGER NOT NULL,
sk_tempo INTEGER NOT NULL,
sk_procedimento INTEGER NOT NULL,

CONSTRAINT fk_dim_paciente
FOREIGN KEY (sk_paciente)
REFERENCES dw_floco.dim_paciente(sk_paciente),

CONSTRAINT fk_dim_medico
FOREIGN KEY (sk_medico)
REFERENCES dw_floco.dim_medico(sk_medico),

CONSTRAINT fk_dim_unidade
FOREIGN KEY (sk_unidade)
REFERENCES dw_floco.dim_unidade(sk_unidade),

CONSTRAINT fk_dim_tempo
FOREIGN KEY (sk_tempo)
REFERENCES dw_floco.dim_tempo(sk_tempo),

CONSTRAINT fk_dim_procedimento
FOREIGN KEY (sk_procedimento)
REFERENCES dw_floco.dim_procedimento(sk_procedimento)

);
