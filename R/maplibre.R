#' Initialize a Maplibre GL Map
#'
#' @param style The style JSON to use.
#' @param center A numeric vector of length 2 specifying the initial center of the map.
#' @param zoom The initial zoom level of the map.
#' @param bearing The initial bearing (rotation) of the map, in degrees.
#' @param pitch The initial pitch (tilt) of the map, in degrees.
#' @param bounds An sf object or an unnamed numeric vector of the form `c(xmin, ymin, xmax, ymax)`
#' indicating the bounding box to fit the map to.
#' @param width The width of the output htmlwidget.
#' @param height The height of the output htmlwidget.
#' @param ... Additional named parameters to be passed to the Mapbox GL map.
#'
#' @return An HTML widget for a Mapbox map.
#' @export
#'
#' @examples
#' \dontrun{
#' maplibre()
#' }
maplibre <- function(
    style = carto_style("voyager"),
    center = c(0, 0),
    zoom = 0,
    bearing = 0,
    pitch = 0,
    bounds = NULL,
    width = "100%",
    height = NULL,
    ...
) {
    additional_params <- list(...)

    if (!is.null(bounds)) {
        if (inherits(bounds, "sf")) {
            bounds <- as.vector(sf::st_bbox(sf::st_transform(bounds, 4326)))
        }
        additional_params$bounds <- bounds
    }

    control_css <- htmltools::htmlDependency(
        name = "layers-control",
        version = "1.0.0",
        src = c(file = system.file("htmlwidgets/styles", package = "mapgl")),
        stylesheet = "layers-control.css"
    )

    htmlwidgets::createWidget(
        name = "maplibregl",
        x = list(
            style = style,
            center = center,
            zoom = zoom,
            bearing = bearing,
            pitch = pitch,
            additional_params = additional_params
        ),
        width = width,
        height = height,
        package = "mapgl",
        dependencies = list(control_css),
        sizingPolicy = htmlwidgets::sizingPolicy(
            viewer.suppress = FALSE,
            browser.fill = TRUE,
            viewer.fill = TRUE,
            knitr.figure = TRUE,
            padding = 0,
            knitr.defaultHeight = "500px",
            viewer.defaultHeight = "100vh",
            browser.defaultHeight = "100vh"
        )
    )
}

#' Create a Maplibre GL output element for Shiny
#'
#' @param outputId The output variable to read from
#' @param width The width of the element
#' @param height The height of the element
#'
#' @return A Maplibre GL output element for use in a Shiny UI
#' @export
maplibreOutput <- function(outputId, width = "100%", height = "400px") {
    htmlwidgets::shinyWidgetOutput(
        outputId,
        "maplibregl",
        width,
        height,
        package = "mapgl"
    )
}

#' Render a Maplibre GL output element in Shiny
#'
#' @param expr An expression that generates a Maplibre GL map
#' @param env The environment in which to evaluate `expr`
#' @param quoted Is `expr` a quoted expression
#'
#' @return A rendered Maplibre GL map for use in a Shiny server
#' @export
renderMaplibre <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) {
        expr <- substitute(expr)
    } # force quoted
    htmlwidgets::shinyRenderWidget(expr, maplibreOutput, env, quoted = TRUE)
}
