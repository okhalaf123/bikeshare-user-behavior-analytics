-- Create Classified Trips Table
-- Filters out trip records that are unlikely to represent valid completed trips.
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
FROM Rentals
WHERE NOT (
      TripDuration_Minutes = 0
      AND FromStationID <> ToStationID
  )
  AND TripDuration_Minutes <= 1440;

SELECT *
FROM ClassifiedTrips;
-- 1) Retrieve Table With All Valid Trips to Create Box Plot
SELECT 
    C.TripID,
    M.CoreCity,
    C.TripDuration_Minutes,
    C.TripCategory
FROM ClassifiedTrips C
JOIN MetroArea M 
    ON C.MetroID = M.MetroID;


-- 2) Summary Statistics by Metro x Trip Category
DROP TEMPORARY TABLE IF EXISTS ClassifiedTrips_Ranked;

CREATE TEMPORARY TABLE ClassifiedTrips_Ranked AS
SELECT
    TripID,
    MetroID,
    TripCategory,
    TripDuration_Minutes,
    PERCENT_RANK() OVER (
        PARTITION BY MetroID, TripCategory
        ORDER BY TripDuration_Minutes
    ) AS pr
FROM ClassifiedTrips;

WITH Statistics AS (
    SELECT
        MetroID,
        TripCategory,
        MIN(TripDuration_Minutes) AS MinDuration,
        MAX(CASE WHEN pr <= 0.25 THEN TripDuration_Minutes END) AS Q1_Approx,
        MAX(CASE WHEN pr <= 0.50 THEN TripDuration_Minutes END) AS Median_Approx,
        MAX(CASE WHEN pr <= 0.75 THEN TripDuration_Minutes END) AS Q3_Approx,
        MAX(TripDuration_Minutes) AS MaxDuration
    FROM ClassifiedTrips_Ranked
    GROUP BY MetroID, TripCategory
)
SELECT
    M.CoreCity,
    C.TripCategory,
    ROUND(AVG(C.TripDuration_Minutes), 2) AS AvgDuration,
    ROUND(STDDEV(C.TripDuration_Minutes), 2) AS StdDevDuration,
    S.MinDuration,
    S.Q1_Approx,
    S.Median_Approx,
    S.Q3_Approx,
    S.MaxDuration
FROM ClassifiedTrips AS C
JOIN MetroArea M
    ON C.MetroID = M.MetroID
JOIN Statistics S
    ON C.MetroID = S.MetroID
   AND C.TripCategory = S.TripCategory
GROUP BY
    M.CoreCity,
    C.TripCategory,
    S.MinDuration,
    S.Q1_Approx,
    S.Median_Approx,
    S.Q3_Approx,
    S.MaxDuration
ORDER BY M.CoreCity, C.TripCategory;


-- 3) Share of Trip Types (Short, Typical, Long) Within Each Metro and Category
-- calculate metro-level duration cutoffs first, then classify trips.

DROP TEMPORARY TABLE IF EXISTS MetroDurationCutoffs;

CREATE TEMPORARY TABLE MetroDurationCutoffs AS
WITH MetroRanked AS (
    SELECT
        MetroID,
        TripDuration_Minutes,
        PERCENT_RANK() OVER (
            PARTITION BY MetroID
            ORDER BY TripDuration_Minutes
        ) AS pr
    FROM ClassifiedTrips
)
SELECT
    MetroID,
    MAX(CASE WHEN pr <= 0.25 THEN TripDuration_Minutes END) AS Q1_Duration,
    MAX(CASE WHEN pr <= 0.75 THEN TripDuration_Minutes END) AS Q3_Duration
FROM MetroRanked
GROUP BY MetroID;


SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    CASE
        WHEN C.TripDuration_Minutes <= D.Q1_Duration
            THEN 'Shorter Trips (Bottom 25% of Metro)'
        WHEN C.TripDuration_Minutes <= D.Q3_Duration
            THEN 'Typical Trips (Middle 50% of Metro)'
        ELSE 'Longer Trips (Top 25% of Metro)'
    END AS DurationBand,
    COUNT(*) AS TripCount,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (
            PARTITION BY M.CoreCity, C.TripCategory
        ),
        2
    ) AS PctWithinCategory
FROM ClassifiedTrips C
JOIN MetroDurationCutoffs D
    ON C.MetroID = D.MetroID
JOIN MetroArea M
    ON C.MetroID = M.MetroID
GROUP BY
    M.CoreCity,
    C.TripCategory,
    DurationBand
ORDER BY
    M.CoreCity,
    C.TripCategory,
    FIELD(DurationBand,
          'Shorter Trips (Bottom 25% of Metro)',
          'Typical Trips (Middle 50% of Metro)',
          'Longer Trips (Top 25% of Metro)');


-- 4) Dockless Involvement vs. Trip Duration
SELECT
    M.CoreCity AS MetroArea,
    C.TripCategory,
    CASE
        WHEN C.FromStationID = -5000 OR C.ToStationID = -5000 THEN 'Dockless Involved'
        ELSE 'Station-to-Station'
    END AS TripMode,
    COUNT(*) AS TripCount,
    ROUND(AVG(C.TripDuration_Minutes), 2) AS AvgDuration_Min,
    ROUND(STDDEV(C.TripDuration_Minutes), 2) AS StdDevDuration_Min
FROM ClassifiedTrips C
JOIN MetroArea M 
    ON C.MetroID = M.MetroID
GROUP BY 
    M.CoreCity, 
    C.TripCategory, 
    TripMode
ORDER BY 
    M.CoreCity, 
    C.TripCategory, 
    TripMode;


-- Base Table for Distance Analysis
-- Excludes dockless trips, invalid station coordinates, and same-station round trips.
-- Same-station round trips are kept in the broader trip behavior analysis,
-- but excluded here because straight-line distance returns 0 miles even if
-- the rider may have traveled and returned to the same station.

DROP TEMPORARY TABLE IF EXISTS SpatialTrips;

CREATE TEMPORARY TABLE SpatialTrips AS
SELECT
    C.TripID,
    C.MetroID,
    C.TripCategory,
    C.TripDuration_Minutes,

    FS.StationName AS FromStationName,
    TS.StationName AS ToStationName,

    FS.Latitude AS FromLat,
    FS.Longitude AS FromLon,
    TS.Latitude AS ToLat,
    TS.Longitude AS ToLon,

    -- Haversine formula in miles
    3959 * 2 * ASIN(
        SQRT(
            POWER(SIN(RADIANS(TS.Latitude - FS.Latitude) / 2), 2) +
            COS(RADIANS(FS.Latitude)) * COS(RADIANS(TS.Latitude)) *
            POWER(SIN(RADIANS(TS.Longitude - FS.Longitude) / 2), 2)
        )
    ) AS TripDistance_Miles

FROM ClassifiedTrips C
JOIN Stations FS
    ON C.FromStationID = FS.StationID
   AND C.MetroID = FS.MetroID
JOIN Stations TS
    ON C.ToStationID = TS.StationID
   AND C.MetroID = TS.MetroID
WHERE
    -- Exclude dockless trips because there is no real station coordinate
    C.FromStationID <> -5000
    AND C.ToStationID <> -5000

    -- Exclude same-station round trips from distance analysis
    -- because straight-line distance equals 0 by definition
    AND C.FromStationID <> C.ToStationID

    -- Keep only valid station coordinates
    AND FS.Latitude > 0
    AND FS.Longitude < 0
    AND TS.Latitude > 0
    AND TS.Longitude < 0;


-- 5) Average Trip Distance by Category x Metro
SELECT
    M.CoreCity AS MetroArea,
    S.TripCategory,
    COUNT(*) AS Trips,
    ROUND(AVG(S.TripDistance_Miles), 2) AS AvgTripDistance_Miles,
    ROUND(STDDEV(S.TripDistance_Miles), 2) AS StdDevTripDistance_Miles
FROM SpatialTrips S
JOIN MetroArea M 
    ON S.MetroID = M.MetroID
GROUP BY 
    M.CoreCity, 
    S.TripCategory
ORDER BY 
    M.CoreCity, 
    S.TripCategory;


-- 6) Distance + Duration Efficiency
SELECT
    M.CoreCity AS MetroArea,
    S.TripCategory,
    ROUND(AVG(S.TripDistance_Miles), 2) AS AvgTripDistance_Miles,
    ROUND(AVG(S.TripDuration_Minutes), 2) AS AvgTripDuration_Min,
    ROUND(
        AVG(S.TripDistance_Miles / NULLIF(S.TripDuration_Minutes, 0)),
        4
    ) AS AvgMilesPerMinute
FROM SpatialTrips S
JOIN MetroArea M 
    ON S.MetroID = M.MetroID
GROUP BY 
    M.CoreCity, 
    S.TripCategory
ORDER BY 
    M.CoreCity, 
    S.TripCategory;