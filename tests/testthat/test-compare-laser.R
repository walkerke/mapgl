test_that("sync compare widgets carry laser pointer options", {
  map1 <- maplibre()
  map2 <- maplibre()

  widget <- compare(
    map1,
    map2,
    mode = "sync",
    laser = TRUE,
    laser_color = "#00ffff",
    laser_size = 18
  )

  expect_s3_class(widget, "maplibregl_compare")
  expect_true(widget$x$laser$enabled)
  expect_equal(widget$x$laser$color, "#00ffff")
  expect_equal(widget$x$laser$size, 18)
})

test_that("laser pointer is ignored outside sync mode", {
  map1 <- maplibre()
  map2 <- maplibre()

  expect_warning(
    widget <- compare(map1, map2, mode = "swipe", laser = TRUE),
    "`laser` is only supported"
  )

  expect_false(widget$x$laser$enabled)
})

test_that("laser pointer size must be positive", {
  map1 <- maplibre()
  map2 <- maplibre()

  expect_error(
    compare(map1, map2, mode = "sync", laser = TRUE, laser_size = 0),
    "`laser_size` must be a positive number"
  )
})
