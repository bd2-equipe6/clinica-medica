-- ETL - executa todos os passos e registra as contagens de linhas
--
-- Primeira vez: rodar os scripts 01, 02, 03, 04 (que só criam as funções)
-- e depois este. Nas próximas vezes (ex.: depois de cadastrar um atendimento
-- pela aplicação), basta rodar:
--
--     SELECT * FROM staging.executar_etl();
--
-- Tudo roda numa única transação: se um passo falhar, nada é gravado no DW.
--
-- PENDENTE: carga da fato (passo 05), que depende da coluna
-- item_atendimento_id na fato_atendimento dos dois DDLs.

CREATE OR REPLACE FUNCTION staging.executar_etl()
RETURNS TABLE (execucao INT, tabela VARCHAR, linhas_antes BIGINT, linhas_depois BIGINT, diferenca BIGINT)
LANGUAGE plpgsql AS $$
#variable_conflict use_column
DECLARE
    v_execucao INT := nextval('staging.seq_execucao_etl');
    v_tabela   TEXT;
    v_tabelas  TEXT[] := ARRAY[
        'staging.stg_item_atendimento',
        'dw.dim_tempo', 'dw.dim_paciente', 'dw.dim_medico',
        'dw.dim_unidade', 'dw.dim_procedimento', 'dw.fato_atendimento',
        'dw_floco.dim_tempo', 'dw_floco.dim_paciente', 'dw_floco.dim_medico',
        'dw_floco.dim_estado', 'dw_floco.dim_cidade', 'dw_floco.dim_unidade',
        'dw_floco.dim_categoria', 'dw_floco.dim_procedimento', 'dw_floco.fato_atendimento'
    ];
BEGIN
    -- Contagens antes
    FOREACH v_tabela IN ARRAY v_tabelas LOOP
        INSERT INTO staging.log_carga (execucao_id, tabela, linhas_antes)
        VALUES (v_execucao, v_tabela, staging.contar_linhas(v_tabela));
    END LOOP;

    -- 01 - extração para o staging
    PERFORM staging.extrair_oltp();

    -- 02 - dimensão Tempo
    PERFORM staging.carregar_dim_tempo('dw');
    PERFORM staging.carregar_dim_tempo('dw_floco');

    -- 03 - dimensões médico, unidade e procedimento
    PERFORM staging.carregar_dimensoes_estrela();
    PERFORM staging.carregar_dimensoes_floco();

    -- 04 - paciente com SCD tipo 2 (antes da fato)
    PERFORM staging.carregar_dim_paciente_scd2('dw');
    PERFORM staging.carregar_dim_paciente_scd2('dw_floco');

    -- 05 - fato (PENDENTE)

    -- Contagens depois
    UPDATE staging.log_carga l
       SET linhas_depois = staging.contar_linhas(l.tabela)
     WHERE l.execucao_id = v_execucao;

    RETURN QUERY
    SELECT l.execucao_id, l.tabela, l.linhas_antes, l.linhas_depois,
           l.linhas_depois - l.linhas_antes
    FROM staging.log_carga l
    WHERE l.execucao_id = v_execucao
    ORDER BY l.id;
END;
$$;

SELECT * FROM staging.executar_etl();
