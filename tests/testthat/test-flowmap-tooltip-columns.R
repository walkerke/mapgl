test_that("tooltip_style() carries hide_after and validates it", {
  s <- tooltip_style(hide_after = 3)
  expect_equal(s$hide_after, 3)
  expect_equal(popup_style("dark", hide_after = 2)$hide_after, 2)

  # hide_after alone resolves to a spec holding only the behavior
  expect_equal(mapgl_normalize_tooltip_style(s), list(hide_after = 3))

  # and travels with a preset
  resolved <- mapgl_normalize_tooltip_style(tooltip_style("dark", hide_after = 3))
  expect_equal(resolved$hide_after, 3)
  expect_equal(resolved$background_color, "rgba(35, 35, 35, 0.94)")

  expect_error(tooltip_style(hide_after = 0), "positive number")
  expect_error(tooltip_style(hide_after = "3"), "positive number")
  expect_error(tooltip_style(hide_after = c(1, 2)), "positive number")
})

test_that("hide_after serializes on layers and flowmaps", {
  pts <- sf::st_as_sf(
    data.frame(lon = 0, lat = 0, name = "x"),
    coords = c("lon", "lat"), crs = 4326
  )
  m <- maplibre() |>
    add_circle_layer(
      id = "c", source = pts, tooltip = "name",
      tooltip_style = tooltip_style(hide_after = 3),
      popup = "name", popup_style = popup_style("dark", hide_after = 5)
    )
  expect_equal(m$x$layers[[1]]$tooltip_style, list(hide_after = 3))
  expect_equal(m$x$layers[[1]]$popup_style$hide_after, 5)

  locations <- data.frame(id = c("a", "b"), lat = c(40, 41), lon = c(-74, -75))
  flows <- data.frame(origin = "a", dest = "b", count = 10, note = "n")
  fm <- maplibre() |>
    add_flowmap(
      id = "flows", locations = locations, flows = flows,
      tooltip_style = tooltip_style("dark", hide_after = 4)
    )
  expect_equal(fm$x$flowmaps[[1]]$tooltip$style$hide_after, 4)
})

test_that("add_flowmap serializes and validates the label zoom threshold", {
  locations <- data.frame(id = c("a", "b"), lat = c(40, 41), lon = c(-74, -75))
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  default <- maplibre() |>
    add_flowmap(id = "flows", locations = locations, flows = flows)
  expect_null(default$x$flowmaps[[1]]$settings$locationLabelsMinZoom)

  m <- maplibre() |>
    add_flowmap(
      id = "flows", locations = locations, flows = flows,
      flow_location_labels_enabled = TRUE,
      flow_location_labels_min_zoom = 5
    )
  expect_equal(m$x$flowmaps[[1]]$settings$locationLabelsMinZoom, 5)

  expect_error(
    maplibre() |>
      add_flowmap(
        id = "flows", locations = locations, flows = flows,
        flow_location_labels_min_zoom = "five"
      ),
    "must be a number or NULL"
  )
})

test_that("flow tooltips use extra columns, labels wait for zoom, tooltips time out (browser)", {
  skip_on_cran()
  skip_if_not_installed("chromote")

  blank_style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list(list(
      id = "bg",
      type = "background",
      paint = list(`background-color` = "#dddddd")
    ))
  )
  locations <- data.frame(
    id = c("a", "b", "c"),
    lat = c(40.75, 40.75, 40.75),
    lon = c(-74.01, -73.98, -73.95),
    kind = c("west end", "middle", "east end")
  )
  # a-b is one row, so its extra column is available; b-c is two rows, so the
  # hovered flow is a sum and carries only the built-in fields.
  flows <- data.frame(
    origin = c("a", "b", "b"), dest = c("b", "c", "c"), count = c(10, 4, 4),
    note = c("one row", "first", "second")
  )
  m <- maplibre(
    style = blank_style, center = c(-73.98, 40.75), zoom = 11
  ) |>
    add_flowmap(
      id = "flows", locations = locations, flows = flows,
      flow_blend = FALSE, flow_clustering_enabled = FALSE,
      flow_adaptive_scales_enabled = FALSE,
      flow_click_to_filter = FALSE, flow_hover_to_spotlight = FALSE,
      flow_location_labels_enabled = TRUE,
      flow_location_labels_min_zoom = 12,
      tooltip = list(flow = "{origin_id}>{dest_id} [{note}]", location = "kind"),
      tooltip_style = tooltip_style("light", hide_after = 1)
    )

  dir <- tempfile("mapgl-flowmap-tooltip-columns-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) skip("chromote could not start a browser")
  on.exit(b$close(), add = TRUE)
  b$Emulation$setDeviceMetricsOverride(
    width = 1000, height = 700, deviceScaleFactor = 1, mobile = FALSE
  )
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
      result <- tryCatch(js_value(expr), error = function(e) NULL)
      if (isTRUE(result)) return(invisible(TRUE))
      if (Sys.time() > deadline) return(FALSE)
      Sys.sleep(0.25)
    }
  }
  hover_between <- function(lon1, lon2) {
    js_value(sprintf(
      "var m=document.querySelector('.html-widget').map;
       var a=m.project([%s,40.75]), b=m.project([%s,40.75]);
       var p={x:(a.x+b.x)/2,y:(a.y+b.y)/2};
       m.fire('mousemove',{point:p,lngLat:m.unproject(p),originalEvent:{}});
       return true;",
      format(lon1, scientific = FALSE), format(lon2, scientific = FALSE)
    ))
  }
  tooltip_text <- "var t=document.querySelector('.mapgl-flowmap-example-tooltip');
     return t && t.style.display!=='none' ? t.innerText : '';"

  b$Page$navigate(paste0("file://", html_file))
  if (!wait_for(
    "var m=document.querySelector('.html-widget').map;
     return !!(m && m._deckgl && m._mapglFlowmapLayers &&
       m._mapglFlowmapLayers.length > 0 && m.loaded());"
  )) {
    skip("the flowmap did not finish loading in the browser")
  }
  Sys.sleep(1.5)

  labels_on <- "var m=document.querySelector('.html-widget').map;
     var l=m._mapglFlowmapLayers.find(function(l){return l.id==='flows';});
     return l && l.props.locationLabelsEnabled;"

  # Labels are held back below the threshold and appear above it.
  expect_false(isTRUE(js_value(labels_on)))
  js_value("document.querySelector('.html-widget').map.setZoom(12.5);return true;")
  expect_true(wait_for(paste0(labels_on, ""), timeout = 5))
  js_value("document.querySelector('.html-widget').map.setZoom(11);return true;")
  expect_true(wait_for(
    sub("return l && l.props.locationLabelsEnabled;",
        "return l && l.props.locationLabelsEnabled === false;", labels_on, fixed = TRUE),
    timeout = 5
  ))
  Sys.sleep(1)

  # A one-row flow shows its extra column.
  hover_between(-74.01, -73.98)
  expect_true(wait_for(
    paste0("var s=(function(){", tooltip_text, "})(); return s==='a>b [one row]';"),
    timeout = 5
  ))

  # The tooltip hides by itself after hide_after seconds.
  expect_true(wait_for(
    paste0("var s=(function(){", tooltip_text, "})(); return s==='';"),
    timeout = 4
  ))

  # An extra locations column is reachable by its bare name.
  js_value(
    "var m=document.querySelector('.html-widget').map;
     var p=m.project([-73.95,40.75]);
     m.fire('mousemove',{point:p,lngLat:m.unproject(p),originalEvent:{}});
     return true;"
  )
  expect_true(wait_for(
    paste0("var s=(function(){", tooltip_text, "})(); return s==='east end';"),
    timeout = 5
  ))
  js_value(
    "var m=document.querySelector('.html-widget').map;
     m.fire('mousemove',{point:{x:5,y:5},lngLat:m.unproject([5,5]),originalEvent:{}});
     return true;"
  )
  Sys.sleep(1.5)

  # A flow summed from two rows carries only the built-in fields.
  hover_between(-73.98, -73.95)
  expect_true(wait_for(
    paste0("var s=(function(){", tooltip_text, "})(); return s==='b>c []';"),
    timeout = 5
  ))
})

test_that("layer tooltips and popups hide after hide_after seconds (browser)", {
  skip_on_cran()
  skip_if_not_installed("chromote")

  blank_style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list(list(
      id = "bg",
      type = "background",
      paint = list(`background-color` = "#dddddd")
    ))
  )
  pts <- sf::st_as_sf(
    data.frame(lon = c(-73.98, -73.90), lat = c(40.75, 40.75), name = c("timed", "plain")),
    coords = c("lon", "lat"), crs = 4326
  )
  m <- maplibre(style = blank_style, center = c(-73.94, 40.75), zoom = 11) |>
    add_circle_layer(
      id = "timed", source = pts[1, ], circle_radius = 20, circle_color = "red",
      tooltip = "name", tooltip_style = tooltip_style(hide_after = 1),
      popup = "name", popup_style = popup_style("dark", hide_after = 1)
    ) |>
    add_circle_layer(
      id = "plain", source = pts[2, ], circle_radius = 20, circle_color = "blue",
      tooltip = "name"
    )

  dir <- tempfile("mapgl-tooltip-hide-after-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) skip("chromote could not start a browser")
  on.exit(b$close(), add = TRUE)
  b$Emulation$setDeviceMetricsOverride(
    width = 1000, height = 700, deviceScaleFactor = 1, mobile = FALSE
  )
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
      result <- tryCatch(js_value(expr), error = function(e) NULL)
      if (isTRUE(result)) return(invisible(TRUE))
      if (Sys.time() > deadline) return(FALSE)
      Sys.sleep(0.25)
    }
  }
  screen_point <- function(lon) {
    js_value(sprintf(
      "var m=document.querySelector('.html-widget').map;
       var p=m.project([%s,40.75]);
       var r=m.getContainer().getBoundingClientRect();
       return {x:p.x+r.left,y:p.y+r.top};",
      format(lon, scientific = FALSE)
    ))
  }
  move_to <- function(lon) {
    p <- screen_point(lon)
    b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$x - 3, y = p$y)
    b$Input$dispatchMouseEvent(type = "mouseMoved", x = p$x, y = p$y)
  }
  click_at <- function(lon) {
    p <- screen_point(lon)
    b$Input$dispatchMouseEvent(
      type = "mousePressed", x = p$x, y = p$y, button = "left", buttons = 1L, clickCount = 1L
    )
    b$Input$dispatchMouseEvent(
      type = "mouseReleased", x = p$x, y = p$y, button = "left", buttons = 0L, clickCount = 1L
    )
  }
  open_popups <- "return Array.from(document.querySelectorAll('.maplibregl-popup-content'))
    .map(function(e){return e.innerText.trim();}).join('|');"
  shows <- function(text) paste0("var s=(function(){", open_popups, "})(); return s==='", text, "';")

  b$Page$navigate(paste0("file://", html_file))
  if (!wait_for(
    "var e=document.querySelector('.html-widget');
     return !!(e && e.map && e.map.loaded() && e.map.getLayer('timed') && e.map.getLayer('plain'));"
  )) {
    skip("the map did not finish loading in the browser")
  }
  Sys.sleep(1)

  # A timed tooltip appears, then removes itself while the pointer rests.
  move_to(-73.98)
  expect_true(wait_for(shows("timed"), timeout = 5))
  expect_true(wait_for(shows(""), timeout = 4))

  # A tooltip without hide_after stays while the pointer rests on its feature.
  move_to(-73.90)
  expect_true(wait_for(shows("plain"), timeout = 5))
  Sys.sleep(2)
  expect_true(isTRUE(js_value(shows("plain"))))

  # A timed popup closes itself too.
  move_to(-73.98)
  click_at(-73.98)
  expect_true(wait_for(
    paste0("var s=(function(){", open_popups, "})(); return s.indexOf('timed')!==-1;"),
    timeout = 5
  ))
  expect_true(wait_for(shows(""), timeout = 5))
})
