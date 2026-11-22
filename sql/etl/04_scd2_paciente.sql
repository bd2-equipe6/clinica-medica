-- ETL - passo 04: dimensão paciente com SCD tipo 2
--
-- Quando a cidade (ou a UF) de um paciente muda no OLTP, o DW NÃO sobrescreve
-- a linha antiga. Ele fecha a versão atual e cria uma versão nova:
--
--   sk  paciente_id  cidade    data_inicio  data_fim    registro_atual
--   10  42           GOIÂNIA   2024-03-01   2026-11-21  false   <- versão antiga
--   87  42           ANÁPOLIS  2026-11-21   NULL        true    <- versão atual
--
-- Assim os atendimentos antigos continuam contando para Goiânia e os novos
-- para Anápolis.
--
-- Convenção de datas: a versão vale de data_inicio (inclusive) até data_fim
-- (exclusive). A carga da fato deve procurar a versão com
--   data_inicio <= data do atendimento
--   AND (data_fim IS NULL OR data do atendimento < data_fim)
--
-- Nome e convênio são SCD tipo 1: se mudarem, são sobrescritos em todas as
-- versões do paciente, sem gerar versão nova.
--
-- Este passo precisa rodar ANTES da carga da fato, para a fato já encontrar
-- a versão nova do paciente.
--
-- A tabela dim_paciente é idêntica nos dois modelos, então a mesma função
-- serve ao estrela (dw) e ao floco de neve (dw_floco).

CREATE OR REPLACE FUNCTION staging.carregar_dim_paciente_scd2(p_esquema TEXT)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    -- 1) SCD tipo 1: nome e convênio sobrescritos em todas as versões.
    EXECUTE format($sql$
        UPDATE %I.dim_paciente d
           SET nome = s.nome, convenio = s.convenio
        FROM staging.stg_paciente s
        WHERE d.paciente_id = s.paciente_id
          AND (d.nome, d.convenio) IS DISTINCT FROM (s.nome, s.convenio)
    $sql$, p_esquema);

    -- 2) SCD tipo 2: fecha a versão atual de quem mudou de cidade ou UF.
    EXECUTE format($sql$
        UPDATE %I.dim_paciente d
           SET data_fim = CURRENT_DATE,
               registro_atual = FALSE
        FROM staging.stg_paciente s
        WHERE d.paciente_id = s.paciente_id
          AND d.registro_atual
          AND (d.cidade, d.uf) IS DISTINCT FROM (s.cidade, s.uf)
    $sql$, p_esquema);

    -- 3) Insere a versão atual de quem ficou sem nenhuma:
    --    - paciente novo: a primeira versão começa no cadastro (ou no primeiro
    --      atendimento, se for anterior), para cobrir todos os atendimentos dele;
    --    - paciente que acabou de ter a versão fechada no passo 2: a versão
    --      nova começa hoje.
    EXECUTE format($sql$
        INSERT INTO %I.dim_paciente
              (paciente_id, nome, cidade, uf, convenio, data_inicio, data_fim, registro_atual)
        SELECT s.paciente_id, s.nome, s.cidade, s.uf, s.convenio,
               CASE
                   WHEN EXISTS (SELECT 1 FROM %I.dim_paciente h WHERE h.paciente_id = s.paciente_id)
                       THEN CURRENT_DATE
                   ELSE COALESCE(LEAST(s.data_cadastro,
                                       (SELECT MIN(i.data) FROM staging.stg_item_atendimento i
                                        WHERE i.paciente_id = s.paciente_id)),
                                 CURRENT_DATE)
               END,
               NULL,
               TRUE
        FROM staging.stg_paciente s
        WHERE NOT EXISTS (SELECT 1 FROM %I.dim_paciente d
                          WHERE d.paciente_id = s.paciente_id AND d.registro_atual)
        ORDER BY s.paciente_id
    $sql$, p_esquema, p_esquema, p_esquema);
END;
$$;
