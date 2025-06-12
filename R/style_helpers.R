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
#' @param api_key Your MapTiler API key (required)
#' @return The style URL corresponding to the given style name.
#' @export
maptiler_style <- function(style_name, api_key = NULL) {
    if (is.null(api_key)) {
        if (Sys.getenv("MAPTILER_API_KEY") == "") {
            rlang::abort("A MapTiler API key is required. Get one at https://www.maptiler.com, then supply it here or set it in your .Renviron file with 'MAPTILER_API_KEY'='YOUR_KEY_HERE'.")
        } else {
            api_key <- Sys.getenv("MAPTILER_API_KEY")
        }
    }

    styles <- list(
        backdrop = "https://api.maptiler.com/maps/backdrop/style.json",
        basic = "https://api.maptiler.com/maps/basic-v2/style.json",
        bright = "https://api.maptiler.com/maps/bright-v2/style.json",
        dataviz = "https://api.maptiler.com/maps/dataviz/style.json",
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

    style_url_with_key <- paste0(style_url, "?key=", api_key)

    return(style_url_with_key)
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
