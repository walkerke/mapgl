geojson_text <- paste0(
  '{"type":"FeatureCollection","geopic":{"method":"anchor"},"features":[',
  '{"type":"Feature","properties":{"geopic:kind":"box"},',
  '"geometry":{"type":"Point","coordinates":[-34.8711,-8.0631]}}]}'
)

test_that("add_source() stores a GeoJSON string verbatim", {
  m <- maplibre() |> add_source("pic", geojson_text)
  src <- m$x$sources[[1]]
  expect_equal(src$id, "pic")
  expect_equal(src$type, "geojson")
  expect_true(inherits(src$data, "json"))
  expect_equal(as.character(src$data), geojson_text)

  # the widget serializer embeds it as an object: property names and the
  # foreign member survive as written
  out <- jsonlite::toJSON(src, auto_unbox = TRUE, json_verbatim = TRUE)
  parsed <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_equal(parsed$data$features[[1]]$properties[["geopic:kind"]], "box")
  expect_equal(parsed$data$geopic$method, "anchor")
})

test_that("add_source() takes geojsonsf and jsonlite output as GeoJSON", {
  gj <- structure(geojson_text, class = c("geojson", "json"))
  m <- mapboxgl() |> add_source("a", gj)
  expect_equal(as.character(m$x$sources[[1]]$data), geojson_text)

  js <- jsonlite::toJSON(
    list(type = "FeatureCollection", features = list()),
    auto_unbox = TRUE
  )
  m2 <- maplibre() |> add_source("b", js)
  expect_true(inherits(m2$x$sources[[1]]$data, "json"))
})

test_that("add_source() still takes sf objects and URLs", {
  pt <- sf::st_sf(
    name = "x",
    geometry = sf::st_sfc(sf::st_point(c(-34.87, -8.06)), crs = 4326)
  )
  m <- maplibre() |> add_source("sf", pt)
  expect_equal(m$x$sources[[1]]$type, "geojson")
  expect_true(inherits(m$x$sources[[1]]$data, "json"))

  u <- maplibre() |> add_source("url", "https://example.com/data.geojson")
  expect_equal(u$x$sources[[1]]$type, "geojson")
  expect_equal(u$x$sources[[1]]$data, "https://example.com/data.geojson")

  expect_error(maplibre() |> add_source("bad", "not geojson"), "GeoJSON string")
})
