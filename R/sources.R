#' Add a GeoJSON or sf source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param data An sf object or a URL pointing to a remote GeoJSON file.
#'
#' @return The modified map object with the new source added.
#' @export
add_source <- function(map, id, data) {
  if (inherits(data, "sf")) {
    geojson <- geojsonsf::sf_geojson(sf::st_transform(data, crs = 4326))
  } else if (is.character(data) && grepl("^http", data)) {
    geojson <- data
  } else {
    stop("Data must be an sf object or a URL to a remote GeoJSON file.")
  }

  source <- list(
    id = id,
    type = "geojson",
    data = geojson,
    generateId = TRUE
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}

#' Add a vector tile source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the vector tile source.
#'
#' @return The modified map object with the new source added.
#' @export
add_vector_source <- function(map, id, url) {
  source <- list(
    id = id,
    type = "vector",
    url = url
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}

#' Add a raster tile source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the raster tile source. (optional)
#' @param tiles A vector of tile URLs for the raster source. (optional)
#' @param tileSize The size of the raster tiles.
#' @param maxzoom The maximum zoom level for the raster tiles.
#'
#' @return The modified map object with the new source added.
#' @export
add_raster_source <- function(map, id, url = NULL, tiles = NULL, tileSize = 256, maxzoom = 22) {
  if (is.null(url) && is.null(tiles)) {
    stop("Either 'url' or 'tiles' must be provided.")
  }

  if (!is.null(url) && !is.null(tiles)) {
    stop("Both 'url' and 'tiles' cannot be provided simultaneously. Please provide only one.")
  }

  source <- list(
    id = id,
    type = "raster",
    tileSize = tileSize
  )

  if (!is.null(url)) {
    source$url <- url
  } else if (!is.null(tiles)) {

    if (!is.list(tiles)) {
      source$tiles <- list(tiles)
    } else {
      source$tiles <- tiles
    }
  }

  if (!is.null(maxzoom)) {
    source$maxzoom <- maxzoom
  }

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}

#' Add a raster DEM source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the raster DEM source.
#' @param tileSize The size of the raster tiles.
#' @param maxzoom The maximum zoom level for the raster tiles.
#'
#' @return The modified map object with the new source added.
#' @export
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

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}

#' Add an image source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the image source.
#' @param coordinates A list of coordinates specifying the image corners in clockwise order: top left, top right, bottom right, bottom left.
#'
#' @return The modified map object with the new source added.
#' @export
add_image_source <- function(map, id, url, coordinates) {
  source <- list(
    id = id,
    type = "image",
    url = url,
    coordinates = coordinates
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}

#' Add a video source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param urls A vector of URLs pointing to the video sources.
#' @param coordinates A list of coordinates specifying the video corners in clockwise order: top left, top right, bottom right, bottom left.
#'
#' @return The modified map object with the new source added.
#' @export
add_video_source <- function(map, id, urls, coordinates) {
  source <- list(
    id = id,
    type = "video",
    urls = urls,
    coordinates = coordinates
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}
