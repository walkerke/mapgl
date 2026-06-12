test_that("compare() syncs more than two maps in a grid", {
  widget <- compare(
    maplibre(center = c(-97.3, 32.75), zoom = 9),
    maplibre(zoom = 4),
    maplibre(),
    maplibre(),
    mode = "sync"
  )

  expect_s3_class(widget, "maplibregl_compare")
  expect_length(widget$x$maps, 4)
  # First two maps keep their map1/map2 slots
  expect_equal(widget$x$map1, widget$x$maps[[1]])
  expect_equal(widget$x$map2, widget$x$maps[[2]])
  expect_equal(widget$x$maps[[1]]$zoom, 9)
  expect_equal(widget$x$maps[[2]]$zoom, 4)
  # Default ncol is ceiling(sqrt(n))
  expect_equal(widget$x$sync_cols, 2)
})

test_that("compare() respects an explicit ncol", {
  widget <- compare(
    maplibre(),
    maplibre(),
    maplibre(),
    mode = "sync",
    ncol = 3
  )

  expect_equal(widget$x$sync_cols, 3)

  # Three maps default to a 2-column grid
  widget <- compare(maplibre(), maplibre(), maplibre(), mode = "sync")
  expect_equal(widget$x$sync_cols, 2)
})

test_that("two-map compare payloads are unchanged", {
  widget <- compare(maplibre(), maplibre(), mode = "sync")
  expect_null(widget$x$maps)
  expect_null(widget$x$sync_cols)

  widget <- compare(maplibre(), maplibre())
  expect_null(widget$x$maps)
  expect_null(widget$x$sync_cols)

  # Explicit ncol with two maps is honored without switching to grid payload
  widget <- compare(maplibre(), maplibre(), mode = "sync", ncol = 1)
  expect_equal(widget$x$sync_cols, 1)
  expect_null(widget$x$maps)
})

test_that("compare() requires sync mode for more than two maps", {
  expect_error(
    compare(maplibre(), maplibre(), maplibre()),
    "supports exactly 2 maps"
  )
  expect_error(
    compare(maplibre(), maplibre(), maplibre(), mode = "swipe"),
    "supports exactly 2 maps"
  )
})

test_that("compare() rejects non-map objects in ...", {
  # Legacy positional arguments get a "must be named" hint
  expect_error(
    compare(maplibre(), maplibre(), "100%"),
    "must be named"
  )
  # Named non-map arguments are reported as unknown
  expect_error(
    compare(maplibre(), maplibre(), widht = "100%"),
    "Unknown argument `widht`"
  )
})

test_that("compare() requires all maps to share an engine", {
  fake_mapbox <- structure(list(x = list()), class = "mapboxgl")
  expect_error(
    compare(maplibre(), maplibre(), fake_mapbox, mode = "sync"),
    "All maps must be either mapboxgl or maplibregl objects"
  )
})

test_that("compare() validates ncol", {
  m <- list(maplibre(), maplibre(), maplibre())
  for (bad in list(NA, Inf, 0, -1, 1.5, "2", c(2, 3), 1e20, 2^31)) {
    expect_error(
      expect_no_warning(
        compare(m[[1]], m[[2]], m[[3]], mode = "sync", ncol = bad)
      ),
      "`ncol` must be a single positive integer"
    )
  }
})

test_that("compare() warns on ncol edge cases", {
  expect_warning(
    widget <- compare(
      maplibre(),
      maplibre(),
      maplibre(),
      mode = "sync",
      ncol = 5
    ),
    "greater than the number of maps"
  )
  expect_equal(widget$x$sync_cols, 3)

  expect_warning(
    widget <- compare(maplibre(), maplibre(), ncol = 2),
    "ignored when"
  )
  expect_null(widget$x$sync_cols)
})

test_that("normalize_map_side() accepts valid sides and rejects bad ones", {
  expect_equal(mapgl:::normalize_map_side("before"), "before")
  expect_equal(mapgl:::normalize_map_side("after"), "after")
  expect_equal(mapgl:::normalize_map_side("map99"), "map99")
  expect_equal(mapgl:::normalize_map_side(3), "map3")
  expect_equal(mapgl:::normalize_map_side(1L), "map1")

  for (bad in list("left", "map0", 0, -1, 2.5, NA, c(1, 2), 1e20, 2^31)) {
    expect_error(
      expect_no_warning(mapgl:::normalize_map_side(bad)),
      "`map_side` must be"
    )
  }
})

test_that("legends can target individual maps in a grid", {
  widget <- compare(
    maplibre(),
    maplibre(),
    maplibre(),
    mode = "sync"
  ) |>
    add_legend(
      "Test legend",
      values = c("Low", "High"),
      colors = c("blue", "red"),
      type = "categorical",
      target = "map3"
    )

  expect_length(widget$x$compare_legends, 1)
  expect_equal(widget$x$compare_legends[[1]]$target, "map3")
})
