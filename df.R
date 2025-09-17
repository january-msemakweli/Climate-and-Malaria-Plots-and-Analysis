# ---- Packages ----
library(tidyverse)
library(zoo)        # for as.yearmon()
library(lubridate)  # for year(), month()

# ---- Setup output + theme ----
setwd(".")
plots_dir <- file.path(getwd(), "Preliminary_Plots")
if (!dir.exists(plots_dir)) dir.create(plots_dir)

pub_theme <- theme_bw(base_size = 12) +
  theme(
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#DDDDDD", linewidth = 0.3),
    panel.border = element_rect(color = "#333333", fill = NA, linewidth = 0.6),
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    legend.text = element_text(size = 11),
    legend.key.width = unit(16, "pt"),
    legend.key.height = unit(12, "pt"),
    legend.box.background = element_rect(color = "#CCCCCC", fill = "white")
  )

# ---- 1) Load & prepare ----
# Put Data.csv in your working directory or adjust the path
df <- read_csv("Data.csv")

# Ensure the time variable is ordered and usable
# Your file already has a 'yearmon' like "2014-01"
df <- df %>%
  mutate(yearmon = as.yearmon(yearmon)) %>%
  arrange(yearmon)

# Pull the two monthly series
malaria  <- df$Malaria_incidence_per_10000
rainfall <- df$monthly_rainfall

# Make monthly ts objects with frequency = 12
start_date <- as.Date(min(df$yearmon))
start_year  <- year(start_date)
start_month <- month(start_date)

malaria_ts  <- ts(malaria,  frequency = 12, start = c(start_year, start_month))
rainfall_ts <- ts(rainfall, frequency = 12, start = c(start_year, start_month))

# ---- 2) STL decomposition (univariate each) ----
# s.window = "periodic" gives a stable seasonal for monthly data
stl_mal  <- stl(malaria_ts,  s.window = "periodic", robust = TRUE)
stl_rain <- stl(rainfall_ts, s.window = "periodic", robust = TRUE)

# Extract seasonal components
seas_mal  <- as.numeric(stl_mal$time.series[, "seasonal"])
seas_rain <- as.numeric(stl_rain$time.series[, "seasonal"])

# Make a proper monthly date index from the ts time
idx <- as.yearmon(time(malaria_ts))        # yearmon index
dates <- as.Date(idx)

# ---- 3) Plot both seasonal components together (standardized) ----
plot_df <- tibble(
  date = dates,
  malaria_seasonal  = seas_mal,
  rainfall_seasonal = seas_rain
) %>%
  mutate(
    malaria_z  = as.numeric(scale(malaria_seasonal)),
    rainfall_z = as.numeric(scale(rainfall_seasonal))
  ) %>%
  pivot_longer(c(malaria_z, rainfall_z),
               names_to = "series", values_to = "seasonal_z") %>%
  mutate(series = recode(series,
                         malaria_z  = "Malaria seasonal (z-score)",
                         rainfall_z = "Rainfall seasonal (z-score)"))

p1 <- ggplot(plot_df, aes(date, seasonal_z, color = series, linetype = series)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.3) +
  labs(x = "Time", y = "Seasonal component (standardized)", color = NULL, linetype = NULL) +
  scale_color_manual(values = c("Malaria seasonal (z-score)" = "#2C7FB8",
                                "Rainfall seasonal (z-score)" = "#7F7F7F")) +
  scale_linetype_manual(values = c("Malaria seasonal (z-score)" = "solid",
                                   "Rainfall seasonal (z-score)" = "dashed")) +
  pub_theme

ggsave(file.path(plots_dir, "11_stl_seasonal_malaria_vs_rainfall.jpg"),
       p1, width = 10, height = 6, dpi = 300, device = "jpeg")

# ---- 4) (Optional) Raw series + seasonal fit for each variable ----
# Build tidy frames with original series and seasonal fit
tidy_mal <- tibble(
  date = dates,
  value = as.numeric(malaria_ts),
  seasonal = seas_mal,
  series = "Malaria incidence per 10,000"
)

tidy_rain <- tibble(
  date = dates,
  value = as.numeric(rainfall_ts),
  seasonal = seas_rain,
  series = "Monthly rainfall"
)

tidy_both <- bind_rows(tidy_mal, tidy_rain)

# Two panels: raw (thin) + seasonal fit (thick)
p2 <- ggplot(tidy_both, aes(date, value)) +
  geom_line(alpha = 0.6, color = "#333333") +
  geom_line(aes(y = seasonal), linewidth = 1, color = "#2C7FB8") +
  facet_wrap(~ series, scales = "free_y", ncol = 1) +
  labs(x = "Time", y = NULL) +
  pub_theme

ggsave(file.path(plots_dir, "12_raw_vs_seasonal_fits.jpg"),
       p2, width = 10, height = 8, dpi = 300, device = "jpeg")

# ---- 5) Repeat for other climate variables (day temp, night temp, humidity) ----
make_pair_plots <- function(var_col, var_label, prefix_num) {
  # Build ts for the selected variable aligned with malaria_ts
  x_vec <- df[[var_col]]
  x_ts  <- ts(x_vec, frequency = 12, start = c(start_year, start_month))
  stl_x <- stl(x_ts, s.window = "periodic", robust = TRUE)
  seas_x <- as.numeric(stl_x$time.series[, "seasonal"])

  # Seasonal comparison (standardized)
  plot_df2 <- tibble(
    date = dates,
    malaria_seasonal  = seas_mal,
    other_seasonal    = seas_x
  ) %>%
    mutate(
      malaria_z  = as.numeric(scale(malaria_seasonal)),
      other_z    = as.numeric(scale(other_seasonal))
    ) %>%
    pivot_longer(c(malaria_z, other_z), names_to = "series", values_to = "seasonal_z") %>%
    mutate(series = recode(series,
                           malaria_z  = "Malaria seasonal (z-score)",
                           other_z    = paste0(var_label, " seasonal (z-score)")))

  p_seas <- ggplot(plot_df2, aes(date, seasonal_z, color = series, linetype = series)) +
    geom_line(linewidth = 1) +
    geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.3) +
    labs(x = "Time", y = "Seasonal component (standardized)", color = NULL, linetype = NULL) +
    scale_color_manual(values = setNames(c("#2C7FB8", "#7F7F7F"),
                                        c("Malaria seasonal (z-score)", paste0(var_label, " seasonal (z-score)"))) ) +
    scale_linetype_manual(values = setNames(c("solid", "dashed"),
                                          c("Malaria seasonal (z-score)", paste0(var_label, " seasonal (z-score)"))) ) +
    pub_theme

  ggsave(file.path(plots_dir, sprintf("%02d_stl_seasonal_malaria_vs_%s.jpg", prefix_num, gsub("[ %()]+", "_", tolower(var_label)))),
         p_seas, width = 10, height = 6, dpi = 300, device = "jpeg")

  # Raw vs STL seasonal fit facets
  tidy_x <- tibble(
    date = dates,
    value = as.numeric(x_ts),
    seasonal = seas_x,
    series = var_label
  )

  tidy_both2 <- bind_rows(tidy_mal, tidy_x)

  p_raw <- ggplot(tidy_both2, aes(date, value)) +
    geom_line(alpha = 0.6, color = "#333333") +
    geom_line(aes(y = seasonal), linewidth = 1, color = "#2C7FB8") +
    facet_wrap(~ series, scales = "free_y", ncol = 1) +
    labs(x = "Time", y = NULL) +
    pub_theme

  ggsave(file.path(plots_dir, sprintf("%02d_raw_vs_seasonal_fits_%s.jpg", prefix_num + 1, gsub("[ %()]+", "_", tolower(var_label)))),
         p_raw, width = 10, height = 8, dpi = 300, device = "jpeg")
}

# Daytime temperature
make_pair_plots("daytime_temperature", "Daytime temperature (°C)", 13)
# Nighttime temperature
make_pair_plots("nighttime_temperature", "Nighttime temperature (°C)", 15)
# Relative humidity
make_pair_plots("Relative_humidity", "Relative humidity (%)", 17)
