test_that("add_image can attach images to style lists", {
  style <- basemap_style(pattern = "bucees") |>
    add_image("bucees", "bucees.png")

  style_images <- attr(style, "mapgl_images", exact = TRUE)

  expect_length(style_images, 1)
  expect_equal(style_images[[1]]$id, "bucees")
  expect_equal(style_images[[1]]$url, "bucees.png")
  expect_equal(style$layers[[1]]$paint[["background-pattern"]], "bucees")
  expect_null(style$x)
})

test_that("add_image still attaches images to map widgets", {
  map <- maplibre() |>
    add_image("icon", "icon.png")

  expect_length(map$x$images, 1)
  expect_equal(map$x$images[[1]]$id, "icon")
  expect_equal(map$x$images[[1]]$url, "icon.png")
})

test_that("add_image recognizes hand-written style lists", {
  style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list()
  ) |>
    add_image("icon", "icon.png")

  expect_length(attr(style, "mapgl_images", exact = TRUE), 1)
})

test_that("maplibre transfers style images to widget config", {
  style <- basemap_style(pattern = "bucees") |>
    add_image("bucees", "bucees.png")

  map <- maplibre(style = style)

  expect_length(map$x$images, 1)
  expect_equal(map$x$images[[1]]$id, "bucees")
  expect_equal(map$x$images[[1]]$url, "bucees.png")
  expect_null(attr(map$x$style, "mapgl_images", exact = TRUE))
})

test_that("mapboxgl transfers style images to widget config", {
  style <- basemap_style(pattern = "bucees") |>
    add_image("bucees", "bucees.png")

  map <- mapboxgl(style = style, access_token = "fake")

  expect_length(map$x$images, 1)
  expect_equal(map$x$images[[1]]$id, "bucees")
  expect_equal(map$x$images[[1]]$url, "bucees.png")
  expect_null(attr(map$x$style, "mapgl_images", exact = TRUE))
})

test_that("add_image rejects objects that are not maps, proxies, or styles", {
  expect_error(
    add_image(list(foo = "bar"), "icon", "icon.png"),
    "map object, map proxy, or style list",
    fixed = TRUE
  )
})
