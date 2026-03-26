
/*
WITH voos_status AS (
    SELECT 
        *,
        JULIANDAY(partidaPrevista) AS tempo_numeric,
        CASE 
            WHEN (((JULIANDAY(partidaReal) - JULIANDAY(partidaPrevista))+30) * 24 * 60) < 0 THEN "ADIANTADO" 
            WHEN (((JULIANDAY(partidaReal) - JULIANDAY(partidaPrevista))+30) * 24 * 60) > 0 THEN "ATRASADO"
            ELSE "NORMAL"
        END AS deltaPartida
        FROM voos
        WHERE partidaPrevista IS NOT NULL AND partidaReal IS NOT NULL
)

SELECT 
    v1.*,
    -- Atrasos HOJE (até agora)
    SUM(CASE WHEN deltaPartida = 'ATRASADO' THEN 1 ELSE 0 END) OVER (
        PARTITION BY date(v1.partidaPrevista) 
        ORDER BY v1.partidaPrevista 
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS atrasos_hoje_acumulado,

    -- Atrasos ONTEM (Dia inteiro)
    (SELECT COUNT(*) FROM voos_status v2 
     WHERE date(v2.partidaPrevista) = date(v1.partidaPrevista, '-1 day') 
     AND v2.deltaPartida = 'ATRASADO') AS atrasos_ontem,

    -- Atrasos ANTEONTEM (Dia inteiro)
    (SELECT COUNT(*) FROM voos_status v2 
     WHERE date(v2.partidaPrevista) = date(v1.partidaPrevista, '-2 days') 
     AND v2.deltaPartida = 'ATRASADO') AS atrasos_anteontem

FROM voos_status v1
LIMIT 100;
*/

/*
WITH voos_status AS (
    SELECT *,
    CASE 
        WHEN ((JULIANDAY(partidaReal) - JULIANDAY(partidaPrevista)) * 24 * 60) < 0 THEN "ADIANTADO" 
        WHEN ((JULIANDAY(partidaReal) - JULIANDAY(partidaPrevista)) * 24 * 60) > 0 THEN "ATRASADO"
        ELSE "NORMAL"
    END AS deltaPartida
    FROM voos
    WHERE partidaPrevista IS NOT NULL AND partidaReal IS NOT NULL
)
SELECT 
    *,
    SUM(CASE WHEN deltaPartida = "ATRASADO" THEN 1 ELSE 0 END) OVER (
        PARTITION BY date(partidaPrevista) 
        ORDER BY partidaPrevista 
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS qtdAtrasosD0
FROM voos_status
LIMIT 100;
*/

SELECT 
    *,

    (JULIANDAY(partidaReal) - JULIANDAY(partidaPrevista)) * 24 * 60 AS deltaPartida_minutos,

    CASE 
        WHEN ((JULIANDAY(partidaReal) - (JULIANDAY(partidaPrevista)+30)) * 24 * 60 ) < 0 THEN "ADIANTADO"
        WHEN ((JULIANDAY(partidaReal) - (JULIANDAY(partidaPrevista)+30)) * 24 * 60 ) > 0 THEN "ATRASADO"
        ELSE "NORMAL"
    END AS status_partida
FROM voos
LIMIT 10