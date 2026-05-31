test_that("add_time_control serializes initial range", {
  timestamps <- as.POSIXct(
    c("2026-01-01 00:15:00", "2026-01-01 01:30:00"),
    tz = "UTC"
  )
  map <- maplibre() |>
    add_time_control(
      data = data.frame(time = timestamps),
      time_column = "time",
      layer_id = "points",
      initial_range = as.POSIXct(
        c("2026-01-01 00:00:00", "2026-01-01 01:00:00"),
        tz = "UTC"
      )
    )

  control <- map$x$time_controls[[1]]
  expect_equal(control$targetLayerIds, list("points"))
  expect_equal(
    control$initialRange,
    c("2026-01-01T00:00:00Z", "2026-01-01T01:00:00Z")
  )
})

test_that("time control JavaScript supports shift-selected ranges", {
  js <- paste(
    readLines(system.file(
      "htmlwidgets/lib/time-control/time-control.js",
      package = "mapgl"
    )),
    collapse = "\n"
  )

  expect_match(js, "sourceEvent\\.shiftKey", fixed = FALSE)
  expect_match(js, "selectedTimeRanges", fixed = TRUE)
  expect_match(js, "\\[\"any\", \\.\\.\\.clauses\\]", fixed = FALSE)
  expect_match(js, "Shift \\+ drag = select multiple", fixed = FALSE)
  expect_match(js, "mapgl-time-icon-btn", fixed = TRUE)
  expect_match(
    js,
    "Math\\.abs\\(dx\\) \\+ Math\\.abs\\(dy\\) < 3",
    fixed = FALSE
  )
})

test_that("flowmap assets support multiple selected time ranges", {
  flowmap_js <- paste(
    readLines(system.file("htmlwidgets/flowmap.js", package = "mapgl")),
    collapse = "\n"
  )
  bundle_js <- paste(
    readLines(system.file(
      "htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js",
      package = "mapgl"
    )),
    collapse = "\n"
  )

  expect_match(flowmap_js, "normalizeTimeRanges", fixed = TRUE)
  expect_match(flowmap_js, "selectedTimeRanges", fixed = TRUE)
  expect_match(bundle_js, "getSelectedTimeRanges", fixed = TRUE)
})
