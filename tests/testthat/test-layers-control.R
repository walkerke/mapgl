test_that("layers-control dependency ships the shared JS and CSS in all widgets", {
  expect_dependency <- function(widget) {
    deps <- Filter(
      function(d) d$name == "layers-control",
      widget$dependencies
    )
    # compare() merges each side's dependencies with its own, so the
    # dependency can appear more than once; every copy must be the shared one
    expect_gte(length(deps), 1)
    for (dep in deps) {
      expect_equal(dep$version, "2.0.0")
      expect_equal(dep$script, "layers-control.js")
      expect_equal(dep$stylesheet, "layers-control.css")
      expect_true(file.exists(file.path(dep$src$file, dep$script)))
      expect_true(file.exists(file.path(dep$src$file, dep$stylesheet)))
    }
  }

  expect_dependency(maplibre())

  withr::with_envvar(c(MAPBOX_PUBLIC_TOKEN = "pk.test"), {
    expect_dependency(mapboxgl())
  })

  cmp <- compare(maplibre(), maplibre())
  expect_dependency(cmp)

  withr::with_envvar(c(MAPBOX_PUBLIC_TOKEN = "pk.test"), {
    expect_dependency(compare(mapboxgl(), mapboxgl()))
  })
})

test_that("compare bindings do not resurrect a cleared layers control on set_style", {
  # applyMapModifications re-runs after a style change; the initial-render
  # guard must track processed control ids (not current mounted state) so a
  # control removed via clear_controls("layers") stays removed
  for (path in c(
    "htmlwidgets/mapboxgl_compare.js",
    "htmlwidgets/maplibregl_compare.js"
  )) {
    js <- paste(
      readLines(system.file(path, package = "mapgl")),
      collapse = "\n"
    )
    expect_match(js, "_mapglProcessedLayersControls", fixed = TRUE, info = path)
    # the guard must not key on the live control registry
    expect_no_match(js, "layersControlExists")
  }
})

test_that("mode is validated and carried in payloads", {
  base_map <- maplibre() |>
    add_fill_layer(id = "l1", source = "src")

  expect_equal(add_layers_control(base_map)$x$layers_control$mode, "multiple")
  expect_equal(
    add_layers_control(base_map, mode = "single")$x$layers_control$mode,
    "single"
  )
  expect_error(add_layers_control(base_map, mode = "radio"), "'arg'")

  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- message
    }
  )
  proxy <- structure(
    list(id = "map", session = session),
    class = "maplibre_proxy"
  )
  add_layers_control(proxy, mode = "single")
  expect_equal(messages[[1]]$message$mode, "single")

  # single-mode behavior lives in the shared control module
  js <- paste(
    readLines(system.file(
      "htmlwidgets/lib/layers-control/layers-control.js",
      package = "mapgl"
    )),
    collapse = "\n"
  )
  expect_match(js, '_config.mode === "single"', fixed = TRUE)
  expect_match(js, "_setEntryState", fixed = TRUE)
})

test_that("initial payload shape is preserved across the layers input forms", {
  base_map <- maplibre() |>
    add_fill_layer(id = "l1", source = "src") |>
    add_line_layer(id = "l2", source = "src")

  # NULL layers: resolved to user layer ids, no layers_config
  m <- add_layers_control(base_map)
  lc <- m$x$layers_control
  expect_equal(lc$layers, c("l1", "l2"))
  expect_null(lc$layers_config)
  expect_true(grepl("^layers-control-", lc$control_id))
  expect_equal(lc$position, "top-left")
  expect_true(lc$collapsible)
  expect_true(lc$use_icon)
  expect_null(lc$custom_colors)
  expect_null(lc$margin_top)

  # Named list with a group
  m <- add_layers_control(
    base_map,
    layers = list("Both" = c("l1", "l2"), "Lines" = "l2")
  )
  cfg <- m$x$layers_control$layers_config
  expect_length(cfg, 2)
  expect_equal(cfg[[1]]$label, "Both")
  expect_equal(cfg[[1]]$ids, c("l1", "l2"))
  expect_equal(cfg[[1]]$type, "group")
  expect_equal(cfg[[2]]$label, "Lines")
  expect_equal(cfg[[2]]$ids, "l2")
  expect_equal(cfg[[2]]$type, "single")

  # Named vector: labels, all singles
  m <- add_layers_control(base_map, layers = c("Fill" = "l1", "Line" = "l2"))
  cfg <- m$x$layers_control$layers_config
  expect_length(cfg, 2)
  expect_equal(cfg[[1]]$label, "Fill")
  expect_equal(cfg[[1]]$ids, "l1")
  expect_equal(cfg[[2]]$type, "single")
})

test_that("styling and margin arguments map to the payload unchanged", {
  m <- maplibre() |>
    add_fill_layer(id = "l1", source = "src") |>
    add_layers_control(
      background_color = "#ffffff",
      active_color = "#4a90e2",
      hover_color = "#eeeeee",
      active_text_color = "#ffffff",
      inactive_text_color = "#404040",
      margin_top = 40
    )
  lc <- m$x$layers_control
  expect_equal(
    lc$custom_colors,
    list(
      background = "#ffffff",
      active = "#4a90e2",
      hover = "#eeeeee",
      text = "#404040",
      activeText = "#ffffff"
    )
  )
  expect_equal(lc$margin_top, 40)
  expect_null(lc$margin_right)
})

test_that("proxy calls send the unchanged message shape with unique control ids", {
  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- list(type = type, message = message)
    }
  )
  proxy <- structure(
    list(id = "map", session = session),
    class = "maplibre_proxy"
  )

  add_layers_control(proxy, position = "top-right", layers = c("a", "b"))
  add_layers_control(proxy, position = "bottom-left")

  expect_length(messages, 2)
  expect_equal(messages[[1]]$type, "maplibre-proxy")
  msg <- messages[[1]]$message$message
  expect_equal(msg$type, "add_layers_control")
  expect_equal(msg$position, "top-right")
  expect_equal(msg$layers, c("a", "b"))
  expect_true(grepl("^layers-control-", msg$control_id))

  msg2 <- messages[[2]]$message$message
  expect_equal(msg2$position, "bottom-left")
  expect_false(identical(msg$control_id, msg2$control_id))
})

test_that("compare proxies include map_side targeting", {
  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- list(type = type, message = message)
    }
  )
  proxy <- structure(
    list(id = "cmp", session = session, map_side = "after"),
    class = c("maplibre_compare_proxy", "maplibre_proxy")
  )

  add_layers_control(proxy, position = "top-right")

  expect_length(messages, 1)
  expect_equal(messages[[1]]$type, "maplibre-compare-proxy")
  msg <- messages[[1]]$message$message
  expect_equal(msg$type, "add_layers_control")
  expect_equal(msg$map, "after")
})

test_that("clear_controls passes the layers type through", {
  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- list(type = type, message = message)
    }
  )
  proxy <- structure(
    list(id = "map", session = session),
    class = "maplibre_proxy"
  )

  clear_controls(proxy, "layers")

  expect_length(messages, 1)
  msg <- messages[[1]]$message$message
  expect_equal(msg$type, "clear_controls")
  expect_equal(msg$controls, "layers")
})
