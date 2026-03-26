library(dplyr)
library(tidyr)
library(purrr)
library(tibble)

df <- read.csv("rain_contingency_table.csv", stringsAsFactors = FALSE)

# Basic checks
stopifnot(all(c("MetroArea","TripCategory","IsRainHour","Trips") %in% names(df)))
df$IsRainHour <- as.integer(df$IsRainHour)
df$Trips <- as.numeric(df$Trips)

# Ensure expected levels exist
unique(df$TripCategory)      # should be Commuter, Leisure
unique(df$IsRainHour)        # should be 0, 1
unique(df$MetroArea)         # should be 4 metros

cramers_v_2x2 <- function(tab) {
  # tab must be a 2x2 matrix
  chi <- suppressWarnings(chisq.test(tab, correct = FALSE))
  n <- sum(tab)
  as.numeric(sqrt(chi$statistic / n))  # for 2x2, V = sqrt(chi^2 / n)
}

run_one_metro <- function(metro_name, df) {
  d <- df %>% filter(MetroArea == metro_name)
  
  # Wide -> 2x2 matrix: rows = TripCategory, cols = IsRainHour
  wide <- d %>%
    mutate(IsRainHour = ifelse(IsRainHour == 1, "Rain", "NoRain")) %>%
    select(TripCategory, IsRainHour, Trips) %>%
    pivot_wider(names_from = IsRainHour, values_from = Trips, values_fill = 0)
  
  tab <- wide %>%
    column_to_rownames("TripCategory") %>%
    as.matrix()
  
  # Chi-square test (no Yates correction; large N makes it unnecessary)
  chi <- chisq.test(tab, correct = FALSE)
  
  print (unname(chi$parameter))
  tibble(
    MetroArea = metro_name,
    ChiSquare = unname(chi$statistic),
    df = unname(chi$parameter),
    p_value = unname(chi$p.value),
    CramersV = cramers_v_2x2(tab),
    MinExpected = min(chi$expected)
  )
}

metros <- sort(unique(df$MetroArea))

results <- map_dfr(metros, run_one_metro, df = df)

results
