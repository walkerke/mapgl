test_that("interpolate_palette stores color ramp metadata", {
  scale <- interpolate_palette(
    data = data.frame(value = 1:10),
    column = "value",
    color_ramps = list(
      Brand = c("#132B43", "#56B1F7"),
      Warm = c("#fff7bc", "#d95f0e")
    ),
    selected_ramp = "Warm",
    n = 4
  )

  expect_s3_class(scale, "mapgl_continuous_scale")
  expect_equal(scale$selected_ramp, "Warm")
  expect_equal(length(scale$color_ramps$Brand), length(scale$breaks))
  expect_equal(scale$colors, scale$color_ramps$Warm)
  expect_equal(scale$column, "value")
})

test_that("color ramp labels are optional", {
  scale <- interpolate_palette(
    data = data.frame(value = 1:10),
    column = "value",
    color_ramps = list(
      c("#132B43", "#56B1F7"),
      c("#fff7bc", "#d95f0e")
    ),
    selected_ramp = 2,
    n = 4
  )

  expect_equal(names(scale$color_ramps), c("Ramp 1", "Ramp 2"))
  expect_equal(scale$selected_ramp, "Ramp 2")
  expect_equal(scale$colors, scale$color_ramps[["Ramp 2"]])

  map <- maplibre() |>
    add_fill_layer(
      id = "values",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      ),
      fill_color = scale$expression
    ) |>
    add_legend(
      "Values",
      colors = scale,
      layer_id = "values",
      ramp_picker = TRUE,
      ramp_labels = FALSE
    )

  config <- map$x$legend_interactivity[[1]]
  expect_equal(config$selectedRamp, "Ramp 2")
  expect_match(map$x$legend_html, "mapgl-ramp-picker-no-labels")
  expect_false(grepl("mapgl-ramp-picker-label", map$x$legend_html, fixed = TRUE))
})

test_that("continuous legends can use scale metadata for ramp picker config", {
  scale <- interpolate_palette(
    data = data.frame(value = 1:10),
    column = "value",
    color_ramps = list(
      Brand = c("#132B43", "#56B1F7"),
      Warm = c("#fff7bc", "#d95f0e")
    )
  )

  map <- maplibre() |>
    add_fill_layer(
      id = "values",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      ),
      fill_color = scale$expression
    ) |>
    add_legend("Values", colors = scale, layer_id = "values", ramp_picker = TRUE)

  config <- map$x$legend_interactivity[[1]]
  expect_true(config$rampPicker)
  expect_false(config$filter)
  expect_equal(config$colorColumn, "value")
  expect_equal(names(config$colorRamps), c("Brand", "Warm"))
  expect_match(map$x$legend_html, "mapgl-ramp-picker")
})

test_that("bottom-positioned ramp pickers open upward", {
  scale <- interpolate_palette(
    data = data.frame(value = 1:10),
    column = "value",
    color_ramps = list(
      Brand = c("#132B43", "#56B1F7"),
      Warm = c("#fff7bc", "#d95f0e")
    )
  )

  map <- maplibre() |>
    add_fill_layer(
      id = "values",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      ),
      fill_color = scale$expression
    ) |>
    add_legend(
      "Values",
      colors = scale,
      layer_id = "values",
      position = "bottom-left",
      ramp_picker = TRUE
    )

  expect_match(map$x$legend_css, ".bottom-left .mapgl-ramp-picker-menu", fixed = TRUE)
  expect_match(map$x$legend_css, "bottom: 4px", fixed = TRUE)
})

test_that("ramp picker requires an associated layer", {
  expect_error(
    maplibre() |>
      add_legend(
        "Values",
        values = 1:3,
        colors = c("red", "white", "blue"),
        color_ramps = list(Brand = c("red", "blue")),
        ramp_picker = TRUE
      ),
    "layer_id"
  )
})

test_that("bivariate_scale creates a 3 by 3 scale expression", {
  scale <- bivariate_scale(
    data = data.frame(x = 1:9, y = 9:1),
    x = "x",
    y = "y"
  )

  expect_s3_class(scale, "mapgl_bivariate_scale")
  expect_equal(dim(scale$colors), c(3, 3))
  expect_equal(scale$expression[[1]], "case")
  expect_equal(scale$expression[[2]][[1]], "any")
  expect_equal(scale$expression[[3]], "lightgrey")
  expect_equal(scale$x, "x")
  expect_equal(scale$y, "y")
  expect_equal(scale$na_color, "lightgrey")
})

test_that("bivariate_scale respects explicit na_color", {
  scale <- bivariate_scale(
    data = data.frame(x = c(1:9, NA), y = c(9:1, 5)),
    x = "x",
    y = "y",
    na_color = "#f0f0f0"
  )

  expect_equal(scale$na_color, "#f0f0f0")
  expect_equal(scale$expression[[3]], "#f0f0f0")
})

test_that("bivariate_scale accepts custom breaks", {
  scale <- bivariate_scale(
    data = data.frame(x = 1:9, y = 9:1),
    x = "x",
    y = "y",
    x_breaks = c(0, 3, 6, 9),
    y_breaks = c(0, 4, 7, 10)
  )

  expect_equal(scale$x_breaks, c(0, 3, 6, 9))
  expect_equal(scale$y_breaks, c(0, 4, 7, 10))
  expect_equal(scale$method, "custom")
  expect_equal(scale$n, 3)

  expect_error(
    bivariate_scale(
      data = data.frame(x = 1:9, y = 9:1),
      x = "x",
      y = "y",
      x_breaks = c(0, 3, 3, 9)
    ),
    "strictly increasing"
  )
})

test_that("bivariate built-in palettes are inspectable", {
  palettes <- bivariate_palettes()
  expect_true(all(c("blue_pink", "blue_red", "green_blue", "purple_orange") %in% names(palettes)))
  expect_equal(dim(bivariate_palettes("blue_red")), c(3, 3))
  expect_error(bivariate_palettes("not-a-palette"), "Unknown bivariate palette")
})

test_that("bivariate legend emits native HTML legend", {
  scale <- bivariate_scale(
    data = data.frame(x = 1:9, y = 9:1),
    x = "x",
    y = "y"
  )

  map <- maplibre() |>
    add_bivariate_legend(scale, layer_id = "bivar")

  expect_match(map$x$legend_html, "mapgl-bivariate-grid")
  expect_match(map$x$legend_css, "mapgl-bivariate-cell")
})
