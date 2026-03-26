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


-- Commuter vs. Leisure by Metro

SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    COUNT(*) AS TripCount,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity), 2) AS PercentOfTrips
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
GROUP BY M.CoreCity, C.TripCategory
ORDER BY M.CoreCity, C.TripCategory;


-- Walk-up share inside Leisure only (by Metro)
SELECT
    M.CoreCity AS MetroArea,
    C.UserType,
    COUNT(*) AS TripCount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity),
        2
    ) AS PercentOfLeisureTrips
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
WHERE C.TripCategory = 'Leisure' AND C.UserType != ""
GROUP BY M.CoreCity, C.UserType
ORDER BY M.CoreCity, C.UserType;

-- One-way vs Round-trip Behavior for Leisure Trips (by Metro)
SELECT
    M.CoreCity AS MetroArea,
    CASE WHEN C.FromStationID = C.ToStationID THEN 'RoundTrip' ELSE 'OneWay' END AS TripDirection,
    COUNT(*) AS TripCount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity, C.TripCategory),
        2
    ) AS PercentWithinTripCategory
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
WHERE C.TripCategory = 'Leisure'
GROUP BY M.CoreCity, TripDirection
ORDER BY M.CoreCity, TripDirection


--Dockless vs Station-based Usage Leisure Only (by Metro)
SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    CASE
        WHEN C.FromStationID = -5000 OR C.ToStationID = -5000 THEN 'Dockless_Involved'
        ELSE 'Station_To_Station'
    END AS TripMode,
    COUNT(*) AS TripCount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity, C.TripCategory),
        2
    ) AS PercentWithinTripCategory
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
GROUP BY M.CoreCity, C.TripCategory, TripMode
ORDER BY M.CoreCity, C.TripCategory, TripMode;

--Classification Diagnostic Check - How Many Trips Satisfy Each Condition (by metro)
WITH Flags AS (
    SELECT
        MetroID,
        TripID,
        (StartDayOfWeek BETWEEN 1 AND 5) AS IsWeekday,
        (UserType = 'Subscriber') AS IsSubscriber,
        (
          (StartTime BETWEEN '06:30:00' AND '09:30:00')
          OR (StartTime BETWEEN '16:00:00' AND '19:00:00')
        ) AS IsRushHour,
        (FromStationID <> ToStationID) AS IsOneWay
    FROM Rentals
)
SELECT
    M.CoreCity AS MetroArea,
    ROUND(100.0 * AVG(IsWeekday), 2) AS Pct_Weekday,
    ROUND(100.0 * AVG(IsSubscriber), 2) AS Pct_Subscriber,
    ROUND(100.0 * AVG(IsRushHour), 2) AS Pct_RushHour,
    ROUND(100.0 * AVG(IsOneWay), 2) AS Pct_OneWay,
    ROUND(100.0 * AVG(IsWeekday AND IsSubscriber AND IsRushHour AND IsOneWay), 2) AS Pct_AllCommuterRules
FROM Flags F
JOIN MetroArea M ON F.MetroID = M.MetroID
GROUP BY M.CoreCity
ORDER BY M.CoreCity;







