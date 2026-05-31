flowmap_test_locations <- function() {
  data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
}

flowmap_test_flows <- function() {
  data.frame(origin = "a", dest = "b", count = 10)
}

flowmap_test_map <- function(flow_blend = FALSE, ...) {
  maplibre() |>
    add_flowmap(
      id = "flows",
      locations = flowmap_test_locations(),
      flows = flowmap_test_flows(),
      flow_blend = flow_blend,
      ...
    )
}

test_that("add_flowmap serializes minimal flowmap config", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_flowmap(
      id = "flows",
      locations = locations,
      flows = flows,
      flow_color_scheme = "Teal",
      flow_dark_mode = FALSE,
      flow_opacity = 0.7,
      flow_blend = FALSE,
      visibility = "none",
      before_id = "labels",
      slot = "top"
    )

  expect_length(map$x$flowmaps, 1)
  flowmap <- map$x$flowmaps[[1]]
  expect_equal(flowmap$id, "flows")
  expect_equal(flowmap$data$locations$id, c("a", "b"))
  expect_equal(flowmap$data$locations$name, c("a", "b"))
  expect_equal(flowmap$data$flows$count, 10)
  expect_equal(flowmap$settings$colorScheme, "Teal")
  expect_false(flowmap$settings$darkMode)
  expect_equal(flowmap$settings$opacity, 0.7)
  expect_false(flowmap$settings$flowBlend)
  expect_equal(flowmap$visibility, "none")
  expect_equal(flowmap$beforeId, "labels")
  expect_equal(flowmap$slot, "top")

  mapbox_map <- mapboxgl(access_token = "test-token") |>
    add_flowmap("flows", locations, flows, flow_blend = FALSE)

  expect_length(mapbox_map$x$flowmaps, 1)
  expect_equal(mapbox_map$x$flowmaps[[1]]$id, "flows")
})

test_that("add_flowmap serializes flowmap tooltip options", {
  no_tooltip <- flowmap_test_map(tooltip = FALSE)
  expect_null(no_tooltip$x$flowmaps[[1]]$tooltip)

  default_tooltip <- flowmap_test_map(tooltip = TRUE)
  tooltip <- default_tooltip$x$flowmaps[[1]]$tooltip
  expect_true(tooltip$enabled)
  expect_equal(tooltip$style, "floating")
  expect_equal(tooltip$theme, "light")
  expect_equal(tooltip$location, list(kind = "template", value = TRUE))
  expect_equal(tooltip$flow, list(kind = "template", value = TRUE))

  dark_tooltip <- mapboxgl(
    style = mapbox_style("dark"),
    access_token = "token"
  ) |>
    add_flowmap(
      id = "flows",
      locations = flowmap_test_locations(),
      flows = flowmap_test_flows(),
      flow_blend = FALSE,
      tooltip = TRUE
    )
  expect_equal(dark_tooltip$x$flowmaps[[1]]$tooltip$theme, "dark")

  custom <- flowmap_test_map(
    tooltip = tooltip_options(
      template = list(
        location = "<strong>{name}</strong>",
        flow = "{origin.id} -> {dest.id}: {count}"
      ),
      theme = "dark",
      offset = c(12, 14)
    )
  )
  tooltip <- custom$x$flowmaps[[1]]$tooltip
  expect_equal(tooltip$style, "floating")
  expect_equal(tooltip$theme, "dark")
  expect_equal(tooltip$location, list(kind = "template", value = "<strong>{name}</strong>"))
  expect_equal(tooltip$flow, list(kind = "template", value = "{origin.id} -> {dest.id}: {count}"))
  expect_equal(tooltip$popup_props$offset, c(12, 14))

  same_template <- flowmap_test_map(tooltip = "{count}")
  expect_equal(same_template$x$flowmaps[[1]]$tooltip$location, list(kind = "template", value = "{count}"))
  expect_equal(same_template$x$flowmaps[[1]]$tooltip$flow, list(kind = "template", value = "{count}"))

  flow_only <- flowmap_test_map(
    tooltip = list(location = FALSE, flow = "{count}")
  )
  expect_false(flow_only$x$flowmaps[[1]]$tooltip$location)
  expect_equal(flow_only$x$flowmaps[[1]]$tooltip$flow, list(kind = "template", value = "{count}"))
})

test_that("add_flowmap validates flowmap tooltip options", {
  expect_error(
    flowmap_test_map(tooltip = 1),
    "must be TRUE, FALSE, NULL, a template string"
  )
  expect_error(
    flowmap_test_map(tooltip_style = "native", tooltip = TRUE),
    "should be one of"
  )
  expect_error(
    flowmap_test_map(tooltip_theme = "sepia", tooltip = TRUE),
    "should be one of"
  )
  expect_error(
    flowmap_test_map(tooltip = list(location = c("a", "b"))),
    "templates for `location`"
  )
  expect_error(
    flowmap_test_map(tooltip = TRUE, tooltip_options = c(offset = 1)),
    "`tooltip_options` must be a named list"
  )
  expect_error(
    tooltip_options(template = TRUE, theme = "auto", render_mode = "floating", list(1)),
    "Additional popup properties must be named"
  )
  expect_error(
    flowmap_test_map(tooltip = tooltip_options(template = list(location = c("a", "b")))),
    "Interaction templates for `location` must be TRUE, FALSE, or a string"
  )
})

test_that("flowmap_color_schemes returns FlowMapGL 9.3.0 presets", {
  expected <- c(
    "Blues",
    "BluGrn",
    "BluYl",
    "BrwnYl",
    "BuGn",
    "BuPu",
    "Burg",
    "BurgYl",
    "Cool",
    "DarkMint",
    "Emrld",
    "GnBu",
    "Grayish",
    "Greens",
    "Greys",
    "Inferno",
    "Magenta",
    "Magma",
    "Mint",
    "Oranges",
    "OrRd",
    "OrYel",
    "Peach",
    "Plasma",
    "PinkYl",
    "PuBu",
    "PuBuGn",
    "PuRd",
    "Purp",
    "Purples",
    "PurpOr",
    "RdPu",
    "RedOr",
    "Reds",
    "Sunset",
    "SunsetDark",
    "Teal",
    "TealGrn",
    "Viridis",
    "Warm",
    "YlGn",
    "YlGnBu",
    "YlOrBr",
    "YlOrRd"
  )

  expect_equal(flowmap_color_schemes(), expected)
  expect_true(all(
    c("Teal", "Blues", "Viridis", "Grayish", "YlOrRd") %in%
      flowmap_color_schemes()
  ))
})

test_that("add_flowmap validates valid flow_color_scheme shapes", {
  preset <- flowmap_test_map(flow_color_scheme = "Viridis")
  expect_equal(preset$x$flowmaps[[1]]$settings$colorScheme, "Viridis")

  colors <- c("red", "#12345678", "rgb(1, 2, 3)", "rgba(4, 5, 6, 0.7)")
  custom <- flowmap_test_map(flow_color_scheme = colors)
  expect_equal(custom$x$flowmaps[[1]]$settings$colorScheme, colors)

  scale <- interpolate_palette(
    data = data.frame(value = c(1, 2)),
    column = "value",
    n = 2,
    colors = c("#111111", "#eeeeee")
  )
  scale_map <- flowmap_test_map(flow_color_scheme = scale)
  expect_equal(scale_map$x$flowmaps[[1]]$settings$colorScheme, scale$colors)
})

test_that("add_flowmap rejects invalid flow_color_scheme values", {
  expect_error(
    flowmap_test_map(flow_color_scheme = "Unknown"),
    "FlowMapGL preset"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = "teal"),
    "FlowMapGL preset"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = "red"),
    "Scalar color strings"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = character()),
    "at least two"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = c("red")),
    "Scalar color strings"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = NA_character_),
    "missing or empty"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = c("red", NA_character_)),
    "missing or empty"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = 1:2),
    "must be a FlowMapGL preset name"
  )
  expect_error(
    flowmap_test_map(flow_color_scheme = c("red", "not-a-color")),
    "invalid CSS color"
  )
  expect_error(
    flowmap_test_map(
      flow_color_scheme = structure(
        list(colors = c("red")),
        class = "mapgl_continuous_scale"
      )
    ),
    "at least two"
  )
  expect_error(
    flowmap_test_map(
      flow_color_scheme = structure(
        list(expression = list()),
        class = "mapgl_continuous_scale"
      )
    ),
    "must contain a `colors` vector"
  )
})

test_that("add_flowmap strictly validates flow_dark_mode", {
  expect_true(
    flowmap_test_map(flow_dark_mode = TRUE)$x$flowmaps[[1]]$settings$darkMode
  )
  expect_false(
    flowmap_test_map(flow_dark_mode = FALSE)$x$flowmaps[[1]]$settings$darkMode
  )

  expect_error(flowmap_test_map(flow_dark_mode = NA), "TRUE` or `FALSE")
  expect_error(flowmap_test_map(flow_dark_mode = "TRUE"), "TRUE` or `FALSE")
  expect_error(flowmap_test_map(flow_dark_mode = 1), "TRUE` or `FALSE")
  expect_error(
    flowmap_test_map(flow_dark_mode = c(TRUE, FALSE)),
    "TRUE` or `FALSE"
  )
})

test_that("add_flowmap validates placement strings", {
  expect_null(flowmap_test_map(before_id = NULL)$x$flowmaps[[1]]$beforeId)
  expect_null(flowmap_test_map(slot = NULL)$x$flowmaps[[1]]$slot)
  expect_equal(
    flowmap_test_map(before_id = "labels")$x$flowmaps[[1]]$beforeId,
    "labels"
  )
  expect_equal(flowmap_test_map(slot = "top")$x$flowmaps[[1]]$slot, "top")

  expect_error(flowmap_test_map(before_id = ""), "`before_id`")
  expect_error(flowmap_test_map(before_id = c("a", "b")), "`before_id`")
  expect_error(flowmap_test_map(before_id = NA_character_), "`before_id`")
  expect_error(flowmap_test_map(before_id = 1), "`before_id`")
  expect_error(flowmap_test_map(slot = ""), "`slot`")
  expect_error(flowmap_test_map(slot = c("top", "bottom")), "`slot`")
  expect_error(flowmap_test_map(slot = NA_character_), "`slot`")
  expect_error(flowmap_test_map(slot = 1), "`slot`")
})

test_that("add_flowmap validates flow_opacity boundaries", {
  expect_equal(
    flowmap_test_map(flow_opacity = 0)$x$flowmaps[[1]]$settings$opacity,
    0
  )
  expect_equal(
    flowmap_test_map(flow_opacity = 1)$x$flowmaps[[1]]$settings$opacity,
    1
  )

  expect_error(flowmap_test_map(flow_opacity = -0.1), "between 0 and 1")
  expect_error(flowmap_test_map(flow_opacity = 1.1), "between 0 and 1")
  expect_error(flowmap_test_map(flow_opacity = NA_real_), "between 0 and 1")
  expect_error(flowmap_test_map(flow_opacity = NaN), "between 0 and 1")
  expect_error(flowmap_test_map(flow_opacity = "1"), "between 0 and 1")
})

test_that("set_flowmap_settings updates one setting on a regular map", {
  map <- flowmap_test_map() |>
    set_flowmap_settings("flows", "opacity", 0.25)

  expect_equal(map$x$flowmaps[[1]]$settings$opacity, 0.25)
})

test_that("set_flowmap_settings normalizes snake_case aliases", {
  map <- flowmap_test_map() |>
    set_flowmap_settings("flows", "color_scheme", "Viridis") |>
    set_flowmap_settings("flows", "temporal_scale_domain", "all") |>
    set_flowmap_settings("flows", "max_top_flows_display_num", 100)

  settings <- map$x$flowmaps[[1]]$settings
  expect_equal(settings$colorScheme, "Viridis")
  expect_equal(settings$temporalScaleDomain, "all")
  expect_equal(settings$maxTopFlowsDisplayNum, 100)
})

test_that("set_flowmap_settings sends unchanged proxy message shape", {
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

  result <- set_flowmap_settings(proxy, "flows", "color_scheme", "Viridis")

  expect_identical(result, proxy)
  expect_length(messages, 1)
  expect_equal(messages[[1]]$type, "maplibre-proxy")
  expect_equal(messages[[1]]$message$id, "map")
  expect_equal(messages[[1]]$message$message$type, "set_flowmap_settings")
  expect_equal(messages[[1]]$message$message$id, "flows")
  expect_equal(
    messages[[1]]$message$message$settings,
    list(colorScheme = "Viridis")
  )
})

test_that("set_flowmap_settings preserves NULL setting values", {
  map <- flowmap_test_map(flow_clustering_level = 5) |>
    set_flowmap_settings("flows", "clusteringLevel", NULL)

  settings <- map$x$flowmaps[[1]]$settings
  expect_true("clusteringLevel" %in% names(settings))
  expect_null(settings$clusteringLevel)
})

test_that("set_flowmap_settings rejects unknown and filter settings", {
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "unknownSetting", 1),
    "Supported names"
  )
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "selectedTimeRange", 1),
    "set_flowmap_filter"
  )
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "selected_time_range", 1),
    "set_flowmap_filter"
  )
})

test_that("set_flowmap_settings validates setting values", {
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "opacity", -0.1),
    "between 0 and 1"
  )
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "fadeAmount", 101),
    "between 0 and 100"
  )
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "darkMode", "TRUE"),
    "TRUE or FALSE"
  )
  expect_error(
    set_flowmap_settings(
      flowmap_test_map(),
      "flows",
      "temporalScaleDomain",
      "hour"
    ),
    "selected"
  )
  expect_error(
    set_flowmap_settings(flowmap_test_map(), "flows", "colorScheme", "red"),
    "FlowMapGL preset"
  )
  expect_error(
    set_flowmap_settings(
      flowmap_test_map(),
      "flows",
      "flowLinesRenderingMode",
      "arc"
    ),
    "animated-straight"
  )
  expect_error(
    set_flowmap_settings(
      flowmap_test_map(),
      "flows",
      "flowEndpointsInViewportMode",
      "none"
    ),
    "both"
  )
  expect_error(
    set_flowmap_settings(
      flowmap_test_map(),
      "flows",
      "maxTopFlowsDisplayNum",
      0
    ),
    "positive number"
  )
})

test_that("flowmap can be included in explicit layers control config", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_flowmap("flows", locations, flows) |>
    add_layers_control(
      layers = list(
        "Migration flowmap" = "flows"
      )
    )

  expect_equal(
    map$x$layers_control$layers_config[[1]]$label,
    "Migration flowmap"
  )
  expect_equal(map$x$layers_control$layers_config[[1]]$ids, "flows")
})

test_that("flowmap added before a regular layer gets inferred beforeId", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_flowmap("flows", locations, flows, flow_blend = FALSE) |>
    add_layer(
      id = "points",
      type = "circle",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      )
    )

  expect_equal(map$x$flowmaps[[1]]$beforeId, "points")
})

test_that("flowmap added after the final regular layer keeps beforeId NULL", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_layer(
      id = "points",
      type = "circle",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      )
    ) |>
    add_flowmap("flows", locations, flows)

  expect_null(map$x$flowmaps[[1]]$beforeId)
})

test_that("explicit flowmap before_id is not overwritten by later layers", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_flowmap(
      "flows",
      locations,
      flows,
      before_id = "labels",
      flow_blend = FALSE
    ) |>
    add_layer(
      id = "points",
      type = "circle",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      )
    )

  expect_equal(map$x$flowmaps[[1]]$beforeId, "labels")
})

test_that("multiple pending flowmaps resolve to the same later regular layer", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_flowmap("flows-a", locations, flows, flow_blend = FALSE) |>
    add_flowmap("flows-b", locations, flows, flow_blend = FALSE) |>
    add_layer(
      id = "points",
      type = "circle",
      source = list(
        type = "geojson",
        data = list(type = "FeatureCollection", features = list())
      )
    )

  expect_equal(
    vapply(map$x$flowmaps, `[[`, character(1), "beforeId"),
    c("points", "points")
  )
})

test_that("add_flowmap validates required columns and IDs", {
  locations <- data.frame(id = c("a", "b"), lat = c(40, 41), lon = c(-74, -75))

  expect_error(
    maplibre() |>
      add_flowmap(
        "flows",
        locations[-1],
        data.frame(origin = "a", dest = "b", count = 1)
      ),
    "missing required column"
  )

  expect_error(
    maplibre() |>
      add_flowmap(
        "flows",
        locations,
        data.frame(origin = "a", dest = "z", count = 1)
      ),
    "unknown ID"
  )

  expect_error(
    maplibre() |>
      add_flowmap(
        "flows",
        locations,
        data.frame(origin = "a", dest = "b", count = NA_real_)
      ),
    "must not contain missing values"
  )
})

test_that("add_flowmap converts sf points to EPSG 4326 lon lat columns", {
  locations <- sf::st_as_sf(
    data.frame(id = c("a", "b"), x = c(0, 1000), y = c(0, 1000)),
    coords = c("x", "y"),
    crs = 3857
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |> add_flowmap("flows", locations, flows)
  serialized_locations <- map$x$flowmaps[[1]]$data$locations

  expect_equal(names(serialized_locations)[1:4], c("id", "lat", "lon", "name"))
  expect_equal(serialized_locations$id, c("a", "b"))
  expect_equal(serialized_locations$lon[1], 0)
  expect_equal(serialized_locations$lat[1], 0)
  expect_gt(serialized_locations$lon[2], 0)
  expect_gt(serialized_locations$lat[2], 0)
})

test_that("Mapbox and MapLibre YAML files include the same flowmap dependencies", {
  mapbox <- readLines(system.file(
    "htmlwidgets/mapboxgl.yaml",
    package = "mapgl"
  ))
  maplibre <- readLines(system.file(
    "htmlwidgets/maplibregl.yaml",
    package = "mapgl"
  ))

  flowmap_entries <- c(
    "  - name: flowmap-gl",
    "    version: \"9.3.0\"",
    "    src: \"htmlwidgets/lib/flowmap-gl\"",
    "      - \"flowmap-gl-bundle.min.js\"",
    "  - name: flowmap-plugin",
    "    version: \"1.0.0\"",
    "    src: \"htmlwidgets\"",
    "      - \"flowmap.js\""
  )

  for (entry in flowmap_entries) {
    expect_true(any(mapbox == entry), info = entry)
    expect_true(any(maplibre == entry), info = entry)
  }

  yaml_dependency_names <- function(lines) {
    name_lines <- grep("^  - name:", lines, value = TRUE)
    sub("^  - name: ", "", name_lines)
  }

  expect_equal(
    yaml_dependency_names(mapbox)[
      match("flowmap-gl", yaml_dependency_names(mapbox)):match(
        "flowmap-plugin",
        yaml_dependency_names(mapbox)
      )
    ],
    c("flowmap-gl", "flowmap-plugin")
  )
  expect_equal(
    yaml_dependency_names(maplibre)[
      match("flowmap-gl", yaml_dependency_names(maplibre)):match(
        "flowmap-plugin",
        yaml_dependency_names(maplibre)
      )
    ],
    c("flowmap-gl", "flowmap-plugin")
  )
})

test_that("compare widgets include and initialize flowmap support", {
  yaml_dependency_names <- function(lines) {
    name_lines <- grep("^  - name:", lines, value = TRUE)
    sub("^  - name: ", "", name_lines)
  }

  compare_yaml_paths <- c(
    "htmlwidgets/mapboxgl_compare.yaml",
    "htmlwidgets/maplibregl_compare.yaml"
  )

  for (path in compare_yaml_paths) {
    lines <- readLines(system.file(path, package = "mapgl"))
    expect_true("flowmap-gl" %in% yaml_dependency_names(lines), info = path)
    expect_true("flowmap-plugin" %in% yaml_dependency_names(lines), info = path)
  }

  compare_js_paths <- c(
    "htmlwidgets/mapboxgl_compare.js",
    "htmlwidgets/maplibregl_compare.js"
  )

  for (path in compare_js_paths) {
    js <- paste(
      readLines(system.file(path, package = "mapgl")),
      collapse = "\n"
    )
    expect_match(js, "MapGLFlowmapPlugin\\.init", fixed = FALSE)
    expect_match(js, "MapGLFlowmapPlugin\\.getVisibility", fixed = FALSE)
    expect_match(js, "MapGLFlowmapPlugin\\.setVisibility", fixed = FALSE)
  }
})

test_that("flowmap plugin prepends Flowmap.gl to native attribution", {
  js <- paste(
    readLines(system.file("htmlwidgets/flowmap.js", package = "mapgl")),
    collapse = "\n"
  )

  expect_match(
    js,
    ".mapboxgl-ctrl-attrib-inner, .maplibregl-ctrl-attrib-inner",
    fixed = TRUE
  )
  expect_match(js, "https://flowmap.gl/", fixed = TRUE)
  expect_match(js, 'data-mapgl-flowmap-attribution", "true"', fixed = TRUE)
  expect_match(
    js,
    "data-mapgl-flowmap-attribution-separator",
    fixed = TRUE
  )
  expect_match(
    js,
    "insertBefore(link, attributionInner.firstChild)",
    fixed = TRUE
  )
  expect_match(js, 'map.on("styledata", refresh)', fixed = TRUE)
  expect_match(js, 'map.on("sourcedata", refresh)', fixed = TRUE)
  expect_match(js, 'map.on("idle", refresh)', fixed = TRUE)
})

test_that("flowmap plugin includes tooltip renderers", {
  js <- paste(
    readLines(system.file("htmlwidgets/flowmap.js", package = "mapgl")),
    collapse = "\n"
  )

  expect_match(js, "DEFAULT_LOCATION_TOOLTIP", fixed = TRUE)
  expect_match(js, "showInteractiveUI", fixed = TRUE)
  expect_match(js, "getTooltipStore(map)", fixed = TRUE)
  expect_match(js, "hideOtherFlowmapTooltips", fixed = TRUE)
  expect_match(js, "layerProps.onHover", fixed = TRUE)
  expect_match(js, "info.layer.onHover(info, event)", fixed = TRUE)
  expect_match(js, "hideAllFlowmapTooltips(map)", fixed = TRUE)
  expect_match(js, "cloneFlowmapLayer", fixed = TRUE)
  expect_match(js, "cloneProps.onHover = layer._mapglOnHover", fixed = TRUE)
  expect_match(js, "cloneFlowmapLayer(layer, {", fixed = TRUE)
})

test_that("flowmap vendoring manifest matches committed bundle", {
  manifest_path <- system.file(
    "htmlwidgets/lib/flowmap-gl/flowmap-gl-vendor-manifest.json",
    package = "mapgl"
  )
  bundle_path <- system.file(
    "htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js",
    package = "mapgl"
  )

  manifest <- jsonlite::read_json(manifest_path)

  expect_equal(
    unname(tools::sha256sum(bundle_path)),
    manifest$bundle$sha256
  )
  expect_equal(
    manifest$bundle$path,
    "inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js"
  )
  expect_equal(manifest$copyrights$path, "LICENSE.note")
})

test_that("flowmap vendoring manifest records temporal-scale patch", {
  manifest_path <- system.file(
    "htmlwidgets/lib/flowmap-gl/flowmap-gl-vendor-manifest.json",
    package = "mapgl"
  )
  manifest <- jsonlite::read_json(manifest_path)
  patch_paths <- vapply(manifest$patches, `[[`, character(1), "path")
  patch_path <- "data-raw/flowmap-vendor/patches/flowmap-temporal-scale-domain.patch"

  expect_equal(intersect(patch_paths, patch_path), patch_path)

  source_patch_path <- patch_path
  if (!file.exists(source_patch_path)) {
    source_patch_path <- file.path("..", "..", patch_path)
  }
  if (!file.exists(source_patch_path)) {
    skip("flowmap vendor patch source is not available in installed package")
  }

  patch <- manifest$patches[[match(patch_path, patch_paths)]]
  expect_equal(unname(tools::sha256sum(source_patch_path)), patch$sha256)
  expect_equal(file.info(source_patch_path)$size, patch$bytes)
  expect_match(patch$purpose, "temporalScaleDomain", fixed = TRUE)
})

test_that("flowmap loaded bundle includes temporalScaleDomain", {
  bundle_path <- system.file(
    "htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js",
    package = "mapgl"
  )
  bundle <- paste(readLines(bundle_path, warn = FALSE), collapse = "\n")

  expect_match(bundle, "temporalScaleDomain", fixed = TRUE)
})

test_that("is_dark_style utility classifies basemaps correctly", {
  # Dark styles
  expect_true(is_dark_style("mapbox://styles/mapbox/dark-v11"))
  expect_true(is_dark_style("mapbox://styles/mapbox/navigation-night-v1"))
  expect_true(is_dark_style("mapbox://styles/mapbox/satellite-v9"))
  expect_true(is_dark_style(
    "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json"
  ))
  expect_true(is_dark_style(
    "https://api.maptiler.com/maps/basic-dark/style.json"
  ))
  expect_true(is_dark_style(
    "https://basemapstyles-api.arcgis.com/arcgis/rest/services/styles/v2/styles/arcgis/imagery"
  ))

  # Light styles
  expect_false(is_dark_style("mapbox://styles/mapbox/light-v11"))
  expect_false(is_dark_style("mapbox://styles/mapbox/streets-v12"))
  expect_false(is_dark_style(
    "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json"
  ))
  expect_false(is_dark_style(
    "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json"
  ))
  expect_false(is_dark_style(
    "https://api.maptiler.com/maps/streets-v2/style.json"
  ))
  expect_false(is_dark_style(
    "https://basemapstyles-api.arcgis.com/arcgis/rest/services/styles/v2/styles/arcgis/streets"
  ))

  # Custom basemap_style list object
  dark_custom <- list(
    layers = list(list(
      type = "background",
      paint = list(`background-color` = "black")
    ))
  )
  light_custom <- list(
    layers = list(list(
      type = "background",
      paint = list(`background-color` = "white")
    ))
  )
  expect_true(is_dark_style(dark_custom))
  expect_false(is_dark_style(light_custom))

  # Fallbacks
  expect_true(is_dark_style(NULL))
  expect_true(is_dark_style(list()))
  expect_true(is_dark_style("random-style"))
})

test_that("add_flowmap validates flow_blend and handles auto-resolution", {
  # Standalone map with flow_blend = "auto" (default) on default light basemap (voyager)
  map_default <- maplibre() |>
    add_flowmap(
      id = "flows",
      locations = flowmap_test_locations(),
      flows = flowmap_test_flows()
    )
  expect_false(map_default$x$flowmaps[[1]]$settings$darkMode) # Inferred to FALSE
  expect_equal(map_default$x$flowmaps[[1]]$settings$flowBlend, "multiply") # Inferred to "multiply"

  # Standalone map with flow_blend = "auto" on dark style
  map_dark <- mapboxgl(style = mapbox_style("dark"), access_token = "token") |>
    add_flowmap(
      id = "flows",
      locations = flowmap_test_locations(),
      flows = flowmap_test_flows()
    )
  expect_true(map_dark$x$flowmaps[[1]]$settings$darkMode) # Inferred to TRUE
  expect_equal(map_dark$x$flowmaps[[1]]$settings$flowBlend, "screen") # Inferred to "screen"

  # Interleaved map with flow_blend = "auto" (default) quietly resolves to FALSE (no warning)
  expect_no_warning(
    map_interleaved <- maplibre() |>
      add_flowmap(
        id = "flows",
        locations = flowmap_test_locations(),
        flows = flowmap_test_flows(),
        before_id = "labels"
      )
  )
  expect_false(map_interleaved$x$flowmaps[[1]]$settings$flowBlend)

  # Check validation
  expect_error(flowmap_test_map(flow_blend = NA), "must be `TRUE` or `FALSE`")
  expect_error(
    flowmap_test_map(flow_blend = "invalid-mode"),
    "must be one of the valid CSS mix-blend-mode"
  )
  expect_error(flowmap_test_map(flow_blend = 123), "must be a logical")

  # Valid string blend mode
  map_string <- maplibre() |>
    add_flowmap(
      id = "flows",
      locations = flowmap_test_locations(),
      flows = flowmap_test_flows(),
      flow_blend = "screen"
    )
  expect_equal(map_string$x$flowmaps[[1]]$settings$flowBlend, "screen")

  # Check warning when interleaved (before_id is set) and flow_blend is explicitly non-FALSE
  expect_warning(
    maplibre() |>
      add_flowmap(
        id = "flows",
        locations = flowmap_test_locations(),
        flows = flowmap_test_flows(),
        flow_blend = TRUE,
        before_id = "labels"
      ),
    "ignored when `before_id` or `slot` is specified"
  )

  expect_warning(
    maplibre() |>
      add_flowmap(
        id = "flows",
        locations = flowmap_test_locations(),
        flows = flowmap_test_flows(),
        flow_blend = "screen",
        before_id = "labels"
      ),
    "ignored when `before_id` or `slot` is specified"
  )
})
