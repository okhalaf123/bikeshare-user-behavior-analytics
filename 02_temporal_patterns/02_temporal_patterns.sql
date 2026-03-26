DROP TEMPORARY TABLE IF EXISTS ClassifiedTrips;

CREATE TEMPORARY TABLE ClassifiedTrips AS
SELECT
    TripID,
    MetroID,
    StartDate,
    StartTime,
    StartDayOfWeek,
    FromStationID,
    ToStationID,
    UserType,
    TripDuration_Minutes,
    CASE
        WHEN StartDayOfWeek BETWEEN 1 AND 5
             AND UserType = 'Subscriber'
             AND (
                  (StartTime BETWEEN '06:30:00' AND '09:30:00')
                  OR (StartTime BETWEEN '16:00:00' AND '19:00:00')
                 )
             AND FromStationID <> ToStationID
        THEN 'Commuter'
        ELSE 'Leisure'
    END AS TripCategory
FROM Rentals;


--1) Hourly usage by metro & trip category
SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    HOUR(C.StartTime) AS StartHour,
    COUNT(*) AS TripCount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity, C.TripCategory),
        2
    ) AS PercentWithinCategory
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
GROUP BY M.CoreCity, C.TripCategory, StartHour
ORDER BY M.CoreCity, C.TripCategory, StartHour;

--2) Daily usage by metro & trip category
SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    D.DayName_en AS DayOfWeek,
    COUNT(*) AS TripCount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity, C.TripCategory),
        2
    ) AS PercentWithinCategory
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
JOIN DaysOfTheWeek D ON C.StartDayOfWeek = D.DayID
GROUP BY M.CoreCity, C.TripCategory, DayID, DayOfWeek
ORDER BY M.CoreCity, C.TripCategory, DayID;

--3) Monthly usage by metro & trip category
SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    YEAR(C.StartDate) AS YEAR,
    MONTH(C.StartDate) AS MONTH,
    COUNT(*) AS TripCount
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
GROUP BY M.CoreCity, C.TripCategory, YEAR, MONTH
ORDER BY M.CoreCity, C.TripCategory, YEAR, MONTH;

--4) Std. deviation across months (share of trips)
WITH MonthlyShares AS (
    SELECT
        M.CoreCity AS MetroArea,
        YEAR(C.StartDate) AS YEAR,
        MONTH(C.StartDate) AS MONTH,
        ROUND(
            100.0 * SUM(CASE WHEN C.TripCategory = 'Commuter' THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS CommuterSharePct
    FROM ClassifiedTrips C
    JOIN MetroArea M ON C.MetroID = M.MetroID
    GROUP BY M.CoreCity, YEAR, MONTH
)
SELECT
    MetroArea,
    STDDEV(CommuterSharePct) AS StdDevMonthlyCommuterSharePct
FROM MonthlyShares
GROUP BY MetroArea
ORDER BY MetroArea;


-- Rain Table
DROP TEMPORARY TABLE IF EXISTS TripsWithWeather;

CREATE TEMPORARY TABLE TripsWithWeather AS
SELECT
    T.MetroID,
    T.StartDate,
    T.StartHour,
    T.TripCategory,
    T.TripCount,
    W.Rain_mm_1h,
    CASE WHEN W.Rain_mm_1h > 0 THEN 1 ELSE 0 END AS IsRainHour
FROM TripsHourly T
JOIN Weather W
  ON T.MetroID = W.MetroID
 AND T.StartDate = W.DateOfReading
 AND T.StartHour = W.HourOfReading;

--5) Rain Resilience and Participation Ratio (Commuter vs Leisure, by Metro)
WITH TripRainShare AS (
    SELECT
        T.MetroID,
        T.TripCategory,
        100.0 * SUM(CASE WHEN T.IsRainHour = 1 THEN T.TripCount ELSE 0 END) / SUM(T.TripCount) AS PctTripsInRain
    FROM TripsWithWeather T
    GROUP BY T.MetroID, T.TripCategory
),
RainHourShare AS (
    SELECT
        W.MetroID,
        100.0 * SUM(CASE WHEN W.Rain_mm_1h > 0 THEN 1 ELSE 0 END) / COUNT(*) AS PctRainyHours
    FROM Weather W
    GROUP BY W.MetroID
)
SELECT
    M.CoreCity AS MetroArea,
    TR.TripCategory,
    ROUND(TR.PctTripsInRain, 2) AS PctTripsInRainHours,
    ROUND(RH.PctRainyHours, 2) AS PctRainyHours,
    ROUND(TR.PctTripsInRain / NULLIF(RH.PctRainyHours, 0), 3) AS RainParticipationRatio
FROM TripRainShare TR
JOIN RainHourShare RH ON TR.MetroID = RH.MetroID
JOIN MetroArea M ON TR.MetroID = M.MetroID
ORDER BY M.CoreCity, TR.TripCategory;


--6) Rain Contingency Table
SELECT
    M.CoreCity AS MetroArea,
    T.TripCategory,
    T.IsRainHour,
    SUM(T.TripCount) AS Trips
FROM TripsWithWeather T
JOIN MetroArea M ON T.MetroID = M.MetroID
GROUP BY M.CoreCity, T.TripCategory, T.IsRainHour
ORDER BY M.CoreCity, T.TripCategory, T.IsRainHour;


