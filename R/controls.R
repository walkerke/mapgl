#' Add a fullscreen control to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param position A string specifying the position of the fullscreen control.
#'        One of "top-right", "top-left", "bottom-right", or "bottom-left".
#'
#' @return The modified map object with the fullscreen control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' maplibre(
#'     style = maptiler_style("streets"),
#'     center = c(11.255, 43.77),
#'     zoom = 13
#' ) |>
#'     add_fullscreen_control(position = "top-right")
#' }
add_fullscreen_control <- function(map, position = "top-right") {
  map$x$fullscreen_control <- list(
    enabled = TRUE,
    position = position
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_fullscreen_control",
            position = position,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_fullscreen_control",
            position = position
          )
        )
      )
    }
  }

  map
}

#' Add a navigation control to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param show_compass Whether to show the compass button.
#' @param show_zoom Whether to show the zoom-in and zoom-out buttons.
#' @param visualize_pitch Whether to visualize the pitch by rotating the X-axis of the compass.
#' @param position The position on the map where the control will be added. Possible values are "top-left", "top-right", "bottom-left", and "bottom-right".
#' @param orientation The orientation of the navigation control. Can be "vertical" (default) or "horizontal".
#'
#' @return The updated map object with the navigation control added.
#' @export
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'     add_navigation_control(visualize_pitch = TRUE)
#' }
add_navigation_control <- function(
  map,
  show_compass = TRUE,
  show_zoom = TRUE,
  visualize_pitch = FALSE,
  position = "top-right",
  orientation = "vertical"
) {
  nav_control <- list(
    show_compass = show_compass,
    show_zoom = show_zoom,
    visualize_pitch = visualize_pitch,
    position = position,
    orientation = orientation
  )

  if (
    any(
      inherits(map, "mapboxgl_proxy"),
      inherits(map, "maplibre_proxy")
    )
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_navigation_control",
            options = nav_control,
            position = position,
            orientation = orientation,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }

      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_navigation_control",
            options = nav_control,
            position = position,
            orientation = orientation
          )
        )
      )
    }
  } else {
    if (is.null(map$x$navigation_control)) {
      map$x$navigation_control <- list()
    }
    map$x$navigation_control <- nav_control
  }

  return(map)
}


#' Add a layers control to the map
#'
#' @param map A map object.
#' @param position The position of the control on the map (one of "top-left", "top-right", "bottom-left", "bottom-right").
#' @param layers Either a character vector of layer IDs to include in the control,
#'   a named list/vector where names are labels and values are layer IDs,
#'   or a named list where values can be vectors to group multiple layers together.
#'   If NULL, all layers will be included.
#' @param collapsible Whether the control should be collapsible.
#' @param use_icon Whether to use a stacked layers icon instead of the "Layers" text when collapsed. Only applies when collapsible = TRUE.
#' @param background_color The background color for the layers control; this will be the
#'        color used for inactive layer items.
#' @param active_color The background color for active layer items.
#' @param hover_color The background color for layer items when hovered.
#' @param active_text_color The text color for active layer items.
#' @param inactive_text_color The text color for inactive layer items.
#' @param margin_top Custom top margin in pixels, allowing for fine control over control positioning to avoid overlaps. Default is NULL (uses standard positioning).
#' @param margin_right Custom right margin in pixels. Default is NULL.
#' @param margin_bottom Custom bottom margin in pixels. Default is NULL.
#' @param margin_left Custom left margin in pixels. Default is NULL.
#'
#' @return The modified map object with the layers control added.
#' @export
#' @examples \dontrun{
#' library(tigris)
#' options(tigris_use_cache = TRUE)
#'
#' rds <- roads("TX", "Tarrant")
#' tr <- tracts("TX", "Tarrant", cb = TRUE)
#' cty <- counties("TX", cb = TRUE)
#'
#' maplibre() |>
#'     fit_bounds(rds) |>
#'     add_fill_layer(
#'         id = "Census tracts",
#'         source = tr,
#'         fill_color = "purple",
#'         fill_opacity = 0.6
#'     ) |>
#'     add_line_layer(
#'         "Local roads",
#'         source = rds,
#'         line_color = "pink"
#'     ) |>
#'     add_layers_control(
#'         position = "top-left",
#'         background_color = "#ffffff",
#'         active_color = "#4a90e2"
#'     )
#'
#' # With custom labels
#' maplibre() |>
#'     add_fill_layer(id = "tract-fill", source = tr) |>
#'     add_line_layer(id = "tract-line", source = tr) |>
#'     add_layers_control(
#'         layers = list(
#'             "Census Tracts" = "tract-fill",
#'             "Tract Borders" = "tract-line"
#'         )
#'     )
#'
#' # Group multiple layers together
#' maplibre(bounds = cty) |>
#'     add_fill_layer(id = "county-fill", source = cty, fill_opacity = 0.3) |>
#'     add_line_layer(
#'         id = "county-outline",
#'         source = cty,
#'         line_color = "yellow",
#'         line_width = 3
#'     ) |>
#'     add_line_layer(
#'         id = "roads-layer",
#'         source = rds,
#'         line_color = "blue"
#'     ) |>
#'     add_layers_control(
#'         layers = list(
#'             "Counties" = c("county-fill", "county-outline"),
#'             "Roads" = "roads-layer"
#'         )
#'     )
#' }
add_layers_control <- function(
  map,
  position = "top-left",
  layers = NULL,
  collapsible = TRUE,
  use_icon = TRUE,
  background_color = NULL,
  active_color = NULL,
  hover_color = NULL,
  active_text_color = NULL,
  inactive_text_color = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL
) {
  control_id <- paste0("layers-control-", as.hexmode(sample(1:1000000, 1)))

  # Process layers parameter
  layers_config <- NULL
  if (is.null(layers)) {
    # If layers is NULL, get the layers added by the user
    layers <- unlist(lapply(map$x$layers, function(y) {
      y$id
    }))
  } else if (is.list(layers) && !is.null(names(layers))) {
    # Named list: process labels and groups
    layers_config <- list()
    for (label in names(layers)) {
      layer_ids <- layers[[label]]
      if (length(layer_ids) > 1) {
        # Multiple IDs - this is a group
        layers_config[[length(layers_config) + 1]] <- list(
          label = label,
          ids = as.character(layer_ids),
          type = "group"
        )
      } else {
        # Single ID - regular layer with label
        layers_config[[length(layers_config) + 1]] <- list(
          label = label,
          ids = as.character(layer_ids),
          type = "single"
        )
      }
    }
  } else if (!is.null(names(layers))) {
    # Named vector: just labels, no groups
    layers_config <- list()
    for (i in seq_along(layers)) {
      layers_config[[i]] <- list(
        label = names(layers)[i],
        ids = as.character(layers[i]),
        type = "single"
      )
    }
  }

  # Create custom colors object if any color options were specified
  custom_colors <- NULL
  if (
    !is.null(background_color) ||
      !is.null(active_color) ||
      !is.null(hover_color) ||
      !is.null(inactive_text_color) ||
      !is.null(active_text_color)
  ) {
    custom_colors <- list()
    if (!is.null(background_color)) custom_colors$background <- background_color
    if (!is.null(active_color)) custom_colors$active <- active_color
    if (!is.null(hover_color)) custom_colors$hover <- hover_color
    if (!is.null(inactive_text_color)) custom_colors$text <- inactive_text_color
    if (!is.null(active_text_color))
      custom_colors$activeText <- active_text_color
  }

  # Add control to map
  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_layers_control",
            control_id = control_id,
            position = position,
            layers = layers,
            layers_config = layers_config,
            collapsible = collapsible,
            use_icon = use_icon,
            custom_colors = custom_colors,
            margin_top = margin_top,
            margin_right = margin_right,
            margin_bottom = margin_bottom,
            margin_left = margin_left,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_layers_control",
            control_id = control_id,
            position = position,
            layers = layers,
            layers_config = layers_config,
            collapsible = collapsible,
            use_icon = use_icon,
            custom_colors = custom_colors,
            margin_top = margin_top,
            margin_right = margin_right,
            margin_bottom = margin_bottom,
            margin_left = margin_left
          )
        )
      )
    }
  } else {
    map$x$layers_control <- list(
      control_id = control_id,
      position = position,
      layers = layers,
      layers_config = layers_config,
      collapsible = collapsible,
      use_icon = use_icon,
      custom_colors = custom_colors,
      margin_top = margin_top,
      margin_right = margin_right,
      margin_bottom = margin_bottom,
      margin_left = margin_left
    )
  }

  return(map)
}

#' Clear all controls from a Mapbox GL or Maplibre GL map in a Shiny app
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#'
#' @return The modified map object with all controls removed.
#' @export
clear_controls <- function(map, controls = NULL) {
  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "clear_controls",
            controls = controls,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "clear_controls",
            controls = controls
          )
        )
      )
    }
  }
  return(map)
}

#' Add a scale control to a map
#'
#' This function adds a scale control to a Mapbox GL or Maplibre GL map.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param position The position of the control. Can be one of "top-left", "top-right", "bottom-left", or "bottom-right". Default is "bottom-left".
#' @param unit The unit of the scale. Can be either "imperial", "metric", or "nautical". Default is "metric".
#' @param max_width The maximum length of the scale control in pixels. Default is 100.
#'
#' @return The modified map object with the scale control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'     add_scale_control(position = "bottom-right", unit = "imperial")
#' }
add_scale_control <- function(
  map,
  position = "bottom-left",
  unit = "metric",
  max_width = 100
) {
  scale_control <- list(
    position = position,
    unit = unit,
    maxWidth = max_width
  )

  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_scale_control",
            options = scale_control,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(type = "add_scale_control", options = scale_control)
        )
      )
    }
  } else {
    if (is.null(map$x$scale_control)) {
      map$x$scale_control <- list()
    }
    map$x$scale_control <- scale_control
  }

  return(map)
}

#' Add a draw control to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param position A string specifying the position of the draw control.
#'        One of "top-right", "top-left", "bottom-right", or "bottom-left".
#' @param freehand Logical, whether to enable freehand drawing mode. Default is FALSE.
#' @param simplify_freehand Logical, whether to apply simplification to freehand drawings. Default is FALSE.
#' @param orientation A string specifying the orientation of the draw control.
#'        Either "vertical" (default) or "horizontal".
#' @param source A character string specifying a source ID to add to the draw control.
#'        Default is NULL.
#' @param point_color Color for point features. Default is "#3bb2d0" (light blue).
#' @param line_color Color for line features. Default is "#3bb2d0" (light blue).
#' @param fill_color Fill color for polygon features. Default is "#3bb2d0" (light blue).
#' @param fill_opacity Fill opacity for polygon features. Default is 0.1.
#' @param active_color Color for active (selected) features. Default is "#fbb03b" (orange).
#' @param vertex_radius Radius of vertex points in pixels. Default is 5.
#' @param line_width Width of lines in pixels. Default is 2.
#' @param download_button Logical, whether to add a download button to export drawn features as GeoJSON. Default is FALSE.
#' @param download_filename Base filename for downloaded GeoJSON (without extension). Default is "drawn-features".
#' @param ... Additional named arguments. See \url{https://github.com/mapbox/mapbox-gl-draw/blob/main/docs/API.md#options} for a list of options.
#'
#' @return The modified map object with the draw control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl(
#'     style = mapbox_style("streets"),
#'     center = c(-74.50, 40),
#'     zoom = 9
#' ) |>
#'     add_draw_control()
#'
#' # With initial features from a source
#' library(tigris)
#' tx <- counties(state = "TX", cb = TRUE)
#' mapboxgl(bounds = tx) |>
#'     add_source(id = "tx", data = tx) |>
#'     add_draw_control(source = "tx")
#'
#' # With custom styling
#' mapboxgl() |>
#'     add_draw_control(
#'         point_color = "#ff0000",
#'         line_color = "#00ff00",
#'         fill_color = "#0000ff",
#'         fill_opacity = 0.3,
#'         active_color = "#ff00ff",
#'         vertex_radius = 7,
#'         line_width = 3
#'     )
#' }
add_draw_control <- function(
  map,
  position = "top-left",
  freehand = FALSE,
  simplify_freehand = FALSE,
  orientation = "vertical",
  source = NULL,
  point_color = "#3bb2d0",
  line_color = "#3bb2d0",
  fill_color = "#3bb2d0",
  fill_opacity = 0.1,
  active_color = "#fbb03b",
  vertex_radius = 5,
  line_width = 2,
  download_button = FALSE,
  download_filename = "drawn-features",
  ...
) {
  # if (inherits(map, "maplibregl") || inherits(map, "maplibre_proxy")) {
  #   rlang::abort("The draw control is not yet supported for MapLibre maps.")
  # }

  options <- list(...)

  # Handle source if provided
  draw_source <- NULL
  if (!is.null(source)) {
    if (is.character(source) && length(source) == 1) {
      # It's a source ID to reference
      draw_source <- source
    } else {
      rlang::abort("source must be a character string referencing a source ID")
    }
  }

  map$x$draw_control <- list(
    enabled = TRUE,
    position = position,
    freehand = freehand,
    simplify_freehand = simplify_freehand,
    orientation = orientation,
    options = options,
    source = draw_source,
    download_button = download_button,
    download_filename = download_filename,
    styling = list(
      point_color = point_color,
      line_color = line_color,
      fill_color = fill_color,
      fill_opacity = fill_opacity,
      active_color = active_color,
      vertex_radius = vertex_radius,
      line_width = line_width
    )
  )

  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_draw_control",
            position = position,
            options = options,
            freehand = freehand,
            simplify_freehand = simplify_freehand,
            orientation = orientation,
            source = draw_source,
            download_button = download_button,
            download_filename = download_filename,
            styling = list(
              point_color = point_color,
              line_color = line_color,
              fill_color = fill_color,
              fill_opacity = fill_opacity,
              active_color = active_color,
              vertex_radius = vertex_radius,
              line_width = line_width
            ),
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_draw_control",
            position = position,
            options = options,
            freehand = freehand,
            simplify_freehand = simplify_freehand,
            orientation = orientation,
            source = draw_source,
            download_button = download_button,
            download_filename = download_filename,
            styling = list(
              point_color = point_color,
              line_color = line_color,
              fill_color = fill_color,
              fill_opacity = fill_opacity,
              active_color = active_color,
              vertex_radius = vertex_radius,
              line_width = line_width
            )
          )
        )
      )
    }
  }

  map
}

#' Get drawn features from the map
#'
#' @param map A map object created by the `mapboxgl` function, or a mapboxgl proxy.
#'
#' @return An sf object containing the drawn features.
#' @export
#'
#' @examples
#' \dontrun{
#' # In a Shiny application
#' library(shiny)
#' library(mapgl)
#'
#' ui <- fluidPage(
#'     mapboxglOutput("map"),
#'     actionButton("get_features", "Get Drawn Features"),
#'     verbatimTextOutput("feature_output")
#' )
#'
#' server <- function(input, output, session) {
#'     output$map <- renderMapboxgl({
#'         mapboxgl(
#'             style = mapbox_style("streets"),
#'             center = c(-74.50, 40),
#'             zoom = 9
#'         ) |>
#'             add_draw_control()
#'     })
#'
#'     observeEvent(input$get_features, {
#'         drawn_features <- get_drawn_features(mapboxgl_proxy("map"))
#'         output$feature_output <- renderPrint({
#'             print(drawn_features)
#'         })
#'     })
#' }
#'
#' shinyApp(ui, server)
#' }
get_drawn_features <- function(map) {
  if (
    !shiny::is.reactive(map) &&
      !inherits(
        map,
        c("mapboxgl", "mapboxgl_proxy", "maplibregl", "maplibre_proxy")
      )
  ) {
    stop(
      "Invalid map object. Expected mapboxgl, mapboxgl_proxy, maplibre or maplibre_proxy object within a Shiny context."
    )
  }

  # If map is reactive (e.g., output$map in Shiny), evaluate it
  if (shiny::is.reactive(map)) {
    map <- map()
  }

  # Determine if we're in a Shiny session
  in_shiny <- shiny::isRunning()

  if (!in_shiny) {
    warning(
      "Getting drawn features outside of a Shiny context is not supported. Please use this function within a Shiny application."
    )
    return(sf::st_sf(geometry = sf::st_sfc())) # Return an empty sf object
  }

  # Get the session object
  session <- shiny::getDefaultReactiveDomain()

  if (inherits(map, "mapboxgl") || inherits(map, "maplibregl")) {
    # Initial map object in Shiny
    map_id <- map$elementId
  } else if (
    inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")
  ) {
    # Proxy object
    map_id <- map$id
  } else {
    stop("Unexpected map object type.")
  }

  # Send message to get drawn features
  if (
    inherits(map, "mapboxgl_compare_proxy") ||
      inherits(map, "maplibre_compare_proxy")
  ) {
    # For compare proxies
    proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
      "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
    session$sendCustomMessage(
      proxy_class,
      list(
        id = map_id,
        message = list(
          type = "get_drawn_features",
          map = map$map_side
        )
      )
    )
  } else {
    # For regular proxies
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
      "maplibre-proxy"
    session$sendCustomMessage(
      proxy_class,
      list(
        id = map_id,
        message = list(type = "get_drawn_features")
      )
    )
  }

  # Trim any module namespacing off to index the session proxy inputs
  map_drawn_id <- sub(
    pattern = session$ns(""),
    replacement = "",
    x = paste0(map_id, "_drawn_features")
  )
  # Wait for response
  features_json <- NULL
  wait_time <- 0
  while (
    is.null(features_json) &&
      wait_time < 3
  ) {
    # Wait up to 3 seconds
    features_json <- session$input[[map_drawn_id]]
    Sys.sleep(0.1)
    wait_time <- wait_time + 0.1
  }

  if (
    !is.null(features_json) &&
      features_json != "null" &&
      nchar(features_json) > 0
  ) {
    sf::st_make_valid(sf::st_read(features_json, quiet = TRUE))
  } else {
    sf::st_sf(geometry = sf::st_sfc()) # Return an empty sf object if no features
  }
}

#' Add features to an existing draw control
#'
#' This function adds features from an existing source to a draw control on a map.
#'
#' @param map A map object with a draw control already added
#' @param source Character string specifying a source ID to get features from
#' @param clear_existing Logical, whether to clear existing drawn features before adding new ones. Default is FALSE.
#'
#' @return The modified map object
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(tigris)
#'
#' # Add features from an existing source
#' tx <- counties(state = "TX", cb = TRUE)
#' mapboxgl(bounds = tx) |>
#'   add_source(id = "tx", data = tx) |>
#'   add_draw_control() |>
#'   add_features_to_draw(source = "tx")
#'
#' # In a Shiny app
#' observeEvent(input$load_data, {
#'   mapboxgl_proxy("map") |>
#'     add_features_to_draw(
#'       source = "dynamic_data",
#'       clear_existing = TRUE
#'     )
#' })
#' }
add_features_to_draw <- function(map, source, clear_existing = FALSE) {
  # Validate source
  if (!is.character(source) || length(source) != 1) {
    rlang::abort("source must be a character string referencing a source ID")
  }

  # Prepare the data
  draw_data <- list(
    source = source,
    clear_existing = clear_existing
  )

  # Handle proxy vs initial map
  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_features_to_draw",
            data = draw_data,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_features_to_draw",
            data = draw_data
          )
        )
      )
    }
  } else {
    # For initial map, store in a queue
    if (is.null(map$x$draw_features_queue)) {
      map$x$draw_features_queue <- list()
    }
    map$x$draw_features_queue <- append(
      map$x$draw_features_queue,
      list(draw_data)
    )
  }

  return(map)
}

#' Clear all drawn features from a map
#'
#' This function removes all features that have been drawn using the draw control
#' on a Mapbox GL or MapLibre GL map in a Shiny application.
#'
#' @param map A proxy object created by the `mapboxgl_proxy` or `maplibre_proxy` functions.
#'
#' @return The modified map object with all drawn features cleared.
#' @export
#'
#' @examples
#' \dontrun{
#' # In a Shiny application
#' library(shiny)
#' library(mapgl)
#'
#' ui <- fluidPage(
#'     mapboxglOutput("map"),
#'     actionButton("clear_btn", "Clear Drawn Features")
#' )
#'
#' server <- function(input, output, session) {
#'     output$map <- renderMapboxgl({
#'         mapboxgl(
#'             style = mapbox_style("streets"),
#'             center = c(-74.50, 40),
#'             zoom = 9
#'         ) |>
#'             add_draw_control()
#'     })
#'
#'     observeEvent(input$clear_btn, {
#'         mapboxgl_proxy("map") |>
#'             clear_drawn_features()
#'     })
#' }
#'
#' shinyApp(ui, server)
#' }
clear_drawn_features <- function(map) {
  if (
    !any(
      inherits(map, "mapboxgl_proxy"),
      inherits(map, "maplibre_proxy")
    )
  ) {
    stop(
      "clear_drawn_features() can only be used with mapboxgl_proxy() or maplibre_proxy()"
    )
  }

  if (
    inherits(map, "mapboxgl_compare_proxy") ||
      inherits(map, "maplibre_compare_proxy")
  ) {
    # For compare proxies
    proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
      "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
    map$session$sendCustomMessage(
      proxy_class,
      list(
        id = map$id,
        message = list(
          type = "clear_drawn_features",
          map = map$map_side
        )
      )
    )
  } else {
    # For regular proxies
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
      "maplibre-proxy"
    map$session$sendCustomMessage(
      proxy_class,
      list(
        id = map$id,
        message = list(type = "clear_drawn_features")
      )
    )
  }

  return(map)
}

#' Add a geocoder control to a map
#'
#' This function adds a Geocoder search bar to a Mapbox GL or MapLibre GL map.
#' By default, a marker will be added at the selected location and the map will
#' fly to that location.  The results of the geocode are accessible in a Shiny
#' session at `input$MAPID_geocoder$result`, where `MAPID` is the name of your map.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param position The position of the control. Can be one of "top-left", "top-right", "bottom-left", or "bottom-right". Default is "top-right".
#' @param placeholder A string to use as placeholder text for the search bar. Default is "Search".
#' @param collapsed Whether the control should be collapsed until hovered or clicked. Default is FALSE.
#' @param provider The geocoding provider to use for MapLibre maps. Either "osm" for OpenStreetMap/Nominatim or "maptiler" for MapTiler geocoding. If NULL (default), MapLibre maps will use "osm". Mapbox maps will always use the Mapbox geocoder, regardless of this parameter.
#' @param maptiler_api_key Your MapTiler API key (required when provider is "maptiler" for MapLibre maps). Can also be set with `MAPTILER_API_KEY` environment variable. Mapbox maps will always use the Mapbox API key set at the map level.
#' @param ... Additional parameters to pass to the Geocoder.
#'
#' @return The modified map object with the geocoder control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'     add_geocoder_control(position = "top-left", placeholder = "Enter an address")
#'
#' maplibre() |>
#'     add_geocoder_control(position = "top-right", placeholder = "Search location")
#'
#' # Using MapTiler geocoder
#' maplibre() |>
#'     add_geocoder_control(provider = "maptiler", maptiler_api_key = "YOUR_API_KEY")
#' }
add_geocoder_control <- function(
  map,
  position = "top-right",
  placeholder = "Search",
  collapsed = FALSE,
  provider = NULL,
  maptiler_api_key = NULL,
  ...
) {
  # Set default provider for MapLibre if NULL
  if (
    is.null(provider) &&
      (inherits(map, "maplibre") ||
        inherits(map, "maplibre_proxy") ||
        inherits(map, "maplibre_compare_proxy"))
  ) {
    provider <- "osm"
  }

  # Validate provider parameter for MapLibre
  if (!is.null(provider) && !provider %in% c("osm", "maptiler")) {
    rlang::abort("Provider must be either 'osm' or 'maptiler'")
  }

  # Check that provider parameter is only used with MapLibre
  if (
    !is.null(provider) &&
      (inherits(map, "mapboxgl") ||
        inherits(map, "mapboxgl_proxy") ||
        inherits(map, "mapboxgl_compare_proxy"))
  ) {
    rlang::abort(
      "The provider parameter is only available for MapLibre GL maps. Mapbox maps will always use the Mapbox geocoder."
    )
  }

  # Handle MapTiler API key
  if (!is.null(provider) && provider == "maptiler") {
    if (is.null(maptiler_api_key)) {
      if (Sys.getenv("MAPTILER_API_KEY") == "") {
        rlang::abort(
          "A MapTiler API key is required for the MapTiler geocoder. Get one at https://www.maptiler.com, then supply it here or set it in your .Renviron file with 'MAPTILER_API_KEY'='YOUR_KEY_HERE'."
        )
      }
      maptiler_api_key <- Sys.getenv("MAPTILER_API_KEY")
    }
  }

  geocoder_options <- list(
    position = position,
    placeholder = placeholder,
    collapsed = collapsed,
    provider = provider,
    api_key = maptiler_api_key,
    ...
  )

  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_geocoder_control",
            options = geocoder_options,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_geocoder_control",
            options = geocoder_options
          )
        )
      )
    }
  } else {
    if (is.null(map$x$geocoder_control)) {
      map$x$geocoder_control <- list()
    }
    map$x$geocoder_control <- geocoder_options
  }

  return(map)
}

#' Add a reset control to a map
#'
#' This function adds a reset control to a Mapbox GL or MapLibre GL map.
#' The reset control allows users to return to the original zoom level and center.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param position The position of the control. Can be one of "top-left", "top-right", "bottom-left", or "bottom-right". Default is "top-right".
#' @param animate Whether or not to animate the transition to the original map view; defaults to `TRUE`.  If `FALSE`, the view will "jump" to the original view with no transition.
#' @param duration The length of the transition from the current view to the original view, specified in milliseconds.  This argument only works with `animate` is `TRUE`.
#'
#' @return The modified map object with the reset control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'     add_reset_control(position = "top-left")
#' }
add_reset_control <- function(
  map,
  position = "top-right",
  animate = TRUE,
  duration = NULL
) {
  reset_control <- list(position = position, animate = animate)

  if (!is.null(duration)) {
    if (!animate) {
      rlang::warn("duration is ignored when `animate` is `FALSE`.")
    }
    reset_control$duration <- duration
  }

  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_reset_control",
            options = reset_control,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(type = "add_reset_control", options = reset_control)
        )
      )
    }
  } else {
    map$x$reset_control <- reset_control
  }

  return(map)
}

#' Add a geolocate control to a map
#'
#' This function adds a Geolocate control to a Mapbox GL or MapLibre GL map.
#' The geolocate control allows users to track their current location on the map.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param position The position of the control. Can be one of "top-left", "top-right",
#'   "bottom-left", or "bottom-right". Default is "top-right".
#' @param track_user Whether to actively track the user's location. If TRUE, the map will
#'   continuously update as the user moves. Default is FALSE.
#' @param show_accuracy_circle Whether to show a circle indicating the accuracy of the
#'   location. Default is TRUE.
#' @param show_user_location Whether to show a dot at the user's location. Default is TRUE.
#' @param show_user_heading Whether to show an arrow indicating the device's heading when
#'   tracking location. Only works when track_user is TRUE. Default is FALSE.
#' @param fit_bounds_options A list of options for fitting bounds when panning to the
#'   user's location. Default maxZoom is 15.
#' @param position_options A list of Geolocation API position options. Default has
#'   enableHighAccuracy=FALSE and timeout=6000.
#'
#' @return The modified map object with the geolocate control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'     add_geolocate_control(
#'         position = "top-right",
#'         track_user = TRUE,
#'         show_user_heading = TRUE
#'     )
#' }
add_geolocate_control <- function(
  map,
  position = "top-right",
  track_user = FALSE,
  show_accuracy_circle = TRUE,
  show_user_location = TRUE,
  show_user_heading = FALSE,
  fit_bounds_options = list(maxZoom = 15),
  position_options = list(
    enableHighAccuracy = FALSE,
    timeout = 6000
  )
) {
  geolocate_control <- list(
    position = position,
    trackUserLocation = track_user,
    showAccuracyCircle = show_accuracy_circle,
    showUserLocation = show_user_location,
    showUserHeading = show_user_heading,
    fitBoundsOptions = fit_bounds_options,
    positionOptions = position_options
  )

  if (
    inherits(map, "mapboxgl_proxy") ||
      inherits(map, "maplibre_proxy")
  ) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_geolocate_control",
            options = geolocate_control,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_geolocate_control",
            options = geolocate_control
          )
        )
      )
    }
  } else {
    if (is.null(map$x$geolocate_control)) {
      map$x$geolocate_control <- list()
    }
    map$x$geolocate_control <- geolocate_control
  }

  return(map)
}

#' Add a globe control to a map
#'
#' This function adds a globe control to a MapLibre GL map that allows toggling
#' between "mercator" and "globe" projections with a single click.
#'
#' @param map A map object created by the `maplibre` function.
#' @param position The position of the control. Can be one of "top-left", "top-right",
#'   "bottom-left", or "bottom-right". Default is "top-right".
#'
#' @return The modified map object with the globe control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' maplibre() |>
#'     add_globe_control(position = "top-right")
#' }
add_globe_control <- function(map, position = "top-right") {
  globe_control <- list(
    position = position
  )

  if (inherits(map, "mapboxgl") || inherits(map, "mapboxgl_proxy")) {
    warning(
      "The globe control is only available for MapLibre maps, not Mapbox GL maps."
    )
    return(map)
  }

  if (inherits(map, "maplibre_proxy")) {
    if (inherits(map, "maplibre_compare_proxy")) {
      # For compare proxies
      map$session$sendCustomMessage(
        "maplibre-compare-proxy",
        list(
          id = map$id,
          message = list(
            type = "add_globe_control",
            position = position,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      map$session$sendCustomMessage(
        "maplibre-proxy",
        list(
          id = map$id,
          message = list(
            type = "add_globe_control",
            position = position
          )
        )
      )
    }
  } else {
    if (is.null(map$x$globe_control)) {
      map$x$globe_control <- list()
    }
    map$x$globe_control <- globe_control
  }

  return(map)
}

#' Add a custom control to a map
#'
#' This function adds a custom control to a Mapbox GL or MapLibre GL map.
#' It allows you to create custom HTML element controls and add them to the map.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param html Character string containing the HTML content for the control.
#' @param position The position of the control. Can be one of "top-left", "top-right",
#'   "bottom-left", or "bottom-right". Default is "top-right".
#' @param className Optional CSS class name for the control container.
#' @param ... Additional arguments passed to the JavaScript side.
#'
#' @return The modified map object with the custom control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' maplibre() |>
#'   add_control(
#'     html = "<div style='background-color: white; padding: 5px;'>
#'              <p>Custom HTML</p>
#'              <img src='path/to/image.png' alt='image'/>
#'             </div>",
#'     position = "top-left"
#'   )
#' }
add_control <- function(
  map,
  html,
  position = "top-right",
  className = NULL,
  id = NULL,
  ...
) {
  # Set control ID - user-provided or default to "custom"
  control_id <- if (!is.null(id)) {
    id
  } else {
    "custom"
  }

  # Create options list
  control_options <- list(
    html = html,
    position = position
  )

  # Add className if provided
  if (!is.null(className)) {
    control_options$className <- className
  }

  # Add any additional parameters
  control_options <- c(control_options, list(...))

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_custom_control",
            control_id = control_id,
            options = control_options,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_custom_control",
            control_id = control_id,
            options = control_options
          )
        )
      )
    }
  } else {
    # For initial map creation
    if (is.null(map$x$custom_controls)) {
      map$x$custom_controls <- list()
    }

    map$x$custom_controls[[control_id]] <- control_options
  }

  return(map)
}
