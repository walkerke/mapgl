#' Create an interpolation expression
#'
#' This function generates an interpolation expression that can be used to style your data.
#'
#' @param column The name of the column to use for the interpolation. If specified, `property` should be NULL.
#' @param property The name of the property to use for the interpolation. If specified, `column` should be NULL.
#' @param type The interpolation type (e.g., "linear").
#' @param values A numeric vector of values at which stops occur.
#' @param stops A vector of corresponding stops (colors, sizes, etc.) for the interpolation.
#' @param na_color The color to use for missing values.  Mapbox GL JS defaults to black if this is not supplied.
#'
#' @return A list representing the interpolation expression.
#' @export
#'
#' @examples
#' interpolate(
#'   column = "estimate",
#'   type = "linear",
#'   values = c(1000, 200000),
#'   stops = c("#eff3ff", "#08519c")
#' )
interpolate <- function(column = NULL,
                        property = NULL,
                        type = "linear",
                        values,
                        stops,
                        na_color = NULL)
{

  if (length(values) != length(stops)) {
    rlang::abort("`values` and `stops` must have the same length.")
  }

  if (!is.null(column)) {
    to_map <- list("get", column)
  } else if (!is.null(property)) {
    to_map <- list(property)
  } else {
    rlang::abort("You must specify a column or property, but not both.")
  }

  expr <- list("interpolate", list(type), to_map)
  for (i in seq_along(values)) {
    expr <- c(expr, list(values[i]), list(stops[i]))
  }

  if (!is.null(na_color)) {
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
#'   column = "category",
#'   values = c("A", "B", "C"),
#'   stops = c("#ff0000", "#00ff00", "#0000ff"),
#'   default = "#cccccc"
#' )
match_expr <- function(column = NULL, property = NULL, values, stops, default = "#cccccc") {

  if (length(values) != length(stops)) {
    rlang::abort("`values` and `stops` must have the same length.")
  }

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

#' Create a step expression for Mapbox GL
#'
#' This function generates a step expression that can be used in Mapbox GL styles.
#'
#' @param column The name of the column to use for the step expression. If specified, `property` should be NULL.
#' @param property The name of the property to use for the step expression. If specified, `column` should be NULL.
#' @param base The base value to use for the step expression.
#' @param values A numeric vector of values at which steps occur.
#' @param stops A vector of corresponding stops (colors, sizes, etc.) for the steps.
#'
#' @return A list representing the step expression.
#' @export
#'
#' @examples
#' step_expr(
#'   column = "value",
#'   base = "#ffffff",
#'   values = c(1000, 5000, 10000),
#'   stops = c("#ff0000", "#00ff00", "#0000ff")
#' )
step_expr <- function(column = NULL, property = NULL, base, values, stops) {

  if (length(values) != length(stops)) {
    rlang::abort("`values` and `stops` must have the same length.")
  }

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

  expr
}

#' Set a configuration property for the Mapbox GL map
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
    `navigation-night` = "mapbox://styles/mapbox/navigation-night-v1"
  )

  style_url <- styles[[style_name]]

  if (is.null(style_url)) {
    stop("Invalid style name. Please choose from: standard, streets, outdoors, light, dark, satellite, satellite-streets, navigation-day, navigation-night.")
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
      rlang::abort("A MapTiler API key is required. Get one at https://www.maptiler.com.")
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
