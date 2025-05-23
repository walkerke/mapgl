#' Quick visualization of geometries with Mapbox GL
#'
#' This function provides a quick way to visualize sf geometries using Mapbox GL JS.
#' It automatically detects the geometry type and applies appropriate styling.
#'
#' @param data An sf object to visualize
#' @param column The name of the column to visualize. If NULL (default), geometries are shown with default styling.
#' @param n Number of quantile breaks for numeric columns. If specified, uses step_expr() instead of interpolate().
#' @param style The Mapbox style to use. Defaults to mapbox_style("light").
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
#' }
mapboxgl_view <- function(data, column = NULL, n = NULL, style = mapbox_style("light"), ...) {
    if (!inherits(data, "sf")) {
        stop("data must be an sf object")
    }

    # Get geometry type
    geom_type <- sf::st_geometry_type(data, by_geometry = FALSE)

    # Initialize map with bounds
    map <- mapboxgl(style = style, bounds = data, ...)

    # Default navy color
    default_color <- "navy"

    # Create popup column with all data
    data_cols <- names(data)[!names(data) %in% c("geometry", attr(data, "sf_column"))]
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
                    id = "quickview",
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
                    breaks <- quantile(col_data, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)
                    breaks <- unique(breaks)  # Remove duplicates
                    n_breaks <- length(breaks) - 1

                    # Generate n_breaks colors for n bins
                    colors <- viridisLite::viridis(n_breaks)

                    # For step expressions, base is first color, stops are remaining colors
                    # values are the thresholds (excluding min)
                    map <- map |>
                        add_circle_layer(
                            id = "quickview",
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
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(
                                paste0("< ", round(breaks[2], 2)),
                                if (n_breaks > 1) {
                                    sapply(2:n_breaks, function(i) {
                                        paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                                    })
                                } else NULL
                            ),
                            colors = colors,
                            type = "categorical"
                        )
                } else {
                    # Use continuous interpolation with 5 equal-interval breaks
                    breaks <- seq(min_val, max_val, length.out = 5)
                    colors <- viridisLite::viridis(5)

                    map <- map |>
                        add_circle_layer(
                            id = "quickview",
                            source = data,
                            circle_color = interpolate(
                                column = column,
                                values = breaks,
                                stops = colors,
                                na_color = "lightgrey"
                            ),
                            circle_radius = 5,
                            circle_opacity = 0.8,
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(round(min_val, 2), round(max_val, 2)),
                            colors = colors,
                            type = "continuous"
                        )
                }
            } else {
                # Categorical column
                unique_vals <- unique(col_data[!is.na(col_data)])
                n_cats <- length(unique_vals)
                colors <- viridisLite::viridis(n_cats)

                map <- map |>
                    add_circle_layer(
                        id = "quickview",
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
                    ) |>
                    add_legend(
                        legend_title = column,
                        values = as.character(unique_vals),
                        colors = colors,
                        type = "categorical"
                    )
            }
        }
    } else if (grepl("LINESTRING|MULTILINESTRING", geom_type)) {
        # LineString/MultiLineString -> line layer
        if (is.null(column)) {
            map <- map |>
                add_line_layer(
                    id = "quickview",
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
                    breaks <- quantile(col_data, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)
                    breaks <- unique(breaks)  # Remove duplicates
                    n_breaks <- length(breaks) - 1

                    # Generate n_breaks colors for n bins
                    colors <- viridisLite::viridis(n_breaks)

                    # For step expressions, base is first color, stops are remaining colors
                    # values are the thresholds (excluding min)
                    map <- map |>
                        add_line_layer(
                            id = "quickview",
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
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(
                                paste0("< ", round(breaks[2], 2)),
                                if (n_breaks > 1) {
                                    sapply(2:n_breaks, function(i) {
                                        paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                                    })
                                } else NULL
                            ),
                            colors = colors,
                            type = "categorical"
                        )
                } else {
                    # Use continuous interpolation with 5 equal-interval breaks
                    breaks <- seq(min_val, max_val, length.out = 5)
                    colors <- viridisLite::viridis(5)

                    map <- map |>
                        add_line_layer(
                            id = "quickview",
                            source = data,
                            line_color = interpolate(
                                column = column,
                                values = breaks,
                                stops = colors,
                                na_color = "lightgrey"
                            ),
                            line_width = 2,
                            line_opacity = 0.8,
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(round(min_val, 2), round(max_val, 2)),
                            colors = colors,
                            type = "continuous"
                        )
                }
            } else {
                # Categorical column
                unique_vals <- unique(col_data[!is.na(col_data)])
                n_cats <- length(unique_vals)
                colors <- viridisLite::viridis(n_cats)

                map <- map |>
                    add_line_layer(
                        id = "quickview",
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
                    ) |>
                    add_legend(
                        legend_title = column,
                        values = as.character(unique_vals),
                        colors = colors,
                        type = "categorical"
                    )
            }
        }
    } else {
        # Polygon/MultiPolygon -> fill layer
        if (is.null(column)) {
            map <- map |>
                add_fill_layer(
                    id = "quickview",
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
                    breaks <- quantile(col_data, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)
                    breaks <- unique(breaks)  # Remove duplicates
                    n_breaks <- length(breaks) - 1

                    # Generate n+1 colors for n bins (base + n stops)
                    colors <- viridisLite::viridis(n_breaks)

                    # For step expressions, base is first color, stops are remaining colors
                    # values are the thresholds (excluding min)
                    map <- map |>
                        add_fill_layer(
                            id = "quickview",
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
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(
                                paste0("< ", round(breaks[2], 2)),
                                if (n_breaks > 1) {
                                    sapply(2:n_breaks, function(i) {
                                        paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                                    })
                                } else NULL
                            ),
                            colors = colors,
                            type = "categorical"
                        )
                } else {
                    # Use continuous interpolation with 5 equal-interval breaks
                    breaks <- seq(min_val, max_val, length.out = 5)
                    colors <- viridisLite::viridis(5)

                    map <- map |>
                        add_fill_layer(
                            id = "quickview",
                            source = data,
                            fill_color = interpolate(
                                column = column,
                                values = breaks,
                                stops = colors,
                                na_color = "lightgrey"
                            ),
                            fill_opacity = 0.6,
                            fill_outline_color = "white",
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(round(min_val, 2), round(max_val, 2)),
                            colors = colors,
                            type = "continuous"
                        )
                }
            } else {
                # Categorical column
                unique_vals <- unique(col_data[!is.na(col_data)])
                n_cats <- length(unique_vals)
                colors <- viridisLite::viridis(n_cats)

                map <- map |>
                    add_fill_layer(
                        id = "quickview",
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
                    ) |>
                    add_legend(
                        legend_title = column,
                        values = as.character(unique_vals),
                        colors = colors,
                        type = "categorical"
                    )
            }
        }
    }

    return(map)
}

#' Quick visualization of geometries with MapLibre GL
#'
#' This function provides a quick way to visualize sf geometries using MapLibre GL JS.
#' It automatically detects the geometry type and applies appropriate styling.
#'
#' @param data An sf object to visualize
#' @param column The name of the column to visualize. If NULL (default), geometries are shown with default styling.
#' @param n Number of quantile breaks for numeric columns. If specified, uses step_expr() instead of interpolate().
#' @param style The MapLibre style to use. Defaults to carto_style("positron").
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
#' }
maplibre_view <- function(data, column = NULL, n = NULL, style = carto_style("positron"), ...) {
    if (!inherits(data, "sf")) {
        stop("data must be an sf object")
    }

    # Get geometry type
    geom_type <- sf::st_geometry_type(data, by_geometry = FALSE)

    # Initialize map with bounds
    map <- maplibre(style = style, bounds = data, ...)

    # Default navy color
    default_color <- "navy"

    # Create popup column with all data
    data_cols <- names(data)[!names(data) %in% c("geometry", attr(data, "sf_column"))]
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
                    id = "quickview",
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
                    breaks <- quantile(col_data, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)
                    breaks <- unique(breaks)  # Remove duplicates
                    n_breaks <- length(breaks) - 1

                    # Generate n_breaks colors for n bins
                    colors <- viridisLite::viridis(n_breaks)

                    # For step expressions, base is first color, stops are remaining colors
                    # values are the thresholds (excluding min)
                    map <- map |>
                        add_circle_layer(
                            id = "quickview",
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
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(
                                paste0("< ", round(breaks[2], 2)),
                                if (n_breaks > 1) {
                                    sapply(2:n_breaks, function(i) {
                                        paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                                    })
                                } else NULL
                            ),
                            colors = colors,
                            type = "categorical"
                        )
                } else {
                    # Use continuous interpolation with 5 equal-interval breaks
                    breaks <- seq(min_val, max_val, length.out = 5)
                    colors <- viridisLite::viridis(5)

                    map <- map |>
                        add_circle_layer(
                            id = "quickview",
                            source = data,
                            circle_color = interpolate(
                                column = column,
                                values = breaks,
                                stops = colors,
                                na_color = "lightgrey"
                            ),
                            circle_radius = 5,
                            circle_opacity = 0.8,
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(round(min_val, 2), round(max_val, 2)),
                            colors = colors,
                            type = "continuous"
                        )
                }
            } else {
                # Categorical column
                unique_vals <- unique(col_data[!is.na(col_data)])
                n_cats <- length(unique_vals)
                colors <- viridisLite::viridis(n_cats)

                map <- map |>
                    add_circle_layer(
                        id = "quickview",
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
                    ) |>
                    add_legend(
                        legend_title = column,
                        values = as.character(unique_vals),
                        colors = colors,
                        type = "categorical"
                    )
            }
        }
    } else if (grepl("LINESTRING|MULTILINESTRING", geom_type)) {
        # LineString/MultiLineString -> line layer
        if (is.null(column)) {
            map <- map |>
                add_line_layer(
                    id = "quickview",
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
                    breaks <- quantile(col_data, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)
                    breaks <- unique(breaks)  # Remove duplicates
                    n_breaks <- length(breaks) - 1

                    # Generate n_breaks colors for n bins
                    colors <- viridisLite::viridis(n_breaks)

                    # For step expressions, base is first color, stops are remaining colors
                    # values are the thresholds (excluding min)
                    map <- map |>
                        add_line_layer(
                            id = "quickview",
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
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(
                                paste0("< ", round(breaks[2], 2)),
                                if (n_breaks > 1) {
                                    sapply(2:n_breaks, function(i) {
                                        paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                                    })
                                } else NULL
                            ),
                            colors = colors,
                            type = "categorical"
                        )
                } else {
                    # Use continuous interpolation with 5 equal-interval breaks
                    breaks <- seq(min_val, max_val, length.out = 5)
                    colors <- viridisLite::viridis(5)

                    map <- map |>
                        add_line_layer(
                            id = "quickview",
                            source = data,
                            line_color = interpolate(
                                column = column,
                                values = breaks,
                                stops = colors,
                                na_color = "lightgrey"
                            ),
                            line_width = 2,
                            line_opacity = 0.8,
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(round(min_val, 2), round(max_val, 2)),
                            colors = colors,
                            type = "continuous"
                        )
                }
            } else {
                # Categorical column
                unique_vals <- unique(col_data[!is.na(col_data)])
                n_cats <- length(unique_vals)
                colors <- viridisLite::viridis(n_cats)

                map <- map |>
                    add_line_layer(
                        id = "quickview",
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
                    ) |>
                    add_legend(
                        legend_title = column,
                        values = as.character(unique_vals),
                        colors = colors,
                        type = "categorical"
                    )
            }
        }
    } else {
        # Polygon/MultiPolygon -> fill layer
        if (is.null(column)) {
            map <- map |>
                add_fill_layer(
                    id = "quickview",
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
                    breaks <- quantile(col_data, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)
                    breaks <- unique(breaks)  # Remove duplicates
                    n_breaks <- length(breaks) - 1

                    # Generate n_breaks colors for n bins
                    colors <- viridisLite::viridis(n_breaks)

                    # For step expressions, base is first color, stops are remaining colors
                    # values are the thresholds (excluding min)
                    map <- map |>
                        add_fill_layer(
                            id = "quickview",
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
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(
                                paste0("< ", round(breaks[2], 2)),
                                if (n_breaks > 1) {
                                    sapply(2:n_breaks, function(i) {
                                        paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                                    })
                                } else NULL
                            ),
                            colors = colors,
                            type = "categorical"
                        )
                } else {
                    # Use continuous interpolation with 5 equal-interval breaks
                    breaks <- seq(min_val, max_val, length.out = 5)
                    colors <- viridisLite::viridis(5)

                    map <- map |>
                        add_fill_layer(
                            id = "quickview",
                            source = data,
                            fill_color = interpolate(
                                column = column,
                                values = breaks,
                                stops = colors,
                                na_color = "lightgrey"
                            ),
                            fill_opacity = 0.6,
                            fill_outline_color = "white",
                            popup = if (exists("popup_content", data)) "popup_content" else NULL
                        ) |>
                        add_legend(
                            legend_title = column,
                            values = c(round(min_val, 2), round(max_val, 2)),
                            colors = colors,
                            type = "continuous"
                        )
                }
            } else {
                # Categorical column
                unique_vals <- unique(col_data[!is.na(col_data)])
                n_cats <- length(unique_vals)
                colors <- viridisLite::viridis(n_cats)

                map <- map |>
                    add_fill_layer(
                        id = "quickview",
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
                    ) |>
                    add_legend(
                        legend_title = column,
                        values = as.character(unique_vals),
                        colors = colors,
                        type = "categorical"
                    )
            }
        }
    }

    return(map)
}
