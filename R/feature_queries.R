

query_bbox_features <- function(map) {

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
