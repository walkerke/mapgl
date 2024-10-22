#' Create a Compare slider widget
#'
#' This function creates a comparison view between two Mapbox GL or Maplibre GL maps, allowing users to swipe between the two maps to compare different styles or data layers.
#'
#' @param map1 A `mapboxgl` or `maplibre` object representing the first map.
#' @param map2 A `mapboxgl` or `maplibre` object representing the second map.
#' @param width Width of the map container.
#' @param height Height of the map container.
#' @param elementId An optional string specifying the ID of the container for the comparison. If NULL, a unique ID will be generated.
#' @param mousemove A logical value indicating whether to enable swiping during cursor movement (rather than only when clicked).
#' @param orientation A string specifying the orientation of the swiper, either "horizontal" or "vertical".
#'
#' @return A comparison widget.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' library(mapgl)
#'
#' m1 <- mapboxgl(style = mapbox_style("light"))
#'
#' m2 <- mapboxgl(style = mapbox_style("dark"))
#'
#' compare(m1, m2)
#' }
compare <- function(map1,
                    map2,
                    width = "100%",
                    height = NULL,
                    elementId = NULL,
                    mousemove = FALSE,
                    orientation = "vertical") {
    if (inherits(map1, "mapboxgl") && inherits(map2, "mapboxgl")) {
        compare.mapboxgl(map1, map2, width, height, elementId, mousemove, orientation)
    } else if (inherits(map1, "maplibregl") && inherits(map2, "maplibregl")) {
        compare.maplibre(map1, map2, width, height, elementId, mousemove, orientation)
    } else {
        stop("Both maps must be either mapboxgl or maplibregl objects.")
    }
}

# Mapbox GL comparison widget
compare.mapboxgl <- function(map1, map2, width, height, elementId, mousemove, orientation) {
    if (is.null(elementId)) {
        elementId <- paste0("compare-container-", as.hexmode(sample(1:1000000, 1)))
    }

    x <- list(
        map1 = map1$x,
        map2 = map2$x,
        elementId = elementId,
        mousemove = mousemove,
        orientation = orientation
    )

    htmlwidgets::createWidget(
        name = "mapboxgl_compare",
        x,
        width = width,
        height = height,
        package = "mapgl",
        elementId = elementId,
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

# Maplibre comparison widget
compare.maplibre <- function(map1, map2, width, height, elementId, mousemove, orientation) {
    if (is.null(elementId)) {
        elementId <- paste0("compare-container-", as.hexmode(sample(1:1000000, 1)))
    }

    check_for_popups_or_tooltips <- function(map) {
        if (!is.null(map$x$layers)) {
            for (layer in map$x$layers) {
                if (!is.null(layer$popup) || !is.null(layer$tooltip)) {
                    return(TRUE)
                }
            }
        }
        return(FALSE)
    }

    if (check_for_popups_or_tooltips(map1) || check_for_popups_or_tooltips(map2)) {
        rlang::warn("Popups and tooltips are not currently supported for `compare()` with maplibre maps.")
    }

    x <- list(
        map1 = map1$x,
        map2 = map2$x,
        elementId = elementId,
        mousemove = mousemove,
        orientation = orientation
    )

    htmlwidgets::createWidget(
        name = "maplibregl_compare",
        x,
        width = width,
        height = height,
        package = "mapgl",
        elementId = elementId,
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
add_globe_minimap <- function(map, position = "bottom-right", globe_size = 82,
                              land_color = "white", water_color = "rgba(30 40 70/60%)",
                              marker_color = "#ff2233", marker_size = 1) {
    if (!inherits(map, c("mapboxgl", "maplibregl"))) {
        stop("Globe minimap is only supported for mapboxgl or maplibre maps.")
    }

    map$x$globe_minimap <- list(
        enabled = TRUE,
        position = position,
        globe_size = globe_size,
        land_color = land_color,
        water_color = water_color,
        marker_color = marker_color,
        marker_size = marker_size
    )

    if (inherits(map, "mapboxgl_proxy")) {
        map$session$sendCustomMessage("mapboxgl-proxy", list(
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
        ))
    } else if (inherits(map, "maplibre_proxy")) {
        map$session$sendCustomMessage("maplibre-proxy", list(
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
        ))
    }

    map
}
