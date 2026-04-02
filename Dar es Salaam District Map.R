## Dar es Salaam district map using local ward shapefile
## Output: Maps/Dar_es_Salaam_5_Districts.png (300 dpi)

install_if_missing <- function(pkgs) {
  to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(to_install)) install.packages(to_install, dependencies = TRUE)
}

pkgs <- c("sf", "ggplot2", "ggspatial")
install_if_missing(pkgs)
invisible(lapply(pkgs, library, character.only = TRUE))

out_dir <- file.path(getwd(), "Maps")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

shp_path <- file.path("SHAPEFILES", "TANZANIA_2022PHC_WARDS_SHAPEFILES.shp")
if (!file.exists(shp_path)) {
  stop("Shapefile not found at: ", shp_path)
}

target_districts <- c("Ilala", "Kinondoni", "Temeke", "Ubungo", "Kigamboni")

# Read ward boundaries and filter Dar es Salaam wards in target districts
wards <- sf::st_read(shp_path, quiet = TRUE)

needed_cols <- c("reg_name", "dist_name")
if (!all(needed_cols %in% names(wards))) {
  stop("Required columns not found in shapefile: reg_name and dist_name")
}

is_dar <- tolower(trimws(wards$reg_name)) == "dar es salaam"
is_target <- trimws(wards$dist_name) %in% target_districts
dar_wards <- wards[is_dar & is_target, ]

if (nrow(dar_wards) == 0) {
  stop("No Dar es Salaam wards found for target districts in shapefile.")
}

# Dissolve wards to district polygons
districts <- aggregate(dar_wards["dist_name"], by = list(district = dar_wards$dist_name), FUN = function(x) x[1])
districts <- sf::st_make_valid(districts)

if (sf::st_is_longlat(districts)) {
  label_pts <- sf::st_point_on_surface(sf::st_transform(districts, 3857))
  label_pts <- sf::st_transform(label_pts, 4326)
} else {
  label_pts <- sf::st_point_on_surface(districts)
}

map_plot <- ggplot2::ggplot(districts) +
  ggplot2::geom_sf(ggplot2::aes(fill = district), color = "white", linewidth = 0.5) +
  ggplot2::geom_sf_text(data = label_pts, ggplot2::aes(label = district), size = 3.5, fontface = "bold") +
  ggspatial::annotation_north_arrow(
    location = "tr",
    which_north = "true",
    style = ggspatial::north_arrow_orienteering(
      fill = c("black", "white"),
      line_col = "black"
    ),
    height = grid::unit(0.9, "cm"),
    width = grid::unit(0.9, "cm"),
    pad_x = grid::unit(0.35, "cm"),
    pad_y = grid::unit(0.35, "cm")
  ) +
  ggplot2::scale_fill_brewer(palette = "Set2") +
  ggplot2::labs(fill = "District") +
  ggplot2::coord_sf(expand = FALSE) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.grid.major = ggplot2::element_line(color = "grey90"),
    axis.title = ggplot2::element_blank(),
    legend.position = "none",
    plot.title = ggplot2::element_blank(),
    plot.subtitle = ggplot2::element_blank()
  )

out_png <- file.path(out_dir, "Dar_es_Salaam_5_Districts.png")
ggplot2::ggsave(out_png, map_plot, width = 8, height = 8, units = "in", dpi = 300, bg = "white")

cat("\nSaved map to:\n", out_png, "\n")
