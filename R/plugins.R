#' Create a Compare widget
#'
#' This function creates a comparison view between two Mapbox GL or Maplibre GL maps, allowing users to either swipe between the two maps or view them side-by-side with synchronized navigation.
#'
#' @param map1 A `mapboxgl` or `maplibre` object representing the first map.
#' @param map2 A `mapboxgl` or `maplibre` object representing the second map.
#' @param width Width of the map container.
#' @param height Height of the map container.
#' @param elementId An optional string specifying the ID of the container for the comparison. If NULL, a unique ID will be generated.
#' @param mousemove A logical value indicating whether to enable swiping during cursor movement (rather than only when clicked). Only applicable when `mode="swipe"`.
#' @param orientation A string specifying the orientation of the swiper or the side-by-side layout, either "horizontal" or "vertical".
#' @param mode A string specifying the comparison mode: "swipe" (default) for a swipeable comparison with a slider, or "sync" for synchronized maps displayed next to each other.
#' @param swiper_color An optional CSS color value (e.g., "#000000", "rgb(0,0,0)", "black") to customize the color of the swiper handle. Only applicable when `mode="swipe"`.
#'
#' @return A comparison widget.
#' @export
#'
#' @details
#' ## Comparison modes
#'
#' The `compare()` function supports two modes:
#'
#' * `mode="swipe"` (default) - Creates a swipeable interface with a slider to reveal portions of each map
#' * `mode="sync"` - Places the maps next to each other with synchronized navigation
#'
#' In both modes, navigation (panning, zooming, rotating, tilting) is synchronized between the maps.
#'
#' ## Using the compare widget in Shiny
#'
#' The compare widget can be used in Shiny applications with the following functions:
#'
#' * `mapboxglCompareOutput()` / `renderMapboxglCompare()` - For Mapbox GL comparisons
#' * `maplibreCompareOutput()` / `renderMaplibreCompare()` - For Maplibre GL comparisons
#' * `mapboxgl_compare_proxy()` / `maplibre_compare_proxy()` - For updating maps in a compare widget
#'
#' After creating a compare widget in a Shiny app, you can use the proxy functions to update either the "before"
#' (left/top) or "after" (right/bottom) map. The proxy objects work with all the regular map update functions like `set_style()`,
#' `set_paint_property()`, etc.
#'
#' To get a proxy that targets a specific map in the comparison:
#'
#' ```r
#' # Access the left/top map
#' left_proxy <- maplibre_compare_proxy("compare_id", map_side = "before")
#'
#' # Access the right/bottom map
#' right_proxy <- maplibre_compare_proxy("compare_id", map_side = "after")
#' ```
#'
#' The compare widget also provides Shiny input values for view state and clicks. For a compare widget with ID "mycompare", you'll have:
#'
#' * `input$mycompare_before_view` - View state (center, zoom, bearing, pitch) of the left/top map
#' * `input$mycompare_after_view` - View state of the right/bottom map
#' * `input$mycompare_before_click` - Click events on the left/top map
#' * `input$mycompare_after_click` - Click events on the right/bottom map
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' m1 <- mapboxgl(style = mapbox_style("light"))
#' m2 <- mapboxgl(style = mapbox_style("dark"))
#'
#' # Default swipe mode
#' compare(m1, m2)
#'
#' # Synchronized side-by-side mode
#' compare(m1, m2, mode = "sync")
#'
#' # Custom swiper color
#' compare(m1, m2, swiper_color = "#FF0000")  # Red swiper
#'
#' # Shiny example
#' library(shiny)
#'
#' ui <- fluidPage(
#'   maplibreCompareOutput("comparison")
#' )
#'
#' server <- function(input, output, session) {
#'   output$comparison <- renderMaplibreCompare({
#'     compare(
#'       maplibre(style = carto_style("positron")),
#'       maplibre(style = carto_style("dark-matter")),
#'       mode = "sync"
#'     )
#'   })
#'
#' # Update the right map
#'   observe({
#'     right_proxy <- maplibre_compare_proxy("comparison", map_side = "after")
#'     set_style(right_proxy, carto_style("voyager"))
#'   })
#'   
#'   # Example with custom swiper color
#'   output$comparison2 <- renderMaplibreCompare({
#'     compare(
#'       maplibre(style = carto_style("positron")),
#'       maplibre(style = carto_style("dark-matter")),
#'       swiper_color = "#3498db"  # Blue swiper
#'     )
#'   })
#' }
#' }
compare <- function(
    map1,
    map2,
    width = "100%",
    height = NULL,
    elementId = NULL,
    mousemove = FALSE,
    orientation = "vertical",
    mode = "swipe",
    swiper_color = NULL
) {
    if (!mode %in% c("swipe", "sync")) {
        stop("Mode must be either 'swipe' or 'sync'.")
    }

    if (inherits(map1, "mapboxgl") && inherits(map2, "mapboxgl")) {
        compare.mapboxgl(
            map1,
            map2,
            width,
            height,
            elementId,
            mousemove,
            orientation,
            mode,
            swiper_color
        )
    } else if (inherits(map1, "maplibregl") && inherits(map2, "maplibregl")) {
        compare.maplibre(
            map1,
            map2,
            width,
            height,
            elementId,
            mousemove,
            orientation,
            mode,
            swiper_color
        )
    } else {
        stop("Both maps must be either mapboxgl or maplibregl objects.")
    }
}

# Mapbox GL comparison widget
compare.mapboxgl <- function(
    map1,
    map2,
    width,
    height,
    elementId,
    mousemove,
    orientation,
    mode,
    swiper_color = NULL
) {
    if (is.null(elementId)) {
        elementId <- paste0(
            "compare-container-",
            as.hexmode(sample(1:1000000, 1))
        )
    }

    x <- list(
        map1 = map1$x,
        map2 = map2$x,
        elementId = elementId,
        mousemove = mousemove,
        orientation = orientation,
        mode = mode,
        swiper_color = swiper_color
    )

    control_css <- htmltools::htmlDependency(
        name = "layers-control",
        version = "1.0.0",
        src = c(file = system.file("htmlwidgets/styles", package = "mapgl")),
        stylesheet = "layers-control.css"
    )

    widget <- htmlwidgets::createWidget(
        name = "mapboxgl_compare",
        x,
        width = width,
        height = height,
        package = "mapgl",
        dependencies = list(control_css),
        elementId = if (is.null(shiny::getDefaultReactiveDomain()))
            elementId else NULL,
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
    
    # Add class to enable S3 methods
    class(widget) <- c("mapboxgl_compare", class(widget))
    widget
}

# Maplibre comparison widget
compare.maplibre <- function(
    map1,
    map2,
    width,
    height,
    elementId,
    mousemove,
    orientation,
    mode,
    swiper_color = NULL
) {
    if (is.null(elementId)) {
        elementId <- paste0(
            "compare-container-",
            as.hexmode(sample(1:1000000, 1))
        )
    }

    # check_for_popups_or_tooltips <- function(map) {
    #     if (!is.null(map$x$layers)) {
    #         for (layer in map$x$layers) {
    #             if (!is.null(layer$popup) || !is.null(layer$tooltip)) {
    #                 return(TRUE)
    #             }
    #         }
    #     }
    #     return(FALSE)
    # }
    #
    # if (
    #     check_for_popups_or_tooltips(map1) || check_for_popups_or_tooltips(map2)
    # ) {
    #     rlang::warn(
    #         "Popups and tooltips are not currently supported for `compare()` with maplibre maps."
    #     )
    # }

    x <- list(
        map1 = map1$x,
        map2 = map2$x,
        elementId = elementId,
        mousemove = mousemove,
        orientation = orientation,
        mode = mode,
        swiper_color = swiper_color
    )

    control_css <- htmltools::htmlDependency(
        name = "layers-control",
        version = "1.0.0",
        src = c(file = system.file("htmlwidgets/styles", package = "mapgl")),
        stylesheet = "layers-control.css"
    )

    widget <- htmlwidgets::createWidget(
        name = "maplibregl_compare",
        x,
        width = width,
        height = height,
        package = "mapgl",
        dependencies = list(control_css),
        elementId = if (is.null(shiny::getDefaultReactiveDomain()))
            elementId else NULL,
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
    
    # Add class to enable S3 methods
    class(widget) <- c("maplibregl_compare", class(widget))
    widget
}

#' Create a Mapbox GL Compare output element for Shiny
#'
#' @param outputId The output variable to read from
#' @param width The width of the element
#' @param height The height of the element
#'
#' @return A Mapbox GL Compare output element for use in a Shiny UI
#' @export
mapboxglCompareOutput <- function(outputId, width = "100%", height = "400px") {
    htmlwidgets::shinyWidgetOutput(
        outputId,
        "mapboxgl_compare",
        width,
        height,
        package = "mapgl"
    )
}

#' Render a Mapbox GL Compare output element in Shiny
#'
#' @param expr An expression that generates a Mapbox GL Compare map
#' @param env The environment in which to evaluate `expr`
#' @param quoted Is `expr` a quoted expression
#'
#' @return A rendered Mapbox GL Compare map for use in a Shiny server
#' @export
renderMapboxglCompare <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) {
        expr <- substitute(expr)
    } # force quoted
    htmlwidgets::shinyRenderWidget(
        expr,
        mapboxglCompareOutput,
        env,
        quoted = TRUE
    )
}

#' Create a Maplibre GL Compare output element for Shiny
#'
#' @param outputId The output variable to read from
#' @param width The width of the element
#' @param height The height of the element
#'
#' @return A Maplibre GL Compare output element for use in a Shiny UI
#' @export
maplibreCompareOutput <- function(outputId, width = "100%", height = "400px") {
    htmlwidgets::shinyWidgetOutput(
        outputId,
        "maplibregl_compare",
        width,
        height,
        package = "mapgl"
    )
}

#' Render a Maplibre GL Compare output element in Shiny
#'
#' @param expr An expression that generates a Maplibre GL Compare map
#' @param env The environment in which to evaluate `expr`
#' @param quoted Is `expr` a quoted expression
#'
#' @return A rendered Maplibre GL Compare map for use in a Shiny server
#' @export
renderMaplibreCompare <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) {
        expr <- substitute(expr)
    } # force quoted
    htmlwidgets::shinyRenderWidget(
        expr,
        maplibreCompareOutput,
        env,
        quoted = TRUE
    )
}

#' Create a proxy object for a Mapbox GL Compare widget in Shiny
#'
#' This function allows updates to be sent to an existing Mapbox GL Compare widget in a Shiny application.
#'
#' @param compareId The ID of the compare output element.
#' @param session The Shiny session object.
#' @param map_side Which map side to target in the compare widget, either "before" or "after".
#'
#' @return A proxy object for the Mapbox GL Compare widget.
#' @export
mapboxgl_compare_proxy <- function(
    compareId,
    session = shiny::getDefaultReactiveDomain(),
    map_side = "before"
) {
    if (is.null(session)) {
        stop(
            "mapboxgl_compare_proxy must be called from within a Shiny session"
        )
    }

    if (
        !is.null(session$ns) &&
            nzchar(session$ns(NULL)) &&
            substring(compareId, 1, nchar(session$ns(""))) != session$ns("")
    ) {
        compareId <- session$ns(compareId)
    }

    proxy <- list(id = compareId, session = session, map_side = map_side)
    class(proxy) <- c("mapboxgl_compare_proxy", "mapboxgl_proxy")
    proxy
}

#' Create a proxy object for a Maplibre GL Compare widget in Shiny
#'
#' This function allows updates to be sent to an existing Maplibre GL Compare widget in a Shiny application.
#'
#' @param compareId The ID of the compare output element.
#' @param session The Shiny session object.
#' @param map_side Which map side to target in the compare widget, either "before" or "after".
#'
#' @return A proxy object for the Maplibre GL Compare widget.
#' @export
maplibre_compare_proxy <- function(
    compareId,
    session = shiny::getDefaultReactiveDomain(),
    map_side = "before"
) {
    if (is.null(session)) {
        stop(
            "maplibre_compare_proxy must be called from within a Shiny session"
        )
    }

    if (
        !is.null(session$ns) &&
            nzchar(session$ns(NULL)) &&
            substring(compareId, 1, nchar(session$ns(""))) != session$ns("")
    ) {
        compareId <- session$ns(compareId)
    }

    proxy <- list(id = compareId, session = session, map_side = map_side)
    class(proxy) <- c("maplibre_compare_proxy", "maplibre_proxy")
    proxy
}

#' Add a Globe Minimap to a map
#'
#' This function adds a globe minimap control to a Mapbox GL or Maplibre map.
#'
#' @param map A `mapboxgl` or `maplibre` object.
#' @param position A string specifying the position of the minimap.
#' @param globe_size Number of pixels for the diameter of the globe. Default is 82.
#' @param land_color HTML color to use for land areas on the globe. Default is 'white'.
#' @param water_color HTML color to use for water areas on the globe. Default is 'rgba(30 40 70/60%)'.
#' @param marker_color HTML color to use for the center point marker. Default is '#ff2233'.
#' @param marker_size Scale ratio for the center point marker. Default is 1.
#'
#' @return The modified map object with the globe minimap added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' m <- mapboxgl() %>%
#'     add_globe_minimap()
#'
#' m <- maplibre() %>%
#'     add_globe_minimap()
#' }
add_globe_minimap <- function(
    map,
    position = "bottom-right",
    globe_size = 82,
    land_color = "white",
    water_color = "rgba(30 40 70/60%)",
    marker_color = "#ff2233",
    marker_size = 1
) {
    map$x$globe_minimap <- list(
        enabled = TRUE,
        position = position,
        globe_size = globe_size,
        land_color = land_color,
        water_color = water_color,
        marker_color = marker_color,
        marker_size = marker_size
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
                        type = "add_globe_minimap",
                        position = position,
                        globe_size = globe_size,
                        land_color = land_color,
                        water_color = water_color,
                        marker_color = marker_color,
                        marker_size = marker_size,
                        map = map$map_side
                    )
                )
            )
        } else {
            # For regular proxies
            proxy_class <- if (inherits(map, "mapboxgl_proxy"))
                "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(
                proxy_class,
                list(
                    id = map$id,
                    message = list(
                        type = "add_globe_minimap",
                        position = position,
                        globe_size = globe_size,
                        land_color = land_color,
                        water_color = water_color,
                        marker_color = marker_color,
                        marker_size = marker_size
                    )
                )
            )
        }
    }

    map
}
