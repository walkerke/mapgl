#' Add markers to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param data A length-2 numeric vector of coordinates or an `sf` POINT object.
#' @param color The color of the marker.
#' @param rotation The rotation of the marker.
#' @param popup A column name for popups (if data is an `sf` object) or a string for a single popup (if data is a numeric vector).
#' @param ... Additional options passed to the marker.
#'
#' @return The modified map object with the markers added.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(
#'   style = "mapbox://styles/mapbox/streets-v12",
#'   center = c(-74.006, 40.7128),
#'   zoom = 10,
#'   access_token = "your_token_here"
#' )
#'
#' # Add a single marker
#' map <- add_markers(map, c(-74.006, 40.7128), color = "blue", rotation = 45, popup = "A marker")
#'
#' # Add multiple markers from an sf object
#' map <- add_markers(map, your_sf_object, color = "red", popup = "your_column_name")
#' }
add_markers <- function(map, data, color = "red", rotation = 0, popup = NULL, ...) {
  options <- list(...)

  if (inherits(data, "sf") && sf::st_geometry_type(data, FALSE)[1] == "POINT") {
    coordinates <- sf::st_coordinates(data)
    properties <- sf::st_drop_geometry(data)
    markers <- lapply(seq_len(nrow(coordinates)), function(i) {
      list(
        lng = unname(coordinates[i, 1]),
        lat = unname(coordinates[i, 2]),
        color = color,
        rotation = rotation,
        popup = if (!is.null(popup)) as.character(properties[i, popup]) else NULL,
        options = options
      )
    })
  } else if (is.numeric(data) && length(data) == 2) {
    markers <- list(list(
      lng = data[1],
      lat = data[2],
      color = color,
      rotation = rotation,
      popup = popup,
      options = options
    ))
  } else {
    stop("Data must be either a length-2 numeric vector or an sf POINT object.")
  }

  if (inherits(map, "mapboxgl_proxy")) {
    map$session$sendCustomMessage("mapboxgl-proxy", list(id = map$id, message = list(type = "add_markers", markers = markers)))
  } else {
    if (!is.null(map$x$markers)) {
      map$x$markers <- c(map$x$markers, markers)
    } else {
      map$x$markers <- markers
    }
  }
  return(map)
}
