test_that("interactive categorical legends isolate a category by hold or 'only'", {
  skip_on_cran()
  skip_if_not_installed("chromote")
  skip_if_not_installed("sf")

  blank_style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list(
      list(id = "bg", type = "background", paint = list(`background-color` = "#dddddd"))
    )
  )
  vals <- c("a", "b", "c", "d")
  cols <- c("red", "blue", "green", "orange")
  pts <- sf::st_as_sf(
    data.frame(x = c(-97, -96, -95, -94), y = 32, cat = vals),
    coords = c("x", "y"), crs = 4326
  )

  m <- maplibre(style = blank_style, center = c(-95.5, 32), zoom = 5) |>
    add_circle_layer(
      "pts", source = pts,
      circle_color = match_expr("cat", values = vals, stops = cols)
    ) |>
    add_categorical_legend(
      legend_title = "Cat", values = c("A", "B", "C", "D"), colors = cols,
      interactive = TRUE, layer_id = "pts", filter_column = "cat",
      filter_values = vals, unique_id = "legend-iso", only_button = TRUE
    ) |>
    add_circle_layer(
      "pts2", source = pts,
      circle_color = match_expr("cat", values = vals, stops = cols)
    ) |>
    add_categorical_legend(
      legend_title = "Plain", values = c("A", "B", "C", "D"), colors = cols,
      interactive = TRUE, layer_id = "pts2", filter_column = "cat",
      filter_values = vals, unique_id = "legend-plain", add = TRUE,
      position = "top-right"
    )

  dir <- tempfile("mapgl-legend-isolate-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) skip("chromote could not start a browser")
  on.exit(b$close(), add = TRUE)

  js_value <- function(expr) {
    out <- b$Runtime$evaluate(
      paste0("JSON.stringify((function() {", expr, "})())"),
      returnByValue = TRUE
    )
    value <- out$result$value
    if (is.null(value) || identical(value, "null")) return(NULL)
    jsonlite::fromJSON(value, simplifyVector = TRUE)
  }
  wait_for <- function(expr, timeout = 30) {
    deadline <- Sys.time() + timeout
    repeat {
      if (isTRUE(tryCatch(js_value(expr), error = function(e) NULL))) return(TRUE)
      if (Sys.time() > deadline) return(FALSE)
      Sys.sleep(0.25)
    }
  }

  b$Page$navigate(paste0("file://", html_file))
  if (!wait_for(
    "var c = document.createElement('canvas');
     return !!(c.getContext('webgl2') || c.getContext('webgl'));",
    timeout = 10
  )) {
    skip("Headless browser does not support WebGL")
  }
  ready <- wait_for(
    "var el = document.querySelector('.maplibregl');
     var w = el && HTMLWidgets.find('.maplibregl');
     return !!(w && w.getMap() && w.getMap().getLayer('pts') &&
       document.querySelectorAll('#legend-iso .legend-only-btn').length === 4);"
  )
  if (!ready) skip("Map failed to initialize in the headless browser")

  shown <- function() {
    js_value(
      "var f = HTMLWidgets.find('.maplibregl').getMap().getFilter('pts');
       return f ? f[2] : 'all';"
    )
  }
  enabled <- function() {
    js_value(
      "return Array.from(document.querySelectorAll('#legend-iso .legend-item'))
         .map(function(i) { return i.getAttribute('data-enabled'); });"
    )
  }
  center <- function(selector, i) {
    js_value(sprintf(
      "var r = document.querySelectorAll('%s')[%d].getBoundingClientRect();
       return [r.left + 12, r.top + r.height / 2];",
      selector, i
    ))
  }
  mouse <- function(type, xy) {
    b$Input$dispatchMouseEvent(
      type = type, x = xy[1], y = xy[2], button = "left", clickCount = 1
    )
  }
  press <- function(i, seconds) {
    xy <- center("#legend-iso .legend-item", i)
    mouse("mouseMoved", xy)
    mouse("mousePressed", xy)
    Sys.sleep(seconds)
    mouse("mouseReleased", xy)
    Sys.sleep(0.2)
  }
  only_button <- function(i) {
    xy <- center("#legend-iso .legend-item", i)
    mouse("mouseMoved", xy)
    Sys.sleep(0.2)
    btn <- js_value(sprintf(
      "var r = document.querySelectorAll('#legend-iso .legend-only-btn')[%d]
         .getBoundingClientRect();
       return [r.left + r.width / 2, r.top + r.height / 2];",
      i
    ))
    mouse("mousePressed", btn)
    mouse("mouseReleased", btn)
    Sys.sleep(0.2)
  }

  # A short click still toggles one category
  press(1, 0.05)
  expect_equal(sort(shown()), c("a", "c", "d"))
  press(1, 0.05)
  expect_false("false" %in% enabled())

  # Holding isolates, and the release does not toggle it back off
  press(2, 0.8)
  expect_equal(shown(), "c")
  expect_equal(enabled(), c("false", "false", "true", "false"))
  expect_equal(
    js_value("return document.querySelectorAll('#legend-iso .legend-only-btn')[2].textContent;"),
    "all"
  )

  # Holding the isolated category again restores every category
  press(2, 0.8)
  expect_equal(shown(), "all")
  expect_false("false" %in% enabled())

  # The "only" button isolates, then shows all again
  only_button(3)
  expect_equal(shown(), "d")
  only_button(3)
  expect_equal(shown(), "all")

  # "only" on a hidden category shows just that category
  press(0, 0.05)
  only_button(0)
  expect_equal(shown(), "a")

  # By default there is no "only" button, and holding still isolates
  expect_equal(
    js_value("return document.querySelectorAll('#legend-plain .legend-only-btn').length;"),
    0
  )
  xy <- center("#legend-plain .legend-item", 1)
  mouse("mouseMoved", xy)
  mouse("mousePressed", xy)
  Sys.sleep(0.8)
  mouse("mouseReleased", xy)
  Sys.sleep(0.2)
  expect_equal(
    js_value(
      "var f = HTMLWidgets.find('.maplibregl').getMap().getFilter('pts2');
       return f ? f[2] : 'all';"
    ),
    "b"
  )
})
