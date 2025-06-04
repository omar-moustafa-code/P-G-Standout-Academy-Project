# Install the necessary library packages, if they aren't already
if(!require("forecast")) install.packages("forecast")
if(!require("prophet")) install.packages("prophet")
if(!require("ggplot2")) install.packages("ggplot2")
if(!require("dplyr")) install.packages("dplyr")

# Loading necessary library packages
library(forecast)
library(prophet)
library(ggplot2)
library(dplyr)

# --- DATA PREPERATION ---
# Market A - Product 1 & 4 demand (1 Year - 52 weeks)
demand = c(12, 13, 9, 7, 12, 10, 6, 6, 40, 40, 15, 7, 5, 10, 9, 7,
           12, 13, 9, 7, 12, 13, 9, 7, 17, 17, 9, 7, 5, 5, 5, 5, 12, 13, 9, 
           7, 12, 13, 9, 7, 22, 13, 9, 7, 7, 7, 7, 7, 5, 5, 5, 5)

# Converting the demand to a time series
# 'frequency = 52' because it is WEEKLY data
time_series_demand = ts(demand, frequency = 52, start = c(2025, 1))

# --- ASSUMPTIONS INTEGRATION ---

# 1. Promotional weeks (Year 1: weeks 9,10,41; Year 2: weeks 61,62,93 with 2x volume)
promo = rep(0, 52) # 52 weeks after 1st full year
promo[c(9, 10, 41)] = 1 # equals to 1 because it's the first year

future_promo = rep(0, 104) # 104 weeks after the 2nd full year
future_promo[c(61, 62, 93)] = 2  # Year 2 promo doubling the volume

# 2. Price increases (2% Jan 2026, 3% Jun 2026)
price_effect = c(rep(1, 30), rep(1.02, 22), rep(1.05, 52))

# 3. Product 4 launch (Sept 2025 = Week 14) - 5% demand increase
product4_effect = c(rep(1, 13), rep(1.05, 91))

