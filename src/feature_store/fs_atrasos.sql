CREATE OR REPLACE TABLE local_duck.feature_store_voos AS  --Criação de tabela de features no duckdb para facilitar manipulação

WITH base_flags AS (
    SELECT
        *,
        CAST(partidaReal AS TIMESTAMP) AS ts_real,
        CAST(partidaPrevista AS TIMESTAMP) AS ts_previsto,
        
        -- Definição do delta de atraso - minutos
        date_diff('minute', CAST(partidaPrevista AS TIMESTAMP), CAST(partidaReal AS TIMESTAMP)) AS deltaPartida_minutos,

        -- Definição da variável target - booleano
        CASE 
            WHEN date_diff('minute', CAST(partidaPrevista AS TIMESTAMP), CAST(partidaReal AS TIMESTAMP)) > 30 THEN 1 
            ELSE 0 
        END AS flagAtraso
    FROM database.slv_voos
)

SELECT
    a.idVoo,
    a.ts_previsto,
    a.ts_real,
    a.flagAtraso,
    -- 1. Total de atrasos na janela
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1) AS atrasos24h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino) AS atrasosRota24h,

    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.aerodromoDestino = a.aerodromoDestino) AS atrasosDestino24h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea) AS atrasosCia24h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino) AS atrasosCiaRota24h,


        -- 1. Total de atrasos na janela
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.ts_previsto >= (a.ts_previsto - INTERVAL 13 HOUR)) AS atrasos12h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 13 HOUR)) AS atrasosRota12h,
    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 13 HOUR)) AS atrasosDestino12h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea AND b.ts_previsto >= (a.ts_previsto - INTERVAL 13 HOUR)) AS atrasosCia12h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 13 HOUR)) AS atrasosCiaRota12h,


            -- 1. Total de atrasos na janela
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.ts_previsto >= (a.ts_previsto - INTERVAL 4 HOUR)) AS atrasos3h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 4 HOUR)) AS atrasosRota3h,
    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 4 HOUR)) AS atrasosDestino3h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea AND b.ts_previsto >= (a.ts_previsto - INTERVAL 4 HOUR)) AS atrasosCia3h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 4 HOUR)) AS atrasosCiaRota3h

FROM base_flags a
LEFT JOIN base_flags b 
    ON  b.ts_previsto >= (a.ts_previsto - INTERVAL 25 HOUR)
    AND b.ts_previsto <= (a.ts_previsto - INTERVAL 1 HOUR)
    AND b.ts_real <= (a.ts_previsto - INTERVAL 1 HOUR) -- Anti-leakage
GROUP BY ALL