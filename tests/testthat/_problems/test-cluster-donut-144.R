# Extracted from test-cluster-donut.R:144

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "mapgl", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
donut_points <- function(n = 20) {
  set.seed(42)
  sf::st_as_sf(
    data.frame(
      x = runif(n, -80, -79),
      y = runif(n, 35, 36),
      race = sample(c("White", "Black", "Hispanic", "Asian"), n, TRUE),
      code = sample(c(100000, 2, 3), n, TRUE),
      pop = runif(n, 0, 100)
    ),
    coords = c("x", "y"),
    crs = 4326
  )
}
race_colors <- function(default = "#cccccc") {
  match_expr(
    "race",
    values = c("White", "Black", "Hispanic"),
    stops = c("#1b9e77", "#d95f02", "#7570b3"),
    default = default
  )
}
find_layer <- function(map, id) {
  Filter(function(layer) identical(layer$id, id), map$x$layers)[[1]]
}
to_json <- function(x) as.character(htmlwidgets:::toJSON2(x))

# test -------------------------------------------------------------------------
local_mocked_bindings(
    .warn_mapbox_pmtiles_cluster = function(map) invisible(NULL),
    .package = "mapgl"
  )
for (constructor in list(maplibre, mapboxgl)) {
    for (precomputed in c(FALSE, TRUE)) {
      m <- constructor() |>
        add_circle_layer(
          "p",
          source = if (precomputed) "tiles" else donut_points(),
          source_layer = if (precomputed) "points" else NULL,
          circle_color = race_colors(),
          before_id = "labels",
          cluster_options = cluster_options(donut_column = "race")
        )
      icon <- find_layer(m, "p-clusters")
      count <- find_layer(m, "p-cluster-count")
      expect_identical(count$layout[["text-allow-overlap"]],
                       icon$layout[["icon-allow-overlap"]])
      expect_identical(count$layout[["text-ignore-placement"]],
                       icon$layout[["icon-ignore-placement"]])
      expect_true(count$layout[["text-allow-overlap"]])
      expect_true(count$layout[["text-ignore-placement"]])
      expect_identical(count$filter, icon$filter)
      expect_identical(count$before_id, icon$before_id)
      expect_equal(count$layout[["text-size"]], 12)
    }
  }
