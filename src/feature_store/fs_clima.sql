SELECT 
    --CAST(voo.data_hora_clima AS TIMESTAMP) AS ts_data_hora_clima,
    --CAST(clima.data_hora_clima AS TIMESTAMP) AS ts_data_hora_voo,
    voo.idVoo,
    voo.partidaPrevista,
    clima.*
FROM database.slv_voos as voo

LEFT JOIN database.slv_clima as clima
ON CAST(clima.data_hora_clima AS TIMESTAMP) = (CAST(voo.data_hora_clima AS TIMESTAMP) - INTERVAL 1 HOUR)
GROUP BY ALL