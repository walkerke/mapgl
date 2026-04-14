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
  if (inherits(data, "sfc")) {
    data <- sf::st_as_sf(data)
    data$id <- seq_len(nrow(data))
  }
  if (inherits(data, "sf")) {
    if (sf::st_crs(data) != 4326) {
      data <- sf::st_transform(data, crs = 4326)
    }
    geojson <- geojsonsf::sf_geojson(data)
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
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source
          )
        )
      )
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
#' @param tiles A vector of tile URLs, typically in the format "https://example.com/\{z\}/\{x\}/\{y\}.mvt" or similar.
#' @param promote_id An optional property name to use as the feature ID. This is required for hover effects on vector tiles.
#' @param ... Additional arguments to be passed to the JavaScript addSource method.
#'
#' @return The modified map object with the new source added.
#' @export
add_vector_source <- function(
  map,
  id,
  url = NULL,
  tiles = NULL,
  promote_id = NULL,
  ...
) {
  source <- list(
    id = id,
    type = "vector"
  )

  if (!is.null(url)) {
    source$url <- url
  }

  if (!is.null(tiles)) {
    # Ensure tiles is always a list/array for JSON
    if (is.character(tiles)) {
      source$tiles <- as.list(tiles)
    } else {
      source$tiles <- tiles
    }
  }

  # Check that at least one is provided
  if (is.null(url) && is.null(tiles)) {
    stop("Either 'url' or 'tiles' must be provided.")
  }

  if (!is.null(promote_id)) {
    source$promoteId <- promote_id
  }

  # Add any additional arguments
  extra_args <- list(...)
  source <- c(source, extra_args)

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source
          )
        )
      )
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
#' @param ... Additional arguments to be passed to the JavaScript addSource method.
#'
#' @return The modified map object with the new source added.
#' @export
add_raster_source <- function(
  map,
  id,
  url = NULL,
  tiles = NULL,
  tileSize = 256,
  maxzoom = 22,
  ...
) {
  if (is.null(url) && is.null(tiles)) {
    stop("Either 'url' or 'tiles' must be provided.")
  }

  if (!is.null(url) && !is.null(tiles)) {
    stop(
      "Both 'url' and 'tiles' cannot be provided simultaneously. Please provide only one."
    )
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

  # Add any additional arguments
  extra_args <- list(...)
  source <- c(source, extra_args)

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(id = map$id, message = list(type = "add_source", source = source))
      )
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
#' @param ... Additional arguments to be passed to the JavaScript addSource method.
#'
#' @return The modified map object with the new source added.
#' @export
add_raster_dem_source <- function(
  map,
  id,
  url,
  tileSize = 512,
  maxzoom = NULL,
  ...
) {
  source <- list(
    id = id,
    type = "raster-dem",
    url = url,
    tileSize = tileSize
  )

  if (!is.null(maxzoom)) {
    source$maxzoom <- maxzoom
  }

  # Add any additional arguments
  extra_args <- list(...)
  source <- c(source, extra_args)

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(id = map$id, message = list(type = "add_source", source = source))
      )
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
add_image_source <- function(
  map,
  id,
  url = NULL,
  data = NULL,
  coordinates = NULL,
  colors = NULL
) {
  if (!is.null(data)) {
    if (inherits(data, "RasterLayer")) {
      data <- terra::rast(data)
    }

    is_categorical <- terra::has.colors(data) || terra::is.factor(data)

    if (is_categorical) {
      # Categorical/color-table raster path
      # Use nearest-neighbor resampling to preserve category values

      # Capture the original color table before projection
      orig_ct <- terra::coltab(data)[[1]]

      if (is.null(orig_ct) || nrow(orig_ct) == 0) {
        # Factor raster without a color table - generate qualitative colors
        cat_values <- sort(unique(
          as.integer(terra::values(data)[!is.na(terra::values(data))])
        ))
        n_cats <- length(cat_values)
        qual_colors <- grDevices::hcl.colors(n_cats, palette = "Set 2")
        rgb_vals <- grDevices::col2rgb(qual_colors, alpha = TRUE)
        orig_ct <- data.frame(
          value = cat_values,
          red = as.integer(rgb_vals["red", ]),
          green = as.integer(rgb_vals["green", ]),
          blue = as.integer(rgb_vals["blue", ]),
          alpha = as.integer(rgb_vals["alpha", ])
        )
      }

      # Project with nearest-neighbor to preserve category values
      data_mercator <- terra::project(data, "EPSG:3857", method = "near")

      # Get extent in WGS84 for coordinates
      data_wgs84 <- terra::project(data_mercator, "EPSG:4326")

      # Render categorical raster to RGBA image using color table
      # (terra writeRaster produces grayscale PNGs even with coltab)
      nr <- terra::nrow(data_mercator)
      nc <- terra::ncol(data_mercator)
      vals <- as.integer(terra::values(data_mercator))

      # Build RGBA lookup table from color table (index 0 = transparent for NA)
      lut_r <- rep(0, 256)
      lut_g <- rep(0, 256)
      lut_b <- rep(0, 256)
      lut_a <- rep(0, 256) # default transparent

      for (i in seq_len(nrow(orig_ct))) {
        idx <- orig_ct$value[i] + 1L # 0-based value to 1-based index
        if (idx >= 1L && idx <= 256L) {
          lut_r[idx] <- orig_ct$red[i]
          lut_g[idx] <- orig_ct$green[i]
          lut_b[idx] <- orig_ct$blue[i]
          lut_a[idx] <- orig_ct$alpha[i]
        }
      }

      # Ensure index 0 (used for NA) is always transparent
      lut_r[1] <- 0L
      lut_g[1] <- 0L
      lut_b[1] <- 0L
      lut_a[1] <- 0L

      # Map NA to index 0 (transparent)
      vals[is.na(vals)] <- 0L
      idx <- vals + 1L

      # Handle values > 255 by remapping to sequential indices
      if (any(idx > 256L, na.rm = TRUE)) {
        unique_vals <- sort(unique(vals[vals > 0L]))
        if (length(unique_vals) > 255) {
          rlang::warn(
            paste0(
              "Raster has ", length(unique_vals),
              " categories, but only 255 can be represented. ",
              "Extra categories will be dropped."
            )
          )
          unique_vals <- unique_vals[1:255]
        }

        # Build remap: original value -> new 1-based index
        val_map <- stats::setNames(seq_along(unique_vals), as.character(unique_vals))

        # Rebuild lookup from original color table with new indices
        lut_r <- rep(0, 256)
        lut_g <- rep(0, 256)
        lut_b <- rep(0, 256)
        lut_a <- rep(0, 256)

        for (i in seq_along(unique_vals)) {
          ct_row <- match(unique_vals[i], orig_ct$value)
          if (!is.na(ct_row)) {
            lut_r[i + 1L] <- orig_ct$red[ct_row]
            lut_g[i + 1L] <- orig_ct$green[ct_row]
            lut_b[i + 1L] <- orig_ct$blue[ct_row]
            lut_a[i + 1L] <- orig_ct$alpha[ct_row]
          }
        }

        # Remap pixel values
        new_vals <- val_map[as.character(vals)]
        new_vals[is.na(new_vals)] <- 0L
        idx <- as.integer(new_vals) + 1L
      }

      # Build RGBA image array (values are row-major, array fills column-major)
      img <- array(0, dim = c(nr, nc, 4))
      img[, , 1] <- matrix(lut_r[idx] / 255, nrow = nr, ncol = nc, byrow = TRUE)
      img[, , 2] <- matrix(lut_g[idx] / 255, nrow = nr, ncol = nc, byrow = TRUE)
      img[, , 3] <- matrix(lut_b[idx] / 255, nrow = nr, ncol = nc, byrow = TRUE)
      img[, , 4] <- matrix(lut_a[idx] / 255, nrow = nr, ncol = nc, byrow = TRUE)

      png_path <- tempfile(fileext = ".png")
      png::writePNG(img, png_path)
      url <- base64enc::dataURI(file = png_path, mime = "image/png")
    } else {
      # Continuous / non-categorical raster path

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
        # For single band continuous data
        if (is.null(colors)) {
          # Get 255 colors for data (0-254), reserving index 255 for NA
          colors <- grDevices::colorRampPalette(c(
            "#440154",
            "#3B528B",
            "#21908C",
            "#5DC863",
            "#FDE725"
          ))(255)
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
        terra::writeRaster(
          data_mercator,
          png_path,
          overwrite = TRUE,
          datatype = "INT1U"
        )
        url <- base64enc::dataURI(file = png_path, mime = "image/png")
      }
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
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(id = map$id, message = list(type = "add_source", source = source))
      )
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
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) {
        "mapboxgl-compare-proxy"
      } else {
        "maplibre-compare-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
        "mapboxgl-proxy"
      } else {
        "maplibre-proxy"
      }
      map$session$sendCustomMessage(
        proxy_class,
        list(id = map$id, message = list(type = "add_source", source = source))
      )
    }
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}


#' Add a PMTiles source to a Mapbox GL or Maplibre GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param id A unique ID for the source.
#' @param url A URL pointing to the PMTiles archive.
#' @param source_type The source type for MapLibre maps. Either "vector" (default) or "raster".
#' @param maxzoom Only used when source_type is "raster". The maximum zoom level for the PMTiles source. Defaults to 22.
#' @param tilesize Only used when source_type is "raster". The size of the tiles in the PMTiles source. Defaults to 256.
#' @param promote_id An optional property name to use as the feature ID. This is required for hover effects on vector sources.
#' @param ... Additional arguments to be passed to the JavaScript addSource method.
#'
#' @return The modified map object with the new source added.
#' @export
#' @examples
#' \dontrun{
#'
#' # Visualize the Overture Maps places data as PMTiles
#' # Works with either `maplibre()` or `mapboxgl()`
#'
#' library(mapgl)
#'
#' maplibre(style = maptiler_style("basic", variant = "dark")) |>
#'   set_projection("globe") |>
#'   add_pmtiles_source(
#'     id = "places-source",
#'     url = "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2025-06-25/places.pmtiles"
#'   ) |>
#'   add_circle_layer(
#'     id = "places-layer",
#'     source = "places-source",
#'     source_layer = "place",
#'     circle_color = "cyan",
#'     circle_opacity = 0.7,
#'     circle_radius = 4,
#'     tooltip = concat(
#'       "Name: ",
#'       get_column("@name"),
#'       "<br>Confidence: ",
#'       number_format(get_column("confidence"), maximum_fraction_digits = 2)
#'     )
#'   )
#' }
add_pmtiles_source <- function(
  map,
  id,
  url,
  source_type = "vector",
  maxzoom = 22,
  tilesize = 256,
  promote_id = NULL,
  ...
) {
  # Detect if we're using Mapbox GL JS or MapLibre GL JS
  is_mapbox <- inherits(map, "mapboxgl") ||
    inherits(map, "mapboxgl_proxy") ||
    inherits(map, "mapboxgl_compare") ||
    inherits(map, "mapboxgl_compare_proxy")

  if (is_mapbox) {
    # Mapbox GL JS v3.21.0+ has native PMTiles support for vector tiles
    if (source_type == "raster") {
      # Raster PMTiles still require the custom source type
      source <- list(
        id = id,
        type = "pmtile-source",
        url = url
      )
    } else {
      # Vector PMTiles use native TileProvider API (auto-detects .pmtiles URLs)
      source <- list(
        id = id,
        type = "vector",
        url = url
      )

      if (!is.null(promote_id)) {
        source$promoteId <- promote_id
      }
    }
  } else {
    # For MapLibre GL JS
    if (source_type == "raster") {
      # For raster PMTiles
      source <- list(
        id = id,
        type = "raster",
        url = paste0("pmtiles://", url),
        tileSize = tilesize,
        maxzoom = maxzoom
      )
    } else {
      # For vector PMTiles
      source <- list(
        id = id,
        type = "vector",
        url = paste0("pmtiles://", url)
      )

      if (!is.null(promote_id)) {
        source$promoteId <- promote_id
      }
    }
  }

  # Add any additional arguments
  extra_args <- list(...)
  source <- c(source, extra_args)

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_source",
            source = source,
            map = map$map_side
          )
        )
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(id = map$id, message = list(type = "add_source", source = source))
      )
    }
  } else {
    map$x$sources <- c(map$x$sources, list(source))
  }

  return(map)
}
