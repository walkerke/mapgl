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
    rlang::warn("`flow_blend` is ignored when `before_id` or `slot` is specified. CSS blending requires a separate canvas overlay, which is not supported in interleaved mode.")
  }

  if (is.logical(flow_blend)) {
    if (length(flow_blend) != 1 || is.na(flow_blend)) {
      rlang::abort("`flow_blend` must be `TRUE` or `FALSE`.")
    }
  } else if (is.character(flow_blend)) {
    if (length(flow_blend) != 1 || is.na(flow_blend) || !nzchar(trimws(flow_blend))) {
      rlang::abort("`flow_blend` must be a valid CSS blend mode name.")
    }
    valid_modes <- c(
      "normal", "multiply", "screen", "overlay", "darken", "lighten",
      "color-dodge", "color-burn", "hard-light", "soft-light",
      "difference", "exclusion", "hue", "saturation", "color", "luminosity"
    )
    if (!flow_blend %in% valid_modes) {
      rlang::abort(paste0(
        "`flow_blend` must be one of the valid CSS mix-blend-mode values: ",
        paste(paste0("\"", valid_modes, "\""), collapse = ", ")
      ))
    }
  } else {
    rlang::abort("`flow_blend` must be a logical (`TRUE` or `FALSE`) or a valid CSS blend mode string.")
  }
  flow_color_scheme <- flowmap_normalize_color_scheme(flow_color_scheme)
  before_id <- flowmap_validate_optional_string(before_id, "before_id")
  slot <- flowmap_validate_optional_string(slot, "slot")

  locations <- flowmap_locations_to_df(locations)
  flows <- flowmap_flows_to_df(flows)
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
      flowBlend = flow_blend
    ),
    visibility = visibility,
    beforeId = before_id,
    slot = slot
  )

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

flowmap_normalize_color_scheme <- function(flow_color_scheme) {
  if (inherits(flow_color_scheme, "mapgl_continuous_scale")) {
    colors <- flow_color_scheme$colors
    if (is.null(colors)) {
      rlang::abort(
        "`flow_color_scheme` scale objects must contain a `colors` vector."
      )
    }
    return(mapgl_validate_color_vector(colors, "`flow_color_scheme$colors`"))
  }

  if (!is.character(flow_color_scheme)) {
    rlang::abort(
      "`flow_color_scheme` must be a FlowMapGL preset name, a CSS color vector, or a mapgl_continuous_scale object."
    )
  }

  if (length(flow_color_scheme) == 1) {
    if (is.na(flow_color_scheme) || !nzchar(trimws(flow_color_scheme))) {
      rlang::abort("`flow_color_scheme` must not be missing or empty.")
    }

    if (flow_color_scheme %in% flowmap_color_scheme_registry()) {
      return(flow_color_scheme)
    }

    rlang::abort(paste0(
      "`flow_color_scheme` must be one of `flowmap_color_schemes()` or a ",
      "character vector of at least two CSS colors. Scalar color strings ",
      "such as \"",
      flow_color_scheme,
      "\" are not valid FlowMapGL preset names."
    ))
  }

  mapgl_validate_color_vector(flow_color_scheme, "`flow_color_scheme`")
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

flowmap_flows_to_df <- function(flows) {
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

  flows$origin <- as.character(flows$origin)
  flows$dest <- as.character(flows$dest)
  flows[,
    unique(c(
      "origin",
      "dest",
      "count",
      setdiff(names(flows), c("origin", "dest", "count"))
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
      bg_layer <- Filter(function(l) isTRUE(l$type == "background"), style$layers)
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
  if (grepl("dark|night|midnight|satellite|hybrid|imagery|nova", style, ignore.case = TRUE)) {
    return(TRUE)
  }

  # Light patterns
  if (grepl("light|day|positron|voyager|streets|outdoors|basic|bright|topo|terrain", style, ignore.case = TRUE)) {
    return(FALSE)
  }

  # Default fallback if unknown
  TRUE
}
