#' Add markers to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param data A length-2 numeric vector of coordinates, a list of length-2 numeric vectors, or an `sf` POINT object.
#' @param color The color of the marker (default is "red").
#' @param rotation The rotation of the marker (default is 0).
#' @param popup A column name for popups (if data is an `sf` object) or a string for a single popup (if data is a numeric vector or list of vectors).
#' @param marker_id A unique ID for the marker. For lists, names will be inherited from the list names.  For `sf` objects, this should be a column name.
#' @param draggable A boolean indicating if the marker should be draggable (default is FALSE).
#' @param ... Additional options passed to the marker.
#'
#' @return The modified map object with the markers added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(sf)
#'
#' # Create a map object
#' map <- mapboxgl(
#'   style = mapbox_style("streets"),
#'   center = c(-74.006, 40.7128),
#'   zoom = 10
#' )
#'
#' # Add a single draggable marker with an ID
#' map <- add_markers(
#'   map,
#'   c(-74.006, 40.7128),
#'   color = "blue",
#'   rotation = 45,
#'   popup = "A marker",
#'   draggable = TRUE,
#'   marker_id = "marker1"
#' )
#'
#' # Add multiple markers from a named list of coordinates
#' coords_list <- list(marker2 = c(-74.006, 40.7128),
#'                     marker3 = c(-73.935242, 40.730610))
#' map <- add_markers(
#'   map,
#'   coords_list,
#'   color = "green",
#'   popup = "Multiple markers",
#'   draggable = TRUE
#' )
#'
#' # Create an sf POINT object
#' points_sf <- st_as_sf(data.frame(
#'   id = c("marker4", "marker5"),
#'   lon = c(-74.006, -73.935242),
#'   lat = c(40.7128, 40.730610)
#' ), coords = c("lon", "lat"), crs = 4326)
#' points_sf$popup <- c("Point 1", "Point 2")
#'
#' # Add multiple markers from an sf object with IDs from a column
#' map <- add_markers(
#'   map,
#'   points_sf,
#'   color = "red",
#'   popup = "popup",
#'   draggable = TRUE,
#'   marker_id = "id"
#' )
#' }
add_markers <- function(map, data, color = "red", rotation = 0, popup = NULL, marker_id = NULL, draggable = FALSE, ...) {
  options <- list(...)
  options$draggable <- draggable

  if (inherits(data, "sf") && sf::st_geometry_type(data, FALSE)[1] == "POINT") {
    coordinates <- sf::st_coordinates(data)
    properties <- sf::st_drop_geometry(data)
    if (!is.null(marker_id) && !marker_id %in% colnames(properties)) {
      stop("When providing an sf object, marker_id must be a column name in the object.")
    }
    markers <- lapply(seq_len(nrow(coordinates)), function(i) {
      list(
        id = if (!is.null(marker_id)) properties[[marker_id]][i] else paste0("marker_", i),
        lng = unname(coordinates[i, 1]),
        lat = unname(coordinates[i, 2]),
        color = color,
        rotation = rotation,
        popup = if (!is.null(popup)) as.character(properties[i, popup]) else NULL,
        options = options
      )
    })
  } else if (is.numeric(data) && length(data) == 2) {
    marker_id <- if (is.null(marker_id)) "marker_1" else marker_id
    markers <- list(list(
      id = marker_id,
      lng = data[1],
      lat = data[2],
      color = color,
      rotation = rotation,
      popup = popup,
      options = options
    ))
  } else if (is.list(data) && all(sapply(data, function(x) is.numeric(x) && length(x) == 2))) {
    marker_names <- if (!is.null(names(data))) names(data) else NULL
    markers <- lapply(seq_along(data), function(i) {
      coord <- data[[i]]
      list(
        id = if (!is.null(marker_names)) marker_names[i] else paste0("marker_", i),
        lng = coord[1],
        lat = coord[2],
        color = color,
        rotation = rotation,
        popup = popup,
        options = options
      )
    })
  } else {
    stop("Data must be either a length-2 numeric vector, a list of length-2 numeric vectors, or an sf POINT object.")
  }

  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_markers", markers = markers)))
  } else {
    if (!is.null(map$x$markers)) {
      map$x$markers <- c(map$x$markers, markers)
    } else {
      map$x$markers <- markers
    }
  }
  return(map)
}
