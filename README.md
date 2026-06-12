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

- Monthly variation in commuter share is lower but commuting patterns do change across months similar to leisure trips.  
- Leisure trips fluctuate more, increasing in warmer months and decreasing in colder months.  

Commuting shows smaller fluctuations year-round, but both leisure and commuting is influenced by season and external conditions.

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


## Category 3: Trip Behavior

### Leisure trips are consistently longer than commuter trips

Average trip duration is higher for leisure trips across all four metro areas:

- Austin: 30.44 min (leisure) vs 13.15 min (commuter)  
- Los Angeles: 39.95 vs 14.18  
- Pittsburgh: 65.96 vs 27.12  
- Portland: 25.69 vs 14.31  

This shows that commuter trips tend to be shorter and more direct, while leisure trips involve longer and more flexible riding patterns.

---

### Leisure trips are more variable and less predictable

<p align="center">
  <img src="images/duration_distribution.jpeg" width="550"><br>
</p>

- Standard deviation of duration is higher for leisure trips in every metro area.  
- Pittsburgh has the highest variability, with leisure trips showing a standard deviation of 172.47 minutes compared with 112.47 minutes for commuter trips.  
- Maximum durations are close to the 24-hour validity threshold across most metro areas, showing that some valid trips are still much longer than typical rides.  

This means leisure usage includes a wider range of trip lengths, while commuting is more concentrated around shorter trips.

---

### Commuter trips are concentrated in short and typical durations, while leisure includes more long trips

Using duration bands based on each metro’s trip duration distribution:

<p align="center">
  <img src="images/share_trip_types.jpeg" width="550"><br>
</p>

- Commuters have a low share of long trips across all metros:
  - Austin: 4.67% long trips  
  - Los Angeles: 6.68%  
  - Pittsburgh: 3.64%  
  - Portland: 7.86%  
- Leisure trips have a much higher share of long trips:
  - Austin: 27.96% long trips  
  - Los Angeles: 29.96%  
  - Pittsburgh: 27.20%  

This confirms that commuter trips are more concentrated in shorter duration ranges, while leisure riders are more likely to take longer trips.

---

### Distance is similar despite longer leisure durations

Average trip distances are similar between commuter and leisure trips:

- Austin: 0.81 miles (leisure) vs 0.70 miles (commuter)  
- Los Angeles: 0.85 vs 0.80  
- Pittsburgh: 1.19 vs 1.18  
- Portland: 0.56 vs 0.64  

This shows that leisure riders are not consistently traveling much farther than commuters. Instead, they are usually spending more time covering a similar distance.

---

### Commuter trips are more efficient than leisure trips

Trip efficiency was measured as average miles per minute:

- Austin: 0.0914 (commuter) vs 0.0643 (leisure)  
- Los Angeles: 0.0902 vs 0.0708  
- Pittsburgh: 0.0975 vs 0.0731  
- Portland: 0.0702 vs 0.0437  

Higher values mean riders cover more distance per minute. Commuter trips are more efficient in every metro area, suggesting that commuters tend to take faster and more direct trips, while leisure rides are slower or less direct.

---

### Pittsburgh shows the strongest difference between commuting and leisure behavior

Pittsburgh has the largest gap between commuter and leisure behavior:

- Average duration: 65.96 minutes for leisure vs 27.12 minutes for commuters  
- Median duration: 22 minutes vs 11 minutes  
- Q3 duration: 55 minutes vs 17 minutes  
- Efficiency: 0.0731 miles per minute for leisure vs 0.0975 for commuters  

This suggests that leisure riding in Pittsburgh is especially recreational or less direct, while commuter trips remain more structured and efficient.

---

### Overall pattern
- Commuters take shorter, faster, and more consistent trips → goal-oriented travel  
- Leisure riders take longer, slower, and more variable trips → exploration and recreation  

The key difference is not just how often bikes are used, but how they are used.


## Recommendations

Based on the insights and findings above, we would recommend the BikeShare Operations & Growth Team consider the following:

---

### Leisure dominates usage → Redesign pricing and product to support longer, flexible trips

- Leisure trips are consistently longer than commuter trips, but they do not cover proportionally more distance. This suggests leisure riders spend more time riding, stopping, or exploring rather than simply traveling farther.

- Introduce flat-fee ride tiers, such as 60–90 minute passes, instead of relying only on time-based pricing.
- Add pause/resume functionality so riders are not penalized for short stops during recreational trips.
- Create casual ride bundles for weekends or tourist-heavy periods.

This aligns pricing with actual leisure behavior and can increase ride duration, satisfaction, and repeat usage.

---

### Leisure demand is time- and condition-dependent → Improve bike allocation

- Leisure trips are more common during weekends and favorable weather, while commuting is more stable and tied to weekday peak hours.

- Shift bikes toward parks, waterfronts, trails, and recreational areas on weekends.
- Reallocate bikes back to business districts, transit areas, and office-heavy zones during weekday commute hours.
- Use weather and day-of-week patterns to anticipate changes in demand.

This improves availability where and when demand is most likely to increase.

---

### User composition differs by metro → Adjust access and pricing by market

- Los Angeles is more subscriber-driven, while Austin, Pittsburgh, and Portland rely more heavily on casual or walk-up users.

- In Los Angeles, focus on subscriber retention and usage frequency, such as bundled weekend rides or loyalty benefits.
- In Austin, Pittsburgh, and Portland, reduce friction for casual riders through simple day passes, faster checkout, and clear station instructions.
- Avoid using the same pricing and access strategy across all cities.

This ensures each market’s dominant user type is supported.

---

### Commuter trips are efficient and predictable → Prioritize reliability over broad expansion

- Commuter trips make up a smaller share of total trips, but they are shorter, more efficient, and more predictable than leisure trips.

- Ensure bike and dock availability at key commute stations during morning and evening peak hours.
- Prioritize station uptime in business districts, transit hubs, and university or employment areas.
- Focus on reliable service in high-use commute corridors before expanding into less proven areas.

This protects a smaller but important user segment that depends on bike share for regular transportation.

---

### Leisure behavior varies by metro → Adapt infrastructure locally

- Portland has high dockless involvement, while Pittsburgh shows especially long and variable leisure trips.

- In Portland, support flexible return options and dockless access where it improves coverage.
- In Pittsburgh, prioritize coverage near parks, trails, and longer recreational routes.
- In Austin and Los Angeles, support leisure growth with weekend availability in high-demand recreational and visitor areas.

This aligns service design with how riders actually use bike share in each city.

---

### Leisure trips are less time-efficient → Position bike share as an experience

- Leisure trips have lower miles per minute than commuter trips across all metros, meaning riders are moving more slowly, stopping more often, or taking less direct routes.

- Shift marketing from only “get there faster” to “enjoy the ride.”
- Highlight scenic routes, casual rides, parks, waterfronts, and exploration.
- Add product features like route suggestions, longer ride passes, and leisure-focused station maps.

This positions bike share as both transportation and recreation, which better matches actual leisure behavior.

## Assumptions & Caveats

- **Trip classification is rule-based, not observed behavior**  
  Trips are labeled as “Commuter” or “Leisure” using time, day, user type, and station differences. This assumes peak-hour subscriber trips are commuting, but some trips may be misclassified.

- **Subscriber = commuter assumption may not always hold**  
  The classification assumes subscribers are more likely to commute, but subscribers can also take leisure trips, especially outside peak commute hours.

- **Zero-duration trips are partially removed as data errors**  
  Trips with 0 minutes are removed only if they are not round trips, meaning the start and end stations are different. These records are unlikely to represent valid completed trips.  
  Round trips with 0 duration are kept because they may reflect real behavior, such as a rider unlocking a bike and immediately returning it.

- **Extremely long trips are removed using a practical validity threshold**  
  Trips longer than 24 hours are removed from trip behavior analysis because they are unlikely to represent normal bikeshare use. These records may reflect docking issues, lost bikes, or system recording errors.  
  Statistical outliers are not removed using the 1.5×IQR rule because unusually long trips are not automatically data errors.

- **Duration statistics are based on valid trips, not IQR-trimmed data**  
  Average duration, median duration, duration bands, and variability are calculated after applying practical data-quality filters. This keeps the analysis focused on trips that are plausible while avoiding arbitrary statistical outlier removal.

- **Round trips vs. one-way trips are simplified indicators of behavior**  
  Trips with the same start and end station are treated as possible recreational or loop trips, but some may still be functional, such as short errands or failed bike checkouts.

- **Distance is estimated using station coordinates, not the actual route taken**  
  Distance is calculated using straight-line Haversine distance between start and end stations. This underestimates the actual distance traveled and does not capture the rider’s full route.

- **Same-station round trips are excluded from distance-based analysis**  
  Same-station round trips are kept in the broader trip behavior analysis, but they are excluded from distance and efficiency calculations. The straight-line distance formula returns 0 miles for these trips even if the rider may have traveled and returned to the same station.

- **Non-round trips with 0 distance are excluded from distance-based analysis**  
  Trips with different start and end stations but 0 calculated distance are treated as invalid for distance analysis because they do not provide a meaningful distance estimate.

- **Dockless trips are excluded from distance and efficiency analysis**  
  Dockless trips lack fixed station coordinates, so they are removed from distance-based metrics. This may affect results in metros with high dockless usage, such as Portland.

- **Weather impact is simplified to rain vs. no rain**  
  The analysis only considers whether it rained, not rain intensity, timing, temperature, wind, or other weather conditions.

- **Time-based patterns assume no external disruptions**  
  Trends by hour, day, and season do not account for events, tourism, construction, service disruptions, or policy changes that may affect demand.

- **Metro comparisons assume similar system conditions**  
  Differences in infrastructure, station density, dockless availability, and local geography may influence results beyond rider behavior.
