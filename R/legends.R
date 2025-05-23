#' Add a legend to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param legend_title The title of the legend.
#' @param values The values being represented on the map (either a vector of categories or a vector of stops).
#' @param colors The corresponding colors for the values (either a vector of colors, a single color, or an interpolate function).
#' @param type One of "continuous" or "categorical".
#' @param circular_patches Logical, whether to use circular patches in the legend (only for categorical legends).
#' @param position The position of the legend on the map (one of "top-left", "bottom-left", "top-right", "bottom-right").
#' @param sizes An optional numeric vector of sizes for the legend patches, or a single numeric value (only for categorical legends).
#' @param add Logical, whether to add this legend to existing legends (TRUE) or replace existing legends (FALSE). Default is FALSE.
#' @param unique_id Optional. A unique identifier for the legend. If not provided, a random ID will be generated.
#' @param width The width of the legend. Can be specified in pixels (e.g., "250px") or as "auto". Default is NULL, which uses the built-in default.
#' @param layer_id The ID of the layer that this legend is associated with. If provided, the legend will be shown/hidden when the layer visibility is toggled.
#' @param margin_top Custom top margin in pixels, allowing for fine control over legend positioning. Default is NULL (uses standard positioning).
#' @param margin_left Custom left margin in pixels. Default is NULL.
#' @param margin_bottom Custom bottom margin in pixels. Default is NULL.
#' @param margin_right Custom right margin in pixels. Default is NULL.
#'
#' @return The updated map object with the legend added.
#' @export
add_legend <- function(
    map,
    legend_title,
    values,
    colors,
    type = c("continuous", "categorical"),
    circular_patches = FALSE,
    position = "top-left",
    sizes = NULL,
    add = FALSE,
    unique_id = NULL,
    width = NULL,
    layer_id = NULL,
    margin_top = NULL,
    margin_right = NULL,
    margin_bottom = NULL,
    margin_left = NULL
) {
    type <- match.arg(type)
    if (is.null(unique_id)) {
        unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
    }

    if (type == "continuous") {
        add_continuous_legend(
            map,
            legend_title,
            values,
            colors,
            position,
            unique_id,
            add,
            width,
            layer_id,
            margin_top,
            margin_right,
            margin_bottom,
            margin_left
        )
    } else {
        add_categorical_legend(
            map,
            legend_title,
            values,
            colors,
            circular_patches,
            position,
            unique_id,
            sizes,
            add,
            width,
            layer_id,
            margin_top,
            margin_right,
            margin_bottom,
            margin_left
        )
    }
}

#' Add a categorical legend to a Mapbox GL map
#'
#' This function adds a categorical legend to a Mapbox GL map. It supports
#' customizable colors, sizes, and shapes for legend items.
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param legend_title The title of the legend.
#' @param values A vector of categories or values to be displayed in the legend.
#' @param colors The corresponding colors for the values. Can be a vector of colors or a single color.
#' @param circular_patches Logical, whether to use circular patches in the legend. Default is FALSE.
#' @param position The position of the legend on the map. One of "top-left", "bottom-left", "top-right", "bottom-right". Default is "top-left".
#' @param unique_id A unique ID for the legend container. If NULL, a random ID will be generated.
#' @param sizes An optional numeric vector of sizes for the legend patches, or a single numeric value. If provided as a vector, it should have the same length as `values`. If `circular_patches` is `FALSE` (for square patches), sizes represent the width and height of the patch in pixels.  If `circular_patches` is `TRUE`, sizes represent the radius of the circle.
#' @param add Logical, whether to add this legend to existing legends (TRUE) or replace existing legends (FALSE). Default is FALSE.
#' @param width The width of the legend. Can be specified in pixels (e.g., "250px") or as "auto". Default is NULL, which uses the built-in default.
#' @param layer_id The ID of the layer that this legend is associated with. If provided, the legend will be shown/hidden when the layer visibility is toggled.
#' @param margin_top Custom top margin in pixels, allowing for fine control over legend positioning. Default is NULL (uses standard positioning).
#' @param margin_left Custom left margin in pixels. Default is NULL.
#' @param margin_bottom Custom bottom margin in pixels. Default is NULL.
#' @param margin_right Custom right margin in pixels. Default is NULL.
#'
#' @return The updated map object with the legend added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapboxgl)
#' map <- mapboxgl(
#'     center = c(-96, 37.8),
#'     zoom = 3
#' )
#' map %>% add_categorical_legend(
#'     legend_title = "Population",
#'     values = c("Low", "Medium", "High"),
#'     colors = c("#FED976", "#FEB24C", "#FD8D3C"),
#'     circular_patches = TRUE,
#'     sizes = c(10, 15, 20),
#'     width = "300px"
#' )
#' }
add_categorical_legend <- function(
    map,
    legend_title,
    values,
    colors,
    circular_patches = FALSE,
    position = "top-left",
    unique_id = NULL,
    sizes = NULL,
    add = FALSE,
    width = NULL,
    layer_id = NULL,
    margin_top = NULL,
    margin_right = NULL,
    margin_bottom = NULL,
    margin_left = NULL
) {
    # Validate and prepare inputs
    if (length(colors) == 1) {
        colors <- rep(colors, length(values))
    } else if (length(colors) != length(values)) {
        stop(
            "'colors' must be a single value or have the same length as 'values'."
        )
    }

    # Give a default size of 20 if no size supplied
    if (is.null(sizes)) {
        if (circular_patches) {
            sizes <- 10
        } else {
            sizes <- 20
        }
    }

    # If circular patches is TRUE, multiply by 2 to get a diameter of the circle
    if (circular_patches) {
        sizes <- sizes * 2
    }

    if (length(sizes) == 1) {
        sizes <- rep(sizes, length(values))
    } else if (length(sizes) != length(values)) {
        stop(
            "'sizes' must be a single value or have the same length as 'values'."
        )
    }

    max_size <- max(sizes)

    legend_items <- lapply(seq_along(values), function(i) {
        shape_style <- if (circular_patches) "border-radius: 50%;" else ""
        size_style <- if (!is.null(sizes))
            sprintf("width: %dpx; height: %dpx;", sizes[i], sizes[i]) else ""
        paste0(
            '<div class="legend-item">',
            '<div class="legend-patch-container" style="width:',
            max_size,
            "px; height:",
            max_size,
            'px;">',
            '<span class="legend-color" style="background-color:',
            colors[i],
            ";",
            shape_style,
            size_style,
            '"></span></div>',
            '<span class="legend-text">',
            values[i],
            "</span>",
            "</div>"
        )
    })

    if (is.null(unique_id)) {
        unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
    }

    # Add data-layer-id attribute if layer_id is provided
    layer_attr <- if (!is.null(layer_id)) {
        paste0(' data-layer-id="', layer_id, '"')
    } else {
        ""
    }

    legend_html <- paste0(
        '<div id="',
        unique_id,
        '" class="mapboxgl-legend ',
        position,
        '"',
        layer_attr,
        ">",
        "<h2>",
        legend_title,
        "</h2>",
        paste0(legend_items, collapse = ""),
        "</div>"
    )

    width_style <- if (!is.null(width)) paste0("width: ", width, ";") else
        "max-width: 250px;"

    legend_css <- paste0(
        "
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');
    #",
        unique_id,
        " h2 {
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
    #",
        unique_id,
        " {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      ",
        width_style,
        "
      background-color: #ffffff80;
      padding: 10px 20px;
      z-index: 1002;
    }
    #",
        unique_id,
        ".top-left {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }
    #",
        unique_id,
        ".bottom-left {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }
    #",
        unique_id,
        ".top-right {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }
    #",
        unique_id,
        ".bottom-right {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }
    #",
        unique_id,
        " .legend-item {
      display: flex;
      align-items: center;
      margin-bottom: 5px;
      font-family: 'Open Sans';
      white-space: nowrap;
      max-width: 100%;
      overflow: hidden;
    }
    #",
        unique_id,
        " .legend-patch-container {
      display: flex;
      justify-content: center;
      align-items: center;
      margin-right: 5px;
    }
    #",
        unique_id,
        " .legend-color {
      display: inline-block;
      flex-shrink: 0;
    }
    #",
        unique_id,
        " .legend-text {
      flex-grow: 1;
      text-overflow: ellipsis;
      overflow: hidden;
    }
  "
    )

    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- ifelse(
            inherits(map, "mapboxgl_proxy"),
            "mapboxgl-proxy",
            "maplibre-proxy"
        )
        map$session$sendCustomMessage(
            proxy_class,
            list(
                id = map$id,
                message = list(
                    type = "add_legend",
                    html = legend_html,
                    legend_css = legend_css,
                    add = add
                )
            )
        )
        map
    } else {
        if (!add) {
            map$x$legend_html <- legend_html
            map$x$legend_css <- legend_css
        } else {
            map$x$legend_html <- paste(map$x$legend_html, legend_html)
            map$x$legend_css <- paste(map$x$legend_css, legend_css)
        }
        return(map)
    }
}

#' Add a continuous legend
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param legend_title The title of the legend.
#' @param values The values being represented on the map (vector of stops).
#' @param colors The colors used to generate the color ramp.
#' @param position The position of the legend on the map (one of "top-left", "bottom-left", "top-right", "bottom-right").
#' @param unique_id A unique ID for the legend container. Defaults to NULL.
#' @param add Logical, whether to add this legend to existing legends (TRUE) or replace existing legends (FALSE). Default is FALSE.
#' @param width The width of the legend. Can be specified in pixels (e.g., "250px") or as "auto". Default is NULL, which uses the built-in default.
#' @param layer_id The ID of the layer that this legend is associated with. If provided, the legend will be shown/hidden when the layer visibility is toggled.
#' @param margin_top Custom top margin in pixels, allowing for fine control over legend positioning. Default is NULL (uses standard positioning).
#' @param margin_left Custom left margin in pixels. Default is NULL.
#' @param margin_bottom Custom bottom margin in pixels. Default is NULL.
#' @param margin_right Custom right margin in pixels. Default is NULL.
#'
#' @return The updated map object with the legend added.
#' @export
add_continuous_legend <- function(
    map,
    legend_title,
    values,
    colors,
    position = "top-left",
    unique_id = NULL,
    add = FALSE,
    width = NULL,
    layer_id = NULL,
    margin_top = NULL,
    margin_right = NULL,
    margin_bottom = NULL,
    margin_left = NULL
) {
    if (is.null(unique_id)) {
        unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
    }

    color_gradient <- paste0(
        "linear-gradient(to right, ",
        paste(colors, collapse = ", "),
        ")"
    )

    num_values <- length(values)

    value_labels <- paste0(
        '<div class="legend-labels">',
        paste0(
            '<span style="position: absolute; left: ',
            seq(0, 100, length.out = num_values),
            '%;">',
            values,
            "</span>",
            collapse = ""
        ),
        "</div>"
    )

    # Add data-layer-id attribute if layer_id is provided
    layer_attr <- if (!is.null(layer_id)) {
        paste0(' data-layer-id="', layer_id, '"')
    } else {
        ""
    }

    legend_html <- paste0(
        '<div id="',
        unique_id,
        '" class="mapboxgl-legend ',
        position,
        '"',
        layer_attr,
        ">",
        "<h2>",
        legend_title,
        "</h2>",
        '<div class="legend-gradient" style="background:',
        color_gradient,
        '"></div>',
        '<div class="legend-labels" style="position: relative; height: 20px;">',
        value_labels,
        "</div>",
        "</div>"
    )

    width_style <- if (!is.null(width)) paste0("width: ", width, ";") else
        "width: 200px;"

    legend_css <- paste0(
        "
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

    #",
        unique_id,
        " h2 {
      font-size: 14px;
      font-family: 'Open Sans';
      line-height: 20px;
      margin-bottom: 10px;
      margin-top: 0px;
    }

    #",
        unique_id,
        " {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      ",
        width_style,
        "
      background-color: #ffffff80;
      padding: 10px 20px;
      z-index: 1002;
    }

    #",
        unique_id,
        ".top-left {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }

    #",
        unique_id,
        ".bottom-left {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }

    #",
        unique_id,
        ".top-right {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }

    #",
        unique_id,
        ".bottom-right {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }

    #",
        unique_id,
        " .legend-gradient {
      height: 20px;
      margin: 5px 10px 5px 10px;
    }

    #",
        unique_id,
        " .legend-labels {
      position: relative;
      height: 20px;
      margin: 0 10px;
    }

    #",
        unique_id,
        " .legend-labels span {
      font-size: 12px;
      position: absolute;
      transform: translateX(-50%);  /* Center all labels by default */
      white-space: nowrap;
    }

"
    )

    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- ifelse(
            inherits(map, "mapboxgl_proxy"),
            "mapboxgl-proxy",
            "maplibre-proxy"
        )

        map$session$sendCustomMessage(
            proxy_class,
            list(
                id = map$id,
                message = list(
                    type = "add_legend",
                    html = legend_html,
                    legend_css = legend_css,
                    add = add
                )
            )
        )

        map
    } else {
        if (!add) {
            map$x$legend_html <- legend_html
            map$x$legend_css <- legend_css
        } else {
            map$x$legend_html <- paste(map$x$legend_html, legend_html)
            map$x$legend_css <- paste(map$x$legend_css, legend_css)
        }
        return(map)
    }
}


#' Clear legend(s) from a map in a proxy session
#'
#' @param map A map object created by the `mapboxgl_proxy` or `maplibre_proxy` function.
#' @param legend_ids Optional. A character vector of legend IDs to clear. If not provided, all legends will be cleared.
#'
#' @return The updated map object with the specified legend(s) cleared.
#' @export
clear_legend <- function(map, legend_ids = NULL) {
    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- ifelse(
            inherits(map, "mapboxgl_proxy"),
            "mapboxgl-proxy",
            "maplibre-proxy"
        )
        message <- if (is.null(legend_ids)) {
            list(type = "clear_legend")
        } else {
            list(type = "clear_legend", ids = legend_ids)
        }
        map$session$sendCustomMessage(
            proxy_class,
            list(id = map$id, message = message)
        )
    } else {
        stop(
            "clear_legend can only be used with mapboxgl_proxy or maplibre_proxy objects."
        )
    }
    return(map)
}
