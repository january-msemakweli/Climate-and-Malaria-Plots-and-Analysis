## =======================================================
## Malaria GAM: Full workflow
## =======================================================

## 0) Install & load packages (quietly)
install_if_missing <- function(pkgs) {
  to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(to_install)) install.packages(to_install, dependencies = TRUE)
}
pkgs <- c("mgcv","dplyr","tidyr","gratia","ggplot2","stringr","purrr")
install_if_missing(pkgs)
invisible(lapply(pkgs, library, character.only = TRUE))

## 1) Reproducibility & paths
set.seed(42)
setwd(".")
plots_dir <- file.path(getwd(), "Smooth Term Plots")
if (!dir.exists(plots_dir)) dir.create(plots_dir)

## 2) Helpers
clean_name <- function(x) {
  x |>
    stringr::str_replace_all("s\\(|\\)", "") |>
    stringr::str_replace_all("[^A-Za-z0-9_]+", "_") |>
    stringr::str_replace("^_+|_+$", "")
}

pub_theme <- ggplot2::theme_bw(base_size = 12) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(face = "bold", hjust = 0),
    axis.title = ggplot2::element_text(face = "bold"),
    axis.text = ggplot2::element_text(color = "black"),
    strip.text = ggplot2::element_text(face = "bold"),
    legend.position = "none"
  )

safe_concurvity <- function(fit) {
  out <- try(mgcv::concurvity(fit, full = TRUE), silent = TRUE)
  if (inherits(out, "try-error")) mgcv::concurvity(fit, full = FALSE) else out
}

pretty_labs <- c(
  daytime_temperature      = "Daytime Temperature (°C)",
  nighttime_temperature      = "Nighttime Temperature (°C)",
  monthly_rainfall         = "Monthly Rainfall (mm)",
  Relative_humidity        = "Relative Humidity (%)",
  lag1_daytime_temperature = "Day Temp (lag 1 mo, °C)",
  lag2_daytime_temperature = "Day Temp (lag 2 mo, °C)",
  lag3_daytime_temperature = "Day Temp (lag 3 mo, °C)",
  lag1_nighttime_temperature = "Night Temp (lag 1 mo, °C)",
  lag2_nighttime_temperature = "Night Temp (lag 2 mo, °C)",
  lag3_nighttime_temperature = "Night Temp (lag 3 mo, °C)",
  lag1_monthly_rainfall    = "Rainfall (lag 1 mo, mm)",
  lag2_monthly_rainfall    = "Rainfall (lag 2 mo, mm)",
  lag3_monthly_rainfall    = "Rainfall (lag 3 mo, mm)",
  lag1_Relative_humidity   = "Rel. Humidity (lag 1 mo, %)",
  lag2_Relative_humidity   = "Rel. Humidity (lag 2 mo, %)",
  lag3_Relative_humidity   = "Rel. Humidity (lag 3 mo, %)",
  yearmon                  = "Time"
)

draw_one_smooth <- function(fit, s_label) {
  var_raw <- clean_name(s_label)
  x_lab   <- pretty_labs[[var_raw]]
  if (is.null(x_lab)) x_lab <- var_raw
  
  p <- gratia::draw(fit, select = s_label, residuals = FALSE, ci_col = "grey50") +
    ggplot2::labs(
      title = paste0("Smooth of ", x_lab),
      x = x_lab,
      y = "Partial effect on Malaria incidence per 10,000"
    ) +
    pub_theme
  p
}

## 3) Load & prepare data
dat <- read.csv("Data.csv", stringsAsFactors = FALSE)
dat$yearmon <- as.numeric(as.Date(paste0(dat$yearmon, "-01")))

dat <- dat %>%
  dplyr::arrange(yearmon) %>%
  dplyr::mutate(
    lag1_daytime_temperature = dplyr::lag(daytime_temperature, 1),
    lag2_daytime_temperature = dplyr::lag(daytime_temperature, 2),
    lag3_daytime_temperature = dplyr::lag(daytime_temperature, 3),
    lag1_nighttime_temperature = dplyr::lag(nighttime_temperature, 1),
    lag2_nighttime_temperature = dplyr::lag(nighttime_temperature, 2),
    lag3_nighttime_temperature = dplyr::lag(nighttime_temperature, 3),
    lag1_monthly_rainfall    = dplyr::lag(monthly_rainfall, 1),
    lag2_monthly_rainfall    = dplyr::lag(monthly_rainfall, 2),
    lag3_monthly_rainfall    = dplyr::lag(monthly_rainfall, 3),
    lag1_Relative_humidity   = dplyr::lag(Relative_humidity, 1),
    lag2_Relative_humidity   = dplyr::lag(Relative_humidity, 2),
    lag3_Relative_humidity   = dplyr::lag(Relative_humidity, 3)
  ) %>%
  tidyr::drop_na()

## 4) Fit shrinkage-GAM
gam_fit <- mgcv::gam(
  Malaria_incidence_per_10000 ~
    s(daytime_temperature,      bs = "cs", k = 10) +
    s(nighttime_temperature,      bs = "cs", k = 10) +
    s(monthly_rainfall,         bs = "cs", k = 10) +
    s(Relative_humidity,        bs = "cs", k = 10) +
    s(lag1_daytime_temperature, bs = "cs", k = 10) +
    s(lag2_daytime_temperature, bs = "cs", k = 10) +
    s(lag3_daytime_temperature, bs = "cs", k = 10) +
    s(lag1_nighttime_temperature, bs = "cs", k = 10) +
    s(lag2_nighttime_temperature, bs = "cs", k = 10) +
    s(lag3_nighttime_temperature, bs = "cs", k = 10) +
    s(lag1_monthly_rainfall,    bs = "cs", k = 10) +
    s(lag2_monthly_rainfall,    bs = "cs", k = 10) +
    s(lag3_monthly_rainfall,    bs = "cs", k = 10) +
    s(lag1_Relative_humidity,   bs = "cs", k = 10) +
    s(lag2_Relative_humidity,   bs = "cs", k = 10) +
    s(lag3_Relative_humidity,   bs = "cs", k = 10) +
    s(yearmon,                  bs = "cs", k = 12),
  data   = dat,
  method = "REML",
  select = TRUE
)

cat("\n=== Model summary ===\n")
print(summary(gam_fit))

cat("\n=== gam.check ===\n")
print(gam.check(gam_fit))

cat("\n=== Concurvity (safe) ===\n")
print(safe_concurvity(gam_fit))

## 5) Save each smooth term as PNG  (fixed)
sm_names <- gratia::smooths(gam_fit)              # returns a character vector
stopifnot(is.character(sm_names) && length(sm_names) > 0)

purrr::walk2(
  sm_names,
  seq_along(sm_names),
  ~{
    p <- draw_one_smooth(gam_fit, .x)
    base <- sprintf("%02d_%s", .y, clean_name(.x))
    
    ggplot2::ggsave(
      filename = file.path(plots_dir, paste0(base, ".png")),
      plot = p, width = 6.5, height = 5, units = "in", dpi = 300
    )
  }
)

cat("\nSaved PNG plots to:\n", plots_dir, "\n")
