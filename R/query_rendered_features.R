#' Query rendered features on a map in a Shiny session
#'
#' This function queries features that are currently rendered (visible) in the map viewport.
#' Only features within the current viewport bounds will be returned - features outside the 
#' visible area or hidden due to zoom constraints will not be included. Use `get_queried_features()` 
#' to retrieve the results as an sf object, or use the `callback` parameter to handle results 
#' automatically when they're ready.
#'
#' @param proxy A MapboxGL or Maplibre proxy object, defined with `mapboxgl_proxy()`, `maplibre_proxy()`, 
#'   `mapboxgl_compare_proxy()`, or `maplibre_compare_proxy()`
#' @param geometry The geometry to query. Can be:
#'   - `NULL` (default): Query the entire viewport
#'   - A length-2 vector `c(x, y)`: Query at a single point in pixel coordinates
#'   - A length-4 vector `c(xmin, ymin, xmax, ymax)`: Query within a bounding box in pixel coordinates
#' @param layer_id A character vector of layer names to include in the query. 
#'   Can be a single layer name or multiple layer names. If `NULL` (default), all layers are queried.
#' @param filter A filter expression used to filter features in the query. Should be a list
#'   representing a Mapbox GL expression. Using this parameter applies the filter during the
#'   query WITHOUT changing the map display, avoiding race conditions. If you've called
#'   `set_filter()` separately, you must pass the same filter here to get aligned results.
#' @param callback A function to execute when results are ready. The function will receive the sf object as its argument.
#'   If provided, this avoids timing issues by automatically handling results when they're available.
#'
#' @details
#' ## Viewport Limitation
#' 
#' This function only queries features that are currently rendered in the map viewport. Features
#' outside the visible area will not be returned, even if they exist in the data source. This 
#' includes features that are:
#' - Outside the current map bounds
#' - Hidden due to zoom level constraints (minzoom/maxzoom)
#' - Not yet loaded (if using vector tiles)
#' 
#' ## Avoiding Race Conditions
#'
#' **IMPORTANT**: `set_filter()` is asynchronous while `query_rendered_features()` is synchronous.
#' Calling `query_rendered_features()` immediately after `set_filter()` will return features from the
#' PREVIOUS filter state, not the new one.
#'
#' ### Safe Usage Patterns:
#'
#' **Pattern 1: Query First, Then Filter (Recommended)**
#' ```r
#' query_rendered_features(proxy, layer_id = "counties", callback = function(features) {
#'   # Process features, then update map based on results
#'   proxy |> set_filter("highlight", list("in", "id", features$id))
#' })
#' ```
#'
#' **Pattern 2: Use Filter Parameter Instead**
#' ```r
#' # Query with filter without changing map display
#' query_rendered_features(proxy, filter = list(">=", "population", 1000),
#'                          callback = function(features) {
#'   # Process filtered results without race condition
#' })
#' ```
#'
#' ### What NOT to Do:
#' ```r
#' # WRONG - This will return stale results!
#' proxy |> set_filter("layer", new_filter)
#' query_rendered_features(proxy, layer_id = "layer")  # Gets OLD filter results
#' ```
#'
#' @return The proxy object (invisibly). Use `get_queried_features()` to retrieve the query results manually,
#'   or provide a `callback` function to handle results automatically.
#' @export
#'
#' @examples
#' \dontrun{
#' # Pattern 1: Query first, then filter (RECOMMENDED)
#' proxy <- maplibre_proxy("map")
#' query_rendered_features(proxy, layer_id = "counties", callback = function(features) {
#'   if (nrow(features) > 0) {
#'     # Filter map based on query results - no race condition
#'     proxy |> set_filter("selected", list("in", "id", features$id))
#'   }
#' })
#'
#' # Pattern 2: Use filter parameter to avoid race conditions
#' query_rendered_features(proxy,
#'                         filter = list(">=", "population", 50000),
#'                         callback = function(features) {
#'   # These results are guaranteed to match the filter
#'   print(paste("Found", nrow(features), "high population areas"))
#' })
#'
#' # Query specific bounding box with callback
#' query_rendered_features(proxy, geometry = c(100, 100, 200, 200),
#'                         layer_id = "counties", callback = function(features) {
#'   print(paste("Found", nrow(features), "features"))
#' })
#'
#' # ANTI-PATTERN - Don't do this!
#' # proxy |> set_filter("layer", new_filter)
#' # query_rendered_features(proxy, layer_id = "layer")  # Will get stale results!
#' }
query_rendered_features <- function(
  proxy,
  geometry = NULL,
  layer_id = NULL,
  filter = NULL,
  callback = NULL
) {
  if (
    !any(
      inherits(proxy, "mapboxgl_proxy"), 
      inherits(proxy, "maplibre_proxy"),
      inherits(proxy, "mapboxgl_compare_proxy"), 
      inherits(proxy, "maplibre_compare_proxy")
    )
  ) {
    stop("Invalid proxy object")
  }

  # Validate geometry parameter
  if (!is.null(geometry)) {
    if (!is.numeric(geometry)) {
      stop("geometry must be NULL or a numeric vector")
    }
    if (length(geometry) == 2) {
      # Point query: c(x, y)
      geometry <- as.list(geometry)
    } else if (length(geometry) == 4) {
      # Bounding box: c(xmin, ymin, xmax, ymax) -> [[xmin, ymin], [xmax, ymax]]
      geometry <- list(
        c(geometry[1], geometry[2]), # bottom-left
        c(geometry[3], geometry[4]) # top-right
      )
    } else {
      stop(
        "geometry must be either length 2 (point) or length 4 (bounding box)"
      )
    }
  }

  # Store callback if provided
  if (!is.null(callback)) {
    if (!is.function(callback)) {
      stop("callback must be a function")
    }

    # Store callback in session userData with unique ID
    callback_id <- paste0(
      proxy$id,
      "_query_callback_",
      as.numeric(Sys.time()) * 1000
    )
    proxy$session$userData[[callback_id]] <- callback

    # Set up observer to handle callback when results are ready
    callback_observer <- shiny::observeEvent(
      proxy$session$input[[paste0(proxy$id, "_queried_features")]],
      {
        features_json <- proxy$session$input[[paste0(
          proxy$id,
          "_queried_features"
        )]]
        if (
          !is.null(features_json) &&
            features_json != "null" &&
            nchar(features_json) > 0
        ) {
          features <- sf::st_make_valid(sf::st_read(
            features_json,
            quiet = TRUE
          ))
          # Execute callback
          callback(features)
        }
        # Clean up
        proxy$session$userData[[callback_id]] <- NULL
        callback_observer$destroy()
      },
      once = TRUE,
      ignoreInit = TRUE
    )
  }

  if (
    inherits(proxy, "mapboxgl_compare_proxy") ||
      inherits(proxy, "maplibre_compare_proxy")
  ) {
    # For compare proxies
    proxy_class <- if (inherits(proxy, "mapboxgl_compare_proxy"))
      "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
    proxy$session$sendCustomMessage(
      proxy_class,
      list(
        id = proxy$id,
        message = list(
          type = "query_rendered_features",
          geometry = geometry,
          layers = if (is.null(layer_id)) NULL else as.list(layer_id),
          filter = filter,
          map = proxy$map_side
        )
      )
    )
  } else {
    # For regular proxies
    proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) "mapboxgl-proxy" else
      "maplibre-proxy"
    proxy$session$sendCustomMessage(
      proxy_class,
      list(
        id = proxy$id,
        message = list(
          type = "query_rendered_features",
          geometry = geometry,
          layers = if (is.null(layer_id)) NULL else as.list(layer_id),
          filter = filter
        )
      )
    )
  }

  invisible(proxy)
}

#' Get queried features from a map as an sf object
#'
#' This function retrieves the results of a feature query triggered by `query_rendered_features()`.
#' It returns the features as a deduplicated sf object. Note that only features that were
#' visible in the viewport at the time of the query will be included.
#'
#' @param map A map object (mapboxgl, maplibre) or proxy object (mapboxgl_proxy, maplibre_proxy, 
#'   mapboxgl_compare_proxy, maplibre_compare_proxy)
#'
#' @return An sf object containing the queried features, or an empty sf object if no features were found
#' @export
#'
#' @examples
#' \dontrun{
#' # In a Shiny server function:
#' observeEvent(input$query_button, {
#'     proxy <- maplibre_proxy("map")
#'     query_rendered_features(proxy, layer_id = "counties")
#'     features <- get_queried_features(proxy)
#'     print(nrow(features))
#' })
#' }
get_queried_features <- function(map) {
  if (
    !shiny::is.reactive(map) &&
      !inherits(
        map,
        c("mapboxgl", "mapboxgl_proxy", "maplibregl", "maplibre_proxy",
          "mapboxgl_compare_proxy", "maplibre_compare_proxy")
      )
  ) {
    stop(
      "Invalid map object. Expected mapboxgl, mapboxgl_proxy, maplibre, maplibre_proxy, mapboxgl_compare_proxy, or maplibre_compare_proxy object within a Shiny context."
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
      "Getting queried features outside of a Shiny context is not supported. Please use this function within a Shiny application."
    )
    return(sf::st_sf(geometry = sf::st_sfc())) # Return an empty sf object
  }

  # Get the session object
  session <- shiny::getDefaultReactiveDomain()

  if (inherits(map, "mapboxgl") || inherits(map, "maplibregl")) {
    # Initial map object in Shiny
    map_id <- map$elementId
  } else if (
    inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy") ||
    inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")
  ) {
    # Proxy object (including compare proxies)
    map_id <- map$id
  } else {
    stop("Unexpected map object type.")
  }

  # Trim any module namespacing off to index the session proxy inputs
  map_queried_id <- sub(
    pattern = session$ns(""),
    replacement = "",
    x = paste0(map_id, "_queried_features")
  )

  # Wait for response
  features_json <- NULL
  wait_time <- 0
  while (
    is.null(features_json) &&
      wait_time < 3
  ) {
    # Wait up to 3 seconds
    features_json <- session$input[[map_queried_id]]
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
