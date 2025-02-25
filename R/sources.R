#' Add a GeoJSON or sf source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param data An sf object or a URL pointing to a remote GeoJSON file.
#' @param ... Additional arguments to be passed to the JavaScript addSource method.
#'
#' @return The modified map object with the new source added.
#' @export
add_source <- function(map, id, data, ...) {
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

    # Add additional arguments
    extra_args <- list(...)
    source <- c(source, extra_args)

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
#' @param data A `SpatRaster` object from the `terra` package or a `RasterLayer` object.
#' @param coordinates A list of coordinates specifying the image corners in clockwise order: top left, top right, bottom right, bottom left.  For `SpatRaster` or `RasterLayer` objects, this will be extracted for you.
#' @param colors A vector of colors to use for the raster image.
#'
#' @return The modified map object with the new source added.
#' @export
add_image_source <- function(map, id, url = NULL, data = NULL, coordinates = NULL, colors = NULL) {
    if (!is.null(data)) {
        if (inherits(data, "RasterLayer")) {
            data <- terra::rast(data)
        }

        if (terra::has.colors(data)) {
            # If the raster already has a color table
            rlang::warn("This function does not support existing color tables, but this feature is in progress.")
        }

        # First project to Web Mercator (like Leaflet does)
        data_mercator <- terra::project(data, "EPSG:3857")

        # Then get the extent in WGS84
        data_wgs84 <- terra::project(data_mercator, "EPSG:4326")

        if (terra::nlyr(data) == 3) {
            # For RGB raster - write the mercator version to PNG
            png_path <- tempfile(fileext = ".png")
            terra::writeRaster(data_mercator, png_path, overwrite = TRUE)
            url <- base64enc::dataURI(file = png_path, mime = "image/png")
        } else {
            # Same for single band data
            if (is.null(colors)) {
                colors <- grDevices::colorRampPalette(c("#440154", "#3B528B", "#21908C", "#5DC863", "#FDE725"))(256)
            } else if (length(colors) < 256) {
                colors <- grDevices::colorRampPalette(colors)(256)
            }

            data_mercator <- data_mercator / max(terra::values(data_mercator), na.rm = TRUE) * 254
            data_mercator <- round(data_mercator)
            data_mercator[is.na(terra::values(data_mercator))] <- 255
            coltb <- data.frame(value = 0:255, col = colors)

            # Create color table
            terra::coltab(data_mercator) <- coltb

            png_path <- tempfile(fileext = ".png")
            terra::writeRaster(data_mercator, png_path, overwrite = TRUE, NAflag = 255, datatype = "INT1U")
            url <- base64enc::dataURI(file = png_path, mime = "image/png")
        }

        # Compute coordinates from the WGS84 version
        if (is.null(coordinates)) {
            ext <- terra::ext(data_wgs84)
            coordinates <- list(
                c(ext[1], ext[4]), # top-left (west, north)
                c(ext[2], ext[4]), # top-right (east, north)
                c(ext[2], ext[3]), # bottom-right (east, south)
                c(ext[1], ext[3]) # bottom-left (west, south)
            )

            # Ensure coordinates are numeric vectors, not any other type
            coordinates <- lapply(coordinates, as.numeric)

            # Ensure proper naming for debugging
            names(coordinates) <- NULL
        }
    }

    # Rest of the function remains the same
    if (is.null(url)) {
        stop("Either 'url' or 'data' must be provided.")
    }

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
