CREATE OR REPLACE TABLE local_duck.fs_temporal AS  --Criação de tabela de features no duckdb para facilitar manipulação

WITH base_flags AS (

    SELECT
        *,
        CAST(partidaReal AS TIMESTAMP) AS ts_partidaReal,
        CAST(partidaPrevista AS TIMESTAMP) AS ts_partidaPrevista,
        CAST(chegadaReal AS TIMESTAMP) AS ts_chegadaReal,
        CAST(chegadaPrevista AS TIMESTAMP) AS ts_chegadaPrevista
    FROM database.slv_voos

    WHERE
        partidaReal IS NOT NULL
        AND aerodromoOrigem = 'SBCF'

)


SELECT
    idVoo,

    CAST(STRFTIME(ts_partidaPrevista, '%d') AS INT) AS partidaDiaMes,
    MONTH(ts_partidaPrevista) AS partidaMes,

    DAYOFWEEK(ts_partidaPrevista) AS partidaDiaSemana,
    CASE 
        WHEN DAYOFWEEK(ts_partidaPrevista) IN (0,6) THEN 1 
        ELSE 0 
    END AS partidaFinalDeSemana,

    DAYOFYEAR(ts_partidaPrevista) AS partidaDiaAno,
    WEEK(ts_partidaPrevista) AS partidaSemanaAno,

    HOUR(ts_partidaPrevista) AS partidaHora,

    CASE 
        WHEN HOUR(ts_partidaPrevista) >= 0 AND HOUR(ts_partidaPrevista) < 6 THEN 'Madrugada'
        WHEN HOUR(ts_partidaPrevista) >= 6 AND HOUR(ts_partidaPrevista) < 12 THEN 'Manha'
        WHEN HOUR(ts_partidaPrevista) >= 12 AND HOUR(ts_partidaPrevista) < 18 THEN 'Tarde'
        ELSE 'Noite'
    END AS partidaPeriodoDia,

    HOUR(ts_partidaPrevista) + ( MINUTE(ts_partidaPrevista)/60.0 ) AS partidaHoraMinutoDecimal,

    CASE 
        WHEN MONTH(ts_partidaPrevista) IN (12, 1, 7) THEN 1 
        ELSE 0 
    END AS partidaAltaTemporada,

    CASE 
        WHEN DAY(ts_partidaPrevista) > 15 THEN DAY(ts_partidaPrevista) - 15 
        ELSE DAY(ts_partidaPrevista) 
    END AS partidaDiaQuinzena


FROM base_flags 