test_that("add_layer_tuner serializes initial UI options", {
  map <- maplibre() |>
    add_layer_tuner(
      layers = c("counties", "roads"),
      show_all_args = TRUE,
      title = "Style editor",
      position = "bottom-right",
      width = 320,
      height = "40vh",
      collapsed = TRUE
    )

  tuner <- map$x$layer_tuner
  expect_true(tuner$enabled)
  expect_equal(tuner$layers, c("counties", "roads"))
  expect_true(tuner$show_all_args)
  expect_equal(tuner$title, "Style editor")
  expect_equal(tuner$position, "bottom-right")
  expect_equal(tuner$width, "320px")
  expect_equal(tuner$height, "40vh")
  expect_true(tuner$collapsed)
})

test_that("add_layer_tuner keeps default UI options compatible", {
  tuner <- maplibre() |>
    add_layer_tuner() |>
    getElement("x") |>
    getElement("layer_tuner")

  expect_null(tuner$title)
  expect_equal(tuner$position, "top-left")
  expect_equal(tuner$width, "245px")
  expect_null(tuner$height)
  expect_false(tuner$collapsed)
})

test_that("add_layer_tuner validates initial UI options", {
  expect_error(add_layer_tuner(maplibre(), title = ""), "`title`")
  expect_error(add_layer_tuner(maplibre(), position = "middle"), "`position`")
  expect_error(add_layer_tuner(maplibre(), width = 0), "`width`")
  expect_error(add_layer_tuner(maplibre(), width = c(200, 300)), "`width`")
  expect_error(add_layer_tuner(maplibre(), height = NA), "`height`")
  expect_error(add_layer_tuner(maplibre(), collapsed = NA), "`collapsed`")
})

test_that("compare widgets preserve child layer tuner dependencies", {
  widget <- compare(
    maplibre() |> add_layer_tuner(),
    maplibre()
  )

  dependency_names <- vapply(
    widget$dependencies,
    `[[`,
    character(1),
    "name"
  )

  expect_true("lil-gui" %in% dependency_names)
  expect_true("layer-tuner" %in% dependency_names)
  expect_true(widget$x$map1$layer_tuner$enabled)
  expect_null(widget$x$map2$layer_tuner)
})

test_that("add_layer_tuner configures both maps in compare widgets", {
  widget <- compare(maplibre(), maplibre()) |>
    add_layer_tuner(position = "top-right")

  expect_true(widget$x$map1$layer_tuner$enabled)
  expect_true(widget$x$map2$layer_tuner$enabled)
  expect_equal(widget$x$map1$layer_tuner$position, "top-right")
  expect_equal(widget$x$map2$layer_tuner$position, "top-right")
})

test_that("compare widget bindings initialize the layer tuner", {
  compare_js_paths <- c(
    "htmlwidgets/mapboxgl_compare.js",
    "htmlwidgets/maplibregl_compare.js"
  )

  for (path in compare_js_paths) {
    js <- paste(
      readLines(system.file(path, package = "mapgl")),
      collapse = "\n"
    )
    expect_match(js, "MapGLLayerTuner\\.init", fixed = FALSE)
    expect_match(js, "mapData\\.layer_tuner", fixed = FALSE)
    expect_match(js, "_basemapLayerIds", fixed = TRUE)
    expect_match(js, "mapgl-compare-layer-tuner-host", fixed = TRUE)
  }
})
