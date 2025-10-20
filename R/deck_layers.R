#' Add a deck.gl ScatterplotLayer to a map
#'
#' This function adds a deck.gl ScatterplotLayer to either a Mapbox GL or MapLibre GL map.
#' deck.gl layers are WebGL-powered visualizations that can handle large datasets efficiently.
#' The ScatterplotLayer renders circles at specified coordinates with configurable styling.
#'
#' @param map A map object created by the `mapboxgl()` or `maplibre()` functions.
#' @param id A unique ID for the layer.
#' @param source An sf object with POINT geometry, or a data frame with longitude and latitude columns.
#' @param lng Column name for longitude coordinates (if source is a data frame). Default is "lng".
#' @param lat Column name for latitude coordinates (if source is a data frame). Default is "lat".
#' @param radius Radius of each point in the specified units. Default is 100.
#' @param radius_units Units for the radius: 'meters' (default), 'common', or 'pixels'.
#' @param radius_scale Global radius multiplier. Default is 1.
#' @param radius_min_pixels Minimum radius in pixels. Default is 0.
#' @param radius_max_pixels Maximum radius in pixels. Default is Number.MAX_SAFE_INTEGER.
#' @param fill_color Fill color for points as an RGBA vector c(r, g, b, a) where values are 0-255. Default is c(255, 0, 0, 255).
#' @param line_color Line color for point outlines as an RGBA vector. Default is c(0, 0, 0, 255).
#' @param line_width Width of point outlines. Default is 1.
#' @param line_width_units Units for line width: 'meters' (default), 'common', or 'pixels'.
#' @param line_width_scale Global line width multiplier. Default is 1.
#' @param line_width_min_pixels Minimum line width in pixels. Default is 0.
#' @param line_width_max_pixels Maximum line width in pixels. Default is Number.MAX_SAFE_INTEGER.
#' @param stroked Whether to draw an outline around points. Default is FALSE.
#' @param filled Whether to fill the points. Default is TRUE.
#' @param billboard Whether points face the camera (TRUE) or lie flat on the ground (FALSE). Default is FALSE.
#' @param antialiasing Whether to use antialiasing. Default is TRUE.
#' @param before_id The ID of an existing layer to insert this layer before (for layer ordering).
#'
#' @return The modified map object with the deck.gl layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(sf)
#'
#' # Create sample point data
#' points <- data.frame(
#'   lng = c(-122.45, -122.46, -122.47),
#'   lat = c(37.78, 37.79, 37.80),
#'   name = c("Point 1", "Point 2", "Point 3")
#' )
#'
#' # Add deck.gl scatterplot layer to MapLibre map
#' maplibre(
#'   style = carto_style("positron"),
#'   center = c(-122.46, 37.79),
#'   zoom = 12
#' ) %>%
#'   add_deck_scatterplot_layer(
#'     id = "points",
#'     source = points,
#'     radius = 500,
#'     fill_color = c(255, 100, 100, 200),
#'     stroked = TRUE,
#'     line_color = c(0, 0, 0, 255),
#'     line_width = 2
#'   )
#'
#' # Using sf object
#' points_sf <- st_as_sf(points, coords = c("lng", "lat"), crs = 4326)
#'
#' mapboxgl(
#'   style = mapbox_style("light"),
#'   center = c(-122.46, 37.79),
#'   zoom = 12
#' ) %>%
#'   add_deck_scatterplot_layer(
#'     id = "points-sf",
#'     source = points_sf,
#'     radius = 300,
#'     radius_units = "meters",
#'     fill_color = c(100, 149, 237, 200)
#'   )
#' }
add_deck_scatterplot_layer <- function(
  map,
  id,
  source,
  lng = "lng",
  lat = "lat",
  radius = 100,
  radius_units = "meters",
  radius_scale = 1,
  radius_min_pixels = 0,
  radius_max_pixels = NULL,
  fill_color = c(255, 0, 0, 255),
  line_color = c(0, 0, 0, 255),
  line_width = 1,
  line_width_units = "meters",
  line_width_scale = 1,
  line_width_min_pixels = 0,
  line_width_max_pixels = NULL,
  stroked = FALSE,
  filled = TRUE,
  billboard = FALSE,
  antialiasing = TRUE,
  before_id = NULL
) {
  # Prepare data in the format expected by deck.gl
  if (inherits(source, "sf")) {
    # Handle sf objects
    if (sf::st_crs(source) != 4326) {
      source <- sf::st_transform(source, crs = 4326)
    }

    # Extract coordinates
    coords <- sf::st_coordinates(source)

    # Create data array with position
    data <- lapply(1:nrow(source), function(i) {
      list(position = c(coords[i, 1], coords[i, 2]))
    })
  } else if (is.data.frame(source)) {
    # Handle data frames with lng/lat columns
    if (!lng %in% names(source) || !lat %in% names(source)) {
      stop(paste0("Columns '", lng, "' and '", lat, "' must exist in source data frame"))
    }

    # Create data array with position
    data <- lapply(1:nrow(source), function(i) {
      list(position = c(source[[lng]][i], source[[lat]][i]))
    })
  } else {
    stop("Source must be an sf object or a data frame with coordinate columns")
  }

  # Create deck.gl layer configuration
  deck_layer <- list(
    type = "scatterplot",
    id = id,
    data = data,
    getRadius = radius,
    radiusUnits = radius_units,
    radiusScale = radius_scale,
    radiusMinPixels = radius_min_pixels,
    getFillColor = as.list(fill_color),
    getLineColor = as.list(line_color),
    getLineWidth = line_width,
    lineWidthUnits = line_width_units,
    lineWidthScale = line_width_scale,
    lineWidthMinPixels = line_width_min_pixels,
    stroked = stroked,
    filled = filled,
    billboard = billboard,
    antialiasing = antialiasing
  )

  # Add optional parameters
  if (!is.null(radius_max_pixels)) {
    deck_layer$radiusMaxPixels <- radius_max_pixels
  }

  if (!is.null(line_width_max_pixels)) {
    deck_layer$lineWidthMaxPixels <- line_width_max_pixels
  }

  if (!is.null(before_id)) {
    deck_layer$beforeId <- before_id
  }

  # Add to map's deck_layers
  if (is.null(map$x$deck_layers)) {
    map$x$deck_layers <- list()
  }

  map$x$deck_layers <- c(map$x$deck_layers, list(deck_layer))

  return(map)
}
