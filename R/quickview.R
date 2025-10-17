#' Quick visualization of geometries with Mapbox GL
#'
#' This function provides a quick way to visualize sf geometries and raster data using Mapbox GL JS.
#' It automatically detects the geometry type and applies appropriate styling.
#'
#' @param data An sf object, SpatRaster, or RasterLayer to visualize
#' @param color The color used to visualize points, lines, or polygons if `column` is NULL.  Defaults to `"navy"`.
#' @param column The name of the column to visualize. If NULL (default), geometries are shown with default styling.
#' @param n Number of quantile breaks for numeric columns. If specified, uses step_expr() instead of interpolate().
#' @param palette Color palette function that takes n and returns a character vector of colors. Defaults to viridisLite::viridis.
#' @param style The Mapbox style to use. Defaults to mapbox_style("light").
#' @param layer_id The layer ID to use for the visualization. Defaults to "quickview".
#' @param legend Logical, whether to add a legend when a column is specified. Defaults to TRUE.
#' @param legend_position The position of the legend on the map. Defaults to "top-left".
#' @param ... Additional arguments passed to mapboxgl()
#'
#' @return A Mapbox GL map object
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"))
#'
#' # Basic view
#' mapboxgl_view(nc)
#'
#' # View with column visualization
#' mapboxgl_view(nc, column = "AREA")
#'
#' # View with quantile breaks
#' mapboxgl_view(nc, column = "AREA", n = 5)
#'
#' # Custom palette examples
#' mapboxgl_view(nc, column = "AREA", palette = viridisLite::mako)
#' mapboxgl_view(nc, column = "AREA", palette = function(n) RColorBrewer::brewer.pal(n, "RdYlBu"))
#' mapboxgl_view(nc, column = "AREA", palette = colorRampPalette(c("red", "white", "blue")))
#' }
mapboxgl_view <- function(
  data,
  color = "navy",
  column = NULL,
  n = NULL,
  palette = viridisLite::viridis,
  style = mapbox_style("light"),
  layer_id = "quickview",
  legend = TRUE,
  legend_position = "top-left",
  ...
) {
  if (!inherits(data, c("sf", "SpatRaster", "RasterLayer"))) {
    stop("data must be an sf object, SpatRaster, or RasterLayer")
  }

  # Check if data is a raster
  is_raster <- inherits(data, c("SpatRaster", "RasterLayer"))

  # Initialize map with bounds
  if (is_raster) {
    # For rasters, don't use bounds parameter with data
    map <- mapboxgl(style = style, ...)
  } else {
    # Get geometry type for sf objects
    geom_type <- sf::st_geometry_type(data, by_geometry = FALSE)
    map <- mapboxgl(style = style, bounds = data, ...)
  }

  # Default navy color
  default_color <- color

  # Handle raster data
  if (is_raster) {
    # Convert RasterLayer to SpatRaster if needed
    if (inherits(data, "RasterLayer")) {
      data <- terra::rast(data)
    }

    # Calculate bbox and fit bounds
    # Project to WGS84 to get bounds in the right coordinate system
    data_wgs84 <- terra::project(data, "EPSG:4326")
    bounds <- unname(sf::st_bbox(data_wgs84))

    # Generate source and layer IDs for raster
    source_id <- paste0(layer_id, "-source")

    # Get raster values for legend (single-band rasters only)
    is_single_band <- terra::nlyr(data) == 1
    raster_values <- NULL
    if (is_single_band) {
      raster_values <- terra::values(data, na.rm = TRUE)
      if (length(raster_values) > 0) {
        min_val <- min(raster_values, na.rm = TRUE)
        max_val <- max(raster_values, na.rm = TRUE)
      }
    }

    # Convert colors parameter for raster
    raster_colors <- if (!is.null(column)) {
      # If column specified, it should refer to color values
      NULL
    } else {
      # Use palette to generate colors for raster visualization
      if (
        is_single_band && !is.null(raster_values) && length(raster_values) > 0
      ) {
        palette(255)
      } else {
        NULL # Let add_image_source handle RGB rasters
      }
    }

    # Add raster source and layer
    map <- map |>
      add_image_source(
        id = source_id,
        data = data,
        colors = raster_colors
      ) |>
      add_raster_layer(
        id = layer_id,
        source = source_id,
        raster_opacity = 0.8
      ) |>
      fit_bounds(bounds)

    # Add legend for single-band rasters
    if (
      is_single_band &&
        !is.null(raster_values) &&
        length(raster_values) > 0 &&
        min_val != max_val &&
        legend
    ) {
      # Use same approach as vector continuous legends with 5 equal-interval breaks
      breaks <- seq(min_val, max_val, length.out = 5)
      legend_colors <- palette(5)

      map <- map |>
        add_legend(
          legend_title = if (!is.null(column)) column else "Values",
          values = c(round(min_val, 2), round(max_val, 2)),
          colors = legend_colors,
          type = "continuous",
          position = legend_position,
          layer_id = layer_id
        )
    }

    return(map)
  }

  # Create popup column with all data (sf objects only)
  data_cols <- names(data)[
    !names(data) %in% c("geometry", attr(data, "sf_column"))
  ]
  if (length(data_cols) > 0) {
    popup_html <- apply(data, 1, function(row) {
      paste0(
        sapply(data_cols, function(col) {
          paste0("<strong>", col, ":</strong> ", row[[col]])
        }),
        collapse = "<br>"
      )
    })
    data$popup_content <- popup_html
  }

  # Determine layer type and add appropriate layer
  if (grepl("POINT|MULTIPOINT", geom_type)) {
    # Point/MultiPoint -> circle layer
    if (is.null(column)) {
      map <- map |>
        add_circle_layer(
          id = layer_id,
          source = data,
          circle_color = default_color,
          circle_radius = 5,
          circle_opacity = 0.8,
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_circle_layer(
              id = layer_id,
              source = data,
              circle_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              circle_radius = 5,
              circle_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                patch_shape = "circle",
                position = legend_position,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_circle_layer(
              id = layer_id,
              source = data,
              circle_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              circle_radius = 5,
              circle_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_circle_layer(
            id = layer_id,
            source = data,
            circle_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            circle_radius = 5,
            circle_opacity = 0.8,
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              patch_shape = "circle",
              position = legend_position,
              layer_id = layer_id
            )
        }
      }
    }
  } else if (grepl("LINESTRING|MULTILINESTRING", geom_type)) {
    # LineString/MultiLineString -> line layer
    if (is.null(column)) {
      map <- map |>
        add_line_layer(
          id = layer_id,
          source = data,
          line_color = default_color,
          line_width = 2,
          line_opacity = 0.8,
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_line_layer(
              id = layer_id,
              source = data,
              line_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              line_width = 2,
              line_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                patch_shape = "line",
                position = legend_position,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_line_layer(
              id = layer_id,
              source = data,
              line_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              line_width = 2,
              line_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_line_layer(
            id = layer_id,
            source = data,
            line_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            line_width = 2,
            line_opacity = 0.8,
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              patch_shape = "line",
              position = legend_position,
              layer_id = layer_id
            )
        }
      }
    }
  } else {
    # Polygon/MultiPolygon -> fill layer
    if (is.null(column)) {
      map <- map |>
        add_fill_layer(
          id = layer_id,
          source = data,
          fill_color = default_color,
          fill_opacity = 0.6,
          fill_outline_color = "white",
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n+1 colors for n bins (base + n stops)
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_fill_layer(
              id = layer_id,
              source = data,
              fill_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              fill_opacity = 0.6,
              fill_outline_color = "white",
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                position = legend_position,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_fill_layer(
              id = layer_id,
              source = data,
              fill_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              fill_opacity = 0.6,
              fill_outline_color = "white",
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_fill_layer(
            id = layer_id,
            source = data,
            fill_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            fill_opacity = 0.6,
            fill_outline_color = "white",
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              position = legend_position,
              layer_id = layer_id
            )
        }
      }
    }
  }

  return(map)
}

#' Quick visualization of geometries with MapLibre GL
#'
#' This function provides a quick way to visualize sf geometries and raster data using MapLibre GL JS.
#' It automatically detects the geometry type and applies appropriate styling.
#'
#' @param data An sf object, SpatRaster, or RasterLayer to visualize
#' @param color The color used to visualize points, lines, or polygons if `column` is NULL.  Defaults to `"navy"`.
#' @param column The name of the column to visualize. If NULL (default), geometries are shown with default styling.
#' @param n Number of quantile breaks for numeric columns. If specified, uses step_expr() instead of interpolate().
#' @param palette Color palette function that takes n and returns a character vector of colors. Defaults to viridisLite::viridis.
#' @param style The MapLibre style to use. Defaults to carto_style("positron").
#' @param layer_id The layer ID to use for the visualization. Defaults to "quickview".
#' @param legend Logical, whether to add a legend when a column is specified. Defaults to TRUE.
#' @param legend_position The position of the legend on the map. Defaults to "top-left".
#' @param ... Additional arguments passed to maplibre()
#'
#' @return A MapLibre GL map object
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"))
#'
#' # Basic view
#' maplibre_view(nc)
#'
#' # View with column visualization
#' maplibre_view(nc, column = "AREA")
#'
#' # View with quantile breaks
#' maplibre_view(nc, column = "AREA", n = 5)
#'
#' # Custom palette examples
#' maplibre_view(nc, column = "AREA", palette = viridisLite::mako)
#' maplibre_view(nc, column = "AREA", palette = function(n) RColorBrewer::brewer.pal(n, "RdYlBu"))
#' maplibre_view(nc, column = "AREA", palette = colorRampPalette(c("red", "white", "blue")))
#' }
maplibre_view <- function(
  data,
  color = "navy",
  column = NULL,
  n = NULL,
  palette = viridisLite::viridis,
  style = carto_style("positron"),
  layer_id = "quickview",
  legend = TRUE,
  legend_position = "top-left",
  ...
) {
  if (!inherits(data, c("sf", "SpatRaster", "RasterLayer"))) {
    stop("data must be an sf object, SpatRaster, or RasterLayer")
  }

  # Check if data is a raster
  is_raster <- inherits(data, c("SpatRaster", "RasterLayer"))

  # Initialize map with bounds
  if (is_raster) {
    # For rasters, don't use bounds parameter with data
    map <- maplibre(style = style, ...)
  } else {
    # Get geometry type for sf objects
    geom_type <- sf::st_geometry_type(data, by_geometry = FALSE)
    map <- maplibre(style = style, bounds = data, ...)
  }

  # Default navy color
  default_color <- color

  # Handle raster data
  if (is_raster) {
    # Convert RasterLayer to SpatRaster if needed
    if (inherits(data, "RasterLayer")) {
      data <- terra::rast(data)
    }

    # Calculate bbox and fit bounds
    # Project to WGS84 to get bounds in the right coordinate system
    data_wgs84 <- terra::project(data, "EPSG:4326")
    bounds <- unname(sf::st_bbox(data_wgs84))

    # Generate source and layer IDs for raster
    source_id <- paste0(layer_id, "-source")

    # Get raster values for legend (single-band rasters only)
    is_single_band <- terra::nlyr(data) == 1
    raster_values <- NULL
    if (is_single_band) {
      raster_values <- terra::values(data, na.rm = TRUE)
      if (length(raster_values) > 0) {
        min_val <- min(raster_values, na.rm = TRUE)
        max_val <- max(raster_values, na.rm = TRUE)
      }
    }

    # Convert colors parameter for raster
    raster_colors <- if (!is.null(column)) {
      # If column specified, it should refer to color values
      NULL
    } else {
      # Use palette to generate colors for raster visualization
      if (
        is_single_band && !is.null(raster_values) && length(raster_values) > 0
      ) {
        palette(255)
      } else {
        NULL # Let add_image_source handle RGB rasters
      }
    }

    # Add raster source and layer
    map <- map |>
      add_image_source(
        id = source_id,
        data = data,
        colors = raster_colors
      ) |>
      add_raster_layer(
        id = layer_id,
        source = source_id,
        raster_opacity = 0.8
      ) |>
      fit_bounds(bounds)

    # Add legend for single-band rasters
    if (
      is_single_band &&
        !is.null(raster_values) &&
        length(raster_values) > 0 &&
        min_val != max_val
    ) {
      # Use same approach as vector continuous legends with 5 equal-interval breaks
      breaks <- seq(min_val, max_val, length.out = 5)
      legend_colors <- palette(5)

      map <- map |>
        add_legend(
          legend_title = if (!is.null(column)) column else "Values",
          values = c(round(min_val, 2), round(max_val, 2)),
          colors = legend_colors,
          type = "continuous",
          layer_id = layer_id
        )
    }

    return(map)
  }

  # Create popup column with all data (sf objects only)
  data_cols <- names(data)[
    !names(data) %in% c("geometry", attr(data, "sf_column"))
  ]
  if (length(data_cols) > 0) {
    popup_html <- apply(data, 1, function(row) {
      paste0(
        sapply(data_cols, function(col) {
          paste0("<strong>", col, ":</strong> ", row[[col]])
        }),
        collapse = "<br>"
      )
    })
    data$popup_content <- popup_html
  }

  # Determine layer type and add appropriate layer
  if (grepl("POINT|MULTIPOINT", geom_type)) {
    # Point/MultiPoint -> circle layer
    if (is.null(column)) {
      map <- map |>
        add_circle_layer(
          id = layer_id,
          source = data,
          circle_color = default_color,
          circle_radius = 5,
          circle_opacity = 0.8,
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_circle_layer(
              id = layer_id,
              source = data,
              circle_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              circle_radius = 5,
              circle_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                patch_shape = "circle",
                position = legend_position,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_circle_layer(
              id = layer_id,
              source = data,
              circle_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              circle_radius = 5,
              circle_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_circle_layer(
            id = layer_id,
            source = data,
            circle_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            circle_radius = 5,
            circle_opacity = 0.8,
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              patch_shape = "circle",
              position = legend_position,
              layer_id = layer_id
            )
        }
      }
    }
  } else if (grepl("LINESTRING|MULTILINESTRING", geom_type)) {
    # LineString/MultiLineString -> line layer
    if (is.null(column)) {
      map <- map |>
        add_line_layer(
          id = layer_id,
          source = data,
          line_color = default_color,
          line_width = 2,
          line_opacity = 0.8,
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_line_layer(
              id = layer_id,
              source = data,
              line_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              line_width = 2,
              line_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                patch_shape = "line",
                position = legend_position,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_line_layer(
              id = layer_id,
              source = data,
              line_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              line_width = 2,
              line_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_line_layer(
            id = layer_id,
            source = data,
            line_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            line_width = 2,
            line_opacity = 0.8,
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              patch_shape = "line",
              position = legend_position,
              layer_id = layer_id
            )
        }
      }
    }
  } else {
    # Polygon/MultiPolygon -> fill layer
    if (is.null(column)) {
      map <- map |>
        add_fill_layer(
          id = layer_id,
          source = data,
          fill_color = default_color,
          fill_opacity = 0.6,
          fill_outline_color = "white",
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_fill_layer(
              id = layer_id,
              source = data,
              fill_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              fill_opacity = 0.6,
              fill_outline_color = "white",
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                position = legend_position,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_fill_layer(
              id = layer_id,
              source = data,
              fill_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              fill_opacity = 0.6,
              fill_outline_color = "white",
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_fill_layer(
            id = layer_id,
            source = data,
            fill_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            fill_opacity = 0.6,
            fill_outline_color = "white",
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              position = legend_position,
              layer_id = layer_id
            )
        }
      }
    }
  }

  return(map)
}

#' Add a visualization layer to an existing map
#'
#' This function allows you to add additional data layers to existing maps
#' created with mapboxgl_view() or maplibre_view(), enabling composition
#' of multiple datasets on a single map.
#'
#' @param map A map object created by mapboxgl_view(), maplibre_view(), mapboxgl(), or maplibre()
#' @param data An sf object, SpatRaster, or RasterLayer to visualize
#' @param color The color used to visualize points, lines, or polygons if `column` is NULL. Defaults to "navy".
#' @param column The name of the column to visualize. If NULL (default), geometries are shown with default styling.
#' @param n Number of quantile breaks for numeric columns. If specified, uses step_expr() instead of interpolate().
#' @param palette Color palette function that takes n and returns a character vector of colors. Defaults to viridisLite::viridis.
#' @param layer_id The layer ID to use for the visualization. If NULL, a unique ID will be auto-generated.
#' @param legend Logical, whether to add a legend when a column is specified. Defaults to FALSE for subsequent layers to avoid overwriting existing legends.
#' @param legend_position The position of the legend on the map. Defaults to "bottom-left".
#'
#' @return The map object with the new layer added
#' @export
#'
#' @examples
#' \dontrun{
#' library(sf)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"))
#'
#' # Basic layering
#' mapboxgl_view(nc) |>
#'   add_view(nc[1:10, ], color = "red", layer_id = "subset")
#'
#' # Layer different geometries
#' mapboxgl_view(polygons) |>
#'   add_view(points, color = "blue") |>
#'   add_view(lines, color = "green")
#'
#' # Add raster data
#' mapboxgl_view(boundaries) |>
#'   add_view(elevation_raster, layer_id = "elevation")
#' }
add_view <- function(
  map,
  data,
  color = "gold",
  column = NULL,
  n = NULL,
  palette = viridisLite::viridis,
  layer_id = NULL,
  legend = FALSE,
  legend_position = "bottom-left"
) {
  # Validate map object
  if (
    !inherits(
      map,
      c("mapboxgl", "maplibregl", "mapboxgl_proxy", "maplibregl_proxy")
    )
  ) {
    stop("map must be a mapboxgl or maplibregl map object")
  }

  if (!inherits(data, c("sf", "SpatRaster", "RasterLayer"))) {
    stop("data must be an sf object, SpatRaster, or RasterLayer")
  }

  # Auto-generate layer ID if not provided
  if (is.null(layer_id)) {
    layer_id <- paste0(
      "view-",
      as.integer(Sys.time()),
      "-",
      sample(1000:9999, 1)
    )
  }

  # Check if data is a raster
  is_raster <- inherits(data, c("SpatRaster", "RasterLayer"))

  # Handle raster data
  if (is_raster) {
    # Convert RasterLayer to SpatRaster if needed
    if (inherits(data, "RasterLayer")) {
      data <- terra::rast(data)
    }

    # Generate source and layer IDs for raster
    source_id <- paste0(layer_id, "-source")

    # Get raster values for legend (single-band rasters only)
    is_single_band <- terra::nlyr(data) == 1
    raster_values <- NULL
    if (is_single_band) {
      raster_values <- terra::values(data, na.rm = TRUE)
      if (length(raster_values) > 0) {
        min_val <- min(raster_values, na.rm = TRUE)
        max_val <- max(raster_values, na.rm = TRUE)
      }
    }

    # Convert colors parameter for raster
    raster_colors <- if (!is.null(column)) {
      # If column specified, it should refer to color values
      NULL
    } else {
      # Use palette to generate colors for raster visualization
      if (
        is_single_band && !is.null(raster_values) && length(raster_values) > 0
      ) {
        palette(255)
      } else {
        NULL # Let add_image_source handle RGB rasters
      }
    }

    # Add raster source and layer
    map <- map |>
      add_image_source(
        id = source_id,
        data = data,
        colors = raster_colors
      ) |>
      add_raster_layer(
        id = layer_id,
        source = source_id,
        raster_opacity = 0.8
      )

    # Add legend for single-band rasters
    if (
      is_single_band &&
        !is.null(raster_values) &&
        length(raster_values) > 0 &&
        min_val != max_val &&
        legend
    ) {
      # Use same approach as vector continuous legends with 5 equal-interval breaks
      breaks <- seq(min_val, max_val, length.out = 5)
      legend_colors <- palette(5)

      map <- map |>
        add_legend(
          legend_title = if (!is.null(column)) column else "Values",
          values = c(round(min_val, 2), round(max_val, 2)),
          colors = legend_colors,
          type = "continuous",
          position = legend_position,
          add = TRUE,
          layer_id = layer_id
        )
    }

    return(map)
  }

  # Get geometry type for sf objects
  geom_type <- sf::st_geometry_type(data, by_geometry = FALSE)

  # Default color
  default_color <- color

  # Create popup column with all data (sf objects only)
  data_cols <- names(data)[
    !names(data) %in% c("geometry", attr(data, "sf_column"))
  ]
  if (length(data_cols) > 0) {
    popup_html <- apply(data, 1, function(row) {
      paste0(
        sapply(data_cols, function(col) {
          paste0("<strong>", col, ":</strong> ", row[[col]])
        }),
        collapse = "<br>"
      )
    })
    data$popup_content <- popup_html
  }

  # Determine layer type and add appropriate layer
  if (grepl("POINT|MULTIPOINT", geom_type)) {
    # Point/MultiPoint -> circle layer
    if (is.null(column)) {
      map <- map |>
        add_circle_layer(
          id = layer_id,
          source = data,
          circle_color = default_color,
          circle_radius = 5,
          circle_opacity = 0.8,
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_circle_layer(
              id = layer_id,
              source = data,
              circle_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              circle_radius = 5,
              circle_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                patch_shape = "circle",
                position = legend_position,
                add = TRUE,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_circle_layer(
              id = layer_id,
              source = data,
              circle_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              circle_radius = 5,
              circle_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                add = TRUE,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_circle_layer(
            id = layer_id,
            source = data,
            circle_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            circle_radius = 5,
            circle_opacity = 0.8,
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              patch_shape = "circle",
              position = legend_position,
              add = TRUE,
              layer_id = layer_id
            )
        }
      }
    }
  } else if (grepl("LINESTRING|MULTILINESTRING", geom_type)) {
    # LineString/MultiLineString -> line layer
    if (is.null(column)) {
      map <- map |>
        add_line_layer(
          id = layer_id,
          source = data,
          line_color = default_color,
          line_width = 2,
          line_opacity = 0.8,
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_line_layer(
              id = layer_id,
              source = data,
              line_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              line_width = 2,
              line_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                patch_shape = "line",
                position = legend_position,
                add = TRUE,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_line_layer(
              id = layer_id,
              source = data,
              line_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              line_width = 2,
              line_opacity = 0.8,
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                add = TRUE,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_line_layer(
            id = layer_id,
            source = data,
            line_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            line_width = 2,
            line_opacity = 0.8,
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              patch_shape = "line",
              position = legend_position,
              add = TRUE,
              layer_id = layer_id
            )
        }
      }
    }
  } else {
    # Polygon/MultiPolygon -> fill layer
    if (is.null(column)) {
      map <- map |>
        add_fill_layer(
          id = layer_id,
          source = data,
          fill_color = default_color,
          fill_opacity = 0.6,
          fill_outline_color = "white",
          popup = if (exists("popup_content", data)) "popup_content" else NULL
        )
    } else {
      # Check if column exists
      if (!column %in% names(data)) {
        stop(paste0("Column '", column, "' not found in data"))
      }

      col_data <- data[[column]]

      if (is.numeric(col_data)) {
        # Numeric column
        min_val <- min(col_data, na.rm = TRUE)
        max_val <- max(col_data, na.rm = TRUE)

        if (!is.null(n)) {
          # Use quantile breaks
          breaks <- quantile(
            col_data,
            probs = seq(0, 1, length.out = n + 1),
            na.rm = TRUE
          )
          breaks <- unique(breaks) # Remove duplicates
          n_breaks <- length(breaks) - 1

          # Generate n_breaks colors for n bins
          colors <- palette(n_breaks)

          # For step expressions, base is first color, stops are remaining colors
          # values are the thresholds (excluding min)
          map <- map |>
            add_fill_layer(
              id = layer_id,
              source = data,
              fill_color = step_expr(
                column = column,
                base = colors[1],
                values = breaks[2:n_breaks],
                stops = colors[2:n_breaks],
                na_color = "lightgrey"
              ),
              fill_opacity = 0.6,
              fill_outline_color = "white",
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(
                  paste0("< ", round(breaks[2], 2)),
                  if (n_breaks > 1) {
                    sapply(2:n_breaks, function(i) {
                      paste0(
                        round(breaks[i], 2),
                        " - ",
                        round(breaks[i + 1], 2)
                      )
                    })
                  } else NULL
                ),
                colors = colors,
                type = "categorical",
                position = legend_position,
                add = TRUE,
                layer_id = layer_id
              )
          }
        } else {
          # Use continuous interpolation with 5 equal-interval breaks
          breaks <- seq(min_val, max_val, length.out = 5)
          colors <- palette(5)

          map <- map |>
            add_fill_layer(
              id = layer_id,
              source = data,
              fill_color = interpolate(
                column = column,
                values = breaks,
                stops = colors,
                na_color = "lightgrey"
              ),
              fill_opacity = 0.6,
              fill_outline_color = "white",
              popup = if (exists("popup_content", data)) "popup_content" else
                NULL
            )

          if (legend) {
            map <- map |>
              add_legend(
                legend_title = column,
                values = c(round(min_val, 2), round(max_val, 2)),
                colors = colors,
                type = "continuous",
                position = legend_position,
                add = TRUE,
                layer_id = layer_id
              )
          }
        }
      } else {
        # Categorical column
        unique_vals <- unique(col_data[!is.na(col_data)])
        n_cats <- length(unique_vals)
        colors <- palette(n_cats)

        map <- map |>
          add_fill_layer(
            id = layer_id,
            source = data,
            fill_color = match_expr(
              column = column,
              values = unique_vals,
              stops = colors,
              default = "lightgrey"
            ),
            fill_opacity = 0.6,
            fill_outline_color = "white",
            popup = if (exists("popup_content", data)) "popup_content" else NULL
          )

        if (legend) {
          map <- map |>
            add_legend(
              legend_title = column,
              values = as.character(unique_vals),
              colors = colors,
              type = "categorical",
              position = legend_position
            )
        }
      }
    }
  }

  return(map)
}
