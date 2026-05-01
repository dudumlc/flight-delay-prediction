CREATE TABLE slv_clima AS 

SELECT
    data,
    hora,
    precipitacaoTotal,
    pressaoAtmosferica,
    pressaoAtmosfericaMaxUltimaHora,
    pressaoAtmosfericaMinUltimaHora,
    --radiacaoGlobal,
    temperaturaBulboSeco,
    temperaturaPontoOrvalho,
    temperaturaMaxUltimaHora,
    temperaturaMinUltimaHora,
    temperaturaPontoOrvalhoMaxUltimaHora,
    temperaturaPontoOrvalhoMinUltimaHora,
    umidadeRelativaMaxUltimaHora,
    umidadeRelativaMinUltimaHora,
    umidadeRelativa,
    ventoDirecaoGraus,
    ventoRajadaMax,
    ventoVelocidade,
    anoRef,
    
    strftime('%Y-%m-%d %H:00:00', data || ' ' || hora || ':00') AS data_hora_clima

FROM brz_clima
WHERE
    CAST(anoRef AS INT) >= 2021;

CREATE INDEX idx_slv_data_hora_clima
ON slv_clima(data_hora_clima);
