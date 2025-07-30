#' Turf.js Geospatial Operations for mapgl
#'
#' This module provides client-side geospatial operations using the turf.js library.
#' All operations work with both mapboxgl and maplibre proxies.

#' Create a buffer around geometries
#'
#' This function creates a buffer around geometries at a specified distance.
#' The operation is performed client-side using turf.js. The result is added as a 
#' source to the map, which can then be styled using add_fill_layer(), add_line_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of an existing layer to buffer (mutually exclusive with data and coordinates).
#' @param data An sf object to buffer (mutually exclusive with layer_id and coordinates).
#' @param coordinates A numeric vector of length 2 with lng/lat coordinates to create a point and buffer (mutually exclusive with layer_id and data).
#' @param radius The buffer distance.
#' @param units The units for the buffer distance. One of "meters", "kilometers", "miles", "feet", "inches", "yards", "centimeters", "millimeters", "degrees", "radians".
#' @param source_id The ID for the new source containing the buffered results. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
#'
#' @examples
#' \dontrun{
#' # Buffer existing layer
#' map |>
#'   turf_buffer(layer_id = "points", radius = 1000, units = "meters", 
#'               source_id = "point_buffers") |>
#'   add_fill_layer(id = "buffers", source = "point_buffers", fill_color = "blue")
#'
#' # Buffer sf object
#' map |>
#'   turf_buffer(data = sf_points, radius = 0.5, units = "miles", 
#'               source_id = "buffers") |>
#'   add_fill_layer(id = "buffer_layer", source = "buffers")
#'
#' # Buffer coordinates (great for hover events)
#' maplibre_proxy("map") |>
#'   turf_buffer(coordinates = c(-122.4, 37.7), radius = 500, units = "meters",
#'               source_id = "hover_buffer")
#' }
turf_buffer <- function(map, layer_id = NULL, data = NULL, coordinates = NULL,
                        radius, units = "meters", source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data), !is.null(coordinates))
  if (input_count != 1) {
    stop("Exactly one of layer_id, data, or coordinates must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Validate coordinates
  if (!is.null(coordinates)) {
    if (!is.numeric(coordinates) || length(coordinates) != 2) {
      stop("coordinates must be a numeric vector of length 2 (lng, lat).")
    }
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_buffer",
        layer_id = layer_id,
        data = geojson_data,
        coordinates = coordinates,
        radius = radius,
        units = units,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_buffer",
      layer_id = layer_id,
      data = geojson_data,
      coordinates = coordinates,
      radius = radius,
      units = units,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_buffer can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Union geometries
#'
#' This function unions all polygons in a layer into a single geometry.
#' The result is added as a source to the map, which can then be styled using add_fill_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of an existing layer to union (mutually exclusive with data).
#' @param data An sf object to union (mutually exclusive with layer_id).
#' @param source_id The ID for the new source containing the union result. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_union <- function(map, layer_id = NULL, data = NULL, source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data))
  if (input_count != 1) {
    stop("Exactly one of layer_id or data must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_union",
        layer_id = layer_id,
        data = geojson_data,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_union",
      layer_id = layer_id,
      data = geojson_data,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_union can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Find intersection of two geometries
#'
#' This function finds the intersection between geometries in two layers.
#' The result is added as a source to the map, which can then be styled using add_fill_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of the first layer (mutually exclusive with data).
#' @param layer_id_2 The ID of the second layer.
#' @param data An sf object for the first geometry (mutually exclusive with layer_id).
#' @param source_id The ID for the new source containing the intersection result. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_intersect <- function(map, layer_id = NULL, layer_id_2, data = NULL, source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data))
  if (input_count != 1) {
    stop("Exactly one of layer_id or data must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_intersect",
        layer_id = layer_id,
        layer_id_2 = layer_id_2,
        data = geojson_data,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_intersect",
      layer_id = layer_id,
      layer_id_2 = layer_id_2,
      data = geojson_data,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_intersect can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Find difference between two geometries
#'
#' This function subtracts the second geometry from the first.
#' The result is added as a source to the map, which can then be styled using add_fill_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of the first layer (geometry to subtract from, mutually exclusive with data).
#' @param layer_id_2 The ID of the second layer (geometry to subtract).
#' @param data An sf object for the first geometry (mutually exclusive with layer_id).
#' @param source_id The ID for the new source containing the difference result. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_difference <- function(map, layer_id = NULL, layer_id_2, data = NULL, source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data))
  if (input_count != 1) {
    stop("Exactly one of layer_id or data must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_difference",
        layer_id = layer_id,
        layer_id_2 = layer_id_2,
        data = geojson_data,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_difference",
      layer_id = layer_id,
      layer_id_2 = layer_id_2,
      data = geojson_data,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_difference can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Create convex hull
#'
#' This function creates a convex hull around a set of points.
#' The result is added as a source to the map, which can then be styled using add_fill_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of an existing layer containing points (mutually exclusive with data and coordinates).
#' @param data An sf object containing points (mutually exclusive with layer_id and coordinates).
#' @param coordinates A list/matrix of coordinate pairs [[lng,lat], [lng,lat], ...] for multiple points (mutually exclusive with layer_id and data).
#' @param source_id The ID for the new source containing the convex hull. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_convex_hull <- function(map, layer_id = NULL, data = NULL, coordinates = NULL,
                             source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data), !is.null(coordinates))
  if (input_count != 1) {
    stop("Exactly one of layer_id, data, or coordinates must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Validate coordinates
  if (!is.null(coordinates)) {
    if (!is.list(coordinates) && !is.matrix(coordinates)) {
      stop("coordinates must be a list or matrix of coordinate pairs.")
    }
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_convex_hull",
        layer_id = layer_id,
        data = geojson_data,
        coordinates = coordinates,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_convex_hull",
      layer_id = layer_id,
      data = geojson_data,
      coordinates = coordinates,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_convex_hull can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Create concave hull
#'
#' This function creates a concave hull around a set of points.
#' The result is added as a source to the map, which can then be styled using add_fill_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of an existing layer containing points (mutually exclusive with data and coordinates).
#' @param data An sf object containing points (mutually exclusive with layer_id and coordinates).
#' @param coordinates A list/matrix of coordinate pairs [[lng,lat], [lng,lat], ...] for multiple points (mutually exclusive with layer_id and data).
#' @param max_edge The maximum edge length for the concave hull. Default is Infinity (convex hull).
#' @param units The units for max_edge. One of "meters", "kilometers", "miles", etc.
#' @param source_id The ID for the new source containing the concave hull. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_concave_hull <- function(map, layer_id = NULL, data = NULL, coordinates = NULL,
                              max_edge = NULL, units = "kilometers", source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data), !is.null(coordinates))
  if (input_count != 1) {
    stop("Exactly one of layer_id, data, or coordinates must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Validate coordinates
  if (!is.null(coordinates)) {
    if (!is.list(coordinates) && !is.matrix(coordinates)) {
      stop("coordinates must be a list or matrix of coordinate pairs.")
    }
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_concave_hull",
        layer_id = layer_id,
        data = geojson_data,
        coordinates = coordinates,
        max_edge = max_edge,
        units = units,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_concave_hull",
      layer_id = layer_id,
      data = geojson_data,
      coordinates = coordinates,
      max_edge = max_edge,
      units = units,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_concave_hull can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Create Voronoi diagram
#'
#' This function creates a Voronoi diagram from a set of points.
#' The result is added as a source to the map, which can then be styled using add_fill_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of an existing layer containing points (mutually exclusive with data and coordinates).
#' @param data An sf object containing points (mutually exclusive with layer_id and coordinates).
#' @param coordinates A list/matrix of coordinate pairs [[lng,lat], [lng,lat], ...] for multiple points (mutually exclusive with layer_id and data).
#' @param bbox Optional. A vector of four numbers representing the bounding box [minX, minY, maxX, maxY].
#' @param source_id The ID for the new source containing the Voronoi diagram. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_voronoi <- function(map, layer_id = NULL, data = NULL, coordinates = NULL,
                         bbox = NULL, source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data), !is.null(coordinates))
  if (input_count != 1) {
    stop("Exactly one of layer_id, data, or coordinates must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Validate coordinates
  if (!is.null(coordinates)) {
    if (!is.list(coordinates) && !is.matrix(coordinates)) {
      stop("coordinates must be a list or matrix of coordinate pairs.")
    }
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_voronoi",
        layer_id = layer_id,
        data = geojson_data,
        coordinates = coordinates,
        bbox = bbox,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_voronoi",
      layer_id = layer_id,
      data = geojson_data,
      coordinates = coordinates,
      bbox = bbox,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_voronoi can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Calculate distance between two features
#'
#' This function calculates the distance between the first features of two layers or coordinates.
#' Note: This function only works with proxy objects as it returns a numeric value to R.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the first layer (mutually exclusive with data and coordinates).
#' @param layer_id_2 The ID of the second layer (required if layer_id is used).
#' @param data An sf object for the first geometry (mutually exclusive with layer_id and coordinates).
#' @param coordinates A numeric vector of length 2 with lng/lat coordinates for the first point (mutually exclusive with layer_id and data).
#' @param coordinates_2 A numeric vector of length 2 with lng/lat coordinates for the second point (required if coordinates is used).
#' @param units The units for the distance calculation. One of "meters", "kilometers", "miles", etc.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result. Default is TRUE.
#'
#' @return The proxy object for method chaining.
#' @export
turf_distance <- function(proxy, layer_id = NULL, layer_id_2 = NULL, data = NULL,
                          coordinates = NULL, coordinates_2 = NULL, units = "kilometers",
                          send_to_r = TRUE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_distance can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data), !is.null(coordinates))
  if (input_count != 1) {
    stop("Exactly one of layer_id, data, or coordinates must be provided.")
  }
  
  # Validate second geometry inputs
  if (!is.null(layer_id) && is.null(layer_id_2)) {
    stop("layer_id_2 is required when layer_id is provided.")
  }
  
  if (!is.null(coordinates) && is.null(coordinates_2)) {
    stop("coordinates_2 is required when coordinates is provided.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Validate coordinates
  if (!is.null(coordinates)) {
    if (!is.numeric(coordinates) || length(coordinates) != 2) {
      stop("coordinates must be a numeric vector of length 2 (lng, lat).")
    }
  }
  
  if (!is.null(coordinates_2)) {
    if (!is.numeric(coordinates_2) || length(coordinates_2) != 2) {
      stop("coordinates_2 must be a numeric vector of length 2 (lng, lat).")
    }
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_distance",
      layer_id = layer_id,
      layer_id_2 = layer_id_2,
      data = geojson_data,
      coordinates = coordinates,
      coordinates_2 = coordinates_2,
      units = units,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Calculate area of geometries
#'
#' This function calculates the area of polygons in a layer or sf object.
#' Note: This function only works with proxy objects as it returns a numeric value to R.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the polygons (mutually exclusive with data).
#' @param data An sf object containing polygons (mutually exclusive with layer_id).
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result. Default is TRUE.
#'
#' @return The proxy object for method chaining.
#' @export
turf_area <- function(proxy, layer_id = NULL, data = NULL, send_to_r = TRUE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_area can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data))
  if (input_count != 1) {
    stop("Exactly one of layer_id or data must be provided.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_area",
      layer_id = layer_id,
      data = geojson_data,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Calculate centroid of geometries
#'
#' This function calculates the centroid of geometries in a layer or sf object.
#' The result is added as a source to the map, which can then be styled using add_circle_layer(), etc.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of an existing layer containing geometries (mutually exclusive with data and coordinates).
#' @param data An sf object containing geometries (mutually exclusive with layer_id and coordinates).
#' @param coordinates A list/matrix of coordinate pairs [[lng,lat], [lng,lat], ...] for multiple points (mutually exclusive with layer_id and data).
#' @param source_id The ID for the new source containing the centroid. Required.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_centroid <- function(map, layer_id = NULL, data = NULL, coordinates = NULL,
                          source_id, send_to_r = FALSE) {
  
  # Validate inputs
  input_count <- sum(!is.null(layer_id), !is.null(data), !is.null(coordinates))
  if (input_count != 1) {
    stop("Exactly one of layer_id, data, or coordinates must be provided.")
  }
  
  if (missing(source_id)) {
    stop("source_id is required.")
  }
  
  # Convert sf data to GeoJSON if provided
  geojson_data <- NULL
  if (!is.null(data)) {
    if (!inherits(data, "sf")) {
      stop("data must be an sf object.")
    }
    geojson_data <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  }
  
  # Validate coordinates
  if (!is.null(coordinates)) {
    if (!is.list(coordinates) && !is.matrix(coordinates)) {
      stop("coordinates must be a list or matrix of coordinate pairs.")
    }
  }
  
  # Handle proxy objects (Shiny)
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }

    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "turf_centroid",
        layer_id = layer_id,
        data = geojson_data,
        coordinates = coordinates,
        source_id = source_id,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    # Add empty source immediately so layers can reference it
    if (!is.null(source_id)) {
      empty_source <- list(
        id = source_id,
        type = "geojson",
        data = list(type = "FeatureCollection", features = list()),
        generateId = TRUE
      )
      map$x$sources <- c(map$x$sources, list(empty_source))
    }
    
    # Add turf operation to be executed later
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_centroid",
      layer_id = layer_id,
      data = geojson_data,
      coordinates = coordinates,
      source_id = source_id
    )
    
    return(map)
  }
  
  stop("turf_centroid can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}