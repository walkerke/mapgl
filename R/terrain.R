#' Set terrain properties on a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param source The ID of the raster DEM source.
#' @param exaggeration The terrain exaggeration factor.
#'
#' @return The modified map object with the terrain settings applied.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(style = "mapbox://styles/mapbox/satellite-streets-v12",
#'                 center = c(-114.26608, 32.7213), zoom = 14, pitch = 80, bearing = 41,
#'                 access_token = "your_token_here")
#' map <- add_source(map, id = "mapbox-dem", type = "raster-dem",
#'                   url = "mapbox://mapbox.mapbox-terrain-dem-v1",
#'                   tileSize = 512, maxzoom = 14)
#' map <- set_terrain(map, source = "mapbox-dem", exaggeration = 1.5)
#' }
set_terrain <- function(map, source, exaggeration = 1.0) {
  map$x$terrain <- list(
    source = source,
    exaggeration = exaggeration
  )
  map
}

#' Set fog on a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function or a proxy object.
#' @param range A numeric vector of length 2 defining the minimum and maximum range of the fog.
#' @param color A string specifying the color of the fog.
#' @param horizon_blend A number between 0 and 1 controlling the blending of the fog at the horizon.
#' @param high_color A string specifying the color of the fog at higher elevations.
#' @param space_color A string specifying the color of the fog in space.
#' @param star_intensity A number between 0 and 1 controlling the intensity of the stars in the fog.
#'
#' @return The updated map object.
#' @export
set_fog <- function(map, range = NULL, color = NULL, horizon_blend = NULL,
                    high_color = NULL, space_color = NULL, star_intensity = NULL) {
  fog <- list()

  if (!is.null(range)) fog[["range"]] <- range
  if (!is.null(color)) fog[["color"]] <- color
  if (!is.null(horizon_blend)) fog[["horizon-blend"]] <- horizon_blend
  if (!is.null(high_color)) fog[["high-color"]] <- high_color
  if (!is.null(space_color)) fog[["space-color"]] <- space_color
  if (!is.null(star_intensity)) fog[["star-intensity"]] <- star_intensity

  map$x$fog <- fog

  map

}
