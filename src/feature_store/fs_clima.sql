SELECT
    *,
    strftime('%Y-%m-%d %H:00:00', data || ' ' || hora || ':00') AS data_hora_clima
FROM brz_clima
WHERE
    CAST(anoRef AS INT) >= 2021
