CREATE OR REPLACE TABLE local_duck.fs_general_abt AS

WITH base_flags AS (

    SELECT
        idVoo,

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
    *
    --atrasos.*,
    --cancelamentos.*
FROM base_flags flag
LEFT JOIN local_duck.fs_clima clima USING (idVoo)
LEFT JOIN local_duck.fs_atrasos atrasos USING (idVoo)
LEFT JOIN local_duck.fs_cancelamentos cancelamentos USING (idVoo)
LEFT JOIN local_duck.fs_operacional operacional USING (idVoo)
LEFT JOIN local_duck.fs_temporal temporal USING (idVoo)
