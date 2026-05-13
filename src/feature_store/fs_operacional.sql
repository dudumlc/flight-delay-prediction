--CREATE OR REPLACE TABLE local_duck.fs_operacional AS  --Criação de tabela de features no duckdb para facilitar manipulação

WITH base_flags AS (

    SELECT
        *,
        CAST(partidaReal AS TIMESTAMP) AS ts_partidaReal,
        CAST(partidaPrevista AS TIMESTAMP) AS ts_partidaPrevista,
        CAST(chegadaReal AS TIMESTAMP) AS ts_chegadaReal,
        CAST(chegadaPrevista AS TIMESTAMP) AS ts_chegadaPrevista,
        
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

)


SELECT
    a.idVoo,
    a.codeTipoLinha,
    a.empresaAerea,
    a.ts_partidaPrevista,
    DATE_TRUNC('day', a.ts_partidaPrevista) AS diaPartida,
    CASE WHEN a.codeTipoLinha in ('N', 'C') THEN 1 ELSE 0 END AS vooDomestico,
    CASE WHEN a.codeTipoLinha in ('I', 'G') THEN 1 ELSE 0 END AS vooInternacional,
    CASE WHEN a.codeTipoLinha in ('C', 'G') THEN 1 ELSE 0 END AS vooCargueiro,
    datediff('minute', a.ts_partidaPrevista, a.ts_chegadaPrevista) AS deltaPartida_minutos,

    COUNT(b.idVoo) FILTER (a.empresaAerea = b.empresaAerea AND b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 2 HOUR) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 2 HOUR)) AS voosMesmaEmpresaIntervalo2h,
    COUNT(b.idVoo) FILTER (a.empresaAerea = b.empresaAerea AND b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 1 HOUR) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 1 HOUR)) AS voosMesmaEmpresaIntervalo1h,
    COUNT(b.idVoo) FILTER (a.empresaAerea = b.empresaAerea AND b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 30 MINUTE) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 30 MINUTE)) AS voosMesmaEmpresaIntervalo30min,
    COUNT(b.idVoo) FILTER (a.empresaAerea = b.empresaAerea AND b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 15 MINUTE) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 15 MINUTE)) AS voosMesmaEmpresaIntervalo15min,
    
    COUNT(b.idVoo) FILTER (b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 2 HOUR) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 2 HOUR)) AS voosConfinsIntervalo2h,
    COUNT(b.idVoo) FILTER (b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 1 HOUR) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 1 HOUR)) AS voosConfinsIntervalo1h,
    COUNT(b.idVoo) FILTER (b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 30 MINUTE) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 30 MINUTE)) AS voosConfinsIntervalo30min,
    COUNT(b.idVoo) FILTER (b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 15 MINUTE) AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 15 MINUTE)) AS voosConfinsIntervalo15min,

    COUNT(b.idVoo) FILTER (DATE_TRUNC('day', b.ts_partidaPrevista) = DATE_TRUNC('day', a.ts_partidaPrevista) AND b.ts_partidaPrevista < a.ts_partidaPrevista) = 0 AS primeiroVooDiaConfins, 
    COUNT(b.idVoo) FILTER (a.aerodromoDestino = b.aerodromoDestino AND DATE_TRUNC('day', b.ts_partidaPrevista) = DATE_TRUNC('day', a.ts_partidaPrevista) AND b.ts_partidaPrevista < a.ts_partidaPrevista) = 0 AS primeiroVooDiaDestino, 
    COUNT(b.idVoo) FILTER (a.empresaAerea = b.empresaAerea AND DATE_TRUNC('day', b.ts_partidaPrevista) = DATE_TRUNC('day', a.ts_partidaPrevista) AND b.ts_partidaPrevista < a.ts_partidaPrevista) = 0 AS primeiroVooDiaEmpresa, 
    COUNT(b.idVoo) FILTER (a.aerodromoDestino = b.aerodromoDestino AND a.empresaAerea = b.empresaAerea AND DATE_TRUNC('day', b.ts_partidaPrevista) = DATE_TRUNC('day', a.ts_partidaPrevista) AND b.ts_partidaPrevista < a.ts_partidaPrevista) = 0 AS primeiroVooDiaEmpresaDestino

FROM base_flags a
LEFT JOIN base_flags b 
    ON  b.ts_partidaPrevista >= (a.ts_partidaPrevista - INTERVAL 24 HOUR)
    AND b.ts_partidaPrevista <= (a.ts_partidaPrevista + INTERVAL 24 HOUR)
    -- AND b.ts_chegadaReal <= (a.ts_chegadaPrevista - INTERVAL 1 HOUR) -- Anti-leakage

GROUP BY ALL