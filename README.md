# BikeShare User Behavior Analysis

## Project Background

This project analyzes bike share rental data across four metro areas: Austin, Los Angeles, Pittsburgh, and Portland. Each rental represents a single trip taken by a user, either as a subscriber (membership-based) or a walk-up customer.

The goal is to understand how bike share systems are used differently across markets, specifically comparing commuting vs. leisure usage. This distinction is important because commuting trips tend to be predictable, time-sensitive, and recurring, while leisure trips are more flexible and influenced by external factors like weather and weekends.

Insights and recommendations are provided across three key areas:

- **Category 1: Market Composition**  
  How trips are distributed across metros, user types, and trip categories  

- **Category 2: Temporal Patterns**  
  How usage varies by time of day, day of week, and season  

- **Category 3: Trip Behavior**  
  How trip characteristics (duration, distance proxies, station usage) differ between commuting and leisure  

Targeted SQL queries for each category can be found here:

- [Category 1 Queries](01_market_structure/01_market_structure.sql)
- [Category 2 Queries](02_temporal_patterns/02_temporal_patterns.sql)
- [Category 3 Queries](03_trip_behavior/03_trip_behavior.sql)
