#' FlowMapGL color scheme names
#'
#' Returns the FlowMapGL 9.3.0 preset color scheme names supported by
#' [add_flowmap()]. These names are case-sensitive.
#'
#' @details
#' The bundled FlowMapGL presets are:
#' `r flowmap_color_schemes_markdown()`.
#'
#' @return A character vector of FlowMapGL preset names.
#' @export
#'
#' @examples
#' flowmap_color_schemes()
flowmap_color_schemes <- function() {
  flowmap_color_scheme_registry()
}

#' Configure FlowmapGL tooltips
#'
#' Creates a tooltip configuration for [add_flowmap()].
#'
#' @param location Location tooltip template, `TRUE` for the default location
#'   tooltip, or `FALSE` to disable location tooltips.
#' @param flow Flow tooltip template, `TRUE` for the default flow tooltip, or
#'   `FALSE` to disable flow tooltips.
#' @param style Tooltip style. `"mapgl"` uses the same popup style as other
#'   mapgl layers; `"flowmap"` uses the upstream Flowmap.gl example style.
#' @param theme Tooltip theme. `"auto"` follows `flow_dark_mode`; `"light"`
#'   and `"dark"` force a theme.
#' @param options A named list of renderer-specific options. For mapgl-style
#'   tooltips, common popup options such as `maxWidth`, `offset`, `anchor`, and
#'   `className` may be used.
#'
#' @return A flowmap tooltip configuration object.
#' @export
#'
#' @examples
#' flowmap_tooltip(
#'   location = "<strong>{name}</strong><br>Incoming: {totals.incomingCount}",
#'   flow = "<strong>{origin.id} to {dest.id}</strong><br>{count}",
#'   style = "flowmap"
#' )
flowmap_tooltip <- function(
  location = TRUE,
  flow = TRUE,
  style = c("mapgl", "flowmap"),
  theme = c("auto", "light", "dark"),
  options = list()
) {
  style <- match.arg(style)
  theme <- match.arg(theme)

  if (
    !is.list(options) ||
      (!is.null(names(options)) && anyNA(names(options))) ||
      (length(options) > 0 &&
        (is.null(names(options)) || any(!nzchar(names(options)))))
  ) {
    rlang::abort("`options` must be a named list.")
  }

  location <- flowmap_validate_tooltip_template(location, "location")
  flow <- flowmap_validate_tooltip_template(flow, "flow")

  structure(
    list(
      location = location,
      flow = flow,
      style = style,
      theme = theme,
      options = options
    ),
    class = "mapgl_flowmap_tooltip"
  )
}

#' Adds a FlowmapGL layer for visualizing origin-destination flows between
#' point locations.
#'
#' @param map A map object created by [mapboxgl()] or [maplibre()].
#' @param id A unique layer ID.
#' @param locations A data frame or `sf` point object with location data.
#'   Data frames must include `id`, `lat`, and `lon` columns. `sf` point
#'   objects must include `id`; coordinates are transformed to EPSG:4326 and
#'   serialized as `lon`/`lat`.
#' @param flows A data frame with `origin`, `dest`, and `count` columns.
#' @param flow_color_scheme FlowMapGL preset color scheme name, a character
#'   vector of at least two CSS colors, or a `mapgl_continuous_scale` object
#'   created by [interpolate_palette()]. Preset names are case-sensitive; use
#'   [flowmap_color_schemes()] to list them.
#' @param flow_opacity Layer opacity between 0 and 1.
#' @param flow_dark_mode Logical (`TRUE` or `FALSE`), or `"auto"`; whether to use FlowMapGL dark-mode
#'   colors. If `"auto"`, the mode is dynamically detected based on the map style.
#' @param flow_blend Logical (`TRUE` or `FALSE`), `"auto"`, or a character string specifying a CSS
#'   mix-blend-mode.
#'
#'   Valid modes are: `"normal"`, `"multiply"`, `"screen"`, `"overlay"`, `"darken"`,
#'   `"lighten"`, `"color-dodge"`, `"color-burn"`, `"hard-light"`, `"soft-light"`,
#'   `"difference"`, `"exclusion"`, `"hue"`, `"saturation"`, `"color"`, and `"luminosity"`.
#'
#'   **Recommendations**:
#'   * On **dark basemaps**: `"screen"` looks best, creating a glowing additive effect where flows overlap.
#'   * On **light basemaps**: `"multiply"` or `"darken"` looks best, increasing contrast against the light background.
#'
#'   If `"auto"`, automatically chooses `"screen"` for dark styles and `"multiply"` for light styles.
#'   If `before_id` or `slot` is specified (interleaved mode), `"auto"` quietly disables blending (`FALSE`)
#'   without throwing a warning. If `TRUE`, defaults to `"screen"` when `flow_dark_mode` is `TRUE`,
#'   and `"multiply"` when `FALSE`. If `FALSE`, no blending is applied. Note: CSS blending requires
#'   a standalone canvas overlay and is ignored when `before_id` or `slot` is specified.
#' @param flow_fade_amount Controls how much lower-magnitude flows fade compared to higher ones. Range: 0-100.
#' @param flow_highlight_color Color used for highlighting hovered elements.
#' @param flow_locations_enabled Whether to show location circles.
#' @param flow_location_totals_enabled Whether to show incoming/outgoing totals as concentric circles at each location.
#' @param flow_location_labels_enabled Whether to show text labels at locations.
#' @param flow_lines_rendering_mode Controls how flow lines are rendered: `"straight"`, `"animated-straight"`, or `"curved"`.
#' @param flow_line_thickness_scale Multiplier for flow line thickness.
#' @param flow_line_curviness Multiplier for flow line curviness (only used when `flow_lines_rendering_mode` is `"curved"`).
#' @param flow_clustering_enabled Whether to cluster nearby locations when zoomed out.
#' @param flow_clustering_auto Whether to automatically adjust clustering level based on zoom.
#' @param flow_clustering_level Fixed clustering zoom level. Only used when `flow_clustering_auto` is `FALSE`.
#' @param flow_fade_enabled Whether to apply color fading to lower-magnitude flows.
#' @param flow_fade_opacity_enabled Whether to also fade opacity for lower-magnitude flows.
#' @param flow_adaptive_scales_enabled Whether to adapt flow thickness and
#'   color scales to the current viewport. This controls the spatial scale
#'   domain while panning and zooming.
#' @param flow_temporal_scale_domain For temporal flowmaps, whether flow
#'   thickness and color scales use only the currently selected time range
#'   (`"selected"`) or all flow data across the full time extent (`"all"`).
#' @param flow_max_top_flows_display_num Maximum number of flows to display.
#' @param flow_endpoints_in_viewport_mode Controls when a flow is considered visible based on endpoint locations: `"any"` or `"both"`.
#' @param flow_time_column Optional column name in `flows` for time data.
#' @param flow_selected_time_range Optional vector of two dates (or strings) for initial time filtering.
#' @param flow_selected_locations Optional vector of location IDs to select.
#' @param flow_location_filter_mode Optional location filter mode: `"ALL"`, `"INCOMING"`, `"OUTGOING"`, or `"BETWEEN"`.
#' @param tooltip Tooltip configuration. Use `FALSE` or `NULL` to disable
#'   tooltips, `TRUE` for default tooltips, a single template string for both
#'   location and flow hovers, a named list with `location` and/or `flow`
#'   templates, or a [flowmap_tooltip()] object.
#' @param tooltip_style Tooltip style used when `tooltip` is not a
#'   [flowmap_tooltip()] object. `"mapgl"` uses the same popup style as other
#'   mapgl layers; `"flowmap"` uses the upstream Flowmap.gl example style.
#' @param tooltip_theme Tooltip theme. `"auto"` follows `flow_dark_mode`;
#'   `"light"` and `"dark"` force a theme.
#' @param tooltip_options A named list of renderer-specific tooltip options.
#' @param visibility Whether the layer is initially `"visible"` or `"none"`.
#' @param before_id Optional map layer ID to render before.
#' @param slot Optional Mapbox Standard slot.
#'
#' @return The modified map object with the flowmap layer added.
#'
#' @details
#' Mapbox and MapLibre layer paint arguments such as `fill_color`,
#' `circle_color`, and `line_color` require a scalar CSS color or a style
#' expression. Use `interpolate_palette(...)$expression` for data-driven layer
#' color ramps. FlowMapGL's `flow_color_scheme` accepts a preset name such as
#' `"Teal"`, a plain color ramp such as `c("red", "white", "blue")`, or an
#' `interpolate_palette(...)` scale object.
#'
#' Flow scale domains have separate spatial and temporal controls.
#' `flow_adaptive_scales_enabled = TRUE` rescales flow thickness and color for
#' the current viewport; `FALSE` keeps the scale tied to the broader map extent.
#' For temporal flowmaps, `flow_temporal_scale_domain = "selected"` rescales
#' within the selected time-control interval, while `"all"` keeps the scale
#' comparable across the full time extent.
#' @export
#'
#' @examples
#' \dontrun{
#' locations <- data.frame(
#'   id = c("NYC", "LA", "CHI"),
#'   lat = c(40.7128, 34.0522, 41.8781),
#'   lon = c(-74.0060, -118.2437, -87.6298)
#' )
#'
#' flows <- data.frame(
#'   origin = c("NYC", "LA"),
#'   dest = c("LA", "CHI"),
#'   count = c(1200, 800)
#' )
#'
#' maplibre(center = c(-98, 39), zoom = 3) |>
#'   add_flowmap("flows", locations, flows)
#' }
add_flowmap <- function(
  map,
  id,
  locations,
  flows,
  flow_color_scheme = "Teal",
  flow_opacity = 1,
  flow_dark_mode = "auto",
  flow_blend = "auto",
  flow_fade_amount = 50,
  flow_highlight_color = "#ff9b29",
  flow_locations_enabled = TRUE,
  flow_location_totals_enabled = TRUE,
  flow_location_labels_enabled = FALSE,
  flow_lines_rendering_mode = c("straight", "animated-straight", "curved"),
  flow_line_thickness_scale = 1,
  flow_line_curviness = 1,
  flow_clustering_enabled = TRUE,
  flow_clustering_auto = TRUE,
  flow_clustering_level = NULL,
  flow_fade_enabled = TRUE,
  flow_fade_opacity_enabled = FALSE,
  flow_adaptive_scales_enabled = TRUE,
  flow_temporal_scale_domain = c("selected", "all"),
  flow_max_top_flows_display_num = 5000,
  flow_endpoints_in_viewport_mode = c("any", "both"),
  flow_time_column = NULL,
  flow_selected_time_range = NULL,
  flow_selected_locations = NULL,
  flow_location_filter_mode = c("ALL", "INCOMING", "OUTGOING", "BETWEEN"),
  tooltip = FALSE,
  tooltip_style = c("mapgl", "flowmap"),
  tooltip_theme = c("auto", "light", "dark"),
  tooltip_options = NULL,
  visibility = c("visible", "none"),
  before_id = NULL,
  slot = NULL
) {
  if (!inherits(map, "mapboxgl") && !inherits(map, "maplibregl")) {
    rlang::abort("`map` must be created by `mapboxgl()` or `maplibre()`.")
  }

  if (!is.character(id) || length(id) != 1 || is.na(id) || !nzchar(id)) {
    rlang::abort("`id` must be a non-empty character string.")
  }

  visibility <- match.arg(visibility)
  flow_lines_rendering_mode <- match.arg(flow_lines_rendering_mode)
  flow_temporal_scale_domain <- match.arg(flow_temporal_scale_domain)
  flow_endpoints_in_viewport_mode <- match.arg(flow_endpoints_in_viewport_mode)
  flow_location_filter_mode <- match.arg(flow_location_filter_mode)
  tooltip_style <- match.arg(tooltip_style)
  tooltip_theme <- match.arg(tooltip_theme)

  if (
    !is.numeric(flow_opacity) ||
      length(flow_opacity) != 1 ||
      is.na(flow_opacity) ||
      flow_opacity < 0 ||
      flow_opacity > 1
  ) {
    rlang::abort("`flow_opacity` must be a number between 0 and 1.")
  }

  # Determine dark mode if "auto"
  if (identical(flow_dark_mode, "auto")) {
    flow_dark_mode <- is_dark_style(map$x$style)
  }

  flow_dark_mode <- flowmap_validate_dark_mode(flow_dark_mode)
  tooltip_config <- flowmap_normalize_tooltip(
    tooltip,
    style = tooltip_style,
    theme = tooltip_theme,
    options = tooltip_options,
    dark_mode = flow_dark_mode
  )

  use_interleaved <- !is.null(before_id) || !is.null(slot)

  # Resolve blend mode if "auto"
  if (identical(flow_blend, "auto")) {
    if (use_interleaved) {
      flow_blend <- FALSE
    } else {
      flow_blend <- if (flow_dark_mode) "screen" else "multiply"
    }
  } else if (isTRUE(flow_blend)) {
    # If explicitly TRUE, we still resolve to the best blend mode
    flow_blend <- if (flow_dark_mode) "screen" else "multiply"
  }

  if (use_interleaved && (!is.logical(flow_blend) || flow_blend)) {
    rlang::warn(
      "`flow_blend` is ignored when `before_id` or `slot` is specified. CSS blending requires a separate canvas overlay, which is not supported in interleaved mode."
    )
  }

  if (is.logical(flow_blend)) {
    if (length(flow_blend) != 1 || is.na(flow_blend)) {
      rlang::abort("`flow_blend` must be `TRUE` or `FALSE`.")
    }
  } else if (is.character(flow_blend)) {
    if (
      length(flow_blend) != 1 ||
        is.na(flow_blend) ||
        !nzchar(trimws(flow_blend))
    ) {
      rlang::abort("`flow_blend` must be a valid CSS blend mode name.")
    }
    valid_modes <- c(
      "normal",
      "multiply",
      "screen",
      "overlay",
      "darken",
      "lighten",
      "color-dodge",
      "color-burn",
      "hard-light",
      "soft-light",
      "difference",
      "exclusion",
      "hue",
      "saturation",
      "color",
      "luminosity"
    )
    if (!flow_blend %in% valid_modes) {
      rlang::abort(paste0(
        "`flow_blend` must be one of the valid CSS mix-blend-mode values: ",
        paste(paste0("\"", valid_modes, "\""), collapse = ", ")
      ))
    }
  } else {
    rlang::abort(
      "`flow_blend` must be a logical (`TRUE` or `FALSE`) or a valid CSS blend mode string."
    )
  }

  flowmap_validate_logical(flow_locations_enabled, "flow_locations_enabled")
  flowmap_validate_logical(
    flow_location_totals_enabled,
    "flow_location_totals_enabled"
  )
  flowmap_validate_logical(
    flow_location_labels_enabled,
    "flow_location_labels_enabled"
  )
  flowmap_validate_logical(flow_clustering_enabled, "flow_clustering_enabled")
  flowmap_validate_logical(flow_clustering_auto, "flow_clustering_auto")
  flowmap_validate_logical(flow_fade_enabled, "flow_fade_enabled")
  flowmap_validate_logical(
    flow_fade_opacity_enabled,
    "flow_fade_opacity_enabled"
  )
  flowmap_validate_logical(
    flow_adaptive_scales_enabled,
    "flow_adaptive_scales_enabled"
  )

  if (
    !is.character(flow_highlight_color) ||
      length(flow_highlight_color) != 1 ||
      is.na(flow_highlight_color)
  ) {
    rlang::abort("`flow_highlight_color` must be a single string.")
  }

  if (
    !is.numeric(flow_fade_amount) ||
      length(flow_fade_amount) != 1 ||
      is.na(flow_fade_amount) ||
      flow_fade_amount < 0 ||
      flow_fade_amount > 100
  ) {
    rlang::abort("`flow_fade_amount` must be a number between 0 and 100.")
  }

  if (
    !is.numeric(flow_max_top_flows_display_num) ||
      length(flow_max_top_flows_display_num) != 1 ||
      is.na(flow_max_top_flows_display_num) ||
      flow_max_top_flows_display_num <= 0
  ) {
    rlang::abort("`flow_max_top_flows_display_num` must be a positive number.")
  }

  if (
    !is.numeric(flow_line_thickness_scale) ||
      length(flow_line_thickness_scale) != 1 ||
      is.na(flow_line_thickness_scale)
  ) {
    rlang::abort("`flow_line_thickness_scale` must be a number.")
  }

  if (
    !is.numeric(flow_line_curviness) ||
      length(flow_line_curviness) != 1 ||
      is.na(flow_line_curviness)
  ) {
    rlang::abort("`flow_line_curviness` must be a number.")
  }

  if (!is.null(flow_clustering_level)) {
    if (
      !is.numeric(flow_clustering_level) ||
        length(flow_clustering_level) != 1 ||
        is.na(flow_clustering_level)
    ) {
      rlang::abort("`flow_clustering_level` must be a number or NULL.")
    }
  }

  if (!is.null(flow_selected_time_range)) {
    if (length(flow_selected_time_range) != 2) {
      rlang::abort(
        "`flow_selected_time_range` must be a vector of two elements (start and end)."
      )
    }
  }

  if (!is.null(flow_selected_locations)) {
    flow_selected_locations <- as.character(flow_selected_locations)
  }

  flow_color_scheme <- flowmap_normalize_color_scheme(flow_color_scheme)
  before_id <- flowmap_validate_optional_string(before_id, "before_id")
  slot <- flowmap_validate_optional_string(slot, "slot")

  locations <- flowmap_locations_to_df(locations)
  flows <- flowmap_flows_to_df(flows, time_column = flow_time_column)
  flowmap_validate_ids(locations, flows)

  flowmap_config <- list(
    id = id,
    data = list(
      locations = locations,
      flows = flows
    ),
    settings = list(
      colorScheme = flow_color_scheme,
      darkMode = flow_dark_mode,
      opacity = flow_opacity,
      flowBlend = flow_blend,
      fadeAmount = flow_fade_amount,
      highlightColor = flow_highlight_color,
      locationsEnabled = flow_locations_enabled,
      locationTotalsEnabled = flow_location_totals_enabled,
      locationLabelsEnabled = flow_location_labels_enabled,
      flowLinesRenderingMode = flow_lines_rendering_mode,
      flowLineThicknessScale = flow_line_thickness_scale,
      flowLineCurviness = flow_line_curviness,
      clusteringEnabled = flow_clustering_enabled,
      clusteringAuto = flow_clustering_auto,
      clusteringLevel = flow_clustering_level,
      fadeEnabled = flow_fade_enabled,
      fadeOpacityEnabled = flow_fade_opacity_enabled,
      adaptiveScalesEnabled = flow_adaptive_scales_enabled,
      temporalScaleDomain = flow_temporal_scale_domain,
      maxTopFlowsDisplayNum = flow_max_top_flows_display_num,
      flowEndpointsInViewportMode = flow_endpoints_in_viewport_mode,
      timeColumn = flow_time_column,
      selectedTimeRange = flow_selected_time_range,
      selectedLocations = flow_selected_locations,
      locationFilterMode = flow_location_filter_mode
    ),
    visibility = visibility,
    beforeId = before_id,
    slot = slot
  )

  if (isTRUE(tooltip_config$enabled)) {
    flowmap_config$tooltip <- tooltip_config
  }

  if (is.null(map$x$flowmaps)) {
    map$x$flowmaps <- list()
  }

  map$x$flowmaps <- c(map$x$flowmaps, list(flowmap_config))
  mapgl_record_flowmap_order(
    map,
    flowmap_index = length(map$x$flowmaps),
    pending = is.null(before_id) && (is.logical(flow_blend) && !flow_blend)
  )
}

#' Update flowmap filter
#'
#' Updates the filter state of a flowmap layer, including selected locations
#' and time range.
#'
#' @param proxy A map proxy object.
#' @param id The ID of the flowmap layer to update.
#' @param selected_locations Optional vector of location IDs to select.
#' @param location_filter_mode Optional location filter mode: `"ALL"`, `"INCOMING"`, `"OUTGOING"`, or `"BETWEEN"`.
#' @param selected_time_range Optional vector of two dates for time filtering.
#'
#' @return The modified map proxy.
#' @export
set_flowmap_filter <- function(
  proxy,
  id,
  selected_locations = NULL,
  location_filter_mode = NULL,
  selected_time_range = NULL
) {
  filter <- list()
  if (!is.null(selected_locations)) {
    filter$selectedLocations <- selected_locations
  }
  if (!is.null(location_filter_mode)) {
    filter$locationFilterMode <- location_filter_mode
  }
  if (!is.null(selected_time_range)) {
    if (length(selected_time_range) != 2) {
      rlang::abort("`selected_time_range` must be a vector of two elements.")
    }
    filter$selectedTimeRange <- selected_time_range
  }

  if (length(filter) == 0) {
    return(proxy)
  }

  flowmap_invoke_method(proxy, "set_flowmap_filter", id = id, filter = filter)
}

#' Update a flowmap setting
#'
#' Updates one setting of a flowmap layer.
#'
#' @param map A map object created by [mapboxgl()] or [maplibre()], or a proxy
#'   object created by [mapboxgl_proxy()] or [maplibre_proxy()].
#' @param id The ID of the flowmap layer to update.
#' @param name The setting name to update. Supported canonical FlowMapGL
#'   setting names are `opacity`, `colorScheme`, `darkMode`, `fadeAmount`,
#'   `highlightColor`, `locationsEnabled`, `locationTotalsEnabled`,
#'   `locationLabelsEnabled`, `flowLinesRenderingMode`,
#'   `flowLineThicknessScale`, `flowLineCurviness`, `clusteringEnabled`,
#'   `clusteringAuto`, `clusteringLevel`, `fadeEnabled`,
#'   `fadeOpacityEnabled`, `adaptiveScalesEnabled`, `temporalScaleDomain`,
#'   `maxTopFlowsDisplayNum`, and `flowEndpointsInViewportMode`.
#'   Snake-case aliases such as `color_scheme`, `temporal_scale_domain`, and
#'   `max_top_flows_display_num` are accepted and normalized internally.
#'   Filter state (`selectedTimeRange`, `selectedLocations`, and
#'   `locationFilterMode`) must be updated with [set_flowmap_filter()].
#' @param value The setting value.
#'
#' @return The modified map object.
#'
#' @details
#' `colorScheme` accepts the same values as `flow_color_scheme` in
#' [add_flowmap()]: a FlowMapGL preset name, a character vector of at least two
#' CSS colors, or a `mapgl_continuous_scale` object from
#' [interpolate_palette()]. `opacity` must be between 0 and 1. `fadeAmount`
#' must be between 0 and 100. `maxTopFlowsDisplayNum` must be positive.
#' `clusteringLevel` must be numeric or `NULL`. `flowLinesRenderingMode` must
#' be `"straight"`, `"animated-straight"`, or `"curved"`.
#' `temporalScaleDomain` must be `"selected"` or `"all"`.
#' `flowEndpointsInViewportMode` must be `"any"` or `"both"`. Boolean
#' settings must be scalar `TRUE` or `FALSE`.
#' @export
set_flowmap_settings <- function(map, id, name, value) {
  setting <- flowmap_normalize_setting(name, value)
  settings <- stats::setNames(list(setting$value), setting$name)

  flowmap_invoke_method(
    map,
    "set_flowmap_settings",
    id = id,
    settings = settings
  )
}

flowmap_invoke_method <- function(map, type, ...) {
  args <- list(...)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) {
        "mapboxgl-compare-proxy"
      } else {
        "maplibre-compare-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = c(list(type = type, map = map$map_side), args)
        )
      )
    } else {
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = c(list(type = type), args)
        )
      )
    }
  } else {
    # Handle non-proxy case by updating map$x
    # This ensures that if called on a map object, the settings are applied on first render
    if (!is.null(map$x$flowmaps)) {
      id <- args$id
      for (i in seq_along(map$x$flowmaps)) {
        if (map$x$flowmaps[[i]]$id == id) {
          if (type == "set_flowmap_filter") {
            # Merge filter into settings (JS init will pick it up)
            if (!is.null(args$filter$selectedTimeRange)) {
              map$x$flowmaps[[
                i
              ]]$settings$selectedTimeRange <- args$filter$selectedTimeRange
            }
            if (!is.null(args$filter$selectedLocations)) {
              map$x$flowmaps[[
                i
              ]]$settings$selectedLocations <- args$filter$selectedLocations
            }
            if (!is.null(args$filter$locationFilterMode)) {
              map$x$flowmaps[[
                i
              ]]$settings$locationFilterMode <- args$filter$locationFilterMode
            }
          } else if (type == "set_flowmap_settings") {
            # Merge settings
            for (s in names(args$settings)) {
              map$x$flowmaps[[i]]$settings[s] <- args$settings[s]
            }
          }
        }
      }
    }
  }
  return(map)
}

flowmap_validate_logical <- function(value, arg) {
  if (!is.logical(value) || length(value) != 1 || is.na(value)) {
    rlang::abort(paste0("`", arg, "` must be TRUE or FALSE."))
  }
}

flowmap_setting_name_map <- c(
  opacity = "opacity",
  colorScheme = "colorScheme",
  color_scheme = "colorScheme",
  darkMode = "darkMode",
  dark_mode = "darkMode",
  fadeAmount = "fadeAmount",
  fade_amount = "fadeAmount",
  highlightColor = "highlightColor",
  highlight_color = "highlightColor",
  locationsEnabled = "locationsEnabled",
  locations_enabled = "locationsEnabled",
  locationTotalsEnabled = "locationTotalsEnabled",
  location_totals_enabled = "locationTotalsEnabled",
  locationLabelsEnabled = "locationLabelsEnabled",
  location_labels_enabled = "locationLabelsEnabled",
  flowLinesRenderingMode = "flowLinesRenderingMode",
  flow_lines_rendering_mode = "flowLinesRenderingMode",
  flowLineThicknessScale = "flowLineThicknessScale",
  flow_line_thickness_scale = "flowLineThicknessScale",
  flowLineCurviness = "flowLineCurviness",
  flow_line_curviness = "flowLineCurviness",
  clusteringEnabled = "clusteringEnabled",
  clustering_enabled = "clusteringEnabled",
  clusteringAuto = "clusteringAuto",
  clustering_auto = "clusteringAuto",
  clusteringLevel = "clusteringLevel",
  clustering_level = "clusteringLevel",
  fadeEnabled = "fadeEnabled",
  fade_enabled = "fadeEnabled",
  fadeOpacityEnabled = "fadeOpacityEnabled",
  fade_opacity_enabled = "fadeOpacityEnabled",
  adaptiveScalesEnabled = "adaptiveScalesEnabled",
  adaptive_scales_enabled = "adaptiveScalesEnabled",
  temporalScaleDomain = "temporalScaleDomain",
  temporal_scale_domain = "temporalScaleDomain",
  maxTopFlowsDisplayNum = "maxTopFlowsDisplayNum",
  max_top_flows_display_num = "maxTopFlowsDisplayNum",
  flowEndpointsInViewportMode = "flowEndpointsInViewportMode",
  flow_endpoints_in_viewport_mode = "flowEndpointsInViewportMode"
)

flowmap_filter_setting_names <- c(
  "selectedTimeRange",
  "selected_time_range",
  "selectedLocations",
  "selected_locations",
  "locationFilterMode",
  "location_filter_mode"
)

flowmap_supported_setting_names <- function() {
  unique(unname(flowmap_setting_name_map))
}

flowmap_normalize_setting <- function(name, value) {
  if (
    !is.character(name) ||
      length(name) != 1 ||
      is.na(name) ||
      !nzchar(trimws(name))
  ) {
    rlang::abort("`name` must be a non-empty character string.")
  }

  if (name %in% flowmap_filter_setting_names) {
    rlang::abort(
      paste0(
        "`",
        name,
        "` is flowmap filter state. Use `set_flowmap_filter()` instead."
      )
    )
  }

  normalized_name <- unname(flowmap_setting_name_map[name])
  if (is.na(normalized_name)) {
    supported <- paste0("`", flowmap_supported_setting_names(), "`")
    rlang::abort(paste0(
      "`name` must be a supported FlowMapGL setting. Supported names are ",
      paste(supported, collapse = ", "),
      "."
    ))
  }

  list(
    name = normalized_name,
    value = flowmap_validate_setting_value(normalized_name, value)
  )
}

flowmap_validate_setting_value <- function(name, value) {
  switch(
    name,
    opacity = flowmap_validate_numeric_range(
      value,
      "value",
      min = 0,
      max = 1
    ),
    colorScheme = flowmap_normalize_color_scheme(value, arg = "value"),
    darkMode = flowmap_validate_logical_setting(value),
    fadeAmount = flowmap_validate_numeric_range(
      value,
      "value",
      min = 0,
      max = 100
    ),
    highlightColor = flowmap_validate_single_string(value, "value"),
    locationsEnabled = flowmap_validate_logical_setting(value),
    locationTotalsEnabled = flowmap_validate_logical_setting(value),
    locationLabelsEnabled = flowmap_validate_logical_setting(value),
    flowLinesRenderingMode = flowmap_validate_choice(
      value,
      "value",
      c("straight", "animated-straight", "curved")
    ),
    flowLineThicknessScale = flowmap_validate_numeric_scalar(value, "value"),
    flowLineCurviness = flowmap_validate_numeric_scalar(value, "value"),
    clusteringEnabled = flowmap_validate_logical_setting(value),
    clusteringAuto = flowmap_validate_logical_setting(value),
    clusteringLevel = flowmap_validate_nullable_numeric_scalar(value, "value"),
    fadeEnabled = flowmap_validate_logical_setting(value),
    fadeOpacityEnabled = flowmap_validate_logical_setting(value),
    adaptiveScalesEnabled = flowmap_validate_logical_setting(value),
    temporalScaleDomain = flowmap_validate_choice(
      value,
      "value",
      c("selected", "all")
    ),
    maxTopFlowsDisplayNum = flowmap_validate_positive_numeric_scalar(
      value,
      "value"
    ),
    flowEndpointsInViewportMode = flowmap_validate_choice(
      value,
      "value",
      c("any", "both")
    )
  )
}

flowmap_validate_logical_setting <- function(value) {
  flowmap_validate_logical(value, "value")
  value
}

flowmap_validate_numeric_scalar <- function(value, arg) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value)) {
    rlang::abort(paste0("`", arg, "` must be a number."))
  }

  value
}

flowmap_validate_nullable_numeric_scalar <- function(value, arg) {
  if (is.null(value)) {
    return(NULL)
  }

  if (!is.numeric(value) || length(value) != 1 || is.na(value)) {
    rlang::abort(paste0("`", arg, "` must be a number or NULL."))
  }

  value
}

flowmap_validate_positive_numeric_scalar <- function(value, arg) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value <= 0) {
    rlang::abort(paste0("`", arg, "` must be a positive number."))
  }

  value
}

flowmap_validate_numeric_range <- function(value, arg, min, max) {
  if (
    !is.numeric(value) ||
      length(value) != 1 ||
      is.na(value) ||
      value < min ||
      value > max
  ) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be a number between ",
      min,
      " and ",
      max,
      "."
    ))
  }

  value
}

flowmap_validate_choice <- function(value, arg, choices) {
  if (
    !is.character(value) ||
      length(value) != 1 ||
      is.na(value) ||
      !value %in% choices
  ) {
    quoted <- paste0("`", choices, "`", collapse = ", ")
    rlang::abort(paste0("`", arg, "` must be one of ", quoted, "."))
  }

  value
}

flowmap_validate_single_string <- function(value, arg) {
  if (!is.character(value) || length(value) != 1 || is.na(value)) {
    rlang::abort(paste0("`", arg, "` must be a single string."))
  }

  value
}

flowmap_normalize_tooltip <- function(
  tooltip,
  style,
  theme,
  options,
  dark_mode
) {
  if (is.null(tooltip) || identical(tooltip, FALSE)) {
    return(list(enabled = FALSE))
  }

  if (is.null(options)) {
    options <- list()
  }
  if (
    !is.list(options) || (!is.null(names(options)) && anyNA(names(options)))
  ) {
    rlang::abort("`tooltip_options` must be a named list.")
  }
  if (
    length(options) > 0 &&
      (is.null(names(options)) || any(!nzchar(names(options))))
  ) {
    rlang::abort("`tooltip_options` must be a named list.")
  }

  location <- TRUE
  flow <- TRUE

  if (inherits(tooltip, "mapgl_flowmap_tooltip")) {
    location <- tooltip$location
    flow <- tooltip$flow
    style <- tooltip$style %||% style
    theme <- tooltip$theme %||% theme
    options <- tooltip$options %||% options
  } else if (isTRUE(tooltip)) {
    # Defaults already set above.
  } else if (is.character(tooltip) && length(tooltip) == 1 && !is.na(tooltip)) {
    location <- tooltip
    flow <- tooltip
  } else if (is.list(tooltip) && !is.null(names(tooltip))) {
    if (!is.null(tooltip$location)) {
      location <- tooltip$location
    }
    if (!is.null(tooltip$flow)) {
      flow <- tooltip$flow
    }
    if (!is.null(tooltip$style)) {
      style <- tooltip$style
    }
    if (!is.null(tooltip$theme)) {
      theme <- tooltip$theme
    }
    if (!is.null(tooltip$options)) {
      options <- tooltip$options
    }
  } else {
    rlang::abort(
      "`tooltip` must be `TRUE`, `FALSE`, `NULL`, a template string, a named list, or a `flowmap_tooltip()` object."
    )
  }

  style <- flowmap_validate_choice(
    style,
    "tooltip_style",
    c("mapgl", "flowmap")
  )
  theme <- flowmap_validate_choice(
    theme,
    "tooltip_theme",
    c("auto", "light", "dark")
  )
  if (identical(theme, "auto")) {
    theme <- if (dark_mode) "dark" else "light"
  }

  if (
    !is.list(options) ||
      (length(options) > 0 &&
        (is.null(names(options)) || any(!nzchar(names(options)))))
  ) {
    rlang::abort("`tooltip_options` must be a named list.")
  }

  location <- flowmap_validate_tooltip_template(location, "tooltip$location")
  flow <- flowmap_validate_tooltip_template(flow, "tooltip$flow")

  enabled <- !identical(location, FALSE) || !identical(flow, FALSE)

  list(
    enabled = enabled,
    style = style,
    theme = theme,
    location = location,
    flow = flow,
    options = options
  )
}

flowmap_validate_tooltip_template <- function(value, arg) {
  if (is.null(value)) {
    return(FALSE)
  }

  if (is.logical(value)) {
    if (length(value) != 1 || is.na(value)) {
      rlang::abort(paste0(
        "`",
        arg,
        "` must be `TRUE`, `FALSE`, or a template string."
      ))
    }
    return(value)
  }

  if (
    !is.character(value) ||
      length(value) != 1 ||
      is.na(value) ||
      !nzchar(trimws(value))
  ) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be `TRUE`, `FALSE`, or a template string."
    ))
  }

  value
}

mapgl_layer_order <- function(map) {
  order <- attr(map, "mapgl_layer_order", exact = TRUE)
  if (is.null(order)) {
    order <- list(markers = list(), pending_flowmaps = integer())
  }
  order
}

mapgl_set_layer_order <- function(map, order) {
  attr(map, "mapgl_layer_order") <- order
  map
}

mapgl_record_flowmap_order <- function(map, flowmap_index, pending) {
  order <- mapgl_layer_order(map)
  order$markers <- c(
    order$markers,
    list(list(type = "flowmap", index = flowmap_index))
  )

  if (pending) {
    order$pending_flowmaps <- c(order$pending_flowmaps, flowmap_index)
  }

  mapgl_set_layer_order(map, order)
}

mapgl_resolve_pending_flowmaps <- function(map, before_id) {
  order <- mapgl_layer_order(map)
  pending_flowmaps <- order$pending_flowmaps

  if (length(pending_flowmaps) == 0) {
    return(map)
  }

  for (flowmap_index in pending_flowmaps) {
    if (flowmap_index > length(map$x$flowmaps)) {
      next
    }

    if (is.null(map$x$flowmaps[[flowmap_index]]$beforeId)) {
      map$x$flowmaps[[flowmap_index]]$beforeId <- before_id
    }
  }

  order$pending_flowmaps <- integer()
  mapgl_set_layer_order(map, order)
}

mapgl_record_layer_order <- function(map, id) {
  order <- mapgl_layer_order(map)
  order$markers <- c(order$markers, list(list(type = "layer", id = id)))
  mapgl_set_layer_order(map, order)
}

flowmap_color_scheme_registry <- local({
  schemes <- NULL

  function() {
    if (!is.null(schemes)) {
      return(schemes)
    }

    manifest_path <- system.file(
      "htmlwidgets/lib/flowmap-gl/flowmap-gl-vendor-manifest.json",
      package = "mapgl",
      mustWork = TRUE
    )
    manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
    names <- manifest$colorSchemes$names

    if (
      !is.character(names) ||
        length(names) == 0 ||
        anyNA(names) ||
        any(!nzchar(names))
    ) {
      rlang::abort(
        "FlowMapGL color scheme metadata is missing from the vendored manifest."
      )
    }

    schemes <<- names
    schemes
  }
})

flowmap_color_schemes_markdown <- function() {
  schemes <- paste0("`", flowmap_color_scheme_registry(), "`")
  if (length(schemes) == 1) {
    return(schemes)
  }

  paste0(
    paste(schemes[-length(schemes)], collapse = ", "),
    ", and ",
    schemes[[length(schemes)]]
  )
}

flowmap_validate_dark_mode <- function(flow_dark_mode) {
  if (
    !is.logical(flow_dark_mode) ||
      length(flow_dark_mode) != 1 ||
      is.na(flow_dark_mode)
  ) {
    rlang::abort("`flow_dark_mode` must be `TRUE` or `FALSE`.")
  }

  flow_dark_mode
}

flowmap_validate_optional_string <- function(value, arg) {
  if (is.null(value)) {
    return(NULL)
  }

  if (
    !is.character(value) ||
      length(value) != 1 ||
      is.na(value) ||
      !nzchar(trimws(value))
  ) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be `NULL` or a non-empty character string."
    ))
  }

  value
}

flowmap_normalize_color_scheme <- function(
  flow_color_scheme,
  arg = "flow_color_scheme"
) {
  arg_label <- paste0("`", arg, "`")

  if (inherits(flow_color_scheme, "mapgl_continuous_scale")) {
    colors <- flow_color_scheme$colors
    if (is.null(colors)) {
      rlang::abort(
        paste0(arg_label, " scale objects must contain a `colors` vector.")
      )
    }
    colors_arg_label <- paste0("`", arg, "$colors`")
    return(mapgl_validate_color_vector(colors, colors_arg_label))
  }

  if (!is.character(flow_color_scheme)) {
    rlang::abort(paste0(
      arg_label,
      " must be a FlowMapGL preset name, a CSS color vector, or a mapgl_continuous_scale object."
    ))
  }

  if (length(flow_color_scheme) == 1) {
    if (is.na(flow_color_scheme) || !nzchar(trimws(flow_color_scheme))) {
      rlang::abort(paste0(arg_label, " must not be missing or empty."))
    }

    if (flow_color_scheme %in% flowmap_color_scheme_registry()) {
      return(flow_color_scheme)
    }

    rlang::abort(paste0(
      arg_label,
      " must be one of `flowmap_color_schemes()` or a ",
      "character vector of at least two CSS colors. Scalar color strings ",
      "such as \"",
      flow_color_scheme,
      "\" are not valid FlowMapGL preset names."
    ))
  }

  mapgl_validate_color_vector(flow_color_scheme, arg_label)
}

flowmap_locations_to_df <- function(locations) {
  if (inherits(locations, "sfc")) {
    locations <- sf::st_as_sf(
      data.frame(id = seq_along(locations)),
      geometry = locations
    )
  }

  if (inherits(locations, "sf")) {
    geometry_type <- as.character(sf::st_geometry_type(
      locations,
      by_geometry = TRUE
    ))
    if (!all(geometry_type == "POINT")) {
      rlang::abort("`locations` must contain only POINT geometries.")
    }

    if (
      !is.na(sf::st_crs(locations)) && sf::st_crs(locations) != sf::st_crs(4326)
    ) {
      locations <- sf::st_transform(locations, crs = 4326)
    }

    coords <- sf::st_coordinates(locations)
    locations <- sf::st_drop_geometry(locations)
    locations$lon <- coords[, "X"]
    locations$lat <- coords[, "Y"]
  } else if (!is.data.frame(locations)) {
    rlang::abort("`locations` must be a data frame or an sf point object.")
  }

  locations <- as.data.frame(locations)
  required <- c("id", "lat", "lon")
  missing <- setdiff(required, names(locations))
  if (length(missing) > 0) {
    rlang::abort(paste0(
      "`locations` is missing required column",
      if (length(missing) == 1) "" else "s",
      ": ",
      paste(missing, collapse = ", ")
    ))
  }

  if (!is.numeric(locations$lat) || !is.numeric(locations$lon)) {
    rlang::abort("`locations$lat` and `locations$lon` must be numeric.")
  }

  if (anyNA(locations$id) || anyNA(locations$lat) || anyNA(locations$lon)) {
    rlang::abort(
      "`locations` must not contain missing values in `id`, `lat`, or `lon`."
    )
  }

  if (any(!is.finite(locations$lat)) || any(!is.finite(locations$lon))) {
    rlang::abort(
      "`locations$lat` and `locations$lon` must contain finite values."
    )
  }

  locations$id <- as.character(locations$id)
  if (anyDuplicated(locations$id)) {
    rlang::abort("`locations$id` values must be unique.")
  }

  if (!"name" %in% names(locations)) {
    locations$name <- locations$id
  } else {
    locations$name <- as.character(locations$name)
  }

  locations[,
    unique(c(
      "id",
      "lat",
      "lon",
      "name",
      setdiff(names(locations), c("id", "lat", "lon", "name"))
    )),
    drop = FALSE
  ]
}

flowmap_flows_to_df <- function(flows, time_column = NULL) {
  if (!is.data.frame(flows)) {
    rlang::abort("`flows` must be a data frame.")
  }

  flows <- as.data.frame(flows)
  required <- c("origin", "dest", "count")
  missing <- setdiff(required, names(flows))
  if (length(missing) > 0) {
    rlang::abort(paste0(
      "`flows` is missing required column",
      if (length(missing) == 1) "" else "s",
      ": ",
      paste(missing, collapse = ", ")
    ))
  }

  if (!is.numeric(flows$count)) {
    rlang::abort("`flows$count` must be numeric.")
  }

  if (anyNA(flows$origin) || anyNA(flows$dest) || anyNA(flows$count)) {
    rlang::abort(
      "`flows` must not contain missing values in `origin`, `dest`, or `count`."
    )
  }

  if (any(!is.finite(flows$count))) {
    rlang::abort("`flows$count` must contain finite values.")
  }

  if (!is.null(time_column)) {
    if (!time_column %in% names(flows)) {
      rlang::abort(paste0(
        "Time column '",
        time_column,
        "' not found in `flows`."
      ))
    }
    flows$time <- flows[[time_column]]
  }

  flows$origin <- as.character(flows$origin)
  flows$dest <- as.character(flows$dest)
  flows[,
    unique(c(
      "origin",
      "dest",
      "count",
      if (!is.null(time_column)) "time",
      setdiff(
        names(flows),
        c("origin", "dest", "count", if (!is.null(time_column)) "time")
      )
    )),
    drop = FALSE
  ]
}

flowmap_validate_ids <- function(locations, flows) {
  ids <- locations$id
  invalid_origins <- setdiff(unique(flows$origin), ids)
  invalid_dests <- setdiff(unique(flows$dest), ids)
  invalid <- unique(c(invalid_origins, invalid_dests))

  if (length(invalid) > 0) {
    rlang::abort(paste0(
      "`flows$origin` and `flows$dest` must match `locations$id`; unknown ID",
      if (length(invalid) == 1) "" else "s",
      ": ",
      paste(utils::head(invalid, 5), collapse = ", "),
      if (length(invalid) > 5) ", ..." else ""
    ))
  }
}

is_dark_style <- function(style) {
  if (is.null(style)) {
    return(TRUE) # Fallback to TRUE as default
  }

  if (!is.character(style) || length(style) != 1 || is.na(style)) {
    # If it's a list (like from basemap_style)
    if (is.list(style)) {
      bg_layer <- Filter(
        function(l) isTRUE(l$type == "background"),
        style$layers
      )
      if (length(bg_layer) > 0) {
        color <- bg_layer[[1]]$paint$`background-color`
        if (is.character(color) && length(color) == 1) {
          if (grepl("white|light|grey|gray", color, ignore.case = TRUE)) {
            return(FALSE)
          }
          if (grepl("black|dark", color, ignore.case = TRUE)) {
            return(TRUE)
          }
        }
      }
    }
    return(TRUE) # Safe fallback
  }

  # Dark patterns
  if (
    grepl(
      "dark|night|midnight|satellite|hybrid|imagery|nova",
      style,
      ignore.case = TRUE
    )
  ) {
    return(TRUE)
  }

  # Light patterns
  if (
    grepl(
      "light|day|positron|voyager|streets|outdoors|basic|bright|topo|terrain",
      style,
      ignore.case = TRUE
    )
  ) {
    return(FALSE)
  }

  # Default fallback if unknown
  TRUE
}
