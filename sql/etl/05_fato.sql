-- ETL - passo 05: carga da fato_atendimento (incremental)
--
-- Granularidade: uma linha por procedimento realizado em um atendimento
-- (um ItemAtendimento do OLTP), identificada por item_atendimento_id.
--
-- Carga incremental: só entram os itens do staging cujo item_atendimento_id
-- ainda não está na fato. A primeira execução carrega tudo; as seguintes
-- carregam só o que foi cadastrado depois. Rodar de novo não duplica nada
-- (e a coluna é UNIQUE no DDL, então o banco também impediria).
--
-- Cada chave natural do OLTP é trocada pela chave substituta da dimensão:
--   data            -> sk_tempo
--   medico_id       -> sk_medico
--   unidade_id      -> sk_unidade
--   procedimento_id -> sk_procedimento
--   paciente_id     -> sk_paciente da VERSÃO válida na data do atendimento
--                      (SCD tipo 2, ver 04_scd2_paciente.sql)
--
-- As medidas (valor bruto e líquido) já chegam calculadas do staging.
--
-- A fato tem as mesmas colunas nos dois modelos, e as dimensões têm as mesmas
-- chaves naturais, então a mesma função carrega o estrela (dw) e o floco (dw_floco).
-- Precisa rodar DEPOIS das dimensões (passos 02, 03 e 04).

CREATE OR REPLACE FUNCTION staging.carregar_fato(p_esquema TEXT)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_faltando BIGINT;
BEGIN
    EXECUTE format($sql$
        INSERT INTO %1$I.fato_atendimento
              (item_atendimento_id, atendimento_id, quantidade, valor_bruto, desconto, valor_liquido,
               sk_tempo, sk_paciente, sk_medico, sk_unidade, sk_procedimento)
        SELECT s.item_atendimento_id, s.atendimento_id, s.quantidade, s.valor_bruto, s.desconto,
               s.valor_liquido, t.sk_tempo, p.sk_paciente, m.sk_medico, u.sk_unidade, pr.sk_procedimento
        FROM staging.stg_item_atendimento s
        INNER JOIN %1$I.dim_tempo t         ON t.data = s.data
        INNER JOIN %1$I.dim_medico m        ON m.medico_id = s.medico_id
        INNER JOIN %1$I.dim_unidade u       ON u.unidade_id = s.unidade_id
        INNER JOIN %1$I.dim_procedimento pr ON pr.procedimento_id = s.procedimento_id
        INNER JOIN %1$I.dim_paciente p      ON p.paciente_id = s.paciente_id
                                           AND p.data_inicio <= s.data
                                           AND (p.data_fim IS NULL OR s.data < p.data_fim)
        WHERE NOT EXISTS (SELECT 1 FROM %1$I.fato_atendimento f
                          WHERE f.item_atendimento_id = s.item_atendimento_id)
        ORDER BY s.item_atendimento_id
    $sql$, p_esquema);

    -- Validação: todo item do staging tem que estar na fato. Se algum ficou de
    -- fora (ex.: dimensão sem a linha correspondente), o INNER JOIN descartaria
    -- o item em silêncio. Aqui isso vira erro, e a transação inteira é desfeita.
    EXECUTE format($sql$
        SELECT COUNT(*) FROM staging.stg_item_atendimento s
        WHERE NOT EXISTS (SELECT 1 FROM %I.fato_atendimento f
                          WHERE f.item_atendimento_id = s.item_atendimento_id)
    $sql$, p_esquema)
    INTO v_faltando;

    IF v_faltando > 0 THEN
        RAISE EXCEPTION 'Carga da fato em %: % item(ns) do staging não encontraram as dimensões.',
                        p_esquema, v_faltando;
    END IF;
END;
$$;
