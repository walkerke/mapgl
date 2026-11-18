test_that("a bottom-anchored interactive legend keeps its rows in place when Reset appears", {
  skip_on_cran()
  skip_if_not_installed("chromote")
  skip_if_not_installed("sf")

  blank_style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list(
      list(
        id = "bg",
        type = "background",
        paint = list(`background-color` = "#dddddd")
      )
    )
  )
  vals <- c("a", "b", "c", "d")
  cols <- c("red", "blue", "green", "orange")
  pts <- sf::st_as_sf(
    data.frame(x = c(-97, -96, -95, -94), y = 32, cat = vals),
    coords = c("x", "y"),
    crs = 4326
  )
  legend_at <- function(map, layer, id, position, add = FALSE) {
    map |>
      add_circle_layer(
        layer,
        source = pts,
        circle_color = match_expr("cat", values = vals, stops = cols)
      ) |>
      add_categorical_legend(
        legend_title = "Cat",
        values = c("A", "B", "C", "D"),
        colors = cols,
        interactive = TRUE,
        layer_id = layer,
        filter_column = "cat",
        filter_values = vals,
        unique_id = id,
        position = position,
        add = add
      )
  }
  m <- maplibre(style = blank_style, center = c(-95.5, 32), zoom = 5) |>
    legend_at("pts", "legend-bottom", "bottom-left") |>
    legend_at("pts2", "legend-top", "top-right", add = TRUE)

  dir <- tempfile("mapgl-legend-reset-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) {
    skip("chromote could not start a browser")
  }
  on.exit(b$close(), add = TRUE)

  js_value <- function(expr) {
    out <- b$Runtime$evaluate(
      paste0("JSON.stringify((function() {", expr, "})())"),
      returnByValue = TRUE
    )
    value <- out$result$value
    if (is.null(value) || identical(value, "null")) {
      return(NULL)
    }
    jsonlite::fromJSON(value, simplifyVector = TRUE)
  }
  wait_for <- function(expr, timeout = 30) {
    deadline <- Sys.time() + timeout
    repeat {
      if (isTRUE(tryCatch(js_value(expr), error = function(e) NULL))) {
        return(TRUE)
      }
      if (Sys.time() > deadline) {
        return(FALSE)
      }
      Sys.sleep(0.25)
    }
  }

  b$Page$navigate(paste0("file://", html_file))
  ready <- wait_for(
    "var el = document.querySelector('.maplibregl');
     return !!(el && el.map && el.map.loaded() && el.map.getLayer('pts') &&
       document.querySelectorAll('#legend-bottom .legend-item').length === 4 &&
       document.querySelector('#legend-bottom .legend-reset-btn'));"
  )
  if (!ready) {
    skip("the map did not finish loading in the browser")
  }

  # Top of the first row, and whether the Reset button takes up space and
  # whether it can be seen.
  state <- function(id) {
    js_value(sprintf(
      "var leg = document.getElementById('%s');
       var row = leg.querySelector('.legend-item').getBoundingClientRect();
       var btn = leg.querySelector('.legend-reset-btn');
       var cs = getComputedStyle(btn);
       return {top: Math.round(row.top), display: cs.display,
               visibility: cs.visibility};",
      id
    ))
  }
  click_first <- function(id) {
    js_value(sprintf(
      "document.getElementById('%s').querySelector('.legend-item').click();
       return true;",
      id
    ))
  }

  bottom_before <- state("legend-bottom")
  top_before <- state("legend-top")

  # Bottom-anchored: the button's space is kept, but it cannot be seen yet.
  expect_equal(bottom_before$display, "block")
  expect_equal(bottom_before$visibility, "hidden")
  # Top-anchored: unchanged, the button takes no space until it is needed.
  expect_equal(top_before$display, "none")

  click_first("legend-bottom")
  click_first("legend-top")
  expect_true(wait_for(
    "var b = document.querySelector('#legend-bottom .legend-reset-btn');
     var t = document.querySelector('#legend-top .legend-reset-btn');
     return b.classList.contains('visible') && t.classList.contains('visible');",
    timeout = 5
  ))

  bottom_after <- state("legend-bottom")
  top_after <- state("legend-top")
  expect_equal(bottom_after$visibility, "visible")
  expect_equal(top_after$display, "block")
  # The rows have not moved in either legend.
  expect_equal(bottom_after$top, bottom_before$top)
  expect_equal(top_after$top, top_before$top)
})
