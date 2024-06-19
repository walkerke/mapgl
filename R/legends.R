#' Add a legend to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param legend_title The title of the legend.
#' @param values The values being represented on the map (either a vector of categories or a vector of stops).
#' @param colors The corresponding colors for the values (either a vector of colors or an interpolate function).
#' @param type one of "continuous" or "categorical"
#' @param circular_patches Logical, whether to use circular patches in the legend.
#' @param position The position of the legend on the map (one of "topleft", "bottomleft", "topright", "bottomright").
#'
#' @return The updated map object with the legend added.
#' @export
add_legend <- function(map, legend_title, values, colors,
                       type = c("continuous", "categorical"),
                       circular_patches = FALSE, position = "topleft") {

  type <- match.arg(type)

  if (type == "continuous") {
    add_continuous_legend(map, legend_title, values, colors, position)
  } else {
    add_categorical_legend(map, legend_title, values, colors, circular_patches, position)
  }
}

#' Add a categorical legend
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param legend_title The title of the legend.
#' @param values The values being represented on the map (vector of categories).
#' @param colors The corresponding colors for the values (vector of colors).
#' @param circular_patches Logical, whether to use circular patches in the legend.
#' @param position The position of the legend on the map (one of "topleft", "bottomleft", "topright", "bottomright").
#'
#' @return The updated map object with the legend added.
#' @export
add_categorical_legend <- function(map, legend_title, values, colors, circular_patches = FALSE, position = "topleft") {
  legend_items <- lapply(seq_along(values), function(i) {
    shape_style <- if (circular_patches) "border-radius: 50%;" else ""
    paste0('<div class="legend-item"><span class="legend-color" style="background-color:', colors[i], ';', shape_style, '"></span>', values[i], '</div>')
  })

  legend_html <- paste0(
    '<div id="mapboxgl-legend" class="', position, '">',
    '<h2>', legend_title, '</h2>',
    paste0(legend_items, collapse = ""),
    '</div>'
  )

  legend_css <- "
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

    #mapboxgl-legend h2 {
      font-size: 14px;
      font-family: 'Open Sans';
      line-height: 20px;
      margin-bottom: 10px;
      margin-top: 0px;
      white-space: nowrap;
      max-width: 100%;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    #mapboxgl-legend {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      max-width: 250px;
      background-color: #ffffff80;
      padding: 10px 20px;
      z-index: 1002;
    }

    #mapboxgl-legend.topleft {
      top: 10px;
      left: 10px;
    }

    #mapboxgl-legend.bottomleft {
      bottom: 10px;
      left: 10px;
    }

    #mapboxgl-legend.topright {
      top: 10px;
      right: 10px;
    }

    #mapboxgl-legend.bottomright {
      bottom: 10px;
      right: 10px;
    }

    #mapboxgl-legend .legend-item {
      display: flex;
      align-items: center;
      margin-bottom: 5px;
      font-family: 'Open Sans';
      white-space: nowrap;
      max-width: 100%;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    #mapboxgl-legend .legend-color {
      width: 20px;
      height: 20px;
      margin-right: 5px;
      display: inline-block;
    }
  "



  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {

    proxy_class <- ifelse(inherits(map, "mapboxgl_proxy"), "mapboxgl-proxy", "maplibre-proxy")

    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_legend", html = legend_html, legend_css = legend_css)))
  } else {
    map$x$legend_html <- legend_html
    map$x$legend_css <- legend_css
    return(map)
  }
}

#' Add a continuous legend
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param legend_title The title of the legend.
#' @param values The values being represented on the map (vector of stops).
#' @param colors The colors used to generate the color ramp.
#' @param position The position of the legend on the map (one of "topleft", "bottomleft", "topright", "bottomright").
#'
#' @return The updated map object with the legend added.
#' @export
add_continuous_legend <- function(map, legend_title, values, colors, position = "topleft") {
  color_gradient <- paste0("linear-gradient(to right, ", paste(colors, collapse = ", "), ")")

  num_values <- length(values)

  value_labels <- paste0(
    '<span style="position: absolute; left: ', seq(0, 100, length.out = num_values),
    '%; transform: translateX(-50%);">', values, '</span>', collapse = ""
  )


  legend_html <- paste0(
    '<div id="mapboxgl-legend" class="', position, '">',
    '<h2>', legend_title, '</h2>',
    '<div class="legend-gradient" style="background:', color_gradient, '"></div>',
    '<div class="legend-labels" style="position: relative; height: 20px;">',
    value_labels,
    '</div>',
    '</div>'
  )

  legend_css <- "
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

    #mapboxgl-legend h2 {
      font-size: 14px;
      font-family: 'Open Sans';
      line-height: 20px;
      margin-bottom: 10px;
      margin-top: 0px;
    }

    #mapboxgl-legend {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      width: 200px;
      background-color: #ffffff80;
      padding: 10px 20px;
      z-index: 1002;
    }

    #mapboxgl-legend.topleft {
      top: 10px;
      left: 10px;
    }

    #mapboxgl-legend.bottomleft {
      bottom: 10px;
      left: 10px;
    }

    #mapboxgl-legend.topright {
      top: 10px;
      right: 10px;
    }

    #mapboxgl-legend.bottomright {
      bottom: 10px;
      right: 10px;
    }

    #mapboxgl-legend .legend-gradient {
      height: 20px;
      margin-bottom: 5px;
    }

    #mapboxgl-legend .legend-labels {
      display: flex;
      justify-content: space-between;
      font-family: 'Open Sans';
    }

    #mapboxgl-legend .legend-labels span {
      position: absolute;
      transform: translateX(-50%);
    }
  "


  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {

    proxy_class <- ifelse(inherits(map, "mapboxgl_proxy"), "mapboxgl-proxy", "maplibre-proxy")

    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_legend", html = legend_html, legend_css = legend_css)))
  } else {
    map$x$legend_html <- legend_html
    map$x$legend_css <- legend_css
    return(map)
  }
}
