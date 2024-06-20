#' Fit the map to a bounding box
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function or a proxy object.
#' @param bbox A bounding box specified as a numeric vector of length 4 (minLng, minLat, maxLng, maxLat), or an sf object from which a bounding box will be calculated.
#' @param ... Additional named arguments for fitting the bounds.
#'
#' @return The updated map object.
#' @export
fit_bounds <- function(map, bbox, ...) {

  options <- list(...)

  if (inherits(bbox, "sf")) {
    bbox <- as.vector(sf::st_bbox(sf::st_transform(bbox, 4326)))
  }

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "fit_bounds", bounds = bbox, options = options)
    ))
  } else {
    map$x$fitBounds <- list(bounds = bbox, options = options)
  }
  return(map)
}

#' Fly to a given view
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function or a proxy object.
#' @param center A numeric vector of length 2 specifying the target center of the map (longitude, latitude).
#' @param zoom The target zoom level.
#' @param ... Additional named arguments for flying to the view.
#'
#' @return The updated map object.
#' @export
fly_to <- function(map, center, zoom = NULL, ...) {

  options <- list(...)

  options$center <- center
  if (!is.null(zoom)) options$zoom <- zoom

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "fly_to", options = options)
    ))
  } else {
    map$x$flyTo <- options
  }
  return(map)
}

#' Ease to a given view
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function or a proxy object.
#' @param center A numeric vector of length 2 specifying the target center of the map (longitude, latitude).
#' @param zoom The target zoom level.
#' @param ... Additional named arguments for easing to the view.
#'
#' @return The updated map object.
#' @export
ease_to <- function(map, center, zoom = NULL, ...) {

  options <- list(...)

  options$center <- center
  if (!is.null(zoom)) options$zoom <- zoom

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "ease_to", options = options)
    ))
  } else {
    map$x$easeTo <- options
  }
  return(map)
}

#' Set the map center and zoom level
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function or a proxy object.
#' @param center A numeric vector of length 2 specifying the center of the map (longitude, latitude).
#' @param zoom The zoom level.
#'
#' @return The updated map object.
#' @export
set_view <- function(map, center, zoom) {
  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "set_center", center = center)
    ))
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "set_zoom", zoom = zoom)
    ))
  } else {
    map$x$setCenter <- center
    map$x$setZoom <- zoom
  }
  return(map)
}

#' Jump to a given view
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function or a proxy object.
#' @param center A numeric vector of length 2 specifying the target center of the map (longitude, latitude).
#' @param zoom The target zoom level.
#' @param ... Additional named arguments for jumping to the view.
#'
#' @return The updated map object.
#' @export
jump_to <- function(map, center, zoom = NULL, ...) {

  options <- list(...)

  options$center <- center
  if (!is.null(zoom)) options$zoom <- zoom

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "jump_to", options = options)
    ))
  } else {
    map$x$jumpTo <- options
  }
  return(map)
}
