#' Create a Compare widget
#'
#' This function creates a comparison view between two or more Mapbox GL or Maplibre GL maps, allowing users to either swipe between two maps or view multiple maps side-by-side with synchronized navigation.
#'
#' @param map1 A `mapboxgl` or `maplibre` object representing the first map.
#' @param map2 A `mapboxgl` or `maplibre` object representing the second map.
#' @param ... Additional `mapboxgl` or `maplibre` objects to include in the
#'   comparison. Supplying more than two maps requires `mode = "sync"`, and
#'   the synced maps are arranged in a grid controlled by `ncol`. When extra
#'   maps are supplied, all other arguments (`width`, `height`, etc.) must be
#'   passed by name.
#' @param width Width of the map container.
#' @param height Height of the map container.
#' @param elementId An optional string specifying the ID of the container for the comparison. If NULL, a unique ID will be generated.
#' @param mousemove A logical value indicating whether to enable swiping during cursor movement (rather than only when clicked). Only applicable when `mode="swipe"`.
#' @param orientation A string specifying the orientation of the swiper or the side-by-side layout, either "horizontal" or "vertical".
#' @param mode A string specifying the comparison mode: "swipe" (default) for a swipeable comparison with a slider, or "sync" for synchronized maps displayed next to each other.
#' @param ncol Number of columns in the synced map grid. Defaults to
#'   `ceiling(sqrt(n))` for more than two maps; for two maps, `orientation`
#'   controls the layout unless `ncol` is given. Only applicable when
#'   `mode = "sync"`.
#' @param swiper_color An optional CSS color value (e.g., "#000000", "rgb(0,0,0)", "black") to customize the color of the swiper handle. Only applicable when `mode="swipe"`.
#' @param laser Logical; if `TRUE`, show a laser pointer on the other maps
#'   that follows the cursor location. Only applies when `mode = "sync"`.
#' @param laser_color CSS color for the laser pointer.
#' @param laser_size Size of the laser pointer in pixels.
#'
#' @return A comparison widget.
#' @export
#'
#' @details
#' ## Comparison modes
#'
#' The `compare()` function supports two modes:
#'
#' * `mode="swipe"` (default) - Creates a swipeable interface with a slider to reveal portions of each map. Swipe mode supports exactly two maps.
#' * `mode="sync"` - Places the maps next to each other with synchronized navigation. Sync mode supports two or more maps; pass additional maps after `map1` and `map2` and control the grid layout with `ncol`.
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
#' ## Comparing more than two maps
#'
#' When more than two maps are supplied with `mode = "sync"`, the maps are
#' identified as "map1", "map2", "map3", and so on, in the order they were
#' passed to `compare()`. Use these identifiers (or their position as an
#' integer) as `map_side` in the proxy functions, e.g.
#' `maplibre_compare_proxy("mycompare", map_side = "map3")` or
#' `map_side = 3`. Shiny input values follow the same naming:
#' `input$mycompare_map1_view`, `input$mycompare_map3_click`, etc.
#' Legends can be targeted at individual maps in the grid with
#' `add_legend(..., target = "map3")`.
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
#' # Synchronized maps with a laser pointer
#' compare(m1, m2, mode = "sync", laser = TRUE)
#'
#' # Synchronize four maps in a 2 x 2 grid
#' m3 <- mapboxgl(style = mapbox_style("streets"))
#' m4 <- mapboxgl(style = mapbox_style("satellite"))
#' compare(m1, m2, m3, m4, mode = "sync", ncol = 2)
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
    ...,
    width = "100%",
    height = NULL,
    elementId = NULL,
    mousemove = FALSE,
    orientation = "vertical",
    mode = "swipe",
    ncol = NULL,
    swiper_color = NULL,
    laser = FALSE,
    laser_color = "#ff2d55",
    laser_size = 14
) {
    extra_maps <- list(...)

    # Distinguish stray named arguments (likely typos) from legacy positional
    # arguments (width/height/etc. must now be passed by name)
    is_map_object <- function(m) {
        inherits(m, "mapboxgl") || inherits(m, "maplibregl")
    }
    if (length(extra_maps) > 0) {
        extra_names <- names(extra_maps)
        for (i in seq_along(extra_maps)) {
            if (!is_map_object(extra_maps[[i]])) {
                if (!is.null(extra_names) && nzchar(extra_names[i])) {
                    stop(
                        sprintf(
                            "Unknown argument `%s` passed to `compare()`; only additional map objects may be supplied beyond the named arguments.",
                            extra_names[i]
                        )
                    )
                } else {
                    stop(
                        "Arguments after the maps must be named, e.g. `compare(m1, m2, width = \"100%\")`. Only additional map objects may be passed unnamed."
                    )
                }
            }
        }
    }

    maps <- c(list(map1, map2), extra_maps)
    n <- length(maps)

    if (!mode %in% c("swipe", "sync")) {
        stop("Mode must be either 'swipe' or 'sync'.")
    }

    if (n > 2 && mode != "sync") {
        stop(
            "`mode = \"swipe\"` supports exactly 2 maps; use `mode = \"sync\"` to compare more than 2 maps."
        )
    }

    laser <- isTRUE(laser)
    if (laser && mode != "sync") {
        rlang::warn("`laser` is only supported when `mode = \"sync\"`; ignoring it.")
        laser <- FALSE
    }

    if (
        length(laser_size) != 1 ||
            !is.numeric(laser_size) ||
            !is.finite(laser_size) ||
            laser_size <= 0
    ) {
        stop("`laser_size` must be a positive number.")
    }

    if (!is.null(ncol)) {
        # The integer.max bound must come before %% 1: it keeps later integer
        # casts safe and short-circuits huge values like 1e20, for which the
        # modulus itself warns about lost accuracy
        if (
            length(ncol) != 1 ||
                !is.numeric(ncol) ||
                is.na(ncol) ||
                !is.finite(ncol) ||
                ncol < 1 ||
                ncol > .Machine$integer.max ||
                ncol %% 1 != 0
        ) {
            stop("`ncol` must be a single positive integer.")
        }
        if (mode != "sync") {
            rlang::warn("`ncol` is ignored when `mode = \"swipe\"`.")
            ncol <- NULL
        } else if (ncol > n) {
            rlang::warn(sprintf(
                "`ncol` (%d) is greater than the number of maps (%d); using %d.",
                as.integer(ncol),
                n,
                n
            ))
            ncol <- n
        }
    }

    # Default grid layout for more than two maps; for two maps, orientation
    # controls the layout unless ncol is explicitly supplied
    if (is.null(ncol) && n > 2) {
        ncol <- ceiling(sqrt(n))
    }

    if (all(vapply(maps, inherits, logical(1), "mapboxgl"))) {
        compare.mapboxgl(
            maps,
            width,
            height,
            elementId,
            mousemove,
            orientation,
            mode,
            ncol,
            swiper_color,
            laser,
            laser_color,
            laser_size
        )
    } else if (all(vapply(maps, inherits, logical(1), "maplibregl"))) {
        compare.maplibre(
            maps,
            width,
            height,
            elementId,
            mousemove,
            orientation,
            mode,
            ncol,
            swiper_color,
            laser,
            laser_color,
            laser_size
        )
    } else {
        stop("All maps must be either mapboxgl or maplibregl objects.")
    }
}

# Mapbox GL comparison widget
compare.mapboxgl <- function(
    maps,
    width,
    height,
    elementId,
    mousemove,
    orientation,
    mode,
    ncol = NULL,
    swiper_color = NULL,
    laser = FALSE,
    laser_color = "#ff2d55",
    laser_size = 14
) {
    if (is.null(elementId)) {
        elementId <- paste0(
            "compare-container-",
            as.hexmode(sample(1:1000000, 1))
        )
    }

    x <- list(
        map1 = maps[[1]]$x,
        map2 = maps[[2]]$x,
        elementId = elementId,
        mousemove = mousemove,
        orientation = orientation,
        mode = mode,
        swiper_color = swiper_color,
        laser = list(
            enabled = laser,
            color = laser_color,
            size = laser_size
        )
    )

    # Grids with more than two maps carry the full map list; the 2-map
    # payload is unchanged for backwards compatibility
    if (length(maps) > 2) {
        x$maps <- lapply(maps, function(m) m$x)
    }
    if (!is.null(ncol)) {
        x$sync_cols <- ncol
    }

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
    maps,
    width,
    height,
    elementId,
    mousemove,
    orientation,
    mode,
    ncol = NULL,
    swiper_color = NULL,
    laser = FALSE,
    laser_color = "#ff2d55",
    laser_size = 14
) {
    if (is.null(elementId)) {
        elementId <- paste0(
            "compare-container-",
            as.hexmode(sample(1:1000000, 1))
        )
    }

    x <- list(
        map1 = maps[[1]]$x,
        map2 = maps[[2]]$x,
        elementId = elementId,
        mousemove = mousemove,
        orientation = orientation,
        mode = mode,
        swiper_color = swiper_color,
        laser = list(
            enabled = laser,
            color = laser_color,
            size = laser_size
        )
    )

    # Grids with more than two maps carry the full map list; the 2-map
    # payload is unchanged for backwards compatibility
    if (length(maps) > 2) {
        x$maps <- lapply(maps, function(m) m$x)
    }
    if (!is.null(ncol)) {
        x$sync_cols <- ncol
    }

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

# Normalize and validate the map_side argument for compare proxies.
# Accepts "before", "after", "mapN" (N >= 1), or a positive integer
# (e.g. 3 becomes "map3").
normalize_map_side <- function(map_side) {
    if (is.numeric(map_side)) {
        # The integer.max bound must come before %% 1: it keeps the cast below
        # safe and short-circuits huge values like 1e20, for which the modulus
        # itself warns about lost accuracy
        if (
            length(map_side) != 1 ||
                is.na(map_side) ||
                !is.finite(map_side) ||
                map_side < 1 ||
                map_side > .Machine$integer.max ||
                map_side %% 1 != 0
        ) {
            stop(
                "`map_side` must be \"before\", \"after\", \"mapN\" (e.g. \"map3\"), or a positive integer."
            )
        }
        return(paste0("map", as.integer(map_side)))
    }

    if (
        !is.character(map_side) ||
            length(map_side) != 1 ||
            is.na(map_side) ||
            !(map_side %in% c("before", "after") ||
                grepl("^map[1-9][0-9]*$", map_side))
    ) {
        stop(
            "`map_side` must be \"before\", \"after\", \"mapN\" (e.g. \"map3\"), or a positive integer."
        )
    }

    map_side
}

#' Create a proxy object for a Mapbox GL Compare widget in Shiny
#'
#' This function allows updates to be sent to an existing Mapbox GL Compare widget in a Shiny application.
#'
#' @param compareId The ID of the compare output element.
#' @param session The Shiny session object.
#' @param map_side Which map to target in the compare widget: "before" or
#'   "after" for two-map widgets, or a map identifier such as "map3" (or its
#'   position as an integer, e.g. `3`) for synced grids with more than two
#'   maps. "before" and "after" are aliases for the first and second maps.
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

    map_side <- normalize_map_side(map_side)

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
#' @param map_side Which map to target in the compare widget: "before" or
#'   "after" for two-map widgets, or a map identifier such as "map3" (or its
#'   position as an integer, e.g. `3`) for synced grids with more than two
#'   maps. "before" and "after" are aliases for the first and second maps.
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

    map_side <- normalize_map_side(map_side)

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
