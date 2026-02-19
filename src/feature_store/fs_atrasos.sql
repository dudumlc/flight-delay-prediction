/* SELECT 
    
    SUM( CASE WHEN situacaoVoo = "CANCELADO" THEN 1 END) AS qtdCancelados ,
    COUNT(situacaoVoo) AS qtdTotal, 
    ( SUM( CASE WHEN situacaoVoo = "CANCELADO" THEN 1 END) * 100.0) / COUNT(situacaoVoo)  AS pctCancelados

FROM voos
*/