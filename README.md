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

## Executive Summary

BikeShare is used mostly for leisure across all four metros. These trips are longer, more flexible, and less focused on speed, while commuting trips are short, consistent, and follow weekday routines.

BikeShare should treat these as two different use cases:
- Keep commuting reliable and easy to access during peak hours  
- Focus most decisions on improving and growing leisure usage through pricing, bike availability, and product features that support longer and more flexible rides  

---

## Category 1: Market Structure

### Leisure dominates usage across all metros

<p align="center">
  <img src="images/usage_across_metros.jpeg" width="550"><br>
</p>

- Leisure trips account for the majority of rides in every city, ranging from 78.22% in Los Angeles to 89.59% in Pittsburgh. 
- Austin (85.93%) and Portland (87.97%) follow a similar pattern.
- Commuter trips are much lower (10%–22%), showing that bike share is primarily used for non-commuting purposes across all markets.

---

### Los Angeles has the highest commuting share, but leisure still dominates
Los Angeles has the highest share of commuter trips at 21.78%, compared to:
- Austin: 14.07%  
- Portland: 12.03%  
- Pittsburgh: 10.41%  

This suggests stronger commuting adoption in LA, but even there, nearly 4 out of 5 trips are still leisure.

---

### Leisure user composition differs by metro
<p align="center">
  <img src="images/leisure_trips_subscriber_composition.jpeg" width="550"><br>
</p>

In Los Angeles, 55.03% of leisure trips come from subscribers, making it the only metro where leisure usage is primarily subscription-based. <br>

In contrast:
- Austin: 59.43% walk-up  
- Pittsburgh: 67.83% walk-up  
- Portland: 66.35% walk-up  

This shows that while leisure dominates everywhere, the type of user driving leisure demand differs by market.

---

### Most leisure trips are one-way, with Pittsburgh showing more round-trip behavior
Across metros, the majority of leisure trips are one-way (70%–82%), meaning users are traveling between different locations.

Pittsburgh stands out with 29.62% round trips, higher than:
- Austin: 18.06%  
- Los Angeles: 18.46%  
- Portland: 21.9%  

This suggests more recreational, loop-style riding in Pittsburgh.

---

### Dockless usage varies significantly by metro
- Austin and Los Angeles are fully station-based (100%)  
- Pittsburgh has limited dockless usage (~7–9%)  
- Portland stands out with 45.51% dockless usage  

This shows that infrastructure differences shape how leisure trips are taken, even if overall usage patterns remain similar.

---

### Overall pattern
Leisure dominates in all metros, but how people take leisure trips differs by market:
- **Who** takes the trips (subscriber vs walk-up)  
- **How** trips are structured (one-way vs round-trip)  
- **How** bikes are accessed (station vs dockless)  

The key difference across metros is not whether bikes are used for leisure, but how that leisure usage happens.


## Category 2: Temporal Patterns

### Commuter demand is stable on weekdays, while leisure spikes on weekends
<p align="center">
  <img src="images/daily_usage.jpeg" width="550"><br>
</p>

- Commuter trips are evenly distributed Monday–Friday in all cities, with each day contributing roughly 18%–21% of trips.  
- In contrast, leisure trips increase sharply on weekends.  
- For example, in Austin, leisure rises from ~10–15% on weekdays to 22.24% on Saturday, with similar patterns across all metros.  

This shows commuting is routine-based, while leisure is concentrated on weekends.

---

### Weekend spikes reinforce that bike share is mainly used for leisure
- Across all metros, the highest leisure usage occurs on Saturday and Sunday.  
- For example, Austin reaches ~241K trips on Saturday compared to ~110K midweek.  
- This same pattern appears in Los Angeles, Pittsburgh, and Portland.  

This reinforces that overall bike share usage is driven more by leisure than commuting, especially during free time.

---

### Commuting is stable year-round, while leisure is seasonal
<p align="center">
  <img src="images/monthly_usage.jpeg" width="550"><br>
</p>

- Monthly variation in commuter share is low (Austin: 4.21, LA: 3.42), meaning commuting patterns do not change much across months.  
- Leisure trips fluctuate more, increasing in warmer months and decreasing in colder months.  

This shows commuting is consistent year-round, while leisure is influenced by season and external conditions.

---

### Leisure peaks in summer in most metros, with Austin as an exception
- In Los Angeles, Pittsburgh, and Portland, leisure trips increase through spring and peak in July–August.  
- Portland, for example, reaches around ~170K–180K trips in summer.  
- Austin shows a different pattern, with a decline during peak summer months, likely due to extreme heat.  

This highlights how local climate affects leisure demand even when overall patterns are similar.

---

### Commuters are more resilient to rain than leisure riders
<p align="center">
  <img src="images/rain_reslience.jpeg" width="550"><br>
</p>
- The Rain Participation Ratio compares how often trips occur in rain relative to how often it rains.  
- A value of 1 means trips occur at the same rate as rain; below 1 means people avoid riding in rain.  

**Commuter ratios (higher):**
- Austin: 0.72  
- Portland: 0.70  
- Pittsburgh: 0.97  

**Leisure ratios (lower):**
- Austin: 0.56  
- Portland: 0.54  
- Pittsburgh: 0.56  

This shows commuters are more likely to ride even in rain, while leisure riders avoid bad weather.

---

### Rain affects leisure more than commuting, but the overall impact is small
- A Chi-Square Test of Independence was used to test the relationship between rain and trip type.  
- Results show statistically significant relationships, but very small effect sizes (Cramér’s V: 0.005–0.053).  

This means rain slightly reduces leisure trips more than commuting, but does not strongly change overall usage patterns.

---

### Overall pattern
- Commuting follows consistent weekday routines and is less affected by season or weather.  
- Leisure, which dominates total usage, varies by weekends, seasons, and weather conditions.  

The key difference is not just how much each type is used, but how sensitive each is to time and external factors.
