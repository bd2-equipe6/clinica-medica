DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;

CREATE TABLE dw.dim_tempo(
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

CREATE TABLE dw.dim_procedimento(
sk_procedimento SERIAL PRIMARY KEY,
procedimento_id BIGINT NOT NULL,
codigo VARCHAR(30) NOT NULL,
nome VARCHAR(120) NOT NULL,
categoria VARCHAR(80) NOT NULL
);

CREATE TABLE dw.dim_medico(
sk_medico SERIAL PRIMARY KEY,
medico_id BIGINT NOT NULL,
nome VARCHAR(120) NOT NULL,
crm VARCHAR(50)NOT NULL
);

CREATE TABLE dw.dim_unidade(
    sk_unidade SERIAL PRIMARY KEY,
    unidade_id BIGINT NOT NULL,
    nome VARCHAR(80) NOT NULL,
    cidade VARCHAR(80) NOT NULL,
    uf CHAR(2) NOT NULL
);

CREATE TABLE dw.dim_paciente(
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

CREATE TABLE dw.fato_atendimento(
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
REFERENCES dw.dim_paciente(sk_paciente),

CONSTRAINT fk_dim_medico
FOREIGN KEY (sk_medico)
REFERENCES dw.dim_medico(sk_medico),

CONSTRAINT fk_dim_unidade
FOREIGN KEY (sk_unidade)
REFERENCES dw.dim_unidade(sk_unidade),

CONSTRAINT fk_dim_tempo
FOREIGN KEY (sk_tempo)
REFERENCES dw.dim_tempo(sk_tempo),

CONSTRAINT fk_dim_procedimento
FOREIGN KEY (sk_procedimento)
REFERENCES dw.dim_procedimento(sk_procedimento)

);
