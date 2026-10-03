# Extracted from test-cluster-donut.R:543

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
expect_equal(cluster_options()$cluster_radius, 50)
expect_equal(cluster_options(donut_column = "race")$cluster_radius, 60)
