#' Create a Compare slider widget
#'
#' This function creates a comparison view between two Mapbox GL or Maplibre GL maps, allowing users to swipe between the two maps to compare different styles or data layers.
#'
#' @param map1 A `mapboxgl` or `maplibre` object representing the first map.
#' @param map2 A `mapboxgl` or `maplibre` object representing the second map.
#' @param width Width of the map container.
#' @param height Height of the map container.
#' @param elementId An optional string specifying the ID of the container for the comparison. If NULL, a unique ID will be generated.
#' @param mousemove A logical value indicating whether to enable swiping during cursor movement.
#' @param orientation A string specifying the orientation of the swiper, either "horizontal" or "vertical".
#'
#' @return A comparison widget.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' library(mapgl)
#'
#' m1 <- mapboxgl(style = mapbox_style("light"))
#'
#' m2 <- mapboxgl(style = mapbox_style("dark"))
#'
#' compare(m1, m2)
#' }
compare <- function(map1,
                    map2,
                    width = '100%',
                    height = '100%',
                    elementId = NULL,
                    mousemove = FALSE,
                    orientation = 'vertical'
) {
  if (inherits(map1, "mapboxgl") && inherits(map2, "mapboxgl")) {
    compare.mapboxgl(map1, map2, width, height, elementId, mousemove, orientation)
  } else if (inherits(map1, "maplibregl") && inherits(map2, "maplibregl")) {
    compare.maplibre(map1, map2, width, height, elementId, mousemove, orientation)
  } else {
    stop("Both maps must be either mapboxgl or maplibregl objects.")
  }
}

# Mapbox GL comparison widget
compare.mapboxgl <- function(map1, map2, width, height, elementId, mousemove, orientation) {
  if (is.null(elementId)) {
    elementId <- paste0("compare-container-", as.hexmode(sample(1:1000000, 1)))
  }

  x <- list(
    map1 = map1$x,
    map2 = map2$x,
    elementId = elementId,
    mousemove = mousemove,
    orientation = orientation
  )

  htmlwidgets::createWidget(
    name = 'mapboxgl_compare',
    x,
    width = width,
    height = height,
    package = 'mapgl',
    elementId = elementId
  )
}

# Maplibre comparison widget
compare.maplibre <- function(map1, map2, width, height, elementId, mousemove, orientation) {
  if (is.null(elementId)) {
    elementId <- paste0("compare-container-", as.hexmode(sample(1:1000000, 1)))
  }

  x <- list(
    map1 = map1$x,
    map2 = map2$x,
    elementId = elementId,
    mousemove = mousemove,
    orientation = orientation
  )

  htmlwidgets::createWidget(
    name = 'maplibregl_compare',
    x,
    width = width,
    height = height,
    package = 'mapgl',
    elementId = elementId
  )
}
