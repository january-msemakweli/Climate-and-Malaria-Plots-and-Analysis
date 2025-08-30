# STL decomposition of malaria incidence time series
# Output: STL Plots/STL_Decomposition.png

## Install & load packages
install_if_missing <- function(pkgs) {
  to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(to_install)) install.packages(to_install, dependencies = TRUE)
}
pkgs <- c("dplyr","zoo")
install_if_missing(pkgs)
invisible(lapply(pkgs, library, character.only = TRUE))

## Setup paths
setwd(".")
out_dir <- file.path(getwd(), "STL Plots")
if (!dir.exists(out_dir)) dir.create(out_dir)

## Load and prepare data
dat <- read.csv("Data.csv",
                check.names = FALSE,
                na.strings  = c("", "NA")) %>%
  mutate(
    yearmon = as.Date(paste0(gsub("/", "-", yearmon), "-01"))
  ) %>%
  arrange(yearmon)

# Convert incidence to numeric if needed
if (!is.numeric(dat$Malaria_incidence_per_10000)) {
  dat$Malaria_incidence_per_10000 <-
    as.numeric(gsub(",", "", dat$Malaria_incidence_per_10000))
}

## Create regular monthly time series with interpolation
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
  )

## Perform STL decomposition
x_ts <- ts(
  full$inc,
  start     = c(as.integer(format(min(full$yearmon), "%Y")),
                as.integer(format(min(full$yearmon), "%m"))),
  frequency = 12
)

fit <- stl(x_ts, s.window = "periodic", robust = TRUE)

## Export plot
png(file.path(out_dir, "STL_Decomposition.png"),
    width = 8, height = 6, units = "in", res = 300, type = "cairo")
par(lwd = 1.1)
plot(fit, main = "STL Decomposition: Dar es Salaam — Malaria incidence per 10,000")
dev.off()

cat("Saved:", file.path(out_dir, "STL_Decomposition.png"), "\n")
