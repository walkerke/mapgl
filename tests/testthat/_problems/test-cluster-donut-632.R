# Extracted from test-cluster-donut.R:632

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
node <- Sys.which("node")
skip_if(node == "", "node is not available")
lib <- system.file("htmlwidgets/lib/mapgl-expressions/mapgl-expressions.js",
    package = "mapgl")
script <- tempfile(fileext = ".js")
on.exit(unlink(script), add = TRUE)
counts <- c(42, 1200, 999499, 999500, 999499999, 999500000,
    1470295708, 9949999999, 9950000000)
writeLines(c(
    paste0("require(", jsonlite::toJSON(lib, auto_unbox = TRUE), ");"),
    paste0("const expr = ", jsonlite::toJSON(.cluster_count_label_expr(), auto_unbox = TRUE), ";"),
    paste0("const counts = ", jsonlite::toJSON(counts, digits = NA), ";"),
    "console.log(JSON.stringify(counts.map(point_count =>",
    "  globalThis._mapglEvaluateExpression(expr, {point_count}))));"
  ), script)
labels <- jsonlite::fromJSON(system2(node, shQuote(script), stdout = TRUE))
expect_equal(labels, c("42", "1.2k", "999k", "1M", "999M", "1B", "1.5B", "9.9B", "10B"))
