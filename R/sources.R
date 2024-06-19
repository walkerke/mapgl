library(sf)
library(jsonlite)
library(geojsonsf)

#' Add a GeoJSON source to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the source.
#' @param data An sf object or a URL pointing to a remote GeoJSON file.
#'
#' @return The modified map object with the new source added.
#' @export
#'
#' @examples
#' \dontrun{
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#' map <- mapboxgl(access_token = "your_token_here")
#' map <- add_source(map, id = "nc-source", data = nc)
#' }
add_source <- function(map, id, data) {
  if (inherits(data, "sf")) {
    geojson <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  } else if (is.character(data) && grepl("^http", data)) {
    geojson <- data
  } else {
    stop("Data must be an sf object or a URL to a remote GeoJSON file.")
  }

  map$x$sources <- c(map$x$sources, list(list(
    id = id,
    type = "geojson",
    geojson = geojson
  )))

  map
}

#' Add a vector tile source to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the vector tile source.
#'
#' @return The modified map object with the new source added.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(access_token = "your_token_here")
#' map <- add_vector_source(map, id = "vector-source", url = "mapbox://mapbox.mapbox-streets-v8")
#' }
add_vector_source <- function(map, id, url) {
  map$x$sources <- c(map$x$sources, list(list(
    id = id,
    type = "vector",
    url = url
  )))

  map
}

#' Add a raster tile source to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the raster tile source.
#' @param tileSize The size of the raster tiles.
#' @param maxzoom The maximum zoom level for the raster tiles.
#'
#' @return The modified map object with the new source added.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(access_token = "your_token_here")
#' map <- add_raster_source(map, id = "raster-source", url = "https://example.com/raster_tiles/{z}/{x}/{y}.png", tileSize = 256, maxzoom = 14)
#' }
add_raster_source <- function(map, id, url, tileSize = 256, maxzoom = 22) {
  source <- list(
    id = id,
    type = "raster",
    url = url,
    tileSize = tileSize
  )

  if (!is.null(maxzoom)) {
    source$maxzoom <- maxzoom
  }

  map$x$sources <- c(map$x$sources, list(source))

  map
}

#' Add a raster DEM source to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the raster DEM source.
#' @param tileSize The size of the raster tiles.
#' @param maxzoom The maximum zoom level for the raster tiles.
#'
#' @return The modified map object with the new source added.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(access_token = "your_token_here")
#' map <- add_raster_dem_source(map, id = "dem-source", url = "mapbox://mapbox.mapbox-terrain-dem-v1", tileSize = 512, maxzoom = 14)
#' }
add_raster_dem_source <- function(map, id, url, tileSize = 512, maxzoom = NULL) {
  source <- list(
    id = id,
    type = "raster-dem",
    url = url,
    tileSize = tileSize
  )

  if (!is.null(maxzoom)) {
    source$maxzoom <- maxzoom
  }

  map$x$sources <- c(map$x$sources, list(source))

  map
}

#' Add an image source to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the image source.
#' @param coordinates A list of coordinates specifying the image corners in clockwise order: top left, top right, bottom right, bottom left.
#'
#' @return The modified map object with the new source added.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(access_token = "your_token_here")
#' map <- add_image_source(map, id = "image-source", url = "https://example.com/image.png", coordinates = list(c(-80.425, 46.437), c(-71.516, 46.437), c(-71.516, 37.936), c(-80.425, 37.936)))
#' }
add_image_source <- function(map, id, url, coordinates) {
  map$x$sources <- c(map$x$sources, list(list(
    id = id,
    type = "image",
    url = url,
    coordinates = coordinates
  )))

  map
}

#' Add a video source to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the source.
#' @param urls A vector of URLs pointing to the video sources.
#' @param coordinates A list of coordinates specifying the video corners in clockwise order: top left, top right, bottom right, bottom left.
#'
#' @return The modified map object with the new source added.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(access_token = "your_token_here")
#' map <- add_video_source(map, id = "video-source", urls = c("https://example.com/video.mp4", "https://example.com/video.webm"), coordinates = list(c(-80.425, 46.437), c(-71.516, 46.437), c(-71.516, 37.936), c(-80.425, 37.936)))
#' }
add_video_source <- function(map, id, urls, coordinates) {
  map$x$sources <- c(map$x$sources, list(list(
    id = id,
    type = "video",
    urls = urls,
    coordinates = coordinates
  )))

  map
}
