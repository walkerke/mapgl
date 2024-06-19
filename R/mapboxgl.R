#' Initialize a Mapbox GL Map
#'
#' @param style The Mapbox style to use.
#' @param center A numeric vector of length 2 specifying the initial center of the map.
#' @param zoom The initial zoom level of the map.
#' @param bearing The initial bearing (rotation) of the map, in degrees.
#' @param pitch The initial pitch (tilt) of the map, in degrees.
#' @param projection The map projection to use (e.g., "mercator", "globe").
#' @param parallels A vector of two numbers representing the standard parellels of the projection.  Only available when the projection is "albers" or "lambertConformalConic".
#' @param access_token Your Mapbox access token.
#' @param width The width of the output htmlwidget.
#' @param height The height of the output htmlwidget.
#' @param ... Additional named parameters to be passed to the Mapbox GL map.
#'
#' @return An HTML widget for a Mapbox map.
#' @export
#'
#' @examples
#' \dontrun{
#' mapboxgl(projection = "globe")
#' }
mapboxgl <- function(style = NULL,
                     center = c(0, 0),
                     zoom = 0,
                     bearing = 0,
                     pitch = 0,
                     projection = "globe",
                     parallels = NULL,
                     access_token = NULL,
                     width = "100%",
                     height = "100%",
                     ...) {

  access_token <- mapboxapi::get_mb_access_token(access_token)

  additional_params <- list(...)

  htmlwidgets::createWidget(
    name = "mapboxgl",
    x = list(
      style = style,
      center = center,
      zoom = zoom,
      bearing = bearing,
      pitch = pitch,
      projection = projection,
      parallels = parallels,
      access_token = access_token,
      additional_params = additional_params
    ),
    width = width,
    height = height,
    package = "mapboxgl"
  )
}

#' Create a Mapbox GL output element for Shiny
#'
#' @param outputId The output variable to read from
#' @param width The width of the element
#' @param height The height of the element
#'
#' @return A Mapbox GL output element for use in a Shiny UI
#' @export
mapboxglOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "mapboxgl", width, height, package = "mapboxgl")
}

#' Render a Mapbox GL output element in Shiny
#'
#' @param expr An expression that generates a Mapbox GL map
#' @param env The environment in which to evaluate `expr`
#' @param quoted Is `expr` a quoted expression
#'
#' @return A rendered Mapbox GL map for use in a Shiny server
#' @export
renderMapboxgl <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, mapboxglOutput, env, quoted = TRUE)
}
