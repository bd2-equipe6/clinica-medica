-- ETL - passo 02: geração da dimensão Tempo
--
-- A dimensão Tempo não vem do OLTP: ela é GERADA, um dia por linha.
-- O intervalo vai de 1º de janeiro do ano do primeiro atendimento até
-- 31 de dezembro do ano do último, para o calendário ficar completo
-- (dias sem atendimento também existem na dimensão).
--
-- Só insere os dias que ainda não existem, então rodar de novo não duplica.
-- A mesma função carrega o modelo estrela (dw) e o floco de neve (dw_floco),
-- que têm a tabela dim_tempo idêntica.

CREATE OR REPLACE FUNCTION staging.carregar_dim_tempo(p_esquema TEXT)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_inicio DATE;
    v_fim    DATE;
BEGIN
    SELECT date_trunc('year', MIN(data))::date,
           (date_trunc('year', MAX(data)) + INTERVAL '1 year - 1 day')::date
      INTO v_inicio, v_fim
    FROM staging.stg_item_atendimento;

    IF v_inicio IS NULL THEN
        RAISE NOTICE 'Sem atendimentos no staging: dim_tempo de % não foi alterada.', p_esquema;
        RETURN;
    END IF;

    EXECUTE format($sql$
        INSERT INTO %I.dim_tempo (data, dia, mes, trimestre, semestre, ano, nome_mes, dia_semana)
        SELECT d::date,
               EXTRACT(DAY     FROM d)::int,
               EXTRACT(MONTH   FROM d)::int,
               EXTRACT(QUARTER FROM d)::int,
               CASE WHEN EXTRACT(MONTH FROM d) <= 6 THEN 1 ELSE 2 END,
               EXTRACT(YEAR    FROM d)::int,
               (ARRAY['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho',
                      'Agosto','Setembro','Outubro','Novembro','Dezembro'])[EXTRACT(MONTH FROM d)::int],
               (ARRAY['Domingo','Segunda-feira','Terça-feira','Quarta-feira',
                      'Quinta-feira','Sexta-feira','Sábado'])[EXTRACT(DOW FROM d)::int + 1]
        FROM generate_series($1::timestamp, $2::timestamp, INTERVAL '1 day') AS d
        WHERE NOT EXISTS (SELECT 1 FROM %I.dim_tempo t WHERE t.data = d::date)
        ORDER BY d
    $sql$, p_esquema, p_esquema)
    USING v_inicio, v_fim;
END;
$$;
