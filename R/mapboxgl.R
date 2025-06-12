#' Initialize a Mapbox GL Map
#'
#' @param style The Mapbox style to use.
#' @param center A numeric vector of length 2 specifying the initial center of the map.
#' @param zoom The initial zoom level of the map.
#' @param bearing The initial bearing (rotation) of the map, in degrees.
#' @param pitch The initial pitch (tilt) of the map, in degrees.
#' @param projection The map projection to use (e.g., "mercator", "globe").
#' @param parallels A vector of two numbers representing the standard parallels of the projection.  Only available when the projection is "albers" or "lambertConformalConic".
#' @param access_token Your Mapbox access token.
#' @param bounds An sf object or bounding box to fit the map to.
#' @param width The width of the output htmlwidget.
#' @param height The height of the output htmlwidget.
#' @param ... Additional named parameters to be passed to the Mapbox GL map.
#'
#' @return An HTML widget for a Mapbox map.
#' @export
#'
#' @examples
#' \dontrun{
#' mapboxgl(projection = "globe")
#' }
mapboxgl <- function(
    style = NULL,
    center = c(0, 0),
    zoom = 0,
    bearing = 0,
    pitch = 0,
    projection = "globe",
    parallels = NULL,
    access_token = NULL,
    bounds = NULL,
    width = "100%",
    height = NULL,
    ...
) {
    if (is.null(access_token)) {
        if (Sys.getenv("MAPBOX_PUBLIC_TOKEN") == "") {
            rlang::abort(c(
                "A Mapbox access token is required. Get one from your account at https://www.mapbox.com, and do one of the following:",
                i = "Run `usethis::edit_r_environ()` and add the line MAPBOX_PUBLIC_TOKEN='your_token_goes_here';",
                i = "Install the mapboxapi R package and run `mb_access_token('your_token_goes_here', install = TRUE)`",
                i = "Alternatively, supply your token to the `access_token` parameter in this function or run `Sys.setenv(MAPBOX_PUBLIC_TOKEN='your_token_goes_here') for this session."
            ))
        } else {
            access_token <- Sys.getenv("MAPBOX_PUBLIC_TOKEN")
        }
    }

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
        name = "mapboxgl",
        x = list(
            style = style,
            center = center,
            zoom = zoom,
            bearing = bearing,
            pitch = pitch,
            projection = projection,
            parallels = parallels,
            access_token = access_token,
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

#' Create a Mapbox GL output element for Shiny
#'
#' @param outputId The output variable to read from
#' @param width The width of the element
#' @param height The height of the element
#'
#' @return A Mapbox GL output element for use in a Shiny UI
#' @export
mapboxglOutput <- function(outputId, width = "100%", height = "400px") {
    htmlwidgets::shinyWidgetOutput(
        outputId,
        "mapboxgl",
        width,
        height,
        package = "mapgl"
    )
}

#' Render a Mapbox GL output element in Shiny
#'
#' @param expr An expression that generates a Mapbox GL map
#' @param env The environment in which to evaluate `expr`
#' @param quoted Is `expr` a quoted expression
#'
#' @return A rendered Mapbox GL map for use in a Shiny server
#' @export
renderMapboxgl <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) {
        expr <- substitute(expr)
    } # force quoted
    htmlwidgets::shinyRenderWidget(expr, mapboxglOutput, env, quoted = TRUE)
}
