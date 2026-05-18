CREATE OR REPLACE TABLE local_duck.fs_atrasos AS  --Criação de tabela de features no duckdb para facilitar manipulação

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

    WHERE
        partidaReal IS NOT NULL
        AND aerodromoOrigem = 'SBCF'
),

base_features_atrasos AS (

SELECT
    a.idVoo,
    --a.ts_previsto,
    --a.ts_real,
    --a.flagAtraso,
    
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
    COUNT(b.idVoo) FILTER (WHERE b.flagAtraso = 1 AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 4 HOUR)) AS atrasosCiaRota3h,


    -- 1. Total de voos na janela
    COUNT(b.idVoo) AS voos24h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino) AS voosRota24h,

    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.aerodromoDestino = a.aerodromoDestino) AS voosDestino24h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.empresaAerea = a.empresaAerea) AS voosCia24h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino) AS voosCiaRota24h,



FROM base_flags a
LEFT JOIN base_flags b 
    ON  b.ts_previsto >= (a.ts_previsto - INTERVAL 25 HOUR)
    AND b.ts_previsto <= (a.ts_previsto - INTERVAL 1 HOUR)
    AND b.ts_real <= (a.ts_previsto - INTERVAL 1 HOUR) -- Anti-leakage
GROUP BY ALL

),

base_final AS (

SELECT 
    *,
    CASE 
        WHEN atrasos24h = 0 AND atrasos12h > 0 THEN 1
        WHEN atrasos24h = 0 AND atrasos12h = 0 THEN 0
        ELSE atrasos12h/atrasos24h 
    END AS ratio_atrasos12h_24h,

    CASE 
        WHEN atrasos24h = 0 AND atrasos3h > 0 THEN 1
        WHEN atrasos24h = 0 AND atrasos3h = 0 THEN 0
        ELSE atrasos3h/atrasos24h 
    END AS ratio_atrasos3h_24h,

    CASE 
        WHEN atrasosRota24h = 0 AND atrasosRota12h > 0 THEN 1 
        WHEN atrasosRota24h = 0 AND atrasosRota12h = 0 THEN 0
        ELSE atrasosRota12h/atrasosRota24h 
    END AS ratio_atrasosRota12h_24h,

    CASE 
        WHEN atrasosRota24h = 0 AND atrasosRota3h > 0 THEN 1 
        WHEN atrasosRota24h = 0 AND atrasosRota3h = 0 THEN 0
        ELSE atrasosRota3h/atrasosRota24h 
    END AS ratio_atrasosRota3h_24h,

    CASE 
        WHEN atrasosDestino24h = 0 AND atrasosDestino12h > 0 THEN 1 
        WHEN atrasosDestino24h = 0 AND atrasosDestino12h = 0 THEN 0
        ELSE atrasosDestino12h/atrasosDestino24h 
    END AS ratio_atrasosDestino12h_24h,

    CASE 
        WHEN atrasosDestino24h = 0 AND atrasosDestino3h > 0 THEN 1 
        WHEN atrasosDestino24h = 0 AND atrasosDestino3h = 0 THEN 0
        ELSE atrasosDestino3h/atrasosDestino24h 
    END AS ratio_atrasosDestino3h_24h,

    CASE 
        WHEN atrasosCia24h = 0 AND atrasosCia12h > 0 THEN 1 
        WHEN atrasosCia24h = 0 AND atrasosCia12h = 0 THEN 0
        ELSE atrasosCia12h/atrasosCia24h 
    END AS ratio_atrasosCia12h_24h,

    CASE 
        WHEN atrasosCia24h = 0 AND atrasosCia3h > 0 THEN 1 
        WHEN atrasosCia24h = 0 AND atrasosCia3h = 0 THEN 0
        ELSE atrasosCia3h/atrasosCia24h 
    END AS ratio_atrasosCia3h_24h,

    CASE 
        WHEN atrasosCiaRota24h = 0 AND atrasosCiaRota12h > 0 THEN 1 
        WHEN atrasosCiaRota24h = 0 AND atrasosCiaRota12h = 0 THEN 0
        ELSE atrasosCiaRota12h/atrasosCiaRota24h 
    END AS ratio_atrasosCiaRota12h_24h,

    CASE 
        WHEN atrasosCiaRota24h = 0 AND atrasosCiaRota3h > 0 THEN 1 
        WHEN atrasosCiaRota24h = 0 AND atrasosCiaRota3h = 0 THEN 0
        ELSE atrasosCiaRota3h/atrasosCiaRota24h 
    END AS ratio_atrasosCiaRota3h_24h,


    CASE 
        WHEN voos24h = 0 AND atrasos24h > 0 THEN 1 
        WHEN voos24h = 0 AND atrasos24h = 0 THEN 0
        ELSE atrasos24h/voos24h 
    END AS pct_atrasos24h,

    CASE 
        WHEN voosRota24h = 0 AND atrasosRota24h > 0 THEN 1 
        WHEN voosRota24h = 0 AND atrasosRota24h = 0 THEN 0
        ELSE atrasosRota24h/voosRota24h 
    END AS pct_atrasosRota24h,

    CASE 
        WHEN voosDestino24h = 0 AND atrasosDestino24h > 0 THEN 1 
        WHEN voosDestino24h = 0 AND atrasosDestino24h = 0 THEN 0
        ELSE atrasosDestino24h/voosDestino24h 
    END AS pct_atrasosDestino24h,

    CASE 
        WHEN voosCia24h = 0 AND atrasosCia24h > 0 THEN 1 
        WHEN voosCia24h = 0 AND atrasosCia24h = 0 THEN 0
        ELSE atrasosCia24h/voosCia24h 
    END AS pct_atrasosCia24h,

    CASE 
        WHEN voosCiaRota24h = 0 AND atrasosCiaRota24h > 0 THEN 1 
        WHEN voosCiaRota24h = 0 AND atrasosCiaRota24h = 0 THEN 0
        ELSE atrasosCiaRota24h/voosCiaRota24h 
    END AS pct_atrasosCiaRota24h

FROM base_features_atrasos

)

SELECT 
    * 
FROM base_final