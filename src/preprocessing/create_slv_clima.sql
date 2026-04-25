CREATE OR REPLACE TABLE slv_clima AS 

SELECT
    *,
    strftime('%Y-%m-%d %H:00:00', data || ' ' || hora || ':00') AS data_hora_clima
FROM brz_clima
WHERE
    CAST(anoRef AS INT) >= 2021;

CREATE INDEX idx_slv_data_hora_clima
ON slv_clima(data_hora_clima);
