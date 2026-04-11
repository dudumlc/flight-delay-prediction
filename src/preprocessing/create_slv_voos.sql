CREATE TABLE slv_voos AS 

SELECT 
    (empresaAerea || "-" || numeroVoo || "-" || aerodromoOrigem || "-" || aerodromoDestino || "-" || strftime('%Y%m%d%H%M', partidaPrevista) || "-" || strftime('%Y%m%d%H%M', chegadaPrevista)) AS idVoo,
    *,
    strftime('%Y-%m-%d %H:00:00', partidaPrevista) AS data_hora_clima
FROM brz_voos
WHERE 
    (aerodromoOrigem = 'SBCF' OR aerodromoDestino = 'SBCF') AND
    CAST(anoRef AS INT) > 2021
    AND partidaPrevista IS NOT NULL 
    -- AND partidaReal IS NOT NULL
    -- AND chegadaPrevista IS NOT NULL 
    -- AND chegadaReal IS NOT NULL
GROUP BY idVoo
ORDER BY partidaPrevista;

CREATE INDEX idx_slv_partidaPrevista 
ON slv_voos(partidaPrevista);


