CREATE TEMPORARY TABLE ClassifiedTrips AS
    SELECT
        TripID,
        MetroID,
        CASE
            WHEN StartDayOfWeek BETWEEN 1 AND 5           -- Weekday
                 AND UserType = 'Subscriber'              -- Regular users
                 AND (
                      (StartTime BETWEEN '06:30:00' AND '09:30:00') OR
                      (StartTime BETWEEN '16:00:00' AND '19:00:00')
                     )
                 AND FromStationID <> ToStationID          -- One-way trip
            THEN 'Commuter'
            ELSE 'Leisure'
        END AS TripCategory,
        TripDuration_Minutes,
        CASE
            WHEN MONTH(StartDate) IN (12, 1, 2) THEN 'Winter'
            WHEN MONTH(StartDate) IN (3, 4, 5) THEN 'Spring'
            WHEN MONTH(StartDate) IN (6, 7, 8) THEN 'Summer'
            WHEN MONTH(StartDate) IN (9, 10, 11) THEN 'Fall'
        END AS Season
    FROM Rentals;
    
    
SELECT
    M.CoreCity AS MetroArea,
    C.Season,
    C.TripCategory,
    COUNT(*) AS TripCount,
    AVG(C.TripDuration_Minutes) AS AvgDuration_Minutes,
    STDDEV(C.TripDuration_Minutes) AS DurationStdDev,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity, C.Season),
        2
    ) AS PercentOfTrips
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
GROUP BY M.CoreCity, C.Season, C.TripCategory
ORDER BY M.CoreCity, FIELD(C.Season,'Spring','Summer','Fall', 'Winter'), C.TripCategory;

SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    COUNT(*) AS TripCount,
    AVG(C.TripDuration_Minutes) AS AvgDuration_Minutes,
    STDDEV(C.TripDuration_Minutes) AS DurationStdDev,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY M.CoreCity),
        2
    ) AS PercentOfTrips
FROM ClassifiedTrips C
JOIN MetroArea M ON C.MetroID = M.MetroID
GROUP BY M.CoreCity, C.TripCategory
ORDER BY M.CoreCity, C.TripCategory;









