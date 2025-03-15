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
        if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
            # For compare proxies
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source,
                    map = map$map_side
                )
            ))
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source
                )
            ))
        }
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
        if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
            # For compare proxies
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source,
                    map = map$map_side
                )
            ))
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source
                )
            ))
        }
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
        if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
            # For compare proxies
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source,
                    map = map$map_side
                )
            ))
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
        }
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
        if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
            # For compare proxies
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source,
                    map = map$map_side
                )
            ))
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
        }
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

        # Project to Web Mercator
        data_mercator <- terra::project(data, "EPSG:3857")

        # Get extent in WGS84 for coordinates
        data_wgs84 <- terra::project(data_mercator, "EPSG:4326")

        if (terra::nlyr(data) == 3) {
            # For RGB raster - write the mercator version to PNG
            png_path <- tempfile(fileext = ".png")
            terra::writeRaster(data_mercator, png_path, overwrite = TRUE)
            url <- base64enc::dataURI(file = png_path, mime = "image/png")
        } else {
            # For single band data
            if (is.null(colors)) {
                # Get 255 colors for data (0-254), reserving index 255 for NA
                colors <- grDevices::colorRampPalette(c("#440154", "#3B528B", "#21908C", "#5DC863", "#FDE725"))(255)
            } else if (length(colors) >= 255) {
                # Use first 255 colors if more provided
                colors <- colors[1:255]
            } else {
                # Interpolate to 255 colors
                colors <- grDevices::colorRampPalette(colors)(255)
            }

            # Extract values
            values <- terra::values(data_mercator)

            # Handle NA values
            na_mask <- is.na(values)

            # Rescale to 0-254 range
            if (all(is.na(values))) {
                # Handle the case where all values are NA
                scaled_values <- values # Keep all as NA
            } else {
                # Get min/max excluding NAs
                min_val <- min(values, na.rm = TRUE)
                max_val <- max(values, na.rm = TRUE)

                if (min_val == max_val) {
                    # Handle case where all non-NA values are the same
                    scaled_values <- values
                    scaled_values[!na_mask] <- 127 # Middle value
                } else {
                    # Normal rescaling
                    scaled_values <- (values - min_val) / (max_val - min_val) * 254
                }
            }

            # Round to integers
            scaled_values <- round(scaled_values)

            # Ensure values are in 0-254 range
            scaled_values[scaled_values < 0] <- 0
            scaled_values[scaled_values > 254] <- 254

            # Set NA values to 255 (which we'll make transparent)
            scaled_values[na_mask] <- 255

            # Update the raster
            terra::values(data_mercator) <- scaled_values

            # Create color table (255 colors + transparent for NA)
            transparent_color <- "#00000000" # Fully transparent
            coltb <- data.frame(value = 0:255, col = c(colors, transparent_color))

            # Apply color table
            terra::coltab(data_mercator) <- coltb

            # Write to PNG with appropriate datatype
            png_path <- tempfile(fileext = ".png")
            terra::writeRaster(data_mercator, png_path, overwrite = TRUE, datatype = "INT1U")
            url <- base64enc::dataURI(file = png_path, mime = "image/png")
        }

        # Compute coordinates from the WGS84 version
        if (is.null(coordinates)) {
            ext <- terra::ext(data_wgs84)

            coordinates <- list(
                c(ext[1], ext[4]), # top-left
                c(ext[2], ext[4]), # top-right
                c(ext[2], ext[3]), # bottom-right
                c(ext[1], ext[3]) # bottom-left
            )

            # Ensure coordinates are numeric vectors
            coordinates <- lapply(coordinates, as.numeric)
            names(coordinates) <- NULL
        }
    }

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
        if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
            # For compare proxies
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source,
                    map = map$map_side
                )
            ))
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
        }
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
        if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
            # For compare proxies
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(proxy_class, list(
                id = map$id, 
                message = list(
                    type = "add_source", 
                    source = source,
                    map = map$map_side
                )
            ))
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_source", source = source)))
        }
    } else {
        map$x$sources <- c(map$x$sources, list(source))
    }

    return(map)
}
