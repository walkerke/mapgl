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
#' maplibre(style = maptiler_style("streets"),
#'          center = c(11.255, 43.77),
#'          zoom = 13) |>
#'   add_fullscreen_control(position = "top-right")
#' }
add_fullscreen_control <- function(map, position = "top-right") {
  map$x$fullscreen_control <- list(
    enabled = TRUE,
    position = position
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {

    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "add_fullscreen_control",
        position = position
      )
    ))
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
#'
#' @return The updated map object with the navigation control added.
#' @export
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'   add_navigation_control(visualize_pitch = TRUE)
#' }
add_navigation_control <- function(map, show_compass = TRUE, show_zoom = TRUE, visualize_pitch = FALSE, position = "top-right") {
  nav_control <- list(
    show_compass = show_compass,
    show_zoom = show_zoom,
    visualize_pitch = visualize_pitch,
    position = position
  )

  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {

    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"

    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_navigation_control", options = nav_control, position = position)))
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
#' @param layers A vector of layer IDs to be included in the control. If NULL, all layers will be included.
#' @param collapsible Whether the control should be collapsible.
#'
#' @return The modified map object with the layers control added.
#' @export
#' @examples \dontrun{
#' library(tigris)
#' options(tigris_use_cache = TRUE)
#'
#' rds <- roads("TX", "Tarrant")
#' tr <- tracts("TX", "Tarrant", cb = TRUE)
#'
#' maplibre() |>
#'   fit_bounds(rds) |>
#'   add_fill_layer(
#'     id = "Census tracts",
#'     source = tr,
#'     fill_color = "purple",
#'     fill_opacity = 0.6
#'   ) |>
#'   add_line_layer(
#'     "Local roads",
#'     source = rds,
#'     line_color = "pink"
#'   ) |>
#'   add_layers_control(collapsible = TRUE)
#'
#' }
add_layers_control <- function(map, position = "top-left", layers = NULL, collapsible = FALSE) {
  control_id <- paste0("layers-control-", as.hexmode(sample(1:1000000, 1)))

  # Create the control container
  control_html <- paste0('<nav id="', control_id, '" class="layers-control', ifelse(collapsible, ' collapsible', ''), '" style="', position, ': 10px;"></nav>')

  # If layers is NULL, get the layers added by the user
  if (is.null(layers)) {
    layers <- unlist(
      lapply(map$x$layers, function(y) {
        y$id
      })
    )
  }

  # Add control to map
  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "add_layers_control", control_id = control_id, position = position, layers = layers, collapsible = collapsible)
    ))

  } else {
    map$x$layers_control <- list(control_id = control_id, position = position, layers = layers, collapsible = collapsible)
    map$x$control_html <- control_html
  }

  return(map)
}

#' Clear all controls from a Mapbox GL or Maplibre GL map in a Shiny app
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#'
#' @return The modified map object with all controls removed.
#' @export
clear_controls <- function(map) {
  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "clear_controls")))
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
#'   add_scale_control(position = "bottom-right", unit = "imperial")
#' }
add_scale_control <- function(map, position = "bottom-left", unit = "metric", max_width = 100) {
  scale_control <- list(
    position = position,
    unit = unit,
    maxWidth = max_width
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "add_scale_control", options = scale_control)
    ))
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
#' @param ... Additional named arguments. See \url{https://github.com/mapbox/mapbox-gl-draw/blob/main/docs/API.md#options} for a list of options.
#'
#' @return The modified map object with the draw control added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl(style = mapbox_style("streets"),
#'          center = c(-74.50, 40),
#'          zoom = 9) |>
#'   add_draw_control(position = "top-left", freehand = TRUE)
#' }
add_draw_control <- function(map, position = "top-left", freehand = FALSE, ...) {
  # if (inherits(map, "maplibregl") || inherits(map, "maplibre_proxy")) {
  #   rlang::abort("The draw control is not yet supported for MapLibre maps.")
  # }

  options <- list(...)

  map$x$draw_control <- list(
    enabled = TRUE,
    position = position,
    freehand = freehand,
    options = options
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "add_draw_control",
        position = position,
        options = options,
        freehand = freehand
      )
    ))
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
#' library(mapboxer)
#'
#' ui <- fluidPage(
#'   mapboxglOutput("map"),
#'   actionButton("get_features", "Get Drawn Features"),
#'   verbatimTextOutput("feature_output")
#' )
#'
#' server <- function(input, output, session) {
#'   output$map <- renderMapboxgl({
#'     mapboxgl(style = mapbox_style("streets-v12"),
#'              center = c(-74.50, 40),
#'              zoom = 9) |>
#'       add_draw_control()
#'   })
#'
#'   observeEvent(input$get_features, {
#'     drawn_features <- get_drawn_features(mapboxgl_proxy("map"))
#'     output$feature_output <- renderPrint({
#'       print(drawn_features)
#'     })
#'   })
#' }
#'
#' shinyApp(ui, server)
#' }
get_drawn_features <- function(map) {
  if (!shiny::is.reactive(map) && !inherits(map, c("mapboxgl", "mapboxgl_proxy"))) {
    stop("Invalid map object. Expected mapboxgl or mapboxgl_proxy object within a Shiny context.")
  }

  # If map is reactive (e.g., output$map in Shiny), evaluate it
  if (shiny::is.reactive(map)) {
    map <- map()
  }

  # Determine if we're in a Shiny session
  in_shiny <- shiny::isRunning()

  if (!in_shiny) {
    warning("Getting drawn features outside of a Shiny context is not supported. Please use this function within a Shiny application.")
    return(sf::st_sf(geometry = sf::st_sfc()))  # Return an empty sf object
  }

  # Get the session object
  session <- shiny::getDefaultReactiveDomain()

  if (inherits(map, "mapboxgl")) {
    # Initial map object in Shiny
    map_id <- map$elementId
  } else if (inherits(map, "mapboxgl_proxy")) {
    # Proxy object
    map_id <- map$id
  } else {
    stop("Unexpected map object type.")
  }

  # Send message to get drawn features
  session$sendCustomMessage("mapboxgl-proxy", list(
    id = map_id,
    message = list(
      type = "get_drawn_features"
    )
  ))

  # Wait for response
  features_json <- NULL
  wait_time <- 0
  while(is.null(features_json) && wait_time < 3) {  # Wait up to 3 seconds
    features_json <- session$input[[paste0(map_id, '_drawn_features')]]
    Sys.sleep(0.1)
    wait_time <- wait_time + 0.1
  }

  if (!is.null(features_json) && features_json != "null" && nchar(features_json) > 0) {
    sf::st_read(features_json, quiet = TRUE)
  } else {
    sf::st_sf(geometry = sf::st_sfc())  # Return an empty sf object if no features
  }
}
