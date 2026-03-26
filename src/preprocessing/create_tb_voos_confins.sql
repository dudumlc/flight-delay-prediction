
CREATE TABLE voos_bh AS 

SELECT 
    (empresaAerea || "-" || numeroVoo || "-" || aerodromoOrigem || "-" || aerodromoDestino || "-" || strftime('%Y%m%d%H%M', partidaPrevista) || "-" || strftime('%Y%m%d%H%M', chegadaPrevista)) AS idVoo,
    *,
    strftime('%Y-%m-%d %H:00:00', partidaPrevista) AS data_hora_clima
FROM voos
WHERE 
    aerodromoOrigem = 'SBCF'
    AND CAST(anoRef AS INT) >= 2015
    AND partidaPrevista IS NOT NULL 
    AND partidaReal IS NOT NULL
    AND chegadaPrevista IS NOT NULL 
    AND chegadaReal IS NOT NULL
GROUP BY idVoo 



