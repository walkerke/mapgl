test_that("add_model embeds a local glb as a data URI", {
  glb <- tempfile(fileext = ".glb")
  writeBin(as.raw(c(0x67, 0x6c, 0x54, 0x46)), glb)

  m <- mapboxgl() |> add_model("turbine", glb)

  expect_length(m$x$models, 1)
  expect_equal(m$x$models[[1]]$id, "turbine")
  expect_match(m$x$models[[1]]$url, "^data:model/gltf-binary;base64,")
})

test_that("add_model keeps remote URLs and rejects maplibre", {
  m <- mapboxgl() |> add_model("car", "https://example.com/car.glb")
  expect_equal(m$x$models[[1]]$url, "https://example.com/car.glb")

  expect_error(maplibre() |> add_model("car", "https://example.com/car.glb"), "Mapbox")
  expect_error(maplibre() |> add_model_layer("cars", "src", model_id = "car"), "Mapbox")
})

test_that("add_model_layer builds a model layer with paint properties", {
  pts <- sf::st_as_sf(
    data.frame(lon = c(-100.4, -100.41), lat = c(32.3, 32.31), s = c(1, 1.5)),
    coords = c("lon", "lat"), crs = 4326
  )
  scale <- list("interpolate", list("linear"), list("get", "s"), 0, list("literal", list(0, 0, 0)), 10, list("literal", list(10, 10, 10)))

  m <- mapboxgl() |>
    add_model("turbine", "https://example.com/turbine.glb") |>
    add_model_layer(
      "turbines", pts,
      model_id = "turbine",
      model_scale = scale,
      model_rotation = c(0, 0, 180),
      model_cast_shadows = TRUE
    )

  layer <- m$x$layers[[1]]
  expect_equal(layer$type, "model")
  expect_equal(layer$layout[["model-id"]], "turbine")
  expect_equal(layer$paint[["model-scale"]], scale)
  expect_equal(layer$paint[["model-rotation"]], list(0, 0, 180))
  expect_true(layer$paint[["model-cast-shadows"]])
  expect_null(layer$paint[["model-translation"]])
  expect_equal(layer$source$type, "geojson")
})

test_that("add_model_layer validates xyz vectors", {
  expect_error(
    mapboxgl() |> add_model_layer("m", "src", model_id = "x", model_scale = c(1, 2)),
    "length 3"
  )
})

test_that("add_model routes compare proxies to the chosen side", {
  sent <- list()
  session <- list(sendCustomMessage = function(type, message) {
    sent[[length(sent) + 1]] <<- list(type = type, message = message)
  })
  proxy <- structure(
    list(id = "cmp", session = session, map_side = "after"),
    class = c("mapboxgl_compare_proxy", "mapboxgl_proxy")
  )

  add_model(proxy, "car", "https://example.com/car.glb")

  expect_equal(sent[[1]]$type, "mapboxgl-compare-proxy")
  expect_equal(sent[[1]]$message$message$type, "add_model")
  expect_equal(sent[[1]]$message$message$map, "after")
})

test_that("compare views carry each map's models", {
  m1 <- mapboxgl() |> add_model("car", "https://example.com/car.glb")
  m2 <- mapboxgl()
  cmp <- compare(m1, m2)
  expect_equal(cmp$x$map1$models[[1]]$id, "car")
})
