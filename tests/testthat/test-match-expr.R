test_that("match_expr() matches Date and POSIXct values as GeoJSON strings", {
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
})

test_that("match_expr() drops NA values and their stops", {
  expect_message(
    expr <- match_expr(
      "zz",
      values = c("a", NA, "b"),
      stops = c("red", "green", "blue")
    ),
    "Dropped `NA`"
  )
  expect_equal(expr, list("match", list("get", "zz"), "a", "red", "b", "blue", "#cccccc"))
  expect_error(
    match_expr("zz", values = NA, stops = "red"),
    "at least one non-missing"
  )
})

test_that("match_expr() matches factor labels, not codes", {
  expr <- match_expr("zz", values = factor(c("a", "b")), stops = c("red", "blue"))
  expect_equal(expr[c(3, 5)], list("a", "b"))
})
