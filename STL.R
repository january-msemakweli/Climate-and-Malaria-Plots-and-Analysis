# ============================================================================
# STL decomposition → publication-ready (300 dpi)
# ----------------------------------------------------------------------------
# - Reads monthly malaria incidence (Dar es Salaam; single series).
# - Normalizes the time index (YYYY-MM or YYYY/MM → Date).
# - Regularizes the monthly grid and linearly interpolates internal gaps
#   (edge extrapolation enabled so STL sees a contiguous series).
# - Decomposes with STL using periodic seasonality and robust fitting.
# - Exports a classic base-R 4-panel STL figure as an 8×6" PNG @ 300 dpi.
# - Output: <working dir>/STL Plots/STL_Decomposition.png
# ============================================================================

## 0) Install & load packages
install_if_missing <- function(pkgs) {
  to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(to_install)) install.packages(to_install, dependencies = TRUE)
}
pkgs <- c("dplyr","zoo")
install_if_missing(pkgs)
invisible(lapply(pkgs, library, character.only = TRUE))

# --- Paths -------------------------------------------------------------------
setwd(".")
out_dir <- file.path(getwd(), "STL Plots")
if (!dir.exists(out_dir)) dir.create(out_dir)

# --- Read + parse -------------------------------------------------------------
dat <- read.csv("Data.csv",
                check.names = FALSE,        # keep original column names
                na.strings  = c("", "NA")) %>%
  mutate(
    # Accept "YYYY-MM" or "YYYY/MM"; append day for a proper Date
    yearmon = as.Date(paste0(gsub("/", "-", yearmon), "-01"))
  ) %>%
  arrange(yearmon)

# Ensure incidence is numeric (handles numbers stored as text with commas)
if (!is.numeric(dat$Malaria_incidence_per_10000)) {
  dat$Malaria_incidence_per_10000 <-
    as.numeric(gsub(",", "", dat$Malaria_incidence_per_10000))
}

# --- Regularize monthly index + light interpolation --------------------------
# Build a complete monthly sequence and fill internal gaps (linear).
# rule = 2 enables linear edge extrapolation so STL gets a contiguous series.
full <- tibble::tibble(
  yearmon = seq(min(dat$yearmon, na.rm = TRUE),
                max(dat$yearmon, na.rm = TRUE),
                by = "month")
) %>%
  left_join(dat, by = "yearmon") %>%
  arrange(yearmon) %>%
  mutate(
    inc = zoo::na.approx(Malaria_incidence_per_10000,
                         rule = 2, na.rm = FALSE)
    # If you prefer no edge extrapolation, use: rule = 1
  )

# --- STL decomposition --------------------------------------------------------
x_ts <- ts(
  full$inc,
  start     = c(as.integer(format(min(full$yearmon), "%Y")),
                as.integer(format(min(full$yearmon), "%m"))),
  frequency = 12
)

# Periodic seasonality (fixed annual cycle); robust down-weights outliers
fit <- stl(x_ts, s.window = "periodic", robust = TRUE)
# If seasonality varies over years, consider an odd integer, e.g. s.window = 13

# --- Figure export (300 dpi) ------------------------------------
png(file.path(out_dir, "STL_Decomposition.png"),
    width = 8, height = 6, units = "in", res = 300, type = "cairo")
par(lwd = 1.1)  # slightly thicker lines for print legibility
plot(fit, main = "STL Decomposition: Dar es Salaam — Malaria incidence per 10,000")
dev.off()

cat("Saved:", file.path(out_dir, "STL_Decomposition.png"), "\n")
