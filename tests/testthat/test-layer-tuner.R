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
