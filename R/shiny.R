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

  proxy <- list(id = mapId, session = session)
  class(proxy) <- "maplibre_proxy"
  proxy
}

#' Add a filter to a Mapbox GL map using a proxy
#'
#' This function allows a filter to be added to an existing Mapbox GL map using a proxy object.
#'
#' @param proxy A proxy object created by `mapboxgl_proxy` or `maplibre_proxy`.
#' @param layer_id The ID of the layer to which the filter will be applied.
#' @param filter The filter expression to apply.
#'
#' @return The updated proxy object.
#' @export
set_filter <- function(proxy, layer_id, filter) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("Invalid proxy object")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"

  message <- list(type = "set_filter", layer = layer_id, filter = filter)
  proxy$session$sendCustomMessage(proxy_class, list(id = proxy$id, message = message))
  proxy
}

#' Clear a layer from a Mapbox GL map using a proxy
#'
#' This function allows a layer to be removed from an existing Mapbox GL map using a proxy object.
#'
#' @param proxy A proxy object created by `mapboxgl_proxy` or `maplibre_proxy`.
#' @param layer_id The ID of the layer to be removed.
#'
#' @return The updated proxy object.
#' @export
clear_layer <- function(proxy, layer_id) {
  if (!any(inherits(proxy, "mapboxgl_proxy"), inherits(proxy, "maplibre_proxy"))) {
    stop("Invalid proxy object")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"

  message <- list(type = "remove_layer", layer = layer_id)
  proxy$session$sendCustomMessage(proxy_class, list(id = proxy$id, message = message))
  proxy
}

#' Set a layout property on a Mapbox GL map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer The ID of the layer to update.
#' @param name The name of the layout property to set.
#' @param value The value to set the property to.
#'
#' @return The updated map object.
#' @export
set_layout_property <- function(map, layer, name, value) {
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "set_layout_property", layer = layer, name = name, value = value)
    ))
  } else {
    if (is.null(map$x$setLayoutProperty)) map$x$setLayoutProperty <- list()
    map$x$setLayoutProperty[[length(map$x$setLayoutProperty) + 1]] <- list(layer = layer, name = name, value = value)
  }
  return(map)
}

#' Set a paint property on a Mapbox GL map layer
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param layer The ID of the layer to update.
#' @param name The name of the paint property to set.
#' @param value The value to set the property to.
#'
#' @return The updated map object.
#' @export
set_paint_property <- function(map, layer, name, value) {
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "set_paint_property", layer = layer, name = name, value = value)
    ))
  } else {
    if (is.null(map$x$setPaintProperty)) map$x$setPaintProperty <- list()
    map$x$setPaintProperty[[length(map$x$setPaintProperty) + 1]] <- list(layer = layer, name = name, value = value)
  }
  return(map)
}

#' Clear markers from a Mapbox GL map in a Shiny session
#'
#' @param map A map object created by the `mapboxgl_proxy` or `maplibre_proxy` function.
#'
#' @return The modified map object with the markers cleared.
#' @export
clear_markers <- function(map) {
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "clear_markers")))
  } else {
    stop("clear_markers() can only be used with mapboxgl_proxy() or maplibre_proxy()")
  }
  return(map)
}

#' Update the style of a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function, or a proxy object.
#' @param style The new style URL to be applied to the map.
#' @param config A named list of options to be passed to the style config.
#' @param diff A boolean that attempts a diff-based update rather than re-drawing the full style.
#'
#' @return The modified map object.
#' @export
#'
#' @examples
#' \dontrun{
#' map <- mapboxgl(
#'   style = mapbox_style("streets"),
#'   center = c(-74.006, 40.7128),
#'   zoom = 10,
#'   access_token = "your_mapbox_access_token"
#' )
#'
#' # Update the map style in a Shiny app
#' observeEvent(input$change_style, {
#'   mapboxgl_proxy("map", session) %>%
#'     set_style(mapbox_style("dark"), config = list(showLabels = FALSE), diff = TRUE)
#' })
#' }
set_style <- function(map, style, config = NULL, diff = TRUE) {
  if (any(inherits(map, "mapboxgl_proxy"), inherits(map, "maplibre_proxy"))) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(
        type = "set_style",
        style = style,
        config = config,
        diff = diff
      )
    ))
  } else {
    stop("set_style can only be used with mapboxgl_proxy or maplibre_proxy.")
  }
  return(map)
}


#' Query rendered features on a map in a Shiny session
#'
#' @param proxy A MapboxGL or Maplibre proxy object, defined with `mapboxgl_proxy()` or `maplibre_proxy()`
#' @param geometry The geometry to query. Should be a length-2 vector representing a single location at which features will be queried, or a list of two coordinates representing the bottom-left and top-right corners of a bounding box within which features will be queried. Defaults to the current map view.
#' @param layers A vector of layer names to include in the query
#' @param filter A filter expression used to filter features in the query.
#'
#' @return The properties accessible at `input$MAPID_feature_query` in your Shiny app code.
#' @export
query_rendered_features <- function(proxy, geometry = NULL, layers = NULL, filter = NULL) {
  if (!inherits(proxy, "mapboxgl_proxy") && !inherits(proxy, "maplibre_proxy")) {
    stop("Invalid proxy object")
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"

  message <- list(
    type = "query_rendered_features",
    geometry = geometry,
    layers = layers,
    filter = filter
  )

  proxy$session$sendCustomMessage(proxy_class, list(id = proxy$id, message = message))
  proxy
}
