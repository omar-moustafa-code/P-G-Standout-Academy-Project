# Install the necessary library packages, if they aren't already
if(!require("forecast")) install.packages("forecast")
if(!require("prophet")) install.packages("prophet")
if(!require("ggplot2")) install.packages("ggplot2")
if(!require("dplyr")) install.packages("dplyr")

# Loading necessary library package
library(forecast)
library(prophet)
library(ggplot2)
library(dplyr)
library(tidyr)

# --- DATA PREPERATION ---
# Market A - Product 1 & 4 demand (1 Year - 52 weeks)
demand = c(12, 13, 9, 7, 12, 10, 6, 6, 40, 40, 15, 7, 5, 10, 9, 7,
           12, 13, 9, 7, 12, 13, 9, 7, 17, 17, 9, 7, 5, 5, 5, 5, 12, 13, 9, 
           7, 12, 13, 9, 7, 22, 13, 9, 7, 7, 7, 7, 7, 5, 5, 5, 5)

# Converting the demand to a time series
# 'frequency = 52' because it is WEEKLY data
time_series_demand = ts(demand, frequency = 52, start = c(2025, 1))

# --- ASSUMPTIONS INTEGRATION ---

# Promotional weeks
promo = rep(0, 52) # 52 weeks after 1st full year
promo[c(9, 10, 41)] = 1 # equals to 1 because it's the first year

future_promo = rep(0, 52) # Another 52 weeks later to complete the second year
future_promo[c(9, 10, 41)] = 2 # equals to 2 because it's the second year

# Price increases (2% Jan 2026, 3% Jun 2026) --> 2% + 3% = 5% = 1.05
price_effect = c(rep(1, 30), rep(1.02, 22), rep(1.05, 52))

# Product 4 launch (September 1, 2025 = Week 14) - 5% demand increase hence the 1.05
product4_effect = c(rep(1, 13), rep(1.05, 91)) # Length = 104 (# of weeks in 2 years)

# Combining the 2 promotions into 1
full_promos = c(promo, future_promo)

full_price_effect = price_effect[1:104]

full_product4_effect = product4_effect[1:104]

# Create a data frame that includes the future dates
future_dates = data.frame(
  ds = seq.Date(from = as.Date("2025-01-01"), by = "week", length.out = 104),
  promo = full_promos, 
  price_effect = full_price_effect,
  product4_effect = full_product4_effect
)

# Create historical data frame for Prophet
historical_dates = seq.Date(from = as.Date("2025-01-01"), by = "week", 
                            length.out = length(demand))

train_df = data.frame(
  ds = historical_dates,
  y = demand,
  promo = promo,  # year 1 only
  price_effect = price_effect_full[1:52],
  product4_effect = product4_effect_full[1:52]
)

# Fit the model with historical data
model = prophet(yearly.seasonality = T, weekly.seasonality = T, daily.seasonality = F)

# Initialize Prophet model with additional regressors
model = prophet()

# Add the regressors
model = add_regressor(model, 'promo')
model = add_regressor(model, 'price_effect')
model = add_regressor(model, 'product4_effect')

model = fit.prophet(model, train_df)

future = make_future_dataframe(model, periods = 52, freq = "week")
# Add the same regressors to future
future$promo = full_promos
future$price_effect = full_price_effect
future$product4_effect = full_product4_effect

# Generate forecast
forecast_df = predict(model, future)

head(forecast_df[c("ds", "yhat", "promo", "price_effect", "product4_effect")], 10)

head(forecast_df[c("ds", "yhat", "trend", "additive_terms", "promo", "price_effect", "product4_effect")])

plot(model, forecast_df)

prophet_plot_components(model, forecast_df)

# Clone base scenario
scenarioA = future_dates
scenarioB = future_dates

# ---- Scenario A: 5-week strong promotion (25% off) starting week 5
scenarioA$promo[5:9] = 25

# ---- Scenario B: Stronger discount on price effect starting week 10
scenarioB$price_effect[10:20] = scenarioB$price_effect[10:20] - 0.5  # e.g., make price effect more negative

# Forecast for Scenario A
forecast_A = predict(model, scenarioA)

# Forecast for Scenario B
forecast_B = predict(model, scenarioB)

# Combine results into one frame
forecast_compare = data.frame(
  ds = forecast_df$ds,
  Base = forecast_df$yhat,
  PromoBoost = forecast_A$yhat,
  PriceDrop = forecast_B$yhat
)

# Convert to long format for plotting
forecast_long = pivot_longer(forecast_compare, cols = -ds, names_to = "Scenario", values_to = "yhat")

# Plot comparison
ggplot(forecast_long, aes(x = ds, y = yhat, color = Scenario)) +
  geom_line() +
  labs(title = "Forecast Comparison Under Different Scenarios",
       x = "Date", y = "Predicted Sales (yhat)") +
  theme_minimal()