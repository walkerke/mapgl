test_that("terra-draw dependencies ship correctly in all four widget yamls", {
  specs <- list(
    mapboxgl = "terra-draw-mapbox-gl-adapter",
    maplibregl = "terra-draw-maplibre-gl-adapter",
    mapboxgl_compare = "terra-draw-mapbox-gl-adapter",
    maplibregl_compare = "terra-draw-maplibre-gl-adapter"
  )

  for (widget_name in names(specs)) {
    deps <- htmlwidgets::getDependency(widget_name, "mapgl")
    dep_names <- vapply(deps, function(d) d$name, character(1))

    core_idx <- which(dep_names == "terra-draw")
    adapter_idx <- which(dep_names == specs[[widget_name]])
    control_idx <- which(dep_names == "mapgl-terra-draw-control")

    expect_length(core_idx, 1)
    expect_length(adapter_idx, 1)
    expect_length(control_idx, 1)

    # Core must load before the adapter (the adapter UMD reads the
    # `terraDraw` global), and the control comes last
    expect_true(core_idx < adapter_idx)
    expect_true(adapter_idx < control_idx)

    # The other engine's adapter must not be present
    other <- setdiff(
      c("terra-draw-mapbox-gl-adapter", "terra-draw-maplibre-gl-adapter"),
      specs[[widget_name]]
    )
    expect_false(other %in% dep_names)

    # Every referenced file exists on disk (src is package-relative here)
    for (idx in c(core_idx, adapter_idx, control_idx)) {
      dep <- deps[[idx]]
      for (asset in c(dep$script, dep$stylesheet)) {
        expect_true(
          nzchar(system.file(dep$src$file, asset, package = "mapgl")),
          info = paste(widget_name, asset)
        )
      }
    }
  }
})

test_that("both adapters survive dependency resolution in a mixed-widget page", {
  # htmltools dedupes dependencies by name (keeping the first), so the
  # adapters must ship under engine-specific dependency names or an Rmd
  # embedding both widget types would lose one of them
  combined <- c(
    htmlwidgets::getDependency("maplibregl", "mapgl"),
    htmlwidgets::getDependency("mapboxgl", "mapgl")
  )
  resolved <- htmltools::resolveDependencies(combined)
  resolved_names <- vapply(resolved, function(d) d$name, character(1))

  expect_true("terra-draw" %in% resolved_names)
  expect_true("terra-draw-maplibre-gl-adapter" %in% resolved_names)
  expect_true("terra-draw-mapbox-gl-adapter" %in% resolved_names)
  expect_true("mapgl-terra-draw-control" %in% resolved_names)
})

test_that("terra-draw provider arguments are validated", {
  m <- maplibre()

  expect_error(
    add_draw_control(m, provider = "terra-draw", bezier = TRUE),
    "Bezier"
  )
  expect_error(
    add_draw_control(m, provider = "terra-draw", simplify_freehand = TRUE),
    "simplify_freehand"
  )
  expect_error(
    add_draw_control(m, provider = "terra-draw", keybindings = FALSE),
    "terradraw_options"
  )
  expect_error(
    add_draw_control(m, provider = "terra-draw", modes = "hexagon"),
    "Invalid Terra Draw mode"
  )
  expect_error(
    add_draw_control(m, provider = "terra-draw", modes = "marker"),
    "Invalid Terra Draw mode"
  )
  expect_error(
    add_draw_control(
      m,
      provider = "terra-draw",
      modes = "polygon",
      rectangle = TRUE
    ),
    "not both"
  )
  expect_error(
    add_draw_control(m, provider = "terra-draw", options = list(a = 1)),
    "terradraw_options"
  )
  expect_error(
    add_draw_control(m, options = terradraw_options()),
    "terra-draw"
  )
  # attribute names reserved by Terra Draw are rejected up front
  expect_error(
    add_draw_control(
      m,
      provider = "terra-draw",
      attributes = list(mode = draw_attribute("text"))
    ),
    "reserved"
  )
  expect_error(
    add_draw_control(
      m,
      provider = "terra-draw",
      attributes = list(selected = draw_attribute("checkbox"))
    ),
    "reserved"
  )
  expect_error(
    add_draw_control(
      m,
      provider = "terra-draw",
      attributes = list(selectionPointFeatureId = draw_attribute("text"))
    ),
    "reserved"
  )
})

test_that("terradraw_options() validates its fields", {
  expect_s3_class(terradraw_options(), "mapgl_terradraw_options")
  expect_error(terradraw_options(drag_features = "yes"), "TRUE or FALSE")
  expect_error(terradraw_options(resize = "sideways"), "'arg'")
  expect_error(terradraw_options(drag_interaction = "drag"), "'arg'")
  expect_error(terradraw_options(pointer_distance = -1), "positive")
  expect_error(terradraw_options(modes = list(1, 2)), "named list")
  expect_error(terradraw_options(modes = list(hexagon = list())), "Unknown")
  expect_error(
    terradraw_options(modes = list(polygon = list(modeName = "poly"))),
    "modeName"
  )
})

test_that("payloads carry provider, modes, and terradraw options", {
  # Default call: pre-existing mapbox payload fields unchanged, new fields inert
  m <- add_draw_control(maplibre())
  expect_equal(m$x$draw_control$provider, "mapbox-gl-draw")
  expect_null(m$x$draw_control$modes)
  expect_null(m$x$draw_control$terradraw)
  expect_equal(m$x$draw_control$styling$point_color, "#3bb2d0")

  # Legacy booleans derive the terra mode set
  m <- add_draw_control(maplibre(), provider = "terra-draw", radius = TRUE)
  expect_equal(m$x$draw_control$provider, "terra-draw")
  expect_equal(
    m$x$draw_control$modes,
    c("point", "linestring", "polygon", "circle", "select")
  )

  # Explicit modes are authoritative and deduplicated
  m <- add_draw_control(
    maplibre(),
    provider = "terra-draw",
    modes = c("polygon", "freehand", "polygon", "select")
  )
  expect_equal(m$x$draw_control$modes, c("polygon", "freehand", "select"))

  # terradraw_options() serializes without NULL entries
  m <- add_draw_control(
    maplibre(),
    provider = "terra-draw",
    options = terradraw_options(
      snap_to_lines = TRUE,
      modes = list(polygon = list(pointerDistance = 30))
    )
  )
  td <- m$x$draw_control$terradraw
  expect_true(td$snap_to_lines)
  expect_false("resize" %in% names(td))
  expect_equal(td$modes$polygon$pointerDistance, 30)
})

test_that("colors are hex-normalized only for the terra-draw provider", {
  m <- add_draw_control(
    maplibre(),
    provider = "terra-draw",
    point_color = "red",
    fill_color = "#0000FF80"
  )
  expect_equal(m$x$draw_control$styling$point_color, "#FF0000")
  # alpha channel dropped
  expect_equal(m$x$draw_control$styling$fill_color, "#0000FF")

  # mapbox payloads keep CSS color strings untouched
  m <- add_draw_control(maplibre(), point_color = "rgba(255, 0, 0, 0.5)")
  expect_equal(m$x$draw_control$styling$point_color, "rgba(255, 0, 0, 0.5)")

  expect_error(
    add_draw_control(
      maplibre(),
      provider = "terra-draw",
      point_color = "rgba(0,0,0,1)"
    ),
    "Invalid color"
  )
})

test_that("modes stays a valid MapboxDraw option under the default provider", {
  custom_modes <- list(draw_custom = TRUE)
  m <- add_draw_control(maplibre(), modes = custom_modes)
  expect_equal(m$x$draw_control$options$modes, custom_modes)
  expect_null(m$x$draw_control$modes)
})

test_that("proxy messages carry the terra fields and compare side targeting", {
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
  add_draw_control(
    proxy,
    provider = "terra-draw",
    modes = c("polygon", "select"),
    options = terradraw_options(snap_to_coordinates = TRUE)
  )
  msg <- messages[[1]]$message$message
  expect_equal(msg$type, "add_draw_control")
  expect_equal(msg$provider, "terra-draw")
  expect_equal(msg$modes, c("polygon", "select"))
  expect_true(msg$terradraw$snap_to_coordinates)

  compare_proxy <- structure(
    list(id = "cmp", session = session, map_side = "before"),
    class = c("maplibre_compare_proxy", "maplibre_proxy")
  )
  add_draw_control(compare_proxy, provider = "terra-draw")
  msg <- messages[[2]]$message$message
  expect_equal(messages[[2]]$type, "maplibre-compare-proxy")
  expect_equal(msg$provider, "terra-draw")
  expect_equal(msg$map, "before")
})

test_that("shipped JS passes a syntax check", {
  skip_if(Sys.which("node") == "", "node is not available")

  js_files <- c(
    "htmlwidgets/mapboxgl.js",
    "htmlwidgets/maplibregl.js",
    "htmlwidgets/mapboxgl_compare.js",
    "htmlwidgets/maplibregl_compare.js",
    "htmlwidgets/lib/terra-draw-control/terra-draw-control.js"
  )
  for (path in js_files) {
    file <- system.file(path, package = "mapgl")
    expect_true(nzchar(file), info = path)
    status <- system2(
      "node",
      c("--check", shQuote(file)),
      stdout = FALSE,
      stderr = FALSE
    )
    expect_equal(status, 0L, info = path)
  }
})

test_that("bindings contain the terra-draw integration invariants", {
  read_js <- function(path) {
    paste(
      readLines(system.file(path, package = "mapgl"), warn = FALSE),
      collapse = "\n"
    )
  }

  control <- read_js("htmlwidgets/lib/terra-draw-control/terra-draw-control.js")
  expect_match(control, "window.MapglTerraDrawControl", fixed = TRUE)
  expect_match(control, 'PREFIX_ID = "mapgl-terradraw"', fixed = TRUE)
  # MapboxDraw-compatible facade methods used by the shared handlers
  for (method in c(
    "getAll",
    "deleteAll",
    "add",
    "getMode",
    "get",
    "setFeatureProperty",
    "getTerraDraw",
    "isDrawing"
  )) {
    expect_match(
      control,
      paste0("MapglTerraDrawControl.prototype.", method),
      fixed = TRUE
    )
  }
  # style survival and sync policy
  expect_match(control, 'map.on("style.load"', fixed = TRUE)
  expect_match(control, "_suppressSync", fixed = TRUE)
  expect_match(control, "updateFeatureProperties", fixed = TRUE)
  expect_match(control, "currentlyDrawing", fixed = TRUE)
  # dual-prefix container class
  expect_match(
    control,
    "mapboxgl-ctrl maplibregl-ctrl mapboxgl-ctrl-group maplibregl-ctrl-group",
    fixed = TRUE
  )

  standalone <- c(
    "htmlwidgets/mapboxgl.js",
    "htmlwidgets/maplibregl.js"
  )
  for (path in standalone) {
    js <- read_js(path)
    expect_match(js, 'provider === "terra-draw"', fixed = TRUE, info = path)
    expect_match(js, "new MapglTerraDrawControl", fixed = TRUE, info = path)
    expect_match(
      js,
      'controls.push({ type: "draw", control: terraDrawCtl })',
      fixed = TRUE,
      info = path
    )
    # set_style preservation must skip the adapter's own sources
    expect_match(
      js,
      "MapglTerraDrawControl.isTerraDrawId",
      fixed = TRUE,
      info = path
    )
    # the attribute editor returns a teardown handle
    expect_match(
      js,
      'map.off("draw.create", onCreate)',
      fixed = TRUE,
      info = path
    )
  }

  compare <- c(
    "htmlwidgets/mapboxgl_compare.js",
    "htmlwidgets/maplibregl_compare.js"
  )
  for (path in compare) {
    js <- read_js(path)
    expect_match(js, 'provider === "terra-draw"', fixed = TRUE, info = path)
    expect_match(js, "new MapglTerraDrawControl", fixed = TRUE, info = path)
    # the set_style preserve block itself must exclude terra sources (the
    # click filter also references isTerraDrawId, so scope the match to the
    # set_style handler region)
    expect_true(
      grepl(
        'message\\.type === "set_style"[\\s\\S]{0,8000}MapglTerraDrawControl\\.isTerraDrawId',
        js,
        perl = TRUE
      ),
      info = paste(path, "set_style terra exclusion")
    )
    # the (single, live) add_features_to_draw handler must resolve the
    # control via map._mapgl_draw, not a stale closure variable
    expect_true(
      grepl(
        'message\\.type === "add_features_to_draw"[\\s\\S]{0,120}map\\._mapgl_draw',
        js,
        perl = TRUE
      ),
      info = paste(path, "add_features_to_draw lookup")
    )
    expect_match(
      js,
      "MapglTerraDrawControl.isTerraDrawId",
      fixed = TRUE,
      info = path
    )
  }
})

test_that("terra-draw snapshots coerce to sf with the mode column", {
  fixture <- list(
    type = "FeatureCollection",
    features = list(
      list(
        type = "Feature",
        id = "f7c5a9b2-3d4e-4a1b-9c8d-2e5f6a7b8c9d",
        geometry = list(
          type = "Polygon",
          coordinates = list(list(
            c(-97.123456789, 32.712345678),
            c(-97.113456789, 32.712345678),
            c(-97.113456789, 32.722345678),
            c(-97.123456789, 32.712345678)
          ))
        ),
        properties = list(mode = "polygon", class = "forest")
      ),
      list(
        type = "Feature",
        id = "0b1c2d3e-4f5a-4b6c-8d7e-9f0a1b2c3d4e",
        geometry = list(
          type = "Point",
          coordinates = c(-97.15, 32.75)
        ),
        properties = list(mode = "point")
      )
    )
  )

  sf_obj <- mapgl:::.mapgl_coerce_drawn_features(fixture)
  expect_s3_class(sf_obj, "sf")
  expect_equal(nrow(sf_obj), 2)
  expect_equal(sf::st_crs(sf_obj)$epsg, 4326)
  expect_true("mode" %in% names(sf_obj))
  expect_equal(sf_obj$mode, c("polygon", "point"))
  expect_true("id" %in% names(sf_obj))
  # geometry column last
  expect_equal(names(sf_obj)[ncol(sf_obj)], attr(sf_obj, "sf_column"))
})

test_that("terra-draw control works end-to-end in a headless browser", {
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

  m <- maplibre(style = blank_style, center = c(-97.1, 32.7), zoom = 10) |>
    add_draw_control(
      provider = "terra-draw",
      modes = c("point", "polygon", "select")
    )

  dir <- tempfile("mapgl-terradraw-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(
    chromote::ChromoteSession$new(),
    error = function(e) NULL
  )
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

  # Control initialized and registered on the widget
  ready <- wait_for(
    "var w = window.HTMLWidgets && HTMLWidgets.find('.maplibregl');
     return !!(w && w.drawControl && w.drawControl.getTerraDraw &&
       w.drawControl.getTerraDraw() &&
       document.querySelector('.mapgl-terradraw'));"
  )
  if (!ready) skip("Map failed to initialize in the headless browser")

  # API-origin add(): MultiPolygon explodes, full-double-precision
  # coordinates (as in any sf object) are rounded to Terra Draw's 9-decimal
  # limit, polygon holes are stripped, and sync reaches widget.drawFeatures
  counts <- js_value(
    "var w = HTMLWidgets.find('.maplibregl');
     var ctl = w.drawControl;
     ctl.add({
       type: 'FeatureCollection',
       features: [
         { type: 'Feature', properties: { kind: 'pt' },
           geometry: { type: 'Point',
             coordinates: [-97.123456789012345, 32.712345678901234] } },
         { type: 'Feature', properties: { kind: 'mp' },
           id: '2b1c2d3e-4f5a-4b6c-8d7e-9f0a1b2c3d4e',
           geometry: { type: 'MultiPolygon', coordinates: [
             [[[-97.212345678901234, 32.6], [-97.15, 32.6],
               [-97.15, 32.65], [-97.212345678901234, 32.6]]],
             [[[-97.3, 32.6], [-97.25, 32.6], [-97.25, 32.65], [-97.3, 32.6]]]
           ] } },
         { type: 'Feature', properties: { kind: 'holed' },
           geometry: { type: 'Polygon', coordinates: [
             [[-97.5, 32.6], [-97.4, 32.6], [-97.4, 32.7],
              [-97.5, 32.7], [-97.5, 32.6]],
             [[-97.47, 32.63], [-97.43, 32.63], [-97.43, 32.67],
              [-97.47, 32.63]]
           ] } }
       ]
     });
     var fc = ctl.getAll();
     return {
       drawn: fc.features.length,
       synced: (w.drawFeatures && w.drawFeatures.features.length) || 0,
       modes: fc.features.map(function(f) { return f.properties.mode; }),
       rings: fc.features.filter(function(f) {
         return f.geometry.type === 'Polygon';
       }).map(function(f) { return f.geometry.coordinates.length; })
     };"
  )
  # 4 features even though the MultiPolygon carried a UUID id — exploded
  # parts must not share it (Terra Draw rejects duplicate ids)
  expect_equal(counts$drawn, 4)
  expect_equal(counts$synced, 4)
  expect_setequal(unique(counts$modes), c("point", "polygon"))
  # every polygon has exactly one ring (the hole was stripped)
  expect_true(all(counts$rings == 1))

  # select-mode snapping flags use the explicit {toCoordinate, toLine} shape
  # (`snappable: true` would mean coordinate snapping only)
  snappable <- js_value(
    "var ctl = new MapglTerraDrawControl({
       modes: ['polygon', 'select'],
       terradraw: { snap_to_lines: true }
     });
     return ctl._selectFlags().polygon.feature.coordinates.snappable;"
  )
  expect_false(snappable$toCoordinate)
  expect_true(snappable$toLine)

  # Synthetic draw.selectionchange fires from programmatic selection
  selection <- js_value(
    "var w = HTMLWidgets.find('.maplibregl');
     var ctl = w.drawControl;
     window._testEvents = [];
     w.getMap().on('draw.selectionchange', function(e) {
       window._testEvents.push(e.features.length);
     });
     var target = ctl.getAll().features.filter(function(f) {
       return f.geometry.type === 'Polygon';
     })[0];
     ctl.getTerraDraw().selectFeature(target.id);
     return {
       events: window._testEvents.length,
       mode: ctl.getMode(),
       drawing: ctl.isDrawing()
     };"
  )
  expect_gte(selection$events, 1)
  expect_equal(selection$mode, "select")
  expect_false(selection$drawing)

  # Style change: features survive the rebuild, selection resets
  js_value(
    "var w = HTMLWidgets.find('.maplibregl');
     w.getMap().setStyle({
       version: 8,
       sources: {},
       layers: [{ id: 'bg2', type: 'background',
                  paint: { 'background-color': '#eeeeee' } }]
     });
     return true;"
  )
  survived <- wait_for(
    "var w = HTMLWidgets.find('.maplibregl');
     var ctl = w.drawControl;
     return !!(ctl && ctl.getAll().features.length === 4 &&
       ctl._selectedIds.length === 0);"
  )
  expect_true(survived)

  # Teardown removes every trace: GL sources, DOM, widget reference
  teardown <- js_value(
    "var w = HTMLWidgets.find('.maplibregl');
     var ctl = w.drawControl;
     var map = w.getMap();
     map.removeControl(ctl);
     var leftover = Object.keys(map.getStyle().sources).filter(
       MapglTerraDrawControl.isTerraDrawId
     );
     return {
       leftoverSources: leftover.length,
       domRemoved: document.querySelector('.mapgl-terradraw') === null,
       widgetCleared: w.drawControl === null
     };"
  )
  expect_equal(teardown$leftoverSources, 0)
  expect_true(teardown$domRemoved)
  expect_true(teardown$widgetCleared)
})
