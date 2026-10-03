# Extracted from test-match-expr.R:19

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "mapgl", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
dt <- as.POSIXct(
    c("2026-07-14 00:00:00", "2026-07-15 08:28:30.75", NA),
    tz = "Asia/Tokyo"
  )
pts <- sf::st_sf(
    dt = dt,
    d = as.Date(c("2026-07-14", "2026-07-15", NA)),
    geometry = sf::st_sfc(
      lapply(1:3, function(i) sf::st_point(c(i, i))),
      crs = 4326
    )
  )
props <- jsonlite::fromJSON(geojsonsf::sf_geojson(pts))$features$properties
for (col in c("dt", "d")) {
    values <- unique(pts[[col]][!is.na(pts[[col]])])
    expr <- match_expr(col, values = values, stops = c("red", "blue"))
    expect_equal(unlist(expr[c(3, 5)]), props[[col]][1:2], info = col)
  }
