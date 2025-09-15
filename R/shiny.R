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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
set_layout_property <- function(
  map,
  layer_id = NULL,
  name,
  value,
  layer = NULL
) {
  # Handle backwards compatibility
  if (!is.null(layer) && is.null(layer_id)) {
    layer_id <- layer
    warning(
      "The 'layer' argument is deprecated. Please use 'layer_id' instead.",
      call. = FALSE
    )
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
set_paint_property <- function(
  map,
  layer_id = NULL,
  name,
  value,
  layer = NULL
) {
  # Handle backwards compatibility
  if (!is.null(layer) && is.null(layer_id)) {
    layer_id <- layer
    warning(
      "The 'layer' argument is deprecated. Please use 'layer_id' instead.",
      call. = FALSE
    )
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
set_style <- function(
  map,
  style,
  config = NULL,
  diff = TRUE,
  preserve_layers = TRUE
) {
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
#' This function allows a layer to be moved to a different z-position in a Mapbox GL or Maplibre GL map. For initial maps, the operation is queued and executed during map initialization. For proxy objects, the operation is executed immediately.
#'
#' @param map A map object created by `mapboxgl` or `maplibre`, or a proxy object created by `mapboxgl_proxy` or `maplibre_proxy`.
#' @param layer_id The ID of the layer to move.
#' @param before_id The ID of an existing layer to insert the new layer before. __Important__: this means that the layer will appear _immediately behind_ the layer defined in `before_id`. If omitted, the layer will be appended to the end of the layers array and appear above all other layers.
#'
#' @return The updated map or proxy object.
#' @export
move_layer <- function(map, layer_id, before_id = NULL) {
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    # Proxy handling (existing logic)
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      message <- list(
        type = "move_layer",
        layer = layer_id,
        before = before_id,
        map = map$map_side
      )
    } else {
      # For regular proxies
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
      message <- list(
        type = "move_layer",
        layer = layer_id,
        before = before_id
      )
    }

    map$session$sendCustomMessage(
      proxy_class,
      list(id = map$id, message = message)
    )
  } else {
    # For non-proxy maps, store the move operation for initialization
    if (is.null(map$x$moveLayer)) map$x$moveLayer <- list()
    map$x$moveLayer[[length(map$x$moveLayer) + 1]] <- list(
      layer = layer_id,
      before = before_id
    )
  }
  return(map)
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
    warning(
      "The 'layer' argument is deprecated. Please use 'layer_id' instead.",
      call. = FALSE
    )
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
    warning(
      "The 'layer' argument is deprecated. Please use 'layer_id' instead.",
      call. = FALSE
    )
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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
    warning(
      "The 'layer' argument is deprecated. Please use 'layer_id' instead.",
      call. = FALSE
    )
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
      proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else
        "maplibre-proxy"
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

#' Clear legends from a map
#'
#' Remove one or more legends from a Mapbox GL or MapLibre GL map in a Shiny application.
#'
#' @param map A map proxy object created by \code{mapboxgl_proxy()} or \code{maplibre_proxy()}.
#' @param legend_ids Optional. A character vector of legend IDs to clear. If not provided, all legends will be cleared.
#'
#' @return The updated map proxy object with the specified legend(s) cleared.
#'
#' @note This function can only be used with map proxy objects in Shiny applications.
#' It cannot be used with static map objects.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # In a Shiny server function:
#'
#' # Clear all legends
#' observeEvent(input$clear_all, {
#'   mapboxgl_proxy("map") %>%
#'     clear_legend()
#' })
#'
#' # Clear specific legends by ID
#' observeEvent(input$clear_specific, {
#'   mapboxgl_proxy("map") %>%
#'     clear_legend(legend_ids = c("legend-1", "legend-2"))
#' })
#'
#' # Clear legend after removing a layer
#' observeEvent(input$remove_layer, {
#'   mapboxgl_proxy("map") %>%
#'     remove_layer("my_layer") %>%
#'     clear_legend(legend_ids = "my_layer_legend")
#' })
#' }
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
