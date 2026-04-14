CREATE OR REPLACE TABLE local_duck.fs_cancelamentos AS  --Criação de tabela de features no duckdb para facilitar manipulação

WITH base_cancelamentos AS (

SELECT    
    *,
    CAST(partidaReal AS TIMESTAMP) AS ts_real,
    CAST(partidaPrevista AS TIMESTAMP) AS ts_previsto
FROM database.slv_voos

)

SELECT
    a.idVoo,
    a.ts_previsto,
    a.ts_real,
    a.situacaoVoo,

    -- 1. Total de cancelamentos na janela
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL) AS cancelamentos24h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino) AS cancelamentosRota24h,

    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.aerodromoDestino = a.aerodromoDestino) AS cancelamentosDestino24h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.empresaAerea = a.empresaAerea) AS cancelamentosCia24h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino) AS cancelamentosCiaRota24h,


            -- 1. Total de cancelamentos na janela
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.ts_previsto >= (a.ts_previsto - INTERVAL 17 HOUR)) AS cancelamentos12h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 17 HOUR)) AS cancelamentosRota12h,
    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 17 HOUR)) AS cancelamentosDestino12h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.empresaAerea = a.empresaAerea AND b.ts_previsto >= (a.ts_previsto - INTERVAL 17 HOUR)) AS cancelamentosCia12h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 17 HOUR)) AS cancelamentosCiaRota12h,


            -- 1. Total de cancelamentos na janela
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.ts_previsto >= (a.ts_previsto - INTERVAL 8 HOUR)) AS cancelamentos3h,

    -- 2. Mesma Rota (Origem AND Destino)
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 8 HOUR)) AS cancelamentosRota3h,
    -- 3. Mesmo Destino
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 8 HOUR)) AS cancelamentosDestino3h,

    -- 4. Mesma Companhia
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.empresaAerea = a.empresaAerea AND b.ts_previsto >= (a.ts_previsto - INTERVAL 8 HOUR)) AS cancelamentosCia3h,

    -- 5. Mesma Companhia + Mesma Rota
    COUNT(b.idVoo) FILTER (WHERE b.ts_real IS NULL AND b.empresaAerea = a.empresaAerea AND b.aerodromoOrigem = a.aerodromoOrigem AND b.aerodromoDestino = a.aerodromoDestino AND b.ts_previsto >= (a.ts_previsto - INTERVAL 8 HOUR)) AS cancelamentosCiaRota3h

FROM base_cancelamentos a
LEFT JOIN base_cancelamentos b 
    ON  b.ts_previsto >= (a.ts_previsto - INTERVAL 29 HOUR)
    AND b.ts_previsto <= (a.ts_previsto - INTERVAL 5 HOUR)
    -- AND b.ts_real <= (a.ts_previsto - INTERVAL 1 HOUR) -- ASSUMINDO RISCO DE DATA LEAKAGE, POIS O VOO PODE TER SIDO CANCELADO APÓS O HORÁRIO PREVISTO, MAS ANTES DO HORÁRIO REAL, O QUE NÃO SERIA CONHECIDO NO MOMENTO DA PREVISÃO
GROUP BY ALL