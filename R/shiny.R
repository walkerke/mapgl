#' Create a proxy object for a Mapbox GL map in Shiny
#'
#' This function allows updates to be sent to an existing Mapbox GL map in a Shiny application without redrawing the entire map.
#'
#' @param mapId The ID of the map output element.
#' @param session The Shiny session object.
#'
#' @return A proxy object for the Mapbox GL map.
#' @export
mapboxgl_proxy <- function(mapId, session = shiny::getDefaultReactiveDomain()) {
    if (is.null(session)) {
        stop("mapboxgl_proxy must be called from within a Shiny session")
    }

    if (
        !is.null(session$ns) &&
            nzchar(session$ns(NULL)) &&
            substring(mapId, 1, nchar(session$ns(""))) != session$ns("")
    ) {
        mapId <- session$ns(mapId)
    }

    proxy <- list(id = mapId, session = session)
    class(proxy) <- "mapboxgl_proxy"
    proxy
}

#' Create a proxy object for a Maplibre GL map in Shiny
#'
#' This function allows updates to be sent to an existing Maplibre GL map in a Shiny application without redrawing the entire map.
#'
#' @param mapId The ID of the map output element.
#' @param session The Shiny session object.
#'
#' @return A proxy object for the Maplibre GL map.
#' @export
maplibre_proxy <- function(mapId, session = shiny::getDefaultReactiveDomain()) {
    if (is.null(session)) {
        stop("maplibre_proxy must be called from within a Shiny session")
    }

    if (
        !is.null(session$ns) &&
            nzchar(session$ns(NULL)) &&
            substring(mapId, 1, nchar(session$ns(""))) != session$ns("")
    ) {
        mapId <- session$ns(mapId)
    }

    proxy <- list(id = mapId, session = session)
    class(proxy) <- "maplibre_proxy"
    proxy
}

#' Set a filter on a map layer
#'
#' This function sets a filter on a map layer, working with both regular map objects and proxy objects.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer_id The ID of the layer to which the filter will be applied.
#' @param filter The filter expression to apply.
#'
#' @return The updated map object.
#' @export
set_filter <- function(map, layer_id, filter) {
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
        if (
            inherits(map, "mapboxgl_compare_proxy") ||
                inherits(map, "maplibre_compare_proxy")
        ) {
            # For compare proxies, use the appropriate message handler
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
                "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(
                proxy_class,
                list(
                    id = map$id,
                    message = list(
                        type = "set_filter",
                        layer = layer_id,
                        filter = filter,
                        map = map$map_side # Add which map to target
                    )
                )
            )
        } else {
            # For regular proxies, use existing message handler
            proxy_class <- if (inherits(map, "mapboxgl_proxy"))
                "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(
                proxy_class,
                list(
                    id = map$id,
                    message = list(
                        type = "set_filter",
                        layer = layer_id,
                        filter = filter
                    )
                )
            )
        }
    } else {
        if (is.null(map$x$setFilter)) map$x$setFilter <- list()
        map$x$setFilter[[length(map$x$setFilter) + 1]] <- list(
            layer = layer_id,
            filter = filter
        )
    }
    return(map)
}

#' Clear layers from a map using a proxy
#'
#' This function allows one or more layers to be removed from an existing Mapbox GL map using a proxy object.
#'
#' @param proxy A proxy object created by `mapboxgl_proxy` or `maplibre_proxy`.
#' @param layer_id A character vector of layer IDs to be removed. Can be a single layer ID or multiple layer IDs.
#'
#' @return The updated proxy object.
#' @export
clear_layer <- function(proxy, layer_id) {
    if (
        !any(
            inherits(proxy, "mapboxgl_proxy"),
            inherits(proxy, "maplibre_proxy")
        )
    ) {
        stop("Invalid proxy object")
    }

    # Handle vector of layer_ids by iterating through them
    for (layer in layer_id) {
        if (
            inherits(proxy, "mapboxgl_compare_proxy") ||
                inherits(proxy, "maplibre_compare_proxy")
        ) {
            # For compare proxies
            proxy_class <- if (inherits(proxy, "mapboxgl_compare_proxy"))
                "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            message <- list(
                type = "remove_layer",
                layer = layer,
                map = proxy$map_side
            )
        } else {
            # For regular proxies
            proxy_class <- if (inherits(proxy, "mapboxgl_proxy"))
                "mapboxgl-proxy" else "maplibre-proxy"
            message <- list(type = "remove_layer", layer = layer)
        }

        proxy$session$sendCustomMessage(
            proxy_class,
            list(id = proxy$id, message = message)
        )
    }
    proxy
}

#' Set a layout property on a map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer_id The ID of the layer to update.
#' @param name The name of the layout property to set.
#' @param value The value to set the property to.
#' @param layer Deprecated. Use `layer_id` instead.
#'
#' @return The updated map object.
#' @export
set_layout_property <- function(map, layer_id = NULL, name, value, layer = NULL) {
    # Handle backwards compatibility
    if (!is.null(layer) && is.null(layer_id)) {
        layer_id <- layer
        warning("The 'layer' argument is deprecated. Please use 'layer_id' instead.", call. = FALSE)
    }
    
    if (is.null(layer_id)) {
        stop("layer_id is required")
    }
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
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
                        type = "set_layout_property",
                        layer = layer_id,
                        name = name,
                        value = value,
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
                        type = "set_layout_property",
                        layer = layer_id,
                        name = name,
                        value = value
                    )
                )
            )
        }
    } else {
        if (is.null(map$x$setLayoutProperty)) map$x$setLayoutProperty <- list()
        map$x$setLayoutProperty[[length(map$x$setLayoutProperty) + 1]] <- list(
            layer = layer_id,
            name = name,
            value = value
        )
    }
    return(map)
}

#' Set a paint property on a map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer_id The ID of the layer to update.
#' @param name The name of the paint property to set.
#' @param value The value to set the property to.
#' @param layer Deprecated. Use `layer_id` instead.
#'
#' @return The updated map object.
#' @export
set_paint_property <- function(map, layer_id = NULL, name, value, layer = NULL) {
    # Handle backwards compatibility
    if (!is.null(layer) && is.null(layer_id)) {
        layer_id <- layer
        warning("The 'layer' argument is deprecated. Please use 'layer_id' instead.", call. = FALSE)
    }
    
    if (is.null(layer_id)) {
        stop("layer_id is required")
    }
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
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
                        type = "set_paint_property",
                        layer = layer_id,
                        name = name,
                        value = value,
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
                        type = "set_paint_property",
                        layer = layer_id,
                        name = name,
                        value = value
                    )
                )
            )
        }
    } else {
        if (is.null(map$x$setPaintProperty)) map$x$setPaintProperty <- list()
        map$x$setPaintProperty[[length(map$x$setPaintProperty) + 1]] <- list(
            layer = layer_id,
            name = name,
            value = value
        )
    }
    return(map)
}

#' Clear markers from a map in a Shiny session
#'
#' @param map A map object created by the `mapboxgl_proxy` or `maplibre_proxy` function.
#'
#' @return The modified map object with the markers cleared.
#' @export
clear_markers <- function(map) {
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
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
                        type = "clear_markers",
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
                list(id = map$id, message = list(type = "clear_markers"))
            )
        }
    } else {
        stop(
            "clear_markers() can only be used with mapboxgl_proxy(), maplibre_proxy(), mapboxgl_compare_proxy(), or maplibre_compare_proxy()"
        )
    }
    return(map)
}

#' Update the style of a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param style The new style URL to be applied to the map.
#' @param config A named list of options to be passed to the style config.
#' @param diff A boolean that attempts a diff-based update rather than re-drawing the full style. Not available for all styles.
#' @param preserve_layers A boolean that indicates whether to preserve user-added sources and layers when changing styles. Defaults to TRUE.
#'
#' @return The modified map object.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(
#'     style = mapbox_style("streets"),
#'     center = c(-74.006, 40.7128),
#'     zoom = 10,
#'     access_token = "your_mapbox_access_token"
#' )
#'
#' # Update the map style in a Shiny app
#' observeEvent(input$change_style, {
#'     mapboxgl_proxy("map", session) %>%
#'         set_style(mapbox_style("dark"), config = list(showLabels = FALSE), diff = TRUE)
#' })
#' }
set_style <- function(map, style, config = NULL, diff = TRUE, preserve_layers = TRUE) {
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
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
                        type = "set_style",
                        style = style,
                        config = config,
                        diff = diff,
                        preserve_layers = preserve_layers,
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
                        type = "set_style",
                        style = style,
                        config = config,
                        diff = diff,
                        preserve_layers = preserve_layers
                    )
                )
            )
        }
    } else {
        stop(
            "set_style can only be used with mapboxgl_proxy, maplibre_proxy, mapboxgl_compare_proxy, or maplibre_compare_proxy."
        )
    }
    return(map)
}

#' Move a layer to a different z-position
#'
#' This function allows a layer to be moved to a different z-position in an existing Mapbox GL or Maplibre GL map using a proxy object.
#'
#' @param proxy A proxy object created by `mapboxgl_proxy` or `maplibre_proxy`.
#' @param layer_id The ID of the layer to move.
#' @param before_id The ID of an existing layer to insert the new layer before. __Important__: this means that the layer will appear _immediately behind_ the layer defined in `before_id`. If omitted, the layer will be appended to the end of the layers array and appear above all other layers.
#'
#' @return The updated proxy object.
#' @export
move_layer <- function(proxy, layer_id, before_id = NULL) {
    if (
        !any(
            inherits(proxy, "mapboxgl_proxy"),
            inherits(proxy, "maplibre_proxy")
        )
    ) {
        stop("Invalid proxy object")
    }

    if (
        inherits(proxy, "mapboxgl_compare_proxy") ||
            inherits(proxy, "maplibre_compare_proxy")
    ) {
        # For compare proxies
        proxy_class <- if (inherits(proxy, "mapboxgl_compare_proxy"))
            "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
        message <- list(
            type = "move_layer",
            layer = layer_id,
            before = before_id,
            map = proxy$map_side
        )
    } else {
        # For regular proxies
        proxy_class <- if (inherits(proxy, "mapboxgl_proxy"))
            "mapboxgl-proxy" else "maplibre-proxy"
        message <- list(
            type = "move_layer",
            layer = layer_id,
            before = before_id
        )
    }

    proxy$session$sendCustomMessage(
        proxy_class,
        list(id = proxy$id, message = message)
    )
    proxy
}

#' Set tooltip on a map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer_id The ID of the layer to update.
#' @param tooltip  The name of the tooltip to set.
#' @param layer Deprecated. Use `layer_id` instead.
#'
#' @return The updated map object.
#' @export
set_tooltip <- function(map, layer_id = NULL, tooltip, layer = NULL) {
    # Handle backwards compatibility
    if (!is.null(layer) && is.null(layer_id)) {
        layer_id <- layer
        warning("The 'layer' argument is deprecated. Please use 'layer_id' instead.", call. = FALSE)
    }
    
    if (is.null(layer_id)) {
        stop("layer_id is required")
    }
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
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
                        type = "set_tooltip",
                        layer = layer_id,
                        tooltip = tooltip,
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
                        type = "set_tooltip",
                        layer = layer_id,
                        tooltip = tooltip
                    )
                )
            )
        }
    } else {
        stop(
            "set_tooltip can only be used with mapboxgl_proxy, maplibre_proxy, mapboxgl_compare_proxy, or maplibre_compare_proxy."
        )
    }
    return(map)
}

#' Set popup on a map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer_id The ID of the layer to update.
#' @param popup The name of the popup property or an expression to set.
#' @param layer Deprecated. Use `layer_id` instead.
#'
#' @return The updated map object.
#' @export
set_popup <- function(map, layer_id = NULL, popup, layer = NULL) {
    # Handle backwards compatibility
    if (!is.null(layer) && is.null(layer_id)) {
        layer_id <- layer
        warning("The 'layer' argument is deprecated. Please use 'layer_id' instead.", call. = FALSE)
    }
    
    if (is.null(layer_id)) {
        stop("layer_id is required")
    }
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
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
                        type = "set_popup",
                        layer = layer_id,
                        popup = popup,
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
                        type = "set_popup",
                        layer = layer_id,
                        popup = popup
                    )
                )
            )
        }
    } else {
        stop(
            "set_popup can only be used with mapboxgl_proxy, maplibre_proxy, mapboxgl_compare_proxy, or maplibre_compare_proxy."
        )
    }
    return(map)
}

#' Set source of a map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer_id The ID of the layer to update.
#' @param source An sf object (which will be converted to a GeoJSON source).
#' @param layer Deprecated. Use `layer_id` instead.
#'
#' @return The updated map object.
#' @export
set_source <- function(map, layer_id = NULL, source, layer = NULL) {
    # Handle backwards compatibility
    if (!is.null(layer) && is.null(layer_id)) {
        layer_id <- layer
        warning("The 'layer' argument is deprecated. Please use 'layer_id' instead.", call. = FALSE)
    }
    
    if (is.null(layer_id)) {
        stop("layer_id is required")
    }
    if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
        # Convert sf objects to GeoJSON source
        if (inherits(source, "sf")) {
            source <- geojsonsf::sf_geojson(sf::st_transform(
                source,
                crs = 4326
            ))
        }

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
                        type = "set_source",
                        layer = layer_id,
                        source = source,
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
                        type = "set_source",
                        layer = layer_id,
                        source = source
                    )
                )
            )
        }
    } else {
        stop(
            "set_source can only be used with mapboxgl_proxy, maplibre_proxy, mapboxgl_compare_proxy, or maplibre_compare_proxy."
        )
    }
    return(map)
}

#' Query rendered features on a map in a Shiny session
#'
#' This function triggers a query for rendered features on a map using a proxy object.
#' Use `get_queried_features()` to retrieve the results as an sf object, or use the 
#' `callback` parameter to handle results automatically when they're ready.
#'
#' @param proxy A MapboxGL or Maplibre proxy object, defined with `mapboxgl_proxy()` or `maplibre_proxy()`
#' @param geometry The geometry to query. Can be:
#'   - `NULL` (default): Query the entire viewport
#'   - A length-2 vector `c(x, y)`: Query at a single point in pixel coordinates
#'   - A length-4 vector `c(xmin, ymin, xmax, ymax)`: Query within a bounding box in pixel coordinates
#' @param layers A character vector of layer names to include in the query. If `NULL` (default), all layers are queried.
#' @param filter A filter expression used to filter features in the query. Should be a list representing a Mapbox GL expression.
#' @param callback A function to execute when results are ready. The function will receive the sf object as its argument.
#'   If provided, this avoids timing issues by automatically handling results when they're available.
#'
#' @return The proxy object (invisibly). Use `get_queried_features()` to retrieve the query results manually, 
#'   or provide a `callback` function to handle results automatically.
#' @export
#'
#' @examples
#' \dontrun{
#' # Query entire viewport with callback (recommended - avoids timing issues)
#' proxy <- maplibre_proxy("map")
#' query_features(proxy, layers = "counties", callback = function(features) {
#'   if (nrow(features) > 0) {
#'     proxy |> set_filter("selected_layer", list("in", "id", features$id))
#'   }
#' })
#'
#' # Manual approach (may have timing issues)
#' query_features(proxy, layers = "counties")
#' features <- get_queried_features(proxy)
#'
#' # Query specific bounding box with callback
#' query_features(proxy, geometry = c(100, 100, 200, 200), 
#'                layers = "counties", callback = function(features) {
#'   print(paste("Found", nrow(features), "features"))
#' })
#' }
query_features <- function(proxy, geometry = NULL, layers = NULL, filter = NULL, callback = NULL) {
    if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
        stop("Invalid proxy object")
    }
    
    # Validate geometry parameter
    if (!is.null(geometry)) {
        if (!is.numeric(geometry)) {
            stop("geometry must be NULL or a numeric vector")
        }
        if (length(geometry) == 2) {
            # Point query: c(x, y)
            geometry <- as.list(geometry)
        } else if (length(geometry) == 4) {
            # Bounding box: c(xmin, ymin, xmax, ymax) -> [[xmin, ymin], [xmax, ymax]]
            geometry <- list(
                c(geometry[1], geometry[2]),  # bottom-left
                c(geometry[3], geometry[4])   # top-right
            )
        } else {
            stop("geometry must be either length 2 (point) or length 4 (bounding box)")
        }
    }
    
    # Store callback if provided
    if (!is.null(callback)) {
        if (!is.function(callback)) {
            stop("callback must be a function")
        }
        
        # Store callback in session userData with unique ID
        callback_id <- paste0(proxy$id, "_query_callback_", as.numeric(Sys.time()) * 1000)
        proxy$session$userData[[callback_id]] <- callback
        
        # Set up observer to handle callback when results are ready
        callback_observer <- shiny::observeEvent(
            proxy$session$input[[paste0(proxy$id, "_queried_features")]], 
            {
                features_json <- proxy$session$input[[paste0(proxy$id, "_queried_features")]]
                if (!is.null(features_json) && features_json != "null" && nchar(features_json) > 0) {
                    features <- sf::st_make_valid(sf::st_read(features_json, quiet = TRUE))
                    # Execute callback
                    callback(features)
                }
                # Clean up
                proxy$session$userData[[callback_id]] <- NULL
                callback_observer$destroy()
            },
            once = TRUE,
            ignoreInit = TRUE
        )
    }
    
    if (
        inherits(proxy, "mapboxgl_compare_proxy") ||
            inherits(proxy, "maplibre_compare_proxy")
    ) {
        # For compare proxies
        proxy_class <- if (inherits(proxy, "mapboxgl_compare_proxy"))
            "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
        proxy$session$sendCustomMessage(
            proxy_class,
            list(
                id = proxy$id,
                message = list(
                    type = "query_rendered_features",
                    geometry = geometry,
                    layers = layers,
                    filter = filter,
                    map = proxy$map_side
                )
            )
        )
    } else {
        # For regular proxies
        proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
        proxy$session$sendCustomMessage(
            proxy_class,
            list(
                id = proxy$id,
                message = list(
                    type = "query_rendered_features",
                    geometry = geometry,
                    layers = layers,
                    filter = filter
                )
            )
        )
    }
    
    invisible(proxy)
}

#' Get queried features from a map as an sf object
#'
#' This function retrieves the results of a feature query triggered by `query_features()`.
#' It returns the features as a deduplicated sf object.
#'
#' @param map A map object (mapboxgl, maplibre) or proxy object (mapboxgl_proxy, maplibre_proxy)
#'
#' @return An sf object containing the queried features, or an empty sf object if no features were found
#' @export
#'
#' @examples
#' \dontrun{
#' # In a Shiny server function:
#' observeEvent(input$query_button, {
#'     proxy <- maplibre_proxy("map")
#'     query_features(proxy, layers = "counties")
#'     features <- get_queried_features(proxy)
#'     print(nrow(features))
#' })
#' }
get_queried_features <- function(map) {
    if (
        !shiny::is.reactive(map) &&
            !inherits(
                map,
                c("mapboxgl", "mapboxgl_proxy", "maplibregl", "maplibre_proxy")
            )
    ) {
        stop(
            "Invalid map object. Expected mapboxgl, mapboxgl_proxy, maplibre or maplibre_proxy object within a Shiny context."
        )
    }
    
    # If map is reactive (e.g., output$map in Shiny), evaluate it
    if (shiny::is.reactive(map)) {
        map <- map()
    }
    
    # Determine if we're in a Shiny session
    in_shiny <- shiny::isRunning()
    
    if (!in_shiny) {
        warning(
            "Getting queried features outside of a Shiny context is not supported. Please use this function within a Shiny application."
        )
        return(sf::st_sf(geometry = sf::st_sfc())) # Return an empty sf object
    }
    
    # Get the session object
    session <- shiny::getDefaultReactiveDomain()
    
    if (inherits(map, "mapboxgl") || inherits(map, "maplibregl")) {
        # Initial map object in Shiny
        map_id <- map$elementId
    } else if (
        inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")
    ) {
        # Proxy object
        map_id <- map$id
    } else {
        stop("Unexpected map object type.")
    }
    
    # Trim any module namespacing off to index the session proxy inputs
    map_queried_id <- sub(
        pattern = session$ns(""),
        replacement = "",
        x = paste0(map_id, "_queried_features")
    )
    
    # Wait for response
    features_json <- NULL
    wait_time <- 0
    while (
        is.null(features_json) &&
            wait_time < 3
    ) {
        # Wait up to 3 seconds
        features_json <- session$input[[map_queried_id]]
        Sys.sleep(0.1)
        wait_time <- wait_time + 0.1
    }
    
    if (
        !is.null(features_json) &&
            features_json != "null" &&
            nchar(features_json) > 0
    ) {
        sf::st_make_valid(sf::st_read(features_json, quiet = TRUE))
    } else {
        sf::st_sf(geometry = sf::st_sfc()) # Return an empty sf object if no features
    }
}
