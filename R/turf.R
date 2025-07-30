#' Turf.js Geospatial Operations for mapgl
#'
#' This module provides client-side geospatial operations using the turf.js library.
#' All operations work with both mapboxgl and maplibre proxies.

#' Create a buffer around geometries
#'
#' This function creates a buffer around points, lines, or polygons at a specified distance.
#' The operation is performed client-side using turf.js.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the geometries to buffer.
#' @param radius The buffer distance.
#' @param units The units for the buffer distance. One of "meters", "kilometers", "miles", "feet", "inches", "yards", "centimeters", "millimeters", "degrees", "radians".
#' @param result_layer_id Optional. The ID for the new layer to display the buffered results on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
#'
#' @examples
#' \dontrun{
#' # Interactive/static usage
#' map <- maplibre() |>
#'   add_circle_layer(id = "points", source = points_data) |>
#'   turf_buffer(layer_id = "points", radius = 1000, units = "meters",
#'               result_layer_id = "point_buffers")
#'
#' # Shiny proxy usage
#' maplibre_proxy("map") |>
#'   turf_buffer(layer_id = "points", radius = 0.5, units = "miles",
#'               send_to_r = TRUE)
#' }
turf_buffer <- function(map, layer_id, radius, units = "meters",
                        result_layer_id = NULL, layer_style = NULL,
                        send_to_r = FALSE) {
  
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
        radius = radius,
        units = units,
        result_layer_id = result_layer_id,
        layer_style = layer_style,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_buffer",
      layer_id = layer_id,
      radius = radius,
      units = units,
      result_layer_id = result_layer_id,
      layer_style = layer_style
    )
    
    return(map)
  }
  
  stop("turf_buffer can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Union geometries
#'
#' This function unions all polygons in a layer into a single geometry.
#'
#' @param map A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the geometries to union.
#' @param result_layer_id Optional. The ID for the new layer to display the union result on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result (proxy only).
#'
#' @return The map or proxy object for method chaining.
#' @export
turf_union <- function(map, layer_id, result_layer_id = NULL,
                       layer_style = NULL, send_to_r = FALSE) {
  
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
        result_layer_id = result_layer_id,
        layer_style = layer_style,
        send_to_r = send_to_r
      )
    ))
    
    return(map)
  }
  
  # Handle static map objects
  if (any(inherits(map, "mapboxgl"), inherits(map, "maplibregl"))) {
    if (is.null(map$x$turf_operations)) {
      map$x$turf_operations <- list()
    }
    
    map$x$turf_operations[[length(map$x$turf_operations) + 1]] <- list(
      type = "turf_union",
      layer_id = layer_id,
      result_layer_id = result_layer_id,
      layer_style = layer_style
    )
    
    return(map)
  }
  
  stop("turf_union can only be used with mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy objects.")
}

#' Find intersection of two geometries
#'
#' This function finds the intersection between geometries in two layers.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the first layer.
#' @param layer_id_2 The ID of the second layer.
#' @param result_layer_id Optional. The ID for the new layer to display the intersection result on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result.
#'
#' @return The proxy object for method chaining.
#' @export
turf_intersect <- function(proxy, layer_id, layer_id_2, result_layer_id = NULL,
                           layer_style = NULL, send_to_r = FALSE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_intersect can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_intersect",
      layer_id = layer_id,
      layer_id_2 = layer_id_2,
      result_layer_id = result_layer_id,
      layer_style = layer_style,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Find difference between two geometries
#'
#' This function subtracts the second geometry from the first.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the first layer (geometry to subtract from).
#' @param layer_id_2 The ID of the second layer (geometry to subtract).
#' @param result_layer_id Optional. The ID for the new layer to display the difference result on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result.
#'
#' @return The proxy object for method chaining.
#' @export
turf_difference <- function(proxy, layer_id, layer_id_2, result_layer_id = NULL,
                            layer_style = NULL, send_to_r = FALSE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_difference can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_difference",
      layer_id = layer_id,
      layer_id_2 = layer_id_2,
      result_layer_id = result_layer_id,
      layer_style = layer_style,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Create convex hull
#'
#' This function creates a convex hull around a set of points.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the points.
#' @param result_layer_id Optional. The ID for the new layer to display the convex hull on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result.
#'
#' @return The proxy object for method chaining.
#' @export
turf_convex_hull <- function(proxy, layer_id, result_layer_id = NULL,
                             layer_style = NULL, send_to_r = FALSE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_convex_hull can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_convex_hull",
      layer_id = layer_id,
      result_layer_id = result_layer_id,
      layer_style = layer_style,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Create concave hull
#'
#' This function creates a concave hull around a set of points.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the points.
#' @param max_edge The maximum edge length for the concave hull. Default is Infinity (convex hull).
#' @param units The units for max_edge. One of "meters", "kilometers", "miles", etc.
#' @param result_layer_id Optional. The ID for the new layer to display the concave hull on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result.
#'
#' @return The proxy object for method chaining.
#' @export
turf_concave_hull <- function(proxy, layer_id, max_edge = NULL, units = "kilometers",
                              result_layer_id = NULL, layer_style = NULL,
                              send_to_r = FALSE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_concave_hull can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_concave_hull",
      layer_id = layer_id,
      max_edge = max_edge,
      units = units,
      result_layer_id = result_layer_id,
      layer_style = layer_style,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Create Voronoi diagram
#'
#' This function creates a Voronoi diagram from a set of points.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the points.
#' @param bbox Optional. A vector of four numbers representing the bounding box [minX, minY, maxX, maxY].
#' @param result_layer_id Optional. The ID for the new layer to display the Voronoi diagram on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result.
#'
#' @return The proxy object for method chaining.
#' @export
turf_voronoi <- function(proxy, layer_id, bbox = NULL, result_layer_id = NULL,
                         layer_style = NULL, send_to_r = FALSE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_voronoi can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_voronoi",
      layer_id = layer_id,
      bbox = bbox,
      result_layer_id = result_layer_id,
      layer_style = layer_style,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Calculate distance between two features
#'
#' This function calculates the distance between the first features of two layers.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the first layer.
#' @param layer_id_2 The ID of the second layer.
#' @param units The units for the distance calculation. One of "meters", "kilometers", "miles", etc.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result. Default is TRUE.
#'
#' @return The proxy object for method chaining.
#' @export
turf_distance <- function(proxy, layer_id, layer_id_2, units = "kilometers",
                          send_to_r = TRUE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_distance can only be used with mapboxgl_proxy or maplibre_proxy objects.")
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
      units = units,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Calculate area of geometries
#'
#' This function calculates the area of polygons in a layer.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the polygons.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result. Default is TRUE.
#'
#' @return The proxy object for method chaining.
#' @export
turf_area <- function(proxy, layer_id, send_to_r = TRUE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_area can only be used with mapboxgl_proxy or maplibre_proxy objects.")
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
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}

#' Calculate centroid of geometries
#'
#' This function calculates the centroid of geometries in a layer.
#'
#' @param proxy A mapboxgl_proxy or maplibre_proxy object.
#' @param layer_id The ID of the layer containing the geometries.
#' @param result_layer_id Optional. The ID for the new layer to display the centroid on the map.
#' @param layer_style Optional. A named list of paint properties for styling the result layer.
#' @param send_to_r Logical. If TRUE, sends the result back to R as input$<map_id>_turf_result.
#'
#' @return The proxy object for method chaining.
#' @export
turf_centroid <- function(proxy, layer_id, result_layer_id = NULL,
                          layer_style = NULL, send_to_r = FALSE) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("turf_centroid can only be used with mapboxgl_proxy or maplibre_proxy objects.")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(proxy_class, list(
    id = proxy$id,
    message = list(
      type = "turf_centroid",
      layer_id = layer_id,
      result_layer_id = result_layer_id,
      layer_style = layer_style,
      send_to_r = send_to_r
    )
  ))

  return(proxy)
}