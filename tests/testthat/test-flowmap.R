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

flowmap_test_map <- function(...) {
  maplibre() |>
    add_flowmap(
      id = "flows",
      locations = flowmap_test_locations(),
      flows = flowmap_test_flows(),
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
  expect_equal(flowmap$visibility, "none")
  expect_equal(flowmap$beforeId, "labels")
  expect_equal(flowmap$slot, "top")

  mapbox_map <- mapboxgl(access_token = "test-token") |>
    add_flowmap("flows", locations, flows)

  expect_length(mapbox_map$x$flowmaps, 1)
  expect_equal(mapbox_map$x$flowmaps[[1]]$id, "flows")
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
    add_flowmap("flows", locations, flows) |>
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
    add_flowmap("flows", locations, flows, before_id = "labels") |>
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
    add_flowmap("flows-a", locations, flows) |>
    add_flowmap("flows-b", locations, flows) |>
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
    tail(yaml_dependency_names(mapbox), 2),
    c("flowmap-gl", "flowmap-plugin")
  )
  expect_equal(
    tail(yaml_dependency_names(maplibre), 2),
    c("flowmap-gl", "flowmap-plugin")
  )
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
  expect_equal(manifest$copyrights$path, "inst/COPYRIGHTS")
  expect_equal(file.exists(system.file("COPYRIGHTS", package = "mapgl")), TRUE)
})
