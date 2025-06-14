#' Create an interpolation expression
#'
#' This function generates an interpolation expression that can be used to style your data.
#'
#' @param column The name of the column to use for the interpolation. If specified, `property` should be NULL.
#' @param property The name of the property to use for the interpolation. If specified, `column` should be NULL.
#' @param type The interpolation type. Can be one of `"linear"`, `list("exponential", base)` where `base` specifies the rate at which the output increases, or `list("cubic-bezier", x1, y1, x2, y2)` where you define a cubic bezier curve with control points.
#' @param values A numeric vector of values at which stops occur.
#' @param stops A vector of corresponding stops (colors, sizes, etc.) for the interpolation.
#' @param na_color The color to use for missing values.  Mapbox GL JS defaults to black if this is not supplied.
#'
#' @return A list representing the interpolation expression.
#' @export
#'
#' @examples
#' interpolate(
#'     column = "estimate",
#'     type = "linear",
#'     values = c(1000, 200000),
#'     stops = c("#eff3ff", "#08519c")
#' )
interpolate <- function(column = NULL,
                        property = NULL,
                        type = "linear",
                        values,
                        stops,
                        na_color = NULL) {
    if (length(values) != length(stops)) {
        rlang::abort("`values` and `stops` must have the same length.")
    }

    stops <- trim_hex_colors(stops)

    if (!is.null(column)) {
        to_map <- list("get", column)
    } else if (!is.null(property)) {
        to_map <- list(property)
    } else {
        rlang::abort("You must specify a column or property, but not both.")
    }

    if (length(type) == 1 && !is.list(type)) {
        type <- list(type)
    }

    expr <- list("interpolate", type, to_map)
    for (i in seq_along(values)) {
        expr <- c(expr, list(values[i]), list(stops[i]))
    }

    if (!is.null(na_color)) {
        na_color <- trim_hex_colors(na_color)

        expr_with_na <- list("case", list("==", to_map, NULL), na_color, expr)

        expr_with_na
    } else {
        expr
    }
}

#' Create a match expression
#'
#' This function generates a match expression that can be used to style your data.
#'
#' @param column The name of the column to use for the match expression. If specified, `property` should be NULL.
#' @param property The name of the property to use for the match expression. If specified, `column` should be NULL.
#' @param values A vector of values to match against.
#' @param stops A vector of corresponding stops (colors, etc.) for the matched values.
#' @param default A default value to use if no matches are found.
#'
#' @return A list representing the match expression.
#' @export
#'
#' @examples
#' match_expr(
#'     column = "category",
#'     values = c("A", "B", "C"),
#'     stops = c("#ff0000", "#00ff00", "#0000ff"),
#'     default = "#cccccc"
#' )
match_expr <- function(column = NULL, property = NULL, values, stops, default = "#cccccc") {
    if (length(values) != length(stops)) {
        rlang::abort("`values` and `stops` must have the same length.")
    }

    stops <- trim_hex_colors(stops)
    default <- trim_hex_colors(default)

    if (!is.null(column)) {
        to_map <- list("get", column)
    } else if (!is.null(property)) {
        to_map <- list(property)
    } else {
        rlang::abort("You must specify a column or property, but not both.")
    }

    expr <- list("match", to_map)
    for (i in seq_along(values)) {
        expr <- c(expr, values[i], stops[i])
    }

    if (!is.null(default)) {
        expr <- c(expr, default)
    }

    expr
}

#' Create a step expression
#'
#' This function generates a step expression that can be used in your styles.
#'
#' @param column The name of the column to use for the step expression. If specified, `property` should be NULL.
#' @param property The name of the property to use for the step expression. If specified, `column` should be NULL.
#' @param base The base value to use for the step expression.
#' @param values A numeric vector of values at which steps occur.
#' @param stops A vector of corresponding stops (colors, sizes, etc.) for the steps.
#' @param na_color The color to use for missing values.  Mapbox GL JS defaults to black if this is not supplied.
#'
#' @return A list representing the step expression.
#' @export
#'
#' @examples
#' step_expr(
#'     column = "value",
#'     base = "#ffffff",
#'     values = c(1000, 5000, 10000),
#'     stops = c("#ff0000", "#00ff00", "#0000ff")
#' )
step_expr <- function(column = NULL, property = NULL, base, values, stops,
                      na_color = NULL) {
    if (length(values) != length(stops)) {
        rlang::abort("`values` and `stops` must have the same length.")
    }

    # Trim colors as needed
    base <- trim_hex_colors(base)
    stops <- trim_hex_colors(stops)

    if (!is.null(column)) {
        to_map <- list("get", column)
    } else if (!is.null(property)) {
        to_map <- list(property)
    } else {
        rlang::abort("You must specify a column or property, but not both.")
    }

    expr <- list("step", to_map)
    if (!is.null(base)) {
        expr <- c(expr, base)
    }
    for (i in seq_along(values)) {
        expr <- c(expr, values[i], stops[i])
    }

    if (!is.null(na_color)) {
        na_color <- trim_hex_colors(na_color)

        expr_with_na <- list("case", list("==", to_map, NULL), na_color, expr)

        expr_with_na
    } else {
        expr
    }
}

#' Set a configuration property for a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function or a proxy object defined with `mapboxgl_proxy()`.
#' @param import_id The name of the imported style to set the config for (e.g., 'basemap').
#' @param config_name The name of the configuration property from the style.
#' @param value The value to set for the configuration property.
#'
#' @return The updated map object with the configuration property set.
#' @export
set_config_property <- function(map, import_id, config_name, value) {
    config <- list(importId = import_id, configName = config_name, value = value)

    if (inherits(map, "mapboxgl_proxy")) {
        map$session$sendCustomMessage("mapboxgl-proxy", list(id = map$id, message = list(type = "set_config_property", importId = import_id, configName = config_name, value = value)))
    } else {
        if (is.null(map$x$config_properties)) {
            map$x$config_properties <- list()
        }
        map$x$config_properties <- append(map$x$config_properties, list(config))
    }

    return(map)
}

#' Get Mapbox Style URL
#'
#' @param style_name The name of the style (e.g., "standard", "streets", "outdoors", etc.).
#' @return The style URL corresponding to the given style name.
#' @export
mapbox_style <- function(style_name) {
    styles <- list(
        standard = "mapbox://styles/mapbox/standard",
        streets = "mapbox://styles/mapbox/streets-v12",
        outdoors = "mapbox://styles/mapbox/outdoors-v12",
        light = "mapbox://styles/mapbox/light-v11",
        dark = "mapbox://styles/mapbox/dark-v11",
        satellite = "mapbox://styles/mapbox/satellite-v9",
        `satellite-streets` = "mapbox://styles/mapbox/satellite-streets-v12",
        `navigation-day` = "mapbox://styles/mapbox/navigation-day-v1",
        `navigation-night` = "mapbox://styles/mapbox/navigation-night-v1",
        `standard-satellite` = "mapbox://styles/mapbox/standard-satellite"
    )

    style_url <- styles[[style_name]]

    if (is.null(style_url)) {
        stop("Invalid style name. Please choose from: standard, streets, outdoors, light, dark, satellite, satellite-streets, navigation-day, navigation-night, standard-satellite.")
    }

    return(style_url)
}

#' Get MapTiler Style URL
#'
#' @param style_name The name of the style (e.g., "basic", "streets", "toner", etc.).
#' @param variant The color variant of the style. Options are "dark", "light", or "pastel". Default is NULL (standard variant). Not all styles support all variants.
#' @param api_key Your MapTiler API key (required)
#' @return The style URL corresponding to the given style name and variant.
#' @export
maptiler_style <- function(style_name, variant = NULL, api_key = NULL) {
    if (is.null(api_key)) {
        if (Sys.getenv("MAPTILER_API_KEY") == "") {
            rlang::abort("A MapTiler API key is required. Get one at https://www.maptiler.com, then supply it here or set it in your .Renviron file with 'MAPTILER_API_KEY'='YOUR_KEY_HERE'.")
        } else {
            api_key <- Sys.getenv("MAPTILER_API_KEY")
        }
    }

    # Define which variants are available for each style
    variant_support <- list(
        backdrop = c("dark", "light"),
        basic = c("dark", "light"),
        bright = c("dark", "pastel"),
        dataviz = c("dark", "light"),
        hybrid = character(0),
        landscape = character(0),
        ocean = character(0),
        openstreetmap = character(0),
        outdoor = c("dark"),
        satellite = character(0),
        streets = c("dark", "light", "pastel"),
        toner = c("light"),
        topo = c("dark", "pastel"),
        winter = c("dark")
    )

    styles <- list(
        backdrop = "https://api.maptiler.com/maps/backdrop/style.json",
        basic = "https://api.maptiler.com/maps/basic-v2/style.json",
        bright = "https://api.maptiler.com/maps/bright-v2/style.json",
        dataviz = "https://api.maptiler.com/maps/dataviz/style.json",
        hybrid = "https://api.maptiler.com/maps/hybrid/style.json",
        landscape = "https://api.maptiler.com/maps/landscape/style.json",
        ocean = "https://api.maptiler.com/maps/ocean/style.json",
        openstreetmap = "https://api.maptiler.com/maps/openstreetmap/style.json",
        outdoor = "https://api.maptiler.com/maps/outdoor-v2/style.json",
        satellite = "https://api.maptiler.com/maps/satellite/style.json",
        streets = "https://api.maptiler.com/maps/streets-v2/style.json",
        toner = "https://api.maptiler.com/maps/toner-v2/style.json",
        topo = "https://api.maptiler.com/maps/topo-v2/style.json",
        winter = "https://api.maptiler.com/maps/winter-v2/style.json"
    )

    style_url <- styles[[style_name]]

    if (is.null(style_url)) {
        stop("Invalid style name. Please choose from: backdrop, basic, bright, dataviz, landscape, ocean, openstreetmap, outdoor, satellite, streets, toner, topo, and winter.")
    }

    # Check if variant is requested and supported
    if (!is.null(variant)) {
        if (!variant %in% c("dark", "light", "pastel")) {
            stop("Invalid variant. Please choose from: dark, light, or pastel.")
        }

        supported_variants <- variant_support[[style_name]]
        if (!variant %in% supported_variants) {
            if (length(supported_variants) == 0) {
                stop(paste0("Style '", style_name, "' does not support any color variants."))
            } else {
                stop(paste0("Style '", style_name, "' does not support the '", variant, "' variant. Available variants: ", paste(supported_variants, collapse = ", ")))
            }
        }

        # Modify URL to include variant
        style_url <- gsub("/style\\.json$", paste0("-", variant, "/style.json"), style_url)
    }

    style_url_with_key <- paste0(style_url, "?key=", api_key)

    return(style_url_with_key)
}

#' Create an interpolation expression with automatic palette and break calculation
#'
#' This function creates an interpolation expression by automatically calculating
#' break points using different methods and applying a color palette. It handles
#' the values/stops matching automatically and supports the same classification
#' methods as the step functions.
#'
#' @param column The name of the column to use for the interpolation.
#' @param data_values A numeric vector of the actual data values used to calculate breaks.
#' @param method The method for calculating breaks. Options are "equal" (equal intervals),
#'   "quantile" (quantile breaks), or "jenks" (Jenks natural breaks). Defaults to "equal".
#' @param n The number of break points to create. Defaults to 5.
#' @param palette A function that takes n and returns a character vector of colors.
#'   Defaults to viridisLite::viridis.
#' @param na_color The color to use for missing values. Defaults to "grey".
#'
#' @return A list of class "mapgl_continuous_scale" containing the interpolation expression and metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' # Create continuous color scale
#' data_values <- c(10, 25, 30, 45, 60, 75, 90)
#' scale <- interpolate_palette("value", data_values, method = "equal", n = 5)
#' 
#' # Use in a layer
#' add_fill_layer(map, fill_color = scale$expression)
#' 
#' # Extract legend information  
#' labels <- get_legend_labels(scale, format = "currency")
#' colors <- scale$colors
#' }
interpolate_palette <- function(column, data_values, method = "equal", n = 5, 
                               palette = viridisLite::viridis, na_color = "grey") {
    if (!is.numeric(data_values)) {
        rlang::abort("data_values must be numeric")
    }
    
    if (n < 2) {
        rlang::abort("n must be at least 2")
    }
    
    # Remove missing values for break calculation
    clean_values <- data_values[!is.na(data_values)]
    
    if (length(clean_values) == 0) {
        rlang::abort("No non-missing values found in data_values")
    }
    
    # Calculate breaks based on method
    if (method == "equal") {
        min_val <- min(clean_values)
        max_val <- max(clean_values)
        if (min_val == max_val) {
            rlang::warn("All values are identical, cannot create intervals")
            breaks <- c(min_val, min_val)
            n <- 2
        } else {
            breaks <- seq(min_val, max_val, length.out = n)
        }
    } else if (method == "quantile") {
        breaks <- quantile(clean_values, probs = seq(0, 1, length.out = n), na.rm = TRUE)
        breaks <- unique(breaks)  # Remove duplicates
        n_actual <- length(breaks)
        if (n_actual < n) {
            rlang::warn(paste0("Only ", n_actual, " unique quantiles possible due to repeated values"))
            n <- n_actual
        }
    } else if (method == "jenks") {
        n_unique <- length(unique(clean_values))
        if (n_unique < n) {
            rlang::warn(paste0("Only ", n_unique, " unique values available, reducing breaks to ", n_unique))
            n <- n_unique
        }
        
        if (n == 1) {
            breaks <- c(min(clean_values), max(clean_values))
        } else {
            class_intervals <- classInt::classIntervals(clean_values, n = n, style = "jenks")
            breaks <- class_intervals$brks
        }
    } else {
        rlang::abort("method must be one of 'equal', 'quantile', or 'jenks'")
    }
    
    # Generate colors - this automatically matches the number of breaks
    colors <- palette(length(breaks))
    
    # Create interpolate expression
    expr <- interpolate(column = column, values = breaks, stops = colors, na_color = na_color)
    
    # Return continuous scale object
    result <- list(
        expression = expr,
        breaks = breaks,
        colors = colors,
        method = paste0("interpolate_", method),
        n_breaks = length(breaks)
    )
    
    class(result) <- "mapgl_continuous_scale"
    result
}


#' Get CARTO Style URL
#'
#' @param style_name The name of the style (e.g., "voyager", "positron", "dark-matter").
#' @return The style URL corresponding to the given style name.
#' @export
carto_style <- function(style_name) {
    styles <- list(
        voyager = "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json",
        positron = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
        `dark-matter` = "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
        `voyager-no-labels` = "https://basemaps.cartocdn.com/gl/voyager-nolabels-gl-style/style.json",
        `positron-no-labels` = "https://basemaps.cartocdn.com/gl/positron-nolabels-gl-style/style.json",
        `dark-matter-no-labels` = "https://basemaps.cartocdn.com/gl/dark-matter-nolabels-gl-style/style.json"
    )

    style_url <- styles[[style_name]]

    if (is.null(style_url)) {
        stop("Invalid style name. Please choose from: voyager, positron, dark-matter, voyager-no-labels, positron-no-labels, or dark-matter-no-labels")
    }

    return(style_url)
}

#' Get column or property for use in mapping
#'
#' This function returns a an expression to get a specified column from a dataset (or a property from a layer).
#'
#' @param column The name of the column or property to get.
#'
#' @return A list representing the expression to get the column.
#' @export
get_column <- function(column) {
    list("get", column)
}

#' Create a concatenation expression
#'
#' This function creates a concatenation expression that combines multiple values or expressions into a single string.
#' Useful for creating dynamic tooltips or labels.
#'
#' @param ... Values or expressions to concatenate. Can be strings, numbers, or other expressions like `get_column()`.
#'
#' @return A list representing the concatenation expression.
#' @export
#' @examples
#' # Create a dynamic tooltip
#' concat("<strong>Name:</strong> ", get_column("name"), "<br>Value: ", get_column("value"))
concat <- function(...) {
    c(list("concat"), list(...))
}

#' Create a number formatting expression
#'
#' This function creates a number formatting expression that formats numeric values
#' according to locale-specific conventions. It can be used in tooltips, popups,
#' and text fields for symbol layers.
#'
#' @param column The name of the column containing the numeric value to format.
#'   Can also be an expression that evaluates to a number.
#' @param locale A string specifying the locale to use for formatting (e.g., "en-US",
#'   "de-DE", "fr-FR"). Defaults to "en-US".
#' @param style The formatting style to use. Options include:
#'   - "decimal" (default): Plain number formatting
#'   - "currency": Currency formatting (requires `currency` parameter)
#'   - "percent": Percentage formatting (multiplies by 100 and adds %)
#'   - "unit": Unit formatting (requires `unit` parameter)
#' @param currency For style = "currency", the ISO 4217 currency code (e.g., "USD", "EUR", "GBP").
#' @param unit For style = "unit", the unit to use (e.g., "kilometer", "mile", "liter").
#' @param minimum_fraction_digits The minimum number of fraction digits to display.
#' @param maximum_fraction_digits The maximum number of fraction digits to display.
#' @param minimum_integer_digits The minimum number of integer digits to display.
#' @param use_grouping Whether to use grouping separators (e.g., thousands separators).
#'   Defaults to TRUE.
#' @param notation The formatting notation. Options include:
#'   - "standard" (default): Regular notation
#'   - "scientific": Scientific notation
#'   - "engineering": Engineering notation
#'   - "compact": Compact notation (e.g., "1.2K", "3.4M")
#' @param compact_display For notation = "compact", whether to use "short" (default)
#'   or "long" form.
#'
#' @return A list representing the number-format expression.
#' @export
#' @examples
#' # Basic number formatting with thousands separators
#' number_format("population")
#'
#' # Currency formatting
#' number_format("income", style = "currency", currency = "USD")
#'
#' # Percentage with 1 decimal place
#' number_format("rate", style = "percent", maximum_fraction_digits = 1)
#'
#' # Compact notation for large numbers
#' number_format("population", notation = "compact")
#'
#' # Using within a tooltip
#' concat("Population: ", number_format("population", notation = "compact"))
#'
#' # Using with get_column()
#' number_format(get_column("value"), style = "currency", currency = "EUR")
number_format <- function(column,
                          locale = "en-US",
                          style = "decimal",
                          currency = NULL,
                          unit = NULL,
                          minimum_fraction_digits = NULL,
                          maximum_fraction_digits = NULL,
                          minimum_integer_digits = NULL,
                          use_grouping = NULL,
                          notation = NULL,
                          compact_display = NULL) {

    # Handle column input - can be a string or an expression
    if (is.character(column) && length(column) == 1) {
        column_expr <- get_column(column)
    } else {
        column_expr <- column
    }

    # Build options list
    options <- list(locale = locale)

    # Add style options
    if (!is.null(style)) options$style <- style
    if (!is.null(currency)) options$currency <- currency
    if (!is.null(unit)) options$unit <- unit

    # Add digit options (using hyphenated names for JS compatibility)
    if (!is.null(minimum_fraction_digits)) options$`min-fraction-digits` <- minimum_fraction_digits
    if (!is.null(maximum_fraction_digits)) options$`max-fraction-digits` <- maximum_fraction_digits
    if (!is.null(minimum_integer_digits)) options$`min-integer-digits` <- minimum_integer_digits

    # Add other options
    if (!is.null(use_grouping)) options$useGrouping <- use_grouping
    if (!is.null(notation)) options$notation <- notation
    if (!is.null(compact_display)) options$compactDisplay <- compact_display

    # Return the expression
    list("number-format", column_expr, options)
}

# Trim hex colors (so packages like viridisLite can be used)
trim_hex_colors <- function(colors) {
    ifelse(substr(colors, 1, 1) == "#" & nchar(colors) == 9,
        substr(colors, 1, nchar(colors) - 2),
        colors
    )
}

#' Create a step expression with equal interval classification
#'
#' This function creates a step expression using equal interval breaks, similar to
#' choropleth mapping in GIS software. It automatically calculates break points
#' by dividing the data range into equal intervals.
#'
#' @param column The name of the column to use for the step expression.
#' @param data_values A numeric vector of the actual data values used to calculate breaks.
#' @param n The number of classes/intervals to create. Defaults to 5.
#' @param colors A vector of colors to use. If NULL, uses viridisLite::viridis(n).
#' @param na_color The color to use for missing values. Defaults to "grey".
#'
#' @return A list of class "mapgl_classification" containing the step expression and metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' # Create equal interval classification
#' data_values <- c(10, 25, 30, 45, 60, 75, 90)
#' classification <- step_equal_interval("value", data_values, n = 4)
#' 
#' # Use in a layer
#' add_circle_layer(map, circle_color = classification$expression)
#' 
#' # Extract legend information
#' labels <- classification$labels
#' colors <- classification$colors
#' }
step_equal_interval <- function(column, data_values, n = 5, colors = NULL, na_color = "grey") {
    if (!is.numeric(data_values)) {
        rlang::abort("data_values must be numeric")
    }
    
    if (n < 2) {
        rlang::abort("n must be at least 2")
    }
    
    # Remove missing values for break calculation
    clean_values <- data_values[!is.na(data_values)]
    
    if (length(clean_values) == 0) {
        rlang::abort("No non-missing values found in data_values")
    }
    
    # Calculate equal interval breaks
    min_val <- min(clean_values, na.rm = TRUE)
    max_val <- max(clean_values, na.rm = TRUE)
    
    if (min_val == max_val) {
        rlang::warn("All values are identical, cannot create intervals")
        breaks <- c(min_val, min_val)
        n <- 1
    } else {
        breaks <- seq(min_val, max_val, length.out = n + 1)
    }
    
    # Generate colors if not provided
    if (is.null(colors)) {
        colors <- viridisLite::viridis(n)
    } else if (length(colors) != n) {
        rlang::abort(paste0("colors must have length ", n, " to match number of classes"))
    }
    
    # Create step expression
    if (n == 1) {
        # Special case for single class
        expr <- step_expr(column = column, base = colors[1], values = numeric(0), stops = character(0), na_color = na_color)
        labels <- paste0(round(min_val, 2), " - ", round(max_val, 2))
    } else {
        # Normal case with multiple classes
        threshold_values <- breaks[2:n]
        stop_colors <- colors[2:n]
        
        expr <- step_expr(
            column = column,
            base = colors[1],
            values = threshold_values,
            stops = stop_colors,
            na_color = na_color
        )
        
        # Create legend labels
        labels <- c(
            paste0("< ", round(breaks[2], 2)),
            if (n > 2) {
                sapply(2:(n-1), function(i) {
                    paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                })
            },
            if (n > 1) paste0(round(breaks[n], 2), "+")
        )
    }
    
    # Return classification object
    result <- list(
        expression = expr,
        breaks = breaks,
        colors = colors,
        labels = labels,
        method = "equal_interval",
        n_classes = n
    )
    
    class(result) <- "mapgl_classification"
    result
}

#' Create a step expression with quantile classification
#'
#' This function creates a step expression using quantile breaks, ensuring
#' approximately equal numbers of observations in each class. This is similar
#' to quantile-based choropleth mapping in GIS software.
#'
#' @param column The name of the column to use for the step expression.
#' @param data_values A numeric vector of the actual data values used to calculate breaks.
#' @param n The number of classes/quantiles to create. Defaults to 5.
#' @param colors A vector of colors to use. If NULL, uses viridisLite::viridis(n).
#' @param na_color The color to use for missing values. Defaults to "grey".
#'
#' @return A list of class "mapgl_classification" containing the step expression and metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' # Create quantile classification
#' data_values <- c(10, 15, 20, 25, 30, 35, 40, 45, 50, 100)
#' classification <- step_quantile("value", data_values, n = 4)
#' 
#' # Use in a layer
#' add_fill_layer(map, fill_color = classification$expression)
#' 
#' # Extract legend information
#' labels <- classification$labels
#' colors <- classification$colors
#' }
step_quantile <- function(column, data_values, n = 5, colors = NULL, na_color = "grey") {
    if (!is.numeric(data_values)) {
        rlang::abort("data_values must be numeric")
    }
    
    if (n < 2) {
        rlang::abort("n must be at least 2")
    }
    
    # Remove missing values for break calculation
    clean_values <- data_values[!is.na(data_values)]
    
    if (length(clean_values) == 0) {
        rlang::abort("No non-missing values found in data_values")
    }
    
    # Calculate quantile breaks
    breaks <- quantile(
        clean_values,
        probs = seq(0, 1, length.out = n + 1),
        na.rm = TRUE
    )
    
    # Remove duplicate breaks (can happen with repeated values)
    breaks <- unique(breaks)
    n_actual <- length(breaks) - 1
    
    if (n_actual < n) {
        rlang::warn(paste0("Only ", n_actual, " unique quantiles possible due to repeated values"))
        n <- n_actual
    }
    
    # Generate colors if not provided
    if (is.null(colors)) {
        colors <- viridisLite::viridis(n)
    } else if (length(colors) != n) {
        colors <- colors[1:n]  # Truncate or recycle colors to match n
        rlang::warn(paste0("Adjusting colors to match ", n, " classes"))
    }
    
    # Create step expression
    if (n == 1) {
        # Special case for single class
        expr <- step_expr(column = column, base = colors[1], values = numeric(0), stops = character(0), na_color = na_color)
        labels <- paste0(round(breaks[1], 2), " - ", round(breaks[2], 2))
    } else {
        # Normal case with multiple classes
        threshold_values <- breaks[2:n]
        stop_colors <- colors[2:n]
        
        expr <- step_expr(
            column = column,
            base = colors[1],
            values = threshold_values,
            stops = stop_colors,
            na_color = na_color
        )
        
        # Create legend labels
        labels <- c(
            paste0("< ", round(breaks[2], 2)),
            if (n > 2) {
                sapply(2:(n-1), function(i) {
                    paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                })
            },
            if (n > 1) paste0(round(breaks[n], 2), "+")
        )
    }
    
    # Return classification object
    result <- list(
        expression = expr,
        breaks = breaks,
        colors = colors,
        labels = labels,
        method = "quantile",
        n_classes = n
    )
    
    class(result) <- "mapgl_classification"
    result
}

#' Create a step expression with Jenks natural breaks classification
#'
#' This function creates a step expression using Jenks natural breaks (also known as
#' Fisher-Jenks optimal classification). This method minimizes within-class variance
#' while maximizing between-class variance, similar to the natural breaks option
#' in GIS software like ArcGIS.
#'
#' @param column The name of the column to use for the step expression.
#' @param data_values A numeric vector of the actual data values used to calculate breaks.
#' @param n The number of classes to create. Defaults to 5.
#' @param colors A vector of colors to use. If NULL, uses viridisLite::viridis(n).
#' @param na_color The color to use for missing values. Defaults to "grey".
#'
#' @return A list of class "mapgl_classification" containing the step expression and metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' # Create Jenks natural breaks classification
#' data_values <- c(2, 5, 8, 12, 20, 25, 40, 60, 80, 100)
#' classification <- step_jenks("value", data_values, n = 4)
#' 
#' # Use in a layer
#' add_circle_layer(map, circle_color = classification$expression)
#' 
#' # Extract legend information
#' labels <- classification$labels
#' colors <- classification$colors
#' }
step_jenks <- function(column, data_values, n = 5, colors = NULL, na_color = "grey") {
    if (!is.numeric(data_values)) {
        rlang::abort("data_values must be numeric")
    }
    
    if (n < 2) {
        rlang::abort("n must be at least 2")
    }
    
    # Remove missing values for break calculation
    clean_values <- data_values[!is.na(data_values)]
    
    if (length(clean_values) == 0) {
        rlang::abort("No non-missing values found in data_values")
    }
    
    # Check if we have enough unique values for the requested number of classes
    n_unique <- length(unique(clean_values))
    if (n_unique < n) {
        rlang::warn(paste0("Only ", n_unique, " unique values available, reducing classes to ", n_unique))
        n <- n_unique
    }
    
    # Calculate Jenks natural breaks using classInt
    if (n == 1) {
        # Special case for single class
        breaks <- c(min(clean_values), max(clean_values))
    } else {
        class_intervals <- classInt::classIntervals(clean_values, n = n, style = "jenks")
        breaks <- class_intervals$brks
    }
    
    # Generate colors if not provided
    if (is.null(colors)) {
        colors <- viridisLite::viridis(n)
    } else if (length(colors) != n) {
        colors <- colors[1:n]  # Truncate or recycle colors to match n
        rlang::warn(paste0("Adjusting colors to match ", n, " classes"))
    }
    
    # Create step expression
    if (n == 1) {
        # Special case for single class
        expr <- step_expr(column = column, base = colors[1], values = numeric(0), stops = character(0), na_color = na_color)
        labels <- paste0(round(breaks[1], 2), " - ", round(breaks[2], 2))
    } else {
        # Normal case with multiple classes
        threshold_values <- breaks[2:n]
        stop_colors <- colors[2:n]
        
        expr <- step_expr(
            column = column,
            base = colors[1],
            values = threshold_values,
            stops = stop_colors,
            na_color = na_color
        )
        
        # Create legend labels
        labels <- c(
            paste0("< ", round(breaks[2], 2)),
            if (n > 2) {
                sapply(2:(n-1), function(i) {
                    paste0(round(breaks[i], 2), " - ", round(breaks[i + 1], 2))
                })
            },
            if (n > 1) paste0(round(breaks[n], 2), "+")
        )
    }
    
    # Return classification object
    result <- list(
        expression = expr,
        breaks = breaks,
        colors = colors,
        labels = labels,
        method = "jenks",
        n_classes = n
    )
    
    class(result) <- "mapgl_classification"
    result
}

#' Extract legend labels from a classification or continuous scale object
#'
#' This function extracts legend labels from a mapgl_classification object
#' created by step_equal_interval(), step_quantile(), or step_jenks(), or from
#' a mapgl_continuous_scale object created by interpolate_palette(). It supports
#' optional number formatting to customize how the values are displayed.
#'
#' @param scale A mapgl_classification or mapgl_continuous_scale object.
#' @param format A character string specifying the format type. Options include:
#'   - "none" (default): No special formatting
#'   - "currency": Format as currency (e.g., "$1,234")
#'   - "percent": Format as percentage (e.g., "12.3%")
#'   - "scientific": Format in scientific notation (e.g., "1.2e+03")
#'   - "compact": Format with abbreviated units (e.g., "1.2K", "3.4M")
#' @param currency_symbol The currency symbol to use when format = "currency". Defaults to "$".
#' @param digits The number of decimal places to display. Defaults to 2.
#' @param big_mark The character to use as thousands separator. Defaults to ",".
#' @param suffix An optional suffix to add to all values (e.g., "km", "mph").
#' @param prefix An optional prefix to add to all values (useful for custom formatting).
#'
#' @return A character vector of formatted legend labels.
#' @export
#'
#' @examples
#' \dontrun{
#' data_values <- c(10000, 25000, 30000, 45000, 60000, 75000, 90000)
#' 
#' # Classification examples
#' classification <- step_equal_interval("value", data_values, n = 4)
#' labels <- get_legend_labels(classification, format = "currency")
#' 
#' # Continuous scale examples  
#' scale <- interpolate_palette("value", data_values, method = "quantile", n = 5)
#' labels <- get_legend_labels(scale, format = "compact")
#' 
#' # Custom formatting with suffix
#' labels <- get_legend_labels(scale, suffix = " km")
#' }
get_legend_labels <- function(scale, 
                              format = "none",
                              currency_symbol = "$",
                              digits = 2,
                              big_mark = ",",
                              suffix = "",
                              prefix = "") {
    if (inherits(scale, "mapgl_classification")) {
        # Handle step/categorical classification
        # If no formatting requested, return original labels
        if (format == "none" && suffix == "" && prefix == "") {
            return(scale$labels)
        }
        
        # Get the breaks and format them
        breaks <- scale$breaks
        formatted_breaks <- format_numbers(breaks, format, currency_symbol, digits, big_mark, suffix, prefix)
        
        # Reconstruct labels with formatted numbers
        n <- length(breaks) - 1
        
        if (n == 1) {
            # Single class case
            labels <- paste0(formatted_breaks[1], " - ", formatted_breaks[2])
        } else {
            # Multiple classes
            labels <- c(
                paste0("< ", formatted_breaks[2]),
                if (n > 2) {
                    sapply(2:(n-1), function(i) {
                        paste0(formatted_breaks[i], " - ", formatted_breaks[i + 1])
                    })
                },
                if (n > 1) paste0(formatted_breaks[n], "+")
            )
        }
        
        labels
    } else if (inherits(scale, "mapgl_continuous_scale")) {
        # Handle continuous/interpolation scale - return formatted break values
        breaks <- scale$breaks
        formatted_breaks <- format_numbers(breaks, format, currency_symbol, digits, big_mark, suffix, prefix)
        
        # For continuous scales, return the actual break values as labels
        formatted_breaks
    } else {
        rlang::abort("scale must be a mapgl_classification or mapgl_continuous_scale object")
    }
}

#' Format numbers for legend labels
#'
#' Internal helper function to format numeric values for display in legends.
#'
#' @param x Numeric vector to format.
#' @param format Format type.
#' @param currency_symbol Currency symbol for currency formatting.
#' @param digits Number of decimal places.
#' @param big_mark Thousands separator.
#' @param suffix Suffix to append.
#' @param prefix Prefix to prepend.
#'
#' @return Character vector of formatted numbers.
#' @keywords internal
format_numbers <- function(x, format, currency_symbol, digits, big_mark, suffix, prefix) {
    if (format == "currency") {
        # Currency formatting: $1,234.56
        formatted <- paste0(currency_symbol, formatC(x, format = "f", digits = digits, big.mark = big_mark))
    } else if (format == "percent") {
        # Percentage formatting: 12.34%
        formatted <- paste0(formatC(x * 100, format = "f", digits = digits, big.mark = big_mark), "%")
    } else if (format == "scientific") {
        # Scientific notation: 1.23e+04
        formatted <- formatC(x, format = "e", digits = digits)
    } else if (format == "compact") {
        # Compact notation: 1.2K, 3.4M, etc.
        formatted <- sapply(x, function(val) {
            if (abs(val) >= 1e9) {
                paste0(round(val / 1e9, digits), "B")
            } else if (abs(val) >= 1e6) {
                paste0(round(val / 1e6, digits), "M")
            } else if (abs(val) >= 1e3) {
                paste0(round(val / 1e3, digits), "K")
            } else {
                formatC(val, format = "f", digits = digits, big.mark = big_mark)
            }
        })
    } else {
        # Default formatting with thousands separator
        formatted <- formatC(x, format = "f", digits = digits, big.mark = big_mark)
    }
    
    # Add prefix and suffix
    paste0(prefix, formatted, suffix)
}

#' Extract legend colors from a classification or continuous scale object
#'
#' This function extracts legend colors from a mapgl_classification object
#' created by step_equal_interval(), step_quantile(), or step_jenks(), or from
#' a mapgl_continuous_scale object created by interpolate_palette().
#'
#' @param scale A mapgl_classification or mapgl_continuous_scale object.
#'
#' @return A character vector of colors.
#' @export
#'
#' @examples
#' \dontrun{
#' data_values <- c(10, 25, 30, 45, 60, 75, 90)
#' classification <- step_equal_interval("value", data_values, n = 4)
#' colors <- get_legend_colors(classification)
#' 
#' scale <- interpolate_palette("value", data_values, method = "jenks", n = 5)
#' colors <- get_legend_colors(scale)
#' }
get_legend_colors <- function(scale) {
    if (inherits(scale, "mapgl_classification") || inherits(scale, "mapgl_continuous_scale")) {
        return(scale$colors)
    } else {
        rlang::abort("scale must be a mapgl_classification or mapgl_continuous_scale object")
    }
}

#' Extract breaks from a classification or continuous scale object
#'
#' This function extracts the break values from a mapgl_classification object
#' created by step_equal_interval(), step_quantile(), or step_jenks(), or from
#' a mapgl_continuous_scale object created by interpolate_palette().
#'
#' @param scale A mapgl_classification or mapgl_continuous_scale object.
#'
#' @return A numeric vector of break values.
#' @export
#'
#' @examples
#' \dontrun{
#' data_values <- c(10, 25, 30, 45, 60, 75, 90)
#' classification <- step_jenks("value", data_values, n = 4)
#' breaks <- get_breaks(classification)
#' 
#' scale <- interpolate_palette("value", data_values, method = "equal", n = 6)
#' breaks <- get_breaks(scale)
#' }
get_breaks <- function(scale) {
    if (inherits(scale, "mapgl_classification") || inherits(scale, "mapgl_continuous_scale")) {
        return(scale$breaks)
    } else {
        rlang::abort("scale must be a mapgl_classification or mapgl_continuous_scale object")
    }
}

#' Print method for mapgl_classification objects
#'
#' @param x A mapgl_classification object.
#' @param format Optional formatting for display. See get_legend_labels() for options.
#' @param ... Additional arguments passed to get_legend_labels() for formatting.
#'
#' @return Invisibly returns the input object.
#' @export
print.mapgl_classification <- function(x, format = "none", ...) {
    cat("mapgl classification (", x$method, ")\n", sep = "")
    cat("Classes:", x$n_classes, "\n")
    cat("Breaks:", paste(round(x$breaks, 2), collapse = ", "), "\n")
    cat("Colors:", length(x$colors), "colors\n")
    
    # Get formatted labels if requested
    if (format != "none" || length(list(...)) > 0) {
        labels <- get_legend_labels(x, format = format, ...)
    } else {
        labels <- x$labels
    }
    
    cat("Labels:\n")
    for (i in seq_along(labels)) {
        cat("  ", i, ": ", labels[i], " (", x$colors[i], ")\n", sep = "")
    }
    invisible(x)
}

#' Print method for mapgl_continuous_scale objects
#'
#' @param x A mapgl_continuous_scale object.
#' @param format Optional formatting for display. See get_legend_labels() for options.
#' @param ... Additional arguments passed to get_legend_labels() for formatting.
#'
#' @return Invisibly returns the input object.
#' @export
print.mapgl_continuous_scale <- function(x, format = "none", ...) {
    cat("mapgl continuous scale (", x$method, ")\n", sep = "")
    cat("Break points:", x$n_breaks, "\n")
    cat("Range:", round(min(x$breaks), 2), "to", round(max(x$breaks), 2), "\n")
    cat("Colors:", length(x$colors), "colors\n")
    
    # Get formatted labels if requested
    if (format != "none" || length(list(...)) > 0) {
        labels <- get_legend_labels(x, format = format, ...)
    } else {
        labels <- round(x$breaks, 2)
    }
    
    cat("Break values:\n")
    for (i in seq_along(labels)) {
        cat("  ", labels[i], " (", x$colors[i], ")\n", sep = "")
    }
    invisible(x)
}

#' Set Projection for a Mapbox/Maplibre Map
#'
#' This function sets the projection dynamically after map initialization.
#'
#' @param map A map object created by mapboxgl() or maplibre() functions, or their respective proxy objects
#' @param projection A string representing the projection name (e.g., "mercator", "globe", "albers", "equalEarth", etc.)
#' @return The modified map object
#' @export
set_projection <- function(map, projection) {
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
        proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
        map$session$sendCustomMessage(proxy_class, list(
            id = map$id,
            message = list(type = "set_projection", projection = projection)
        ))
    } else {
        if (is.null(map$x$setProjection)) map$x$setProjection <- list()
        map$x$setProjection[[length(map$x$setProjection) + 1]] <- list(projection = projection)
    }
    return(map)
}
