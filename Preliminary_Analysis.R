## Preliminary Analysis: Malaria Incidence and Climate Variables
## Dar es Salaam, Tanzania (2014-2024)

## Install & load packages
install_if_missing <- function(pkgs) {
  to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(to_install)) install.packages(to_install, dependencies = TRUE)
}
pkgs <- c("dplyr", "ggplot2", "tidyr", "lubridate", "cowplot", "viridis", "ggthemes", "tibble")
install_if_missing(pkgs)
invisible(lapply(pkgs, library, character.only = TRUE))

## Setup
set.seed(42)
setwd(".")
plots_dir <- file.path(getwd(), "Preliminary_Plots")
if (!dir.exists(plots_dir)) dir.create(plots_dir)

# Define a function to categorize months into seasons
assign_season <- function(month) {
  if (month %in% c("Jan", "Feb")) {
    return("JF")
  } else if (month %in% c("Mar", "Apr", "May")) {
    return("MAM")
  } else if (month %in% c("Jun", "Jul", "Aug")) {
    return("JJA")
  } else if (month %in% c("Sep")) {
    return("S")
  } else if (month %in% c("Oct", "Nov", "Dec")) {
    return("OND")
  } else {
    return(NA)
  }
}

## Load data
dat <- read.csv("Data.csv", stringsAsFactors = FALSE) %>%
  mutate(
    yearmon = as.Date(paste0(yearmon, "-01")),
    year = year(yearmon),
    month = month(yearmon, label = TRUE, abbr = TRUE),
    season = sapply(month, assign_season)
  ) %>%
  arrange(yearmon)

# Publication theme
pub_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0),
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

## 1. Time series of malaria incidence
p1 <- ggplot(dat, aes(x = yearmon, y = Malaria_incidence_per_10000)) +
  geom_line(color = "darkred", linewidth = 0.8) +
  geom_point(color = "darkred", size = 1.5, alpha = 0.7) +
  labs(
    title = "Monthly Malaria Incidence in Dar es Salaam (2014-2024)",
    x = "Year",
    y = "Malaria Incidence per 10,000 Population"
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  pub_theme

ggsave(file.path(plots_dir, "01_malaria_timeseries.png"), 
       p1, width = 10, height = 6, dpi = 300)

## 2. Seasonal patterns - Box plot by month
p2 <- ggplot(dat, aes(x = month, y = Malaria_incidence_per_10000, fill = month)) +
  geom_boxplot(alpha = 0.8) +
  geom_jitter(width = 0.2, alpha = 0.5, size = 1) +
  labs(
    title = "Seasonal Patterns in Malaria Incidence",
    x = "Month",
    y = "Malaria Incidence per 10,000 Population",
    fill = "Month"
  ) +
  scale_fill_viridis_d() +
  pub_theme +
  theme(legend.position = "none")

ggsave(file.path(plots_dir, "02_seasonal_patterns.png"), 
       p2, width = 10, height = 6, dpi = 300)

## 3. Annual trends - Mean by year
annual_summary <- dat %>%
  group_by(year) %>%
  summarise(
    mean_incidence = mean(Malaria_incidence_per_10000, na.rm = TRUE),
    sd_incidence = sd(Malaria_incidence_per_10000, na.rm = TRUE),
    n_months = n()
  )

p3 <- ggplot(annual_summary, aes(x = year, y = mean_incidence)) +
  geom_line(color = "darkblue", linewidth = 1.2) +
  geom_point(color = "darkblue", size = 3) +
  geom_errorbar(aes(ymin = mean_incidence - sd_incidence, 
                    ymax = mean_incidence + sd_incidence), 
                width = 0.3, color = "darkblue") +
  labs(
    title = "Annual Trends in Malaria Incidence",
    x = "Year",
    y = "Mean Annual Malaria Incidence per 10,000 Population (±SD)"
  ) +
  pub_theme

ggsave(file.path(plots_dir, "03_annual_trends.png"), 
       p3, width = 10, height = 6, dpi = 300)

## 4. Climate variables time series
climate_long <- dat %>%
  select(yearmon, daytime_temperature, nighttime_temperature, 
         monthly_rainfall, Relative_humidity) %>%
  pivot_longer(cols = -yearmon, names_to = "variable", values_to = "value") %>%
  mutate(
    variable = factor(variable, 
                     levels = c("daytime_temperature", "nighttime_temperature", 
                               "monthly_rainfall", "Relative_humidity"),
                     labels = c("Daytime Temperature (°C)", "Nighttime Temperature (°C)",
                               "Monthly Rainfall (mm)", "Relative Humidity (%)"))
  )

p4 <- ggplot(climate_long, aes(x = yearmon, y = value, color = variable)) +
  geom_line(linewidth = 0.8) +
  facet_wrap(~variable, scales = "free_y", ncol = 2) +
  labs(
    title = "Climate Variables in Dar es Salaam (2014-2024)",
    x = "Year",
    y = "Value"
  ) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  scale_color_viridis_d() +
  pub_theme +
  theme(legend.position = "none")

ggsave(file.path(plots_dir, "04_climate_timeseries.png"), 
       p4, width = 12, height = 8, dpi = 300)

## 5. Correlation heatmap
correlation_matrix <- dat %>%
  select(Malaria_incidence_per_10000, daytime_temperature, nighttime_temperature,
         monthly_rainfall, Relative_humidity) %>%
  cor(use = "complete.obs")

correlation_data <- correlation_matrix %>%
  as.data.frame() %>%
  tibble::rownames_to_column("var1") %>%
  pivot_longer(cols = -var1, names_to = "var2", values_to = "correlation") %>%
  mutate(
    var1 = factor(var1, 
                 levels = c("Malaria_incidence_per_10000", "daytime_temperature", 
                           "nighttime_temperature", "monthly_rainfall", "Relative_humidity"),
                 labels = c("Malaria Incidence", "Day Temp", "Night Temp", 
                           "Rainfall", "Humidity")),
    var2 = factor(var2,
                 levels = c("Malaria_incidence_per_10000", "daytime_temperature", 
                           "nighttime_temperature", "monthly_rainfall", "Relative_humidity"),
                 labels = c("Malaria Incidence", "Day Temp", "Night Temp", 
                           "Rainfall", "Humidity"))
  )

p5 <- ggplot(correlation_data, aes(x = var1, y = var2, fill = correlation)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", correlation)), 
            color = "white", fontface = "bold", size = 3) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", 
                       midpoint = 0, limits = c(-1, 1)) +
  labs(
    title = "Correlation Matrix: Malaria Incidence and Climate Variables",
    x = "",
    y = "",
    fill = "Correlation"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

ggsave(file.path(plots_dir, "05_correlation_heatmap.png"), 
       p5, width = 8, height = 6, dpi = 300)

## 6. Scatter plots with trend lines
scatter_vars <- c("daytime_temperature", "nighttime_temperature", 
                  "monthly_rainfall", "Relative_humidity")
scatter_labels <- c("Daytime Temperature (°C)", "Nighttime Temperature (°C)",
                   "Monthly Rainfall (mm)", "Relative Humidity (%)")

scatter_plots <- list()
for(i in 1:length(scatter_vars)) {
  scatter_plots[[i]] <- ggplot(dat, aes_string(x = scatter_vars[i], 
                                               y = "Malaria_incidence_per_10000")) +
    geom_point(alpha = 0.6, color = "darkred") +
    geom_smooth(method = "loess", color = "blue", se = TRUE) +
    labs(
      title = paste("Malaria Incidence vs", scatter_labels[i]),
      x = scatter_labels[i],
      y = "Malaria Incidence per 10,000 Population"
    ) +
    pub_theme
}

# Combine scatter plots
p6 <- plot_grid(plotlist = scatter_plots, ncol = 2)
ggsave(file.path(plots_dir, "06_scatter_plots.png"), 
       p6, width = 12, height = 10, dpi = 300)

## 7. Seasonal decomposition visualization
# Create monthly averages for seasonal pattern
monthly_avg <- dat %>%
  group_by(month) %>%
  summarise(
    mean_incidence = mean(Malaria_incidence_per_10000, na.rm = TRUE),
    se_incidence = sd(Malaria_incidence_per_10000, na.rm = TRUE) / sqrt(n())
  )

p7 <- ggplot(monthly_avg, aes(x = month, y = mean_incidence)) +
  geom_line(group = 1, color = "darkred", linewidth = 1.2) +
  geom_point(color = "darkred", size = 3) +
  geom_errorbar(aes(ymin = mean_incidence - se_incidence, 
                    ymax = mean_incidence + se_incidence), 
                width = 0.2, color = "darkred") +
  labs(
    title = "Average Seasonal Pattern in Malaria Incidence",
    x = "Month",
    y = "Average Malaria Incidence per 10,000 Population (±SE)"
  ) +
  pub_theme

ggsave(file.path(plots_dir, "07_seasonal_decomposition.png"), 
       p7, width = 10, height = 6, dpi = 300)

## 8. Summary statistics table
summary_stats <- dat %>%
  summarise(
    n_observations = n(),
    mean_incidence = mean(Malaria_incidence_per_10000, na.rm = TRUE),
    sd_incidence = sd(Malaria_incidence_per_10000, na.rm = TRUE),
    min_incidence = min(Malaria_incidence_per_10000, na.rm = TRUE),
    max_incidence = max(Malaria_incidence_per_10000, na.rm = TRUE),
    mean_day_temp = mean(daytime_temperature, na.rm = TRUE),
    mean_night_temp = mean(nighttime_temperature, na.rm = TRUE),
    mean_rainfall = mean(monthly_rainfall, na.rm = TRUE),
    mean_humidity = mean(Relative_humidity, na.rm = TRUE)
  )

# Save summary statistics
write.csv(summary_stats, file.path(plots_dir, "summary_statistics.csv"), row.names = FALSE)

## 9. Peak months identification
peak_months <- dat %>%
  group_by(month) %>%
  summarise(
    mean_incidence = mean(Malaria_incidence_per_10000, na.rm = TRUE),
    max_incidence = max(Malaria_incidence_per_10000, na.rm = TRUE)
  ) %>%
  arrange(desc(mean_incidence))

p9 <- ggplot(peak_months, aes(x = reorder(month, mean_incidence), y = mean_incidence)) +
  geom_col(fill = "darkred", alpha = 0.8) +
  geom_text(aes(label = sprintf("%.1f", mean_incidence)), 
            vjust = -0.5, fontface = "bold") +
  labs(
    title = "Average Malaria Incidence by Month",
    x = "Month",
    y = "Average Malaria Incidence per 10,000 Population"
  ) +
  pub_theme

ggsave(file.path(plots_dir, "09_peak_months.png"), 
       p9, width = 10, height = 6, dpi = 300)

## 10. Climate-malaria relationship by season
seasonal_climate <- dat %>%
  group_by(season) %>%
  summarise(
    mean_incidence = mean(Malaria_incidence_per_10000, na.rm = TRUE),
    mean_day_temp = mean(daytime_temperature, na.rm = TRUE),
    mean_night_temp = mean(nighttime_temperature, na.rm = TRUE),
    mean_rainfall = mean(monthly_rainfall, na.rm = TRUE),
    mean_humidity = mean(Relative_humidity, na.rm = TRUE)
  )

p10 <- ggplot(seasonal_climate, aes(x = season, y = mean_incidence, fill = season)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = sprintf("%.1f", mean_incidence)), 
            vjust = -0.5, fontface = "bold") +
  labs(
    title = "Average Malaria Incidence by Season",
    x = "Season",
    y = "Average Malaria Incidence per 10,000 Population",
    fill = "Season"
  ) +
  scale_fill_discrete(labels = c("JF" = "Short Dry", "MAM" = "Long Rainy", 
                                "JJA" = "Long Dry", "S" = "Transition", 
                                "OND" = "Short Rainy")) +
  pub_theme +
  theme(legend.position = "bottom")

ggsave(file.path(plots_dir, "10_seasonal_analysis.png"), 
       p10, width = 10, height = 6, dpi = 300)

cat("\n=== Preliminary Analysis Complete ===\n")
cat("Generated plots saved to:", plots_dir, "\n")
cat("Files created:\n")
cat("01_malaria_timeseries.png - Overall time series\n")
cat("02_seasonal_patterns.png - Monthly box plots\n")
cat("03_annual_trends.png - Yearly trends\n")
cat("04_climate_timeseries.png - Climate variables\n")
cat("05_correlation_heatmap.png - Correlation matrix\n")
cat("06_scatter_plots.png - Scatter plots with trends\n")
cat("07_seasonal_decomposition.png - Seasonal pattern\n")
cat("08_summary_statistics.csv - Summary statistics\n")
cat("09_peak_months.png - Peak months identification\n")
cat("10_seasonal_analysis.png - Seasonal analysis\n")
