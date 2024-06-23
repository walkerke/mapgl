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
#' map1 <- mapboxgl(style = "mapbox://styles/mapbox/light-v11", center = c(0, 0), zoom = 0, access_token = "your_token_here")
#' map2 <- mapboxgl(style = "mapbox://styles/mapbox/dark-v11", center = c(0, 0), zoom = 0, access_token = "your_token_here")
#'
#' compare(map1, map2, mousemove = TRUE, orientation = 'vertical')
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

#' Create a UI output for a comparison map
#'
#' This function creates a UI output element for a comparison map in a Shiny application.
#'
#' @param outputId The output variable to read the map from.
#' @param width The width of the map container.
#' @param height The height of the map container.
#'
#' @return A UI output element for the comparison map.
#' @export
compareOutput <- function(outputId, width = '100%', height = '400px') {
  htmlwidgets::shinyWidgetOutput(outputId, 'mapboxgl_compare', width, height, package = 'mapgl')
}

#' Render a comparison map in a Shiny application
#'
#' This function renders a comparison map in a Shiny application.
#'
#' @param expr An expression that generates a comparison map.
#' @param env The environment in which to evaluate the expression.
#' @param quoted Logical, whether the expression is quoted. This is useful if you want to save an expression in a variable.
#'
#' @return A rendered comparison map.
#' @export
renderCompare <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) }
  htmlwidgets::shinyRenderWidget(expr, compareOutput, env, quoted = TRUE)
}
