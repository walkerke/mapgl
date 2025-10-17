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
#' library(mapgl)
#'
#' mapboxgl(
#'   style = mapbox_style("standard-satellite"),
#'   center = c(-114.26608, 32.7213),
#'   zoom = 14,
#'   pitch = 80,
#'   bearing = 41
#' ) |>
#'   add_raster_dem_source(
#'     id = "mapbox-dem",
#'     url = "mapbox://mapbox.mapbox-terrain-dem-v1",
#'     tileSize = 512,
#'     maxzoom = 14
#'   ) |>
#'   set_terrain(
#'     source = "mapbox-dem",
#'     exaggeration = 1.5
#'   )
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

#' Set rain effect on a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function or a proxy object.
#' @param density A number between 0 and 1 controlling the rain particles density. Default is 0.5.
#' @param intensity A number between 0 and 1 controlling the rain particles movement speed. Default is 1.
#' @param color A string specifying the color of the rain droplets. Default is "#a8adbc".
#' @param opacity A number between 0 and 1 controlling the rain particles opacity. Default is 0.7.
#' @param center_thinning A number between 0 and 1 controlling the thinning factor of rain particles from center. Default is 0.57.
#' @param direction A numeric vector of length 2 defining the azimuth and polar angles of the rain direction. Default is c(0, 80).
#' @param droplet_size A numeric vector of length 2 controlling the rain droplet size (x - normal to direction, y - along direction). Default is c(2.6, 18.2).
#' @param distortion_strength A number between 0 and 1 controlling the rain particles screen-space distortion strength. Default is 0.7.
#' @param vignette A number between 0 and 1 controlling the screen-space vignette rain tinting effect intensity. Default is 1.0.
#' @param vignette_color A string specifying the rain vignette screen-space corners tint color. Default is "#464646".
#' @param remove A logical value indicating whether to remove the rain effect. Default is FALSE.
#'
#' @return The updated map object.
#' @export
#' 
#' @examples
#' \dontrun{
#' # Add rain effect with default values
#' mapboxgl(...) |> set_rain()
#' 
#' # Add rain effect with custom values
#' mapboxgl(
#'   style = mapbox_style("standard"),
#'   center = c(24.951528, 60.169573),
#'   zoom = 16.8,
#'   pitch = 74,
#'   bearing = 12.8
#' ) |>
#'   set_rain(
#'     density = 0.5,
#'     opacity = 0.7,
#'     color = "#a8adbc"
#'   )
#'   
#' # Remove rain effect (useful in Shiny)
#' map_proxy |> set_rain(remove = TRUE)
#' }
set_rain <- function(map, density = 0.5, intensity = 1.0, color = "#a8adbc", 
                     opacity = 0.7, center_thinning = 0.57, direction = c(0, 80), 
                     droplet_size = c(2.6, 18.2), distortion_strength = 0.7, 
                     vignette = 1.0, vignette_color = "#464646",
                     remove = FALSE) {
  
  # Check if this is a proxy object (only Mapbox proxy supported)
  if (inherits(map, "mapboxgl_proxy")) {
    # For proxy objects, send a message to update the rain effect
    if (remove) {
      # Send message to remove rain effect
      map$session$sendCustomMessage(
        "mapboxgl-proxy",
        list(
          id = map$id,
          message = list(
            type = "set_rain",
            remove = TRUE
          )
        )
      )
    } else {
      # Send message to set rain effect with parameters
      rain <- list(
        density = density,
        intensity = intensity,
        color = color,
        opacity = opacity,
        "center-thinning" = center_thinning,
        direction = direction,
        "droplet-size" = droplet_size,
        "distortion-strength" = distortion_strength,
        vignette = vignette,
        "vignette-color" = vignette_color
      )
      
      map$session$sendCustomMessage(
        "mapboxgl-proxy",
        list(
          id = map$id,
          message = list(
            type = "set_rain",
            rain = rain
          )
        )
      )
    }
  } else {
    # For regular map objects, use existing logic
    if (remove) {
      map$x$rain <- NULL
      return(map)
    }
    
    rain <- list(
      density = density,
      intensity = intensity,
      color = color,
      opacity = opacity,
      "center-thinning" = center_thinning,
      direction = direction,
      "droplet-size" = droplet_size,
      "distortion-strength" = distortion_strength,
      vignette = vignette,
      "vignette-color" = vignette_color
    )
    
    map$x$rain <- rain
  }
  
  map
}

#' Set snow effect on a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function or a proxy object.
#' @param density A number between 0 and 1 controlling the snow particles density. Default is 0.85.
#' @param intensity A number between 0 and 1 controlling the snow particles movement speed. Default is 1.0.
#' @param color A string specifying the color of the snow particles. Default is "#ffffff".
#' @param opacity A number between 0 and 1 controlling the snow particles opacity. Default is 1.0.
#' @param center_thinning A number between 0 and 1 controlling the thinning factor of snow particles from center. Default is 0.4.
#' @param direction A numeric vector of length 2 defining the azimuth and polar angles of the snow direction. Default is c(0, 50).
#' @param flake_size A number between 0 and 5 controlling the snow flake particle size. Default is 0.71.
#' @param vignette A number between 0 and 1 controlling the snow vignette screen-space effect. Default is 0.3.
#' @param vignette_color A string specifying the snow vignette screen-space corners tint color. Default is "#ffffff".
#' @param remove A logical value indicating whether to remove the snow effect. Default is FALSE.
#'
#' @return The updated map object.
#' @export
#' 
#' @examples
#' \dontrun{
#' # Add snow effect with default values
#' mapboxgl(...) |> set_snow()
#' 
#' # Add snow effect with custom values
#' mapboxgl(
#'   style = mapbox_style("standard"),
#'   center = c(24.951528, 60.169573),
#'   zoom = 16.8,
#'   pitch = 74,
#'   bearing = 12.8
#' ) |>
#'   set_snow(
#'     density = 0.85,
#'     flake_size = 0.71,
#'     color = "#ffffff"
#'   )
#'   
#' # Remove snow effect (useful in Shiny)
#' map_proxy |> set_snow(remove = TRUE)
#' }
set_snow <- function(map, density = 0.85, intensity = 1.0, color = "#ffffff", 
                     opacity = 1.0, center_thinning = 0.4, direction = c(0, 50), 
                     flake_size = 0.71, vignette = 0.3, vignette_color = "#ffffff",
                     remove = FALSE) {
  
  # Check if this is a proxy object (only Mapbox proxy supported)
  if (inherits(map, "mapboxgl_proxy")) {
    # For proxy objects, send a message to update the snow effect
    if (remove) {
      # Send message to remove snow effect
      map$session$sendCustomMessage(
        "mapboxgl-proxy",
        list(
          id = map$id,
          message = list(
            type = "set_snow",
            remove = TRUE
          )
        )
      )
    } else {
      # Send message to set snow effect with parameters
      snow <- list(
        density = density,
        intensity = intensity,
        color = color,
        opacity = opacity,
        "center-thinning" = center_thinning,
        direction = direction,
        "flake-size" = flake_size,
        vignette = vignette,
        "vignette-color" = vignette_color
      )
      
      map$session$sendCustomMessage(
        "mapboxgl-proxy",
        list(
          id = map$id,
          message = list(
            type = "set_snow",
            snow = snow
          )
        )
      )
    }
  } else {
    # For regular map objects, use existing logic
    if (remove) {
      map$x$snow <- NULL
      return(map)
    }
    
    snow <- list(
      density = density,
      intensity = intensity,
      color = color,
      opacity = opacity,
      "center-thinning" = center_thinning,
      direction = direction,
      "flake-size" = flake_size,
      vignette = vignette,
      "vignette-color" = vignette_color
    )
    
    map$x$snow <- snow
  }
  
  map
}