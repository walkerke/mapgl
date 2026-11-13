test_that("add_source passes a URL or path through for the browser to resolve", {
  rel <- maplibre() |> add_source("lines", "geojson/lines.json")
  expect_equal(rel$x$sources[[1]]$type, "geojson")
  expect_equal(rel$x$sources[[1]]$data, "geojson/lines.json")

  url <- mapboxgl() |> add_source("lines", "https://example.com/lines.geojson")
  expect_equal(url$x$sources[[1]]$data, "https://example.com/lines.geojson")
})

test_that("add_source rejects data that is not an sf object or a single string", {
  expect_error(
    maplibre() |> add_source("x", c("a.geojson", "b.geojson")),
    "sf object, or a URL or path"
  )
  expect_error(maplibre() |> add_source("x", 1), "sf object, or a URL or path")
})
