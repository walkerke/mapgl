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
