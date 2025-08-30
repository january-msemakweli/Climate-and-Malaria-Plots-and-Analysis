# Climate and Malaria Analysis Project

## Overview
This repository contains R code for analyzing the relationship between climate variables and malaria incidence in Dar es Salaam, Tanzania. The analysis includes both STL (Seasonal and Trend decomposition using Loess) decomposition and Generalized Additive Model (GAM) analysis.

## Project Structure

```
Climate and Malaria Plots and Analysis/
├── Data.csv                           # Main dataset with climate and malaria data
├── STL.R                             # STL decomposition analysis
├── GAM Analysis Code.R               # GAM analysis with smooth term plots
├── Preliminary_Analysis.R            # Comprehensive preliminary analysis
├── Smooth Term Plots/                # Output directory for GAM plots
├── STL Plots/                        # Output directory for STL plots
├── Preliminary_Plots/                # Output directory for preliminary analysis
├── renv/                             # R environment management
├── renv.lock                         # Locked package versions
├── Climate and Malaria Plots and Analysis.Rproj  # RStudio project file
└── README.md                         # This file
```

## Data Description

The `Data.csv` file contains monthly time series data with the following variables:
- `yearmon`: Time period (YYYY-MM format)
- `Malaria_incidence_per_10000`: Malaria cases per 10,000 population
- `daytime_temperature`: Daytime temperature in °C
- `nighttime_temperature`: Nighttime temperature in °C
- `monthly_rainfall`: Monthly rainfall in mm
- `Relative_humidity`: Relative humidity in %

## Analysis Components

### 1. STL Decomposition (`STL.R`)
**Purpose**: Decompose the malaria incidence time series into trend, seasonal, and residual components.

**What it does**:
- Reads monthly malaria incidence data
- Normalizes time index and handles missing values
- Performs STL decomposition with periodic seasonality
- Creates publication-ready 4-panel STL plot (300 dpi PNG)

**Output**: `STL Plots/STL_Decomposition.png`

**Key features**:
- Robust fitting to handle outliers
- Linear interpolation for internal gaps
- Edge extrapolation for contiguous series
- Publication-quality graphics

### 2. GAM Analysis (`GAM Analysis Code.R`)
**Purpose**: Model the relationship between climate variables and malaria incidence using Generalized Additive Models.

**What it does**:
- Fits GAM with smooth terms for all climate variables
- Includes lagged effects (1-3 months) for each climate variable
- Uses shrinkage selection to automatically remove unimportant terms
- Creates individual plots for each smooth term
- Performs model diagnostics (gam.check, concurvity)

**Output**: Multiple PNG files in `Smooth Term Plots/` directory

**Key features**:
- Cubic spline basis functions with shrinkage
- REML estimation
- Automatic term selection
- Publication-ready theme for all plots

### 3. Preliminary Analysis (`Preliminary_Analysis.R`)
**Purpose**: Comprehensive exploratory analysis of malaria incidence patterns and climate relationships.

**What it does**:
- Creates time series plots of malaria incidence and climate variables
- Analyzes seasonal patterns and annual trends
- Generates correlation matrices and scatter plots
- Identifies peak months and seasonal variations
- Provides summary statistics for all variables

**Output**: 10 PNG files and 1 CSV file in `Preliminary_Plots/` directory

**Key visualizations**:
- Monthly malaria incidence time series (2014-2024)
- Seasonal patterns with box plots by month
- Annual trends with error bars
- Climate variables time series (4-panel)
- Correlation heatmap matrix
- Scatter plots with trend lines
- Seasonal decomposition
- Peak months identification
- Seasonal analysis by climate zones

## How to Run the Code

### Prerequisites
- R (version 4.0 or higher recommended)
- RStudio (optional but recommended)

### Setup Instructions

1. **Clone or download this repository**
   ```bash
   git clone [repository-url]
   cd "Climate and Malaria Plots and Analysis"
   ```

2. **Open the RStudio project**
   - Double-click `Climate and Malaria Plots and Analysis.Rproj`
   - Or open RStudio and use File → Open Project

3. **Install dependencies** (if using renv)
   ```r
   renv::restore()
   ```

4. **Run the analyses**
   
   **For STL decomposition:**
   ```r
   source("STL.R")
   ```
   
   **For GAM analysis:**
   ```r
   source("GAM Analysis Code.R")
   ```
   
   **For preliminary analysis:**
   ```r
   source("Preliminary_Analysis.R")
   ```

### Alternative Setup (without renv)
If you prefer not to use renv, the code will automatically install required packages:
- `dplyr`, `zoo` (for STL analysis)
- `mgcv`, `dplyr`, `tidyr`, `gratia`, `ggplot2`, `stringr`, `purrr` (for GAM analysis)

## Output Files

### STL Analysis
- `STL Plots/STL_Decomposition.png`: 4-panel STL decomposition plot showing:
  - Original time series
  - Trend component
  - Seasonal component
  - Residuals

### GAM Analysis
- Multiple PNG files in `Smooth Term Plots/` directory, each showing:
  - Individual smooth term effects
  - 95% confidence intervals
  - Partial effects on malaria incidence

### Preliminary Analysis
- `01_malaria_timeseries.png`: Monthly malaria incidence over time
- `02_seasonal_patterns.png`: Box plots showing seasonal variation
- `03_annual_trends.png`: Annual averages with standard deviations
- `04_climate_timeseries.png`: Time series of all climate variables
- `05_correlation_heatmap.png`: Correlation matrix between variables
- `06_scatter_plots.png`: Scatter plots with trend lines
- `07_seasonal_decomposition.png`: Average seasonal pattern
- `08_summary_statistics.csv`: Summary statistics table
- `09_peak_months.png`: Peak months identification
- `10_seasonal_analysis.png`: Seasonal analysis by climate zones

## Code Features

### Reproducibility
- Set random seed for consistent results
- Uses relative paths (setwd(".")) for portability
- Automatic package installation and loading

### Data Handling
- Robust handling of missing values
- Automatic data type conversion
- Time series regularization

### Visualization
- Publication-ready graphics (300 dpi)
- Consistent theming across plots
- Professional color schemes and typography

## Technical Notes

### STL Parameters
- `s.window = "periodic"`: Fixed annual seasonality
- `robust = TRUE`: Outlier-resistant fitting
- Linear interpolation with edge extrapolation

### GAM Specifications
- Cubic spline basis (`bs = "cs"`)
- 10 knots per smooth term (`k = 10`)
- REML estimation for optimal smoothing
- Shrinkage selection (`select = TRUE`)

### Model Diagnostics
- `gam.check()`: Residual diagnostics
- `concurvity()`: Check for concurvity issues
- Automatic model validation

## Troubleshooting

### Common Issues
1. **Package installation errors**: Ensure you have write permissions and internet connection
2. **Missing data**: The code handles missing values automatically
3. **Path issues**: All paths are now relative to the project root

### Getting Help
- Check R console for error messages
- Ensure all required packages are installed
- Verify the `Data.csv` file is in the project root

## Citation
If you use this code in your research, please cite the relevant R packages:
- `mgcv` for GAM analysis
- `zoo` for time series operations
- `ggplot2` for visualization

## Contact
For questions about this analysis, please contact the original author or repository maintainer.
