# BikeShare User Behavior Analysis

## Project Background

This project analyzes bike share rental data across four metro areas: Austin, Los Angeles, Pittsburgh, and Portland. Each rental represents a single trip taken by a user, either as a subscriber (membership-based) or a walk-up customer.

The goal is to understand how bike share systems are used differently across markets, specifically comparing commuting vs. leisure usage. This distinction is important because commuting trips tend to be predictable, time-sensitive, and recurring, while leisure trips are more flexible and influenced by external factors like weather and weekends.

Insights and recommendations are provided across three key areas:

- **Category 1: Market Structure**  
  How trips are distributed across metros, user types, and trip categories  

- **Category 2: Temporal Patterns**  
  How usage varies by time of day, day of week, and season  

- **Category 3: Trip Behavior**  
  How trip characteristics (duration, distance proxies, station usage) differ between commuting and leisure  

Targeted SQL queries for each category can be found here:

- [Category 1 Queries](01_market_structure/01_market_structure.sql)
- [Category 2 Queries](02_temporal_patterns/02_temporal_patterns.sql)
- [Category 3 Queries](03_trip_behavior/03_trip_behavior.sql)

## Data Structure & Initial Checks

The BikeShare database consists of five main tables with rental, location, time, and weather data. The core table used for analysis is the `Rentals` table, where each row represents a single trip.

### Database Schema

![Database Schema](schema.png)

---

### Main Tables

#### Rentals
Contains trip-level data including start/end time, stations, trip duration, and user type. Each row represents one rental.

**Key fields:**
- `TripDuration_Minutes` — trip length  
- `UserType` — Subscriber vs Walk-up  
- `FromStationID` / `ToStationID`  
- `StartDate`, `StartTime`, `StartDayOfWeek`  

#### Stations
Contains station-level data including location and metro assignment. Includes a special “dockless” station for trips not starting or ending at a fixed station.

#### MetroArea
Defines the four metro areas and their associated bike share systems. Used to group and compare markets.

#### DaysOfTheWeek
Lookup table mapping numeric day IDs (1–7) to day names.

#### Weather
Hourly weather data for each metro area, including temperature, precipitation, and conditions. Used to analyze how weather affects trip behavior.

---

### Initial Checks & Data Cleaning

Before analysis, several checks were performed to ensure data quality:

- **Trip Duration Validation**  
  Trips with `TripDuration_Minutes = 0` were reviewed. These may represent data errors or immediate returns (e.g., unlocking and re-locking a bike). These were considered for filtering or separate handling.

- **Station Consistency**  
  Trips where `FromStationID = ToStationID` were identified. These may indicate round trips or non-meaningful movement and were treated carefully in classification.

- **Dockless Trips**  
  Trips with `StationID = -5000` were flagged as dockless. These were retained but considered separately when analyzing station-based behavior.

- **Missing Values**  
  Some fields (e.g., time, station IDs) allow nulls. These were checked and excluded where necessary for analysis consistency.

- **Time Features**  
  Additional fields such as time-of-day buckets and seasons were derived from `StartTime` and `StartDate` to support temporal analysis.

- **Trip Classification Setup**  
  Trips were labeled as **Commuter** or **Leisure** based on:
  - Weekday vs weekend  
  - Peak commuting hours (06:30–09:30 and 16:00–19:00)  
  - Subscriber vs walk-up users  
  - Different start and end stations  

This cleaned and structured dataset forms the basis for all subsequent analysis.
