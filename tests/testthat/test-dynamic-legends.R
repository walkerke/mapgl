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

test_that("categorical legends emit zoom visibility attributes", {
  map <- maplibre() |>
    add_categorical_legend(
      legend_title = "Zoomed",
      values = c("A", "B"),
      colors = c("red", "blue"),
      min_zoom = 4,
      max_zoom = 10.5
    )

  expect_match(map$x$legend_html, 'data-min-zoom="4"', fixed = TRUE)
  expect_match(map$x$legend_html, 'data-max-zoom="10.5"', fixed = TRUE)

  # Absent by default
  plain <- maplibre() |>
    add_categorical_legend(
      legend_title = "Plain",
      values = c("A", "B"),
      colors = c("red", "blue")
    )
  expect_false(grepl("data-min-zoom", plain$x$legend_html, fixed = TRUE))
  expect_false(grepl("data-max-zoom", plain$x$legend_html, fixed = TRUE))
  expect_false(grepl("data-manual-position", plain$x$legend_html, fixed = TRUE))
})

test_that("continuous legends emit zoom visibility attributes via add_legend", {
  map <- maplibre() |>
    add_legend(
      "Zoomed",
      values = c(0, 100),
      colors = c("blue", "red"),
      type = "continuous",
      min_zoom = 6
    )

  expect_match(map$x$legend_html, 'data-min-zoom="6"', fixed = TRUE)
  expect_false(grepl("data-max-zoom", map$x$legend_html, fixed = TRUE))

  # add_legend threading for categorical legends
  cat_map <- maplibre() |>
    add_legend(
      "Zoomed",
      values = c("A", "B"),
      colors = c("red", "blue"),
      type = "categorical",
      max_zoom = 9
    )
  expect_match(cat_map$x$legend_html, 'data-max-zoom="9"', fixed = TRUE)
})

test_that("bivariate legends emit zoom visibility attributes", {
  scale <- bivariate_scale(
    data = data.frame(x = 1:9, y = 9:1),
    x = "x",
    y = "y"
  )

  map <- maplibre() |>
    add_bivariate_legend(scale, min_zoom = 5, max_zoom = 12)

  expect_match(map$x$legend_html, 'data-min-zoom="5"', fixed = TRUE)
  expect_match(map$x$legend_html, 'data-max-zoom="12"', fixed = TRUE)
})

test_that("explicit margins mark legends as manually positioned", {
  map <- maplibre() |>
    add_categorical_legend(
      legend_title = "Manual",
      values = c("A"),
      colors = c("red"),
      margin_bottom = 100
    )
  expect_match(map$x$legend_html, 'data-manual-position="true"', fixed = TRUE)

  cont <- maplibre() |>
    add_continuous_legend(
      legend_title = "Manual",
      values = c(0, 1),
      colors = c("blue", "red"),
      margin_left = 40
    )
  expect_match(cont$x$legend_html, 'data-manual-position="true"', fixed = TRUE)
})

test_that("compare legends emit zoom, manual-position, and draggable attributes", {
  m1 <- maplibre()
  m2 <- maplibre()

  cmp <- compare(m1, m2) |>
    add_legend(
      "Categorical",
      values = c("A", "B"),
      colors = c("red", "blue"),
      type = "categorical",
      target = "before",
      draggable = TRUE,
      min_zoom = 3,
      max_zoom = 11
    ) |>
    add_legend(
      "Continuous",
      values = c(0, 100),
      colors = c("blue", "red"),
      type = "continuous",
      target = "after",
      margin_top = 60,
      min_zoom = 2,
      add = TRUE
    )

  cat_html <- cmp$x$compare_legends[[1]]$html
  expect_match(cat_html, 'data-min-zoom="3"', fixed = TRUE)
  expect_match(cat_html, 'data-max-zoom="11"', fixed = TRUE)
  expect_match(cat_html, 'data-draggable="true"', fixed = TRUE)
  expect_false(grepl("data-manual-position", cat_html, fixed = TRUE))

  cont_html <- cmp$x$compare_legends[[2]]$html
  expect_match(cont_html, 'data-min-zoom="2"', fixed = TRUE)
  expect_false(grepl("data-max-zoom", cont_html, fixed = TRUE))
  expect_match(cont_html, 'data-manual-position="true"', fixed = TRUE)

  # Absent by default
  plain <- compare(maplibre(), maplibre()) |>
    add_legend(
      "Plain",
      values = c("A"),
      colors = c("red"),
      type = "categorical",
      target = "before"
    )
  plain_html <- plain$x$compare_legends[[1]]$html
  expect_false(grepl("data-min-zoom", plain_html, fixed = TRUE))
  expect_false(grepl("data-draggable", plain_html, fixed = TRUE))
})

test_that("replacing existing legends without add = TRUE informs the user", {
  base <- maplibre() |>
    add_legend(
      "First",
      values = c("A"),
      colors = c("red"),
      type = "categorical"
    )

  expect_message(
    base |>
      add_legend(
        "Second",
        values = c("B"),
        colors = c("blue"),
        type = "categorical"
      ),
    "Replacing existing legend"
  )
  expect_message(
    base |>
      add_continuous_legend(
        legend_title = "Second",
        values = c(0, 1),
        colors = c("blue", "red")
      ),
    "Replacing existing legend"
  )

  # No message on the first legend, or when adding alongside
  expect_no_message(
    maplibre() |>
      add_legend("First", values = c("A"), colors = c("red"), type = "categorical")
  )
  expect_no_message(
    base |>
      add_legend(
        "Second",
        values = c("B"),
        colors = c("blue"),
        type = "categorical",
        add = TRUE
      )
  )

  # Compare-level legends have the same replace-by-default behavior
  cmp_base <- compare(maplibre(), maplibre()) |>
    add_legend("First", values = c("A"), colors = c("red"), type = "categorical")
  expect_message(
    cmp_base |>
      add_legend("Second", values = c("B"), colors = c("blue"), type = "categorical"),
    "Replacing existing legend"
  )
  expect_no_message(
    cmp_base |>
      add_legend(
        "Second",
        values = c("B"),
        colors = c("blue"),
        type = "categorical",
        add = TRUE
      )
  )
})

test_that("legend zoom visibility and stacking work in a headless browser", {
  skip_on_cran()
  skip_if_not_installed("chromote")

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

  m <- maplibre(style = blank_style, center = c(-97.1, 32.7), zoom = 5) |>
    add_categorical_legend(
      legend_title = "Gated",
      values = c("A", "B"),
      colors = c("red", "blue"),
      position = "bottom-left",
      unique_id = "legend-gated",
      min_zoom = 4,
      max_zoom = 8
    ) |>
    add_categorical_legend(
      legend_title = "Always",
      values = c("C", "D"),
      colors = c("green", "orange"),
      position = "bottom-left",
      unique_id = "legend-always",
      add = TRUE
    ) |>
    add_categorical_legend(
      legend_title = "Manual",
      values = c("E"),
      colors = c("purple"),
      position = "bottom-left",
      margin_bottom = 250,
      unique_id = "legend-manual",
      add = TRUE
    )

  dir <- tempfile("mapgl-legend-zoom-")
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
    if (is.null(value) || identical(value, "null")) {
      return(NULL)
    }
    jsonlite::fromJSON(value, simplifyVector = TRUE)
  }

  wait_for <- function(expr, timeout = 30) {
    deadline <- Sys.time() + timeout
    repeat {
      result <- tryCatch(js_value(expr), error = function(e) NULL)
      if (isTRUE(result)) {
        return(invisible(TRUE))
      }
      if (Sys.time() > deadline) {
        return(FALSE)
      }
      Sys.sleep(0.25)
    }
  }

  b$Page$navigate(paste0("file://", html_file))

  if (
    !wait_for(
      "var c = document.createElement('canvas');
       return !!(c.getContext('webgl2') || c.getContext('webgl'));",
      timeout = 10
    )
  ) {
    skip("Headless browser does not support WebGL")
  }

  ready <- wait_for(
    "var el = document.querySelector('.maplibregl');
     return !!(el && el._mapglLegendManager &&
       document.getElementById('legend-gated') &&
       document.getElementById('legend-always') &&
       document.getElementById('legend-manual'));"
  )
  if (!ready) skip("Map failed to initialize in the headless browser")

  hidden <- function(id) {
    paste0(
      "return document.getElementById('",
      id,
      "').classList.contains('mapgl-legend-zoom-hidden');"
    )
  }
  visible <- function(id) {
    paste0(
      "return !document.getElementById('",
      id,
      "').classList.contains('mapgl-legend-zoom-hidden');"
    )
  }
  set_zoom <- function(z) {
    js_value(paste0(
      "HTMLWidgets.find('.maplibregl').getMap().setZoom(",
      z,
      "); return true;"
    ))
  }

  # At zoom 5 both legends are visible and stacked without overlap;
  # "Always" (added second) sits above "Gated"
  expect_true(wait_for(
    "var g = document.getElementById('legend-gated').getBoundingClientRect();
     var a = document.getElementById('legend-always').getBoundingClientRect();
     return a.bottom <= g.top && a.height > 0 && g.height > 0;"
  ))
  expect_false(js_value(hidden("legend-gated")))

  # The manually positioned legend is untouched by the stacker
  expect_true(js_value(
    "var m = document.getElementById('legend-manual');
     return m.style.top === '' && m.style.bottom === '';"
  ))

  # min_zoom is inclusive, max_zoom is exclusive
  set_zoom(4)
  expect_true(wait_for(visible("legend-gated")))
  set_zoom(3.9)
  expect_true(wait_for(hidden("legend-gated")))
  set_zoom(7.9)
  expect_true(wait_for(visible("legend-gated")))
  set_zoom(8)
  expect_true(wait_for(hidden("legend-gated")))

  # With "Gated" zoom-hidden, "Always" reflows into the bottom slot
  expect_true(wait_for(
    "return document.getElementById('legend-always').style.bottom === '';"
  ))

  # A legend injected later (as the Shiny proxy does) is picked up by the
  # manager's MutationObserver and zoom-gated immediately
  js_value(
    "var el = document.querySelector('.maplibregl');
     var wrapper = document.createElement('div');
     wrapper.classList.add('mapboxgl-legend');
     wrapper.innerHTML = '<div id=\"legend-injected\" ' +
       'class=\"mapboxgl-legend bottom-left\" data-min-zoom=\"10\">' +
       '<h2>Injected</h2></div>';
     el.appendChild(wrapper);
     return true;"
  )
  expect_true(wait_for(hidden("legend-injected")))
})

test_that("compare legend managers stay scoped and drags use the outer bounds", {
  skip_on_cran()
  skip_if_not_installed("chromote")

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

  m1 <- maplibre(style = blank_style, center = c(-97.1, 32.7), zoom = 5)
  m2 <- maplibre(style = blank_style, center = c(-97.1, 32.7), zoom = 5)

  # sync mode lays the maps out side by side, so the before map's container
  # occupies only the left half - which lets the drag test below prove the
  # compare-level legend is bounded by the outer element, not one map
  cmp <- compare(m1, m2, mode = "sync") |>
    add_legend(
      "Outer",
      values = c("A", "B"),
      colors = c("red", "blue"),
      type = "categorical",
      target = "compare",
      position = "bottom-left",
      draggable = TRUE,
      unique_id = "legend-outer"
    ) |>
    add_legend(
      "Side",
      values = c("C", "D"),
      colors = c("green", "orange"),
      type = "categorical",
      target = "before",
      position = "bottom-left",
      unique_id = "legend-side",
      add = TRUE
    )

  dir <- tempfile("mapgl-legend-compare-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(cmp, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) skip("chromote could not start a browser")
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
      result <- tryCatch(js_value(expr), error = function(e) NULL)
      if (isTRUE(result)) {
        return(invisible(TRUE))
      }
      if (Sys.time() > deadline) {
        return(FALSE)
      }
      Sys.sleep(0.25)
    }
  }

  b$Page$navigate(paste0("file://", html_file))

  if (
    !wait_for(
      "var c = document.createElement('canvas');
       return !!(c.getContext('webgl2') || c.getContext('webgl'));",
      timeout = 10
    )
  ) {
    skip("Headless browser does not support WebGL")
  }

  ready <- wait_for(
    "var outer = document.getElementById('legend-outer');
     var side = document.getElementById('legend-side');
     if (!outer || !side) return false;
     var outerOwner = outer.parentElement.parentElement;
     return !!(outerOwner && outerOwner._mapglLegendManager);"
  )
  if (!ready) skip("Compare map failed to initialize in the headless browser")

  # Ownership: the outer legend hangs off the compare element, the side
  # legend off the before map's container - and neither manager stacked
  # the other's legend (both are alone in their corner group)
  expect_true(js_value(
    "var outer = document.getElementById('legend-outer');
     var side = document.getElementById('legend-side');
     var outerOwner = outer.parentElement.parentElement;
     var sideOwner = side.parentElement.parentElement;
     return outerOwner !== sideOwner &&
       sideOwner.classList.contains('maplibregl-map') &&
       outer.style.top === '' && outer.style.bottom === '' &&
       side.style.top === '' && side.style.bottom === '';"
  ))

  # Dragging the compare-level legend uses the outer container's bounds:
  # a large horizontal drag carries it past the before map into the
  # second map's half, but never outside the compare element
  moved <- js_value(
    "var outer = document.getElementById('legend-outer');
     var owner = outer.parentElement.parentElement;
     var start = outer.getBoundingClientRect();
     var opts = { bubbles: true, clientX: start.left + 5, clientY: start.top + 5 };
     outer.dispatchEvent(new MouseEvent('mousedown', opts));
     document.dispatchEvent(new MouseEvent('mousemove', {
       bubbles: true, clientX: start.left + 5000, clientY: start.top - 100
     }));
     document.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
     var rect = outer.getBoundingClientRect();
     var ownerRect = owner.getBoundingClientRect();
     var sideRect = document.getElementById('legend-side')
       .parentElement.parentElement.getBoundingClientRect();
     return {
       userMoved: outer.dataset.mapglUserMoved === 'true',
       pastBeforeMap: rect.left >= sideRect.right - 1,
       // A zero-height wrapper bound would clamp the drag to top 0; real
       // vertical freedom proves the bounds are the outer element. The
       // right-edge check tolerates the 10px legend margin (the drag code
       // clamps the margin edge) plus scrollbar-induced width changes.
       keptVerticalFreedom: rect.top > ownerRect.top + 100,
       insideOuter: rect.right <= ownerRect.right + 30 &&
         rect.bottom <= ownerRect.bottom + 30
     };"
  )
  expect_true(moved$userMoved)
  expect_true(moved$pastBeforeMap)
  expect_true(moved$keptVerticalFreedom)
  expect_true(moved$insideOuter)
})
