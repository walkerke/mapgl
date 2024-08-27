#' Add a layer to a map from a source
#'
#' In many cases, you will use `add_layer()` internal to other layer-specific functions in mapgl. Advanced users will want to use `add_layer()` for more fine-grained control over the appearance of their layers.
#'
#' @param map A map object created by the `mapboxgl()` or `maplibre()` functions.
#' @param id A unique ID for the layer.
#' @param type The type of the layer (e.g., "fill", "line", "circle").
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param paint A list of paint properties for the layer.
#' @param layout A list of layout properties for the layer.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup A column name containing information to display in a popup on click.  Columns containing HTML will be parsed.
#' @param tooltip A column name containing information to display in a tooltip on hover. Columns containing HTML will be parsed.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' # Load necessary libraries
#'library(mapgl)
#'library(tigris)
#'
#'# Load geojson data for North Carolina tracts
#'nc_tracts <- tracts(state = "NC", cb = TRUE)
#'
#'# Create a Mapbox GL map
#'map <- mapboxgl(
#'  style = mapbox_style("light"),
#'  center = c(-79.0193, 35.7596),
#'  zoom = 7
#')
#'
#'# Add a source and fill layer for North Carolina tracts
#'map %>%
#'  add_source(
#'    id = "nc-tracts",
#'    data = nc_tracts
#'  ) %>%
#'  add_layer(
#'    id = "nc-layer",
#'    type = "fill",
#'    source = "nc-tracts",
#'    paint = list(
#'      "fill-color" = "#888888",
#'      "fill-opacity" = 0.4
#'    )
#'  )
#' }
add_layer <- function(map,
                      id,
                      type = "fill",
                      source,
                      source_layer = NULL,
                      paint = list(),
                      layout = list(),
                      slot = NULL,
                      min_zoom = NULL,
                      max_zoom = NULL,
                      popup = NULL,
                      tooltip = NULL,
                      hover_options = NULL,
                      before_id = NULL,
                      filter = NULL
) {

  if (length(paint) == 0) {
    paint <- NULL
  }

  if (length(layout) == 0) {
    layout <- NULL
  }

  # Convert sf objects to GeoJSON source
  if (inherits(source, "sf")) {
    geojson <- geojsonsf::sf_geojson(sf::st_transform(source, crs = 4326))
    source <- list(
      type = "geojson",
      data = geojson,
      generateId = TRUE
    )
  }

  map$x$layers <- c(map$x$layers, list(list(
    id = id,
    type = type,
    source = source,
    source_layer = source_layer,
    paint = paint,
    layout = layout,
    slot = slot,
    minzoom = min_zoom,
    maxzoom = max_zoom,
    popup = popup,
    tooltip = tooltip,
    hover_options = hover_options,
    before_id = before_id,
    filter = filter
  )))

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    layer <- list(
      id = id,
      type = type,
      source = source,
      layout = layout,
      paint = paint,
      popup = popup,
      tooltip = tooltip,
      hover_options = hover_options,
      before_id = before_id,
      filter = filter
    )

    if (!is.null(source_layer)) {
      layer$source_layer <- source_layer
    }

    if (!is.null(slot)) {
      layer$slot <- slot
    }

    if (!is.null(min_zoom)) {
      layer$minzoom <- min_zoom
    }

    if (!is.null(max_zoom)) {
      layer$maxzoom = max_zoom
    }

    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"


    map$session$sendCustomMessage(proxy_class, list(
      id = map$id,
      message = list(type = "add_layer", layer = layer)
    ))

    map

  } else {
    map
  }

}

#' Add a fill layer to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param fill_antialias Whether or not the fill should be antialiased.
#' @param fill_color The color of the filled part of this layer.
#' @param fill_emissive_strength Controls the intensity of light emitted on the source features.
#' @param fill_opacity The opacity of the entire fill layer.
#' @param fill_outline_color The outline color of the fill.
#' @param fill_pattern Name of image in sprite to use for drawing image fills.
#' @param fill_sort_key Sorts features in ascending order based on this value.
#' @param fill_translate The geometry's offset. Values are `c(x, y)` where negatives indicate left and up.
#' @param fill_translate_anchor Controls the frame of reference for `fill-translate`.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup A column name containing information to display in a popup on click.  Columns containing HTML will be parsed.
#' @param tooltip A column name containing information to display in a tooltip on hover. Columns containing HTML will be parsed.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new fill layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(tidycensus)
#'
#' fl_age <- get_acs(
#'   geography = "tract",
#'   variables = "B01002_001",
#'   state = "FL",
#'   year = 2022,
#'   geometry = TRUE
#' )
#'
#' mapboxgl() |>
#'   fit_bounds(fl_age, animate = FALSE) |>
#'   add_fill_layer(
#'     id = "fl_tracts",
#'     source = fl_age,
#'     fill_color = interpolate(
#'       column = "estimate",
#'       values = c(20, 80),
#'       stops = c("lightblue", "darkblue"),
#'       na_color = "lightgrey"
#'     ),
#'     fill_opacity = 0.5
#'   )
#' }
add_fill_layer <- function(map,
                           id,
                           source,
                           source_layer = NULL,
                           fill_antialias = TRUE,
                           fill_color = NULL,
                           fill_emissive_strength = NULL,
                           fill_opacity = NULL,
                           fill_outline_color = NULL,
                           fill_pattern = NULL,
                           fill_sort_key = NULL,
                           fill_translate = NULL,
                           fill_translate_anchor = "map",
                           visibility = "visible",
                           slot = NULL,
                           min_zoom = NULL,
                           max_zoom = NULL,
                           popup = NULL,
                           tooltip = NULL,
                           hover_options = NULL,
                           before_id = NULL,
                           filter = NULL) {
  paint <- list()
  layout <- list()



  if (!is.null(fill_antialias)) paint[["fill-antialias"]] <- fill_antialias
  if (!is.null(fill_color)) paint[["fill-color"]] <- fill_color
  if (!is.null(fill_emissive_strength)) paint[["fill-emissive-strength"]] <- fill_emissive_strength
  if (!is.null(fill_opacity)) paint[["fill-opacity"]] <- fill_opacity
  if (!is.null(fill_outline_color)) paint[["fill-outline-color"]] <- fill_outline_color
  if (!is.null(fill_pattern)) paint[["fill-pattern"]] <- fill_pattern
  if (!is.null(fill_translate)) paint[["fill-translate"]] <- fill_translate
  if (!is.null(fill_translate_anchor)) paint[["fill-translate-anchor"]] <- fill_translate_anchor

  if (!is.null(fill_sort_key)) layout[["fill-sort-key"]] <- fill_sort_key
  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(
    map,
    id,
    "fill",
    source,
    source_layer,
    paint,
    layout,
    slot,
    min_zoom,
    max_zoom,
    popup,
    tooltip,
    hover_options,
    before_id,
    filter
  )

  return(map)
}

#' Add a line layer to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param line_blur Amount to blur the line.
#' @param line_color The color with which the line will be drawn.
#' @param line_dasharray Specifies the lengths of the alternating dashes and gaps that form the dash pattern.
#' @param line_gap_width The width of the gap between a dashed line's individual dashes.
#' @param line_offset The line's offset.
#' @param line_opacity The opacity at which the line will be drawn.
#' @param line_pattern Name of image in sprite to use for drawing image fills.
#' @param line_sort_key Sorts features in ascending order based on this value.
#' @param line_translate The geometry's offset. Values are `c(x, y)` where negatives indicate left and up.
#' @param line_translate_anchor Controls the frame of reference for `line-translate`.
#' @param line_width Stroke thickness.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order. Only available when using the Mapbox Standard style.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup A column name containing information to display in a popup on click.  Columns containing HTML will be parsed.
#' @param tooltip A column name containing information to display in a tooltip on hover. Columns containing HTML will be parsed.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels)
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new line layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(tigris)
#'
#' loving_roads <- roads("TX", "Loving")
#'
#' maplibre(style = maptiler_style("backdrop")) |>
#'   fit_bounds(loving_roads) |>
#'   add_line_layer(
#'     id = "tracks",
#'     source = loving_roads,
#'     line_color = "navy",
#'     line_opacity = 0.7
#'   )
#' }
add_line_layer <- function(map,
                           id,
                           source,
                           source_layer = NULL,
                           line_blur = NULL,
                           line_color = NULL,
                           line_dasharray = NULL,
                           line_gap_width = NULL,
                           line_offset = NULL,
                           line_opacity = NULL,
                           line_pattern = NULL,
                           line_sort_key = NULL,
                           line_translate = NULL,
                           line_translate_anchor = "map",
                           line_width = NULL,
                           visibility = "visible",
                           slot = NULL,
                           min_zoom = NULL,
                           max_zoom = NULL,
                           popup = NULL,
                           tooltip = NULL,
                           hover_options = NULL,
                           before_id = NULL,
                           filter = NULL) {
  paint <- list()
  layout <- list()

  if (!is.null(line_blur)) paint[["line-blur"]] <- line_blur
  if (!is.null(line_color)) paint[["line-color"]] <- line_color
  if (!is.null(line_dasharray)) paint[["line-dasharray"]] <- line_dasharray
  if (!is.null(line_gap_width)) paint[["line-gap-width"]] <- line_gap_width
  if (!is.null(line_offset)) paint[["line-offset"]] <- line_offset
  if (!is.null(line_opacity)) paint[["line-opacity"]] <- line_opacity
  if (!is.null(line_pattern)) paint[["line-pattern"]] <- line_pattern
  if (!is.null(line_translate)) paint[["line-translate"]] <- line_translate
  if (!is.null(line_translate_anchor)) paint[["line-translate-anchor"]] <- line_translate_anchor
  if (!is.null(line_width)) paint[["line-width"]] <- line_width

  if (!is.null(line_sort_key)) layout[["line-sort-key"]] <- line_sort_key
  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(
    map,
    id,
    "line",
    source,
    source_layer,
    paint,
    layout,
    slot,
    min_zoom,
    max_zoom,
    popup,
    tooltip,
    hover_options,
    before_id,
    filter
  )

  return(map)
}

#' Add a heatmap layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param heatmap_color The color of the heatmap points.
#' @param heatmap_intensity The intensity of the heatmap points.
#' @param heatmap_opacity The opacity of the heatmap layer.
#' @param heatmap_radius The radius of influence of each individual heatmap point.
#' @param heatmap_weight The weight of each individual heatmap point.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new heatmap layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl(style = mapbox_style("dark"),
#'          center = c(-120, 50),
#'          zoom = 2) |>
#'   add_heatmap_layer(
#'     id = "earthquakes-heat",
#'     source = list(
#'       type = "geojson",
#'       data = "https://docs.mapbox.com/mapbox-gl-js/assets/earthquakes.geojson"
#'     ),
#'     heatmap_weight = interpolate(
#'       column = "mag",
#'       values = c(0, 6),
#'       stops = c(0, 1)
#'     ),
#'     heatmap_intensity = interpolate(
#'       property = "zoom",
#'       values = c(0, 9),
#'       stops = c(1, 3)
#'     ),
#'     heatmap_color = interpolate(
#'       property = "heatmap-density",
#'       values = seq(0, 1, 0.2),
#'       stops = c('rgba(33,102,172,0)', 'rgb(103,169,207)',
#'                 'rgb(209,229,240)', 'rgb(253,219,199)',
#'                 'rgb(239,138,98)', 'rgb(178,24,43)')
#'     ),
#'     heatmap_opacity = 0.7
#'   )
#' }
add_heatmap_layer <- function(map,
                              id,
                              source,
                              source_layer = NULL,
                              heatmap_color = NULL,
                              heatmap_intensity = NULL,
                              heatmap_opacity = NULL,
                              heatmap_radius = NULL,
                              heatmap_weight = NULL,
                              visibility = "visible",
                              slot = NULL,
                              min_zoom = NULL,
                              max_zoom = NULL,
                              before_id = NULL,
                              filter = NULL) {
  paint <- list()
  layout <- list()

  if (!is.null(heatmap_color)) paint[["heatmap-color"]] <- heatmap_color
  if (!is.null(heatmap_intensity)) paint[["heatmap-intensity"]] <- heatmap_intensity
  if (!is.null(heatmap_opacity)) paint[["heatmap-opacity"]] <- heatmap_opacity
  if (!is.null(heatmap_radius)) paint[["heatmap-radius"]] <- heatmap_radius
  if (!is.null(heatmap_weight)) paint[["heatmap-weight"]] <- heatmap_weight

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(map, id, "heatmap", source, source_layer, paint, layout, slot, min_zoom, max_zoom, before_id, filter)

  return(map)
}

#' Add a fill-extrusion layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param fill_extrusion_base The base height of the fill extrusion.
#' @param fill_extrusion_color The color of the fill extrusion.
#' @param fill_extrusion_height The height of the fill extrusion.
#' @param fill_extrusion_opacity The opacity of the fill extrusion.
#' @param fill_extrusion_pattern Name of image in sprite to use for drawing image fills.
#' @param fill_extrusion_translate The geometry's offset. Values are `c(x, y)` where negatives indicate left and up.
#' @param fill_extrusion_translate_anchor Controls the frame of reference for `fill-extrusion-translate`.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup A column name containing information to display in a popup on click.  Columns containing HTML will be parsed.
#' @param tooltip A column name containing information to display in a tooltip on hover. Columns containing HTML will be parsed.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new fill-extrusion layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' maplibre(
#'   style = maptiler_style("basic"),
#'   center = c(-74.0066, 40.7135),
#'   zoom = 15.5,
#'   pitch = 45,
#'   bearing = -17.6
#' ) |>
#'   add_vector_source(
#'     id = "openmaptiles",
#'     url = paste0("https://api.maptiler.com/tiles/v3/tiles.json?key=",
#'                  Sys.getenv("MAPTILER_API_KEY"))
#'   ) |>
#'   add_fill_extrusion_layer(
#'     id = "3d-buildings",
#'     source = 'openmaptiles',
#'     source_layer = 'building',
#'     fill_extrusion_color = interpolate(
#'       column = 'render_height',
#'       values = c(0, 200, 400),
#'       stops = c('lightgray', 'royalblue', 'lightblue')
#'     ),
#'     fill_extrusion_height = list(
#'       'interpolate',
#'       list('linear'),
#'       list('zoom'),
#'       15,
#'       0,
#'       16,
#'       list('get', 'render_height')
#'     )
#'   )
#' }
add_fill_extrusion_layer <- function(map,
                                     id,
                                     source,
                                     source_layer = NULL,
                                     fill_extrusion_base = NULL,
                                     fill_extrusion_color = NULL,
                                     fill_extrusion_height = NULL,
                                     fill_extrusion_opacity = NULL,
                                     fill_extrusion_pattern = NULL,
                                     fill_extrusion_translate = NULL,
                                     fill_extrusion_translate_anchor = "map",
                                     visibility = "visible",
                                     slot = NULL,
                                     min_zoom = NULL,
                                     max_zoom = NULL,
                                     popup = NULL,
                                     tooltip = NULL,
                                     hover_options = NULL,
                                     before_id = NULL,
                                     filter = NULL) {
  paint <- list()
  layout <- list()

  if (!is.null(fill_extrusion_base)) paint[["fill-extrusion-base"]] <- fill_extrusion_base
  if (!is.null(fill_extrusion_color)) paint[["fill-extrusion-color"]] <- fill_extrusion_color
  if (!is.null(fill_extrusion_height)) paint[["fill-extrusion-height"]] <- fill_extrusion_height
  if (!is.null(fill_extrusion_opacity)) paint[["fill-extrusion-opacity"]] <- fill_extrusion_opacity
  if (!is.null(fill_extrusion_pattern)) paint[["fill-extrusion-pattern"]] <- fill_extrusion_pattern
  if (!is.null(fill_extrusion_translate)) paint[["fill-extrusion-translate"]] <- fill_extrusion_translate
  if (!is.null(fill_extrusion_translate_anchor)) paint[["fill-extrusion-translate-anchor"]] <- fill_extrusion_translate_anchor

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(map, id, "fill-extrusion", source, source_layer, paint, layout, slot, min_zoom, max_zoom, popup, tooltip, hover_options, before_id, filter)

  return(map)
}

#' Add a circle layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param circle_blur Amount to blur the circle.
#' @param circle_color The color of the circle.
#' @param circle_opacity The opacity at which the circle will be drawn.
#' @param circle_radius Circle radius.
#' @param circle_sort_key Sorts features in ascending order based on this value.
#' @param circle_stroke_color The color of the circle's stroke.
#' @param circle_stroke_opacity The opacity of the circle's stroke.
#' @param circle_stroke_width The width of the circle's stroke.
#' @param circle_translate The geometry's offset. Values are `c(x, y)` where negatives indicate left and up.
#' @param circle_translate_anchor Controls the frame of reference for `circle-translate`.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup A column name containing information to display in a popup on click.  Columns containing HTML will be parsed.
#' @param tooltip A column name containing information to display in a tooltip on hover. Columns containing HTML will be parsed.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new circle layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(sf)
#' library(dplyr)
#'
#' # Set seed for reproducibility
#' set.seed(1234)
#'
#' # Define the bounding box for Washington DC (approximately)
#' bbox <- st_bbox(c(
#'   xmin = -77.119759,
#'   ymin = 38.791645,
#'   xmax = -76.909393,
#'   ymax = 38.995548
#' ),
#' crs = st_crs(4326))
#'
#' # Generate 30 random points within the bounding box
#' random_points <- st_as_sf(
#'   data.frame(
#'     id = 1:30,
#'     lon = runif(30, bbox["xmin"], bbox["xmax"]),
#'     lat = runif(30, bbox["ymin"], bbox["ymax"])
#'   ),
#'   coords = c("lon", "lat"),
#'   crs = 4326
#' )
#'
#' # Assign random categories
#' categories <- c('music', 'bar', 'theatre', 'bicycle')
#' random_points <- random_points %>%
#'   mutate(category = sample(categories, n(), replace = TRUE))
#'
#' # Map with circle layer
#' mapboxgl(style = mapbox_style("light")) %>%
#'   fit_bounds(random_points, animate = FALSE) %>%
#'   add_circle_layer(
#'     id = "poi-layer",
#'     source = random_points,
#'     circle_color = match_expr(
#'       "category",
#'       values = c("music", "bar", "theatre",
#'                  "bicycle"),
#'       stops = c("#1f78b4", "#33a02c",
#'                 "#e31a1c", "#ff7f00")
#'     ),
#'     circle_radius = 8,
#'     circle_stroke_color = "#ffffff",
#'     circle_stroke_width = 2,
#'     circle_opacity = 0.8,
#'     tooltip = "category",
#'     hover_options = list(circle_radius = 12,
#'                          circle_color = "#ffff99")
#'   ) %>%
#'   add_categorical_legend(
#'     legend_title = "Points of Interest",
#'     values = c("Music", "Bar", "Theatre", "Bicycle"),
#'     colors = c("#1f78b4", "#33a02c", "#e31a1c", "#ff7f00"),
#'     circular_patches = TRUE
#'   )
#' }
add_circle_layer <- function(map,
                             id,
                             source,
                             source_layer = NULL,
                             circle_blur = NULL,
                             circle_color = NULL,
                             circle_opacity = NULL,
                             circle_radius = NULL,
                             circle_sort_key = NULL,
                             circle_stroke_color = NULL,
                             circle_stroke_opacity = NULL,
                             circle_stroke_width = NULL,
                             circle_translate = NULL,
                             circle_translate_anchor = "map",
                             visibility = "visible",
                             slot = NULL,
                             min_zoom = NULL,
                             max_zoom = NULL,
                             popup = NULL,
                             tooltip = NULL,
                             hover_options = NULL,
                             before_id = NULL,
                             filter = NULL) {
  paint <- list()
  layout <- list()

  if (!is.null(circle_blur)) paint[["circle-blur"]] <- circle_blur
  if (!is.null(circle_color)) paint[["circle-color"]] <- circle_color
  if (!is.null(circle_opacity)) paint[["circle-opacity"]] <- circle_opacity
  if (!is.null(circle_radius)) paint[["circle-radius"]] <- circle_radius
  if (!is.null(circle_stroke_color)) paint[["circle-stroke-color"]] <- circle_stroke_color
  if (!is.null(circle_stroke_opacity)) paint[["circle-stroke-opacity"]] <- circle_stroke_opacity
  if (!is.null(circle_stroke_width)) paint[["circle-stroke-width"]] <- circle_stroke_width
  if (!is.null(circle_translate)) paint[["circle-translate"]] <- circle_translate
  if (!is.null(circle_translate_anchor)) paint[["circle-translate-anchor"]] <- circle_translate_anchor

  if (!is.null(circle_sort_key)) layout[["circle-sort-key"]] <- circle_sort_key
  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(
    map,
    id,
    "circle",
    source,
    source_layer,
    paint,
    layout,
    slot,
    min_zoom,
    max_zoom,
    popup,
    tooltip,
    hover_options,
    before_id,
    filter
  )

  return(map)
}

#' Add a raster layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` function.
#' @param id A unique ID for the layer.
#' @param source The ID of the source.
#' @param source_layer The source layer (for vector sources).
#' @param raster_brightness_max The maximum brightness of the image.
#' @param raster_brightness_min The minimum brightness of the image.
#' @param raster_contrast Increase or reduce the brightness of the image.
#' @param raster_fade_duration The duration of the fade-in/fade-out effect.
#' @param raster_hue_rotate Rotates hues around the color wheel.
#' @param raster_opacity The opacity at which the raster will be drawn.
#' @param raster_resampling The resampling/interpolation method to use for overscaling.
#' @param raster_saturation Increase or reduce the saturation of the image.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#'
#' @return The modified map object with the new raster layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' mapboxgl(style = mapbox_style("dark"),
#'          zoom = 5,
#'          center = c(-75.789, 41.874)) |>
#'   add_image_source(
#'     id = "radar",
#'     url = "https://docs.mapbox.com/mapbox-gl-js/assets/radar.gif",
#'     coordinates = list(
#'       c(-80.425, 46.437),
#'       c(-71.516, 46.437),
#'       c(-71.516, 37.936),
#'       c(-80.425, 37.936)
#'     )
#'   ) |>
#'   add_raster_layer(
#'     id = 'radar-layer',
#'     source = 'radar',
#'     raster_fade_duration = 0
#'   )
#' }
add_raster_layer <- function(map,
                             id,
                             source,
                             source_layer = NULL,
                             raster_brightness_max = NULL,
                             raster_brightness_min = NULL,
                             raster_contrast = NULL,
                             raster_fade_duration = NULL,
                             raster_hue_rotate = NULL,
                             raster_opacity = NULL,
                             raster_resampling = NULL,
                             raster_saturation = NULL,
                             visibility = "visible",
                             slot = NULL,
                             min_zoom = NULL,
                             max_zoom = NULL,
                             before_id = NULL) {
  paint <- list()
  layout <- list()

  if (!is.null(raster_brightness_max)) paint[["raster-brightness-max"]] <- raster_brightness_max
  if (!is.null(raster_brightness_min)) paint[["raster-brightness-min"]] <- raster_brightness_min
  if (!is.null(raster_contrast)) paint[["raster-contrast"]] <- raster_contrast
  if (!is.null(raster_fade_duration)) paint[["raster-fade-duration"]] <- raster_fade_duration
  if (!is.null(raster_hue_rotate)) paint[["raster-hue-rotate"]] <- raster_hue_rotate
  if (!is.null(raster_opacity)) paint[["raster-opacity"]] <- raster_opacity
  if (!is.null(raster_resampling)) paint[["raster-resampling"]] <- raster_resampling
  if (!is.null(raster_saturation)) paint[["raster-saturation"]] <- raster_saturation

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(map, id, "raster", source, source_layer, paint, layout, slot, min_zoom, max_zoom, before_id)

  return(map)
}


#' Add a symbol layer to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param icon_allow_overlap If TRUE, the icon will be visible even if it collides with other previously drawn symbols.
#' @param icon_anchor Part of the icon placed closest to the anchor.
#' @param icon_color The color of the icon.  This is not supported for many Mapbox icons; read more at \url{https://docs.mapbox.com/help/troubleshooting/using-recolorable-images-in-mapbox-maps/}.
#' @param icon_color_brightness_max The maximum brightness of the icon color.
#' @param icon_color_brightness_min The minimum brightness of the icon color.
#' @param icon_color_contrast The contrast of the icon color.
#' @param icon_color_saturation The saturation of the icon color.
#' @param icon_emissive_strength The strength of the icon's emissive color.
#' @param icon_halo_blur The blur applied to the icon's halo.
#' @param icon_halo_color The color of the icon's halo.
#' @param icon_halo_width The width of the icon's halo.
#' @param icon_ignore_placement If TRUE, the icon will be visible even if it collides with other symbols.
#' @param icon_image Name of image in sprite to use for drawing an image background. To use values in a column of your input dataset, use `c('get', 'YOUR_ICON_COLUMN_NAME')`.
#' @param icon_image_cross_fade The cross-fade parameter for the icon image.
#' @param icon_keep_upright If TRUE, the icon will be kept upright.
#' @param icon_offset Offset distance of icon.
#' @param icon_opacity The opacity at which the icon will be drawn.
#' @param icon_optional If TRUE, the icon will be optional.
#' @param icon_padding Padding around the icon.
#' @param icon_pitch_alignment Alignment of the icon with respect to the pitch of the map.
#' @param icon_rotate Rotates the icon clockwise.
#' @param icon_rotation_alignment Alignment of the icon with respect to the map.
#' @param icon_size The size of the icon.
#' @param icon_text_fit Scales the text to fit the icon.
#' @param icon_text_fit_padding Padding for text fitting the icon.
#' @param icon_translate The offset distance of the icon.
#' @param icon_translate_anchor Controls the frame of reference for `icon-translate`.
#' @param symbol_avoid_edges If TRUE, the symbol will be avoided when near the edges.
#' @param symbol_placement Placement of the symbol on the map.
#' @param symbol_sort_key Sorts features in ascending order based on this value.
#' @param symbol_spacing Spacing between symbols.
#' @param symbol_z_elevate Elevates the symbol z-axis.
#' @param symbol_z_order Orders the symbol z-axis.
#' @param text_allow_overlap If TRUE, the text will be visible even if it collides with other previously drawn symbols.
#' @param text_anchor Part of the text placed closest to the anchor.
#' @param text_color The color of the text.
#' @param text_emissive_strength The strength of the text's emissive color.
#' @param text_field Value to use for a text label.
#' @param text_font Font stack to use for displaying text.
#' @param text_halo_blur The blur applied to the text's halo.
#' @param text_halo_color The color of the text's halo.
#' @param text_halo_width The width of the text's halo.
#' @param text_ignore_placement If TRUE, the text will be visible even if it collides with other symbols.
#' @param text_justify The justification of the text.
#' @param text_keep_upright If TRUE, the text will be kept upright.
#' @param text_letter_spacing Spacing between text letters.
#' @param text_line_height Height of the text lines.
#' @param text_max_angle Maximum angle of the text.
#' @param text_max_width Maximum width of the text.
#' @param text_offset Offset distance of text.
#' @param text_opacity The opacity at which the text will be drawn.
#' @param text_optional If TRUE, the text will be optional.
#' @param text_padding Padding around the text.
#' @param text_pitch_alignment Alignment of the text with respect to the pitch of the map.
#' @param text_radial_offset Radial offset of the text.
#' @param text_rotate Rotates the text clockwise.
#' @param text_rotation_alignment Alignment of the text with respect to the map.
#' @param text_size The size of the text.
#' @param text_transform Transform applied to the text.
#' @param text_translate The offset distance of the text.
#' @param text_translate_anchor Controls the frame of reference for `text-translate`.
#' @param text_variable_anchor Variable anchor for the text.
#' @param text_writing_mode Writing mode for the text.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup A column name containing information to display in a popup on click. Columns containing HTML will be parsed.
#' @param tooltip A column name containing information to display in a tooltip on hover. Columns containing HTML will be parsed.
#' @param hover_options A named list of options for highlighting features in the layer on hover. Not all elements of SVG icons can be styled.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#'
#' @return The modified map object with the new symbol layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(sf)
#' library(dplyr)
#'
#' # Set seed for reproducibility
#' set.seed(1234)
#'
#' # Define the bounding box for Washington DC (approximately)
#' bbox <- st_bbox(c(
#'   xmin = -77.119759,
#'   ymin = 38.791645,
#'   xmax = -76.909393,
#'   ymax = 38.995548
#' ),
#' crs = st_crs(4326))
#'
#' # Generate 30 random points within the bounding box
#' random_points <- st_as_sf(
#'   data.frame(
#'     id = 1:30,
#'     lon = runif(30, bbox["xmin"], bbox["xmax"]),
#'     lat = runif(30, bbox["ymin"], bbox["ymax"])
#'   ),
#'   coords = c("lon", "lat"),
#'   crs = 4326
#' )
#'
#' # Assign random icons
#' icons <- c('music', 'bar', 'theatre', 'bicycle')
#' random_points <- random_points |>
#'   mutate(icon = sample(icons, n(), replace = TRUE))
#'
#' # Map with icons
#' mapboxgl(style = mapbox_style("light")) |>
#'   fit_bounds(random_points, animate = FALSE) |>
#'   add_symbol_layer(
#'     id = "points-of-interest",
#'     source = random_points,
#'     icon_image = c("get", "icon"),
#'     icon_allow_overlap = TRUE,
#'     tooltip = "icon"
#'   )
#' }
add_symbol_layer <- function(map,
                             id,
                             source,
                             source_layer = NULL,
                             icon_allow_overlap = NULL,
                             icon_anchor = NULL,
                             icon_color = NULL,
                             icon_color_brightness_max = NULL,
                             icon_color_brightness_min = NULL,
                             icon_color_contrast = NULL,
                             icon_color_saturation = NULL,
                             icon_emissive_strength = NULL,
                             icon_halo_blur = NULL,
                             icon_halo_color = NULL,
                             icon_halo_width = NULL,
                             icon_ignore_placement = NULL,
                             icon_image = NULL,
                             icon_image_cross_fade = NULL,
                             icon_keep_upright = NULL,
                             icon_offset = NULL,
                             icon_opacity = NULL,
                             icon_optional = NULL,
                             icon_padding = NULL,
                             icon_pitch_alignment = NULL,
                             icon_rotate = NULL,
                             icon_rotation_alignment = NULL,
                             icon_size = NULL,
                             icon_text_fit = NULL,
                             icon_text_fit_padding = NULL,
                             icon_translate = NULL,
                             icon_translate_anchor = NULL,
                             symbol_avoid_edges = NULL,
                             symbol_placement = NULL,
                             symbol_sort_key = NULL,
                             symbol_spacing = NULL,
                             symbol_z_elevate = NULL,
                             symbol_z_order = NULL,
                             text_allow_overlap = NULL,
                             text_anchor = NULL,
                             text_color = NULL,
                             text_emissive_strength = NULL,
                             text_field = NULL,
                             text_font = NULL,
                             text_halo_blur = NULL,
                             text_halo_color = NULL,
                             text_halo_width = NULL,
                             text_ignore_placement = NULL,
                             text_justify = NULL,
                             text_keep_upright = NULL,
                             text_letter_spacing = NULL,
                             text_line_height = NULL,
                             text_max_angle = NULL,
                             text_max_width = NULL,
                             text_offset = NULL,
                             text_opacity = NULL,
                             text_optional = NULL,
                             text_padding = NULL,
                             text_pitch_alignment = NULL,
                             text_radial_offset = NULL,
                             text_rotate = NULL,
                             text_rotation_alignment = NULL,
                             text_size = NULL,
                             text_transform = NULL,
                             text_translate = NULL,
                             text_translate_anchor = NULL,
                             text_variable_anchor = NULL,
                             text_writing_mode = NULL,
                             visibility = "visible",
                             slot = NULL,
                             min_zoom = NULL,
                             max_zoom = NULL,
                             popup = NULL,
                             tooltip = NULL,
                             hover_options = NULL,
                             before_id = NULL,
                             filter = NULL) {
  paint <- list()
  layout <- list()

  if (!is.null(icon_allow_overlap)) layout[["icon-allow-overlap"]] <- icon_allow_overlap
  if (!is.null(icon_anchor)) layout[["icon-anchor"]] <- icon_anchor
  if (!is.null(icon_color)) paint[["icon-color"]] <- icon_color
  if (!is.null(icon_color_brightness_max)) paint[["icon-color-brightness-max"]] <- icon_color_brightness_max
  if (!is.null(icon_color_brightness_min)) paint[["icon-color-brightness-min"]] <- icon_color_brightness_min
  if (!is.null(icon_color_contrast)) paint[["icon-color-contrast"]] <- icon_color_contrast
  if (!is.null(icon_color_saturation)) paint[["icon-color-saturation"]] <- icon_color_saturation
  if (!is.null(icon_emissive_strength)) paint[["icon-emissive-strength"]] <- icon_emissive_strength
  if (!is.null(icon_halo_blur)) paint[["icon-halo-blur"]] <- icon_halo_blur
  if (!is.null(icon_halo_color)) paint[["icon-halo-color"]] <- icon_halo_color
  if (!is.null(icon_halo_width)) paint[["icon-halo-width"]] <- icon_halo_width
  if (!is.null(icon_ignore_placement)) layout[["icon-ignore-placement"]] <- icon_ignore_placement
  if (!is.null(icon_image)) layout[["icon-image"]] <- icon_image
  if (!is.null(icon_image_cross_fade)) layout[["icon-image-cross-fade"]] <- icon_image_cross_fade
  if (!is.null(icon_keep_upright)) layout[["icon-keep-upright"]] <- icon_keep_upright
  if (!is.null(icon_offset)) layout[["icon-offset"]] <- icon_offset
  if (!is.null(icon_opacity)) paint[["icon-opacity"]] <- icon_opacity
  if (!is.null(icon_optional)) layout[["icon-optional"]] <- icon_optional
  if (!is.null(icon_padding)) layout[["icon-padding"]] <- icon_padding
  if (!is.null(icon_pitch_alignment)) layout[["icon-pitch-alignment"]] <- icon_pitch_alignment
  if (!is.null(icon_rotate)) layout[["icon-rotate"]] <- icon_rotate
  if (!is.null(icon_rotation_alignment)) layout[["icon-rotation-alignment"]] <- icon_rotation_alignment
  if (!is.null(icon_size)) layout[["icon-size"]] <- icon_size
  if (!is.null(icon_text_fit)) layout[["icon-text-fit"]] <- icon_text_fit
  if (!is.null(icon_text_fit_padding)) layout[["icon-text-fit-padding"]] <- icon_text_fit_padding
  if (!is.null(icon_translate)) paint[["icon-translate"]] <- icon_translate
  if (!is.null(icon_translate_anchor)) paint[["icon-translate-anchor"]] <- icon_translate_anchor

  if (!is.null(symbol_avoid_edges)) layout[["symbol-avoid-edges"]] <- symbol_avoid_edges
  if (!is.null(symbol_placement)) layout[["symbol-placement"]] <- symbol_placement
  if (!is.null(symbol_sort_key)) layout[["symbol-sort-key"]] <- symbol_sort_key
  if (!is.null(symbol_spacing)) layout[["symbol-spacing"]] <- symbol_spacing
  if (!is.null(symbol_z_elevate)) paint[["symbol-z-elevate"]] <- symbol_z_elevate
  if (!is.null(symbol_z_order)) layout[["symbol-z-order"]] <- symbol_z_order

  if (!is.null(text_allow_overlap)) layout[["text-allow-overlap"]] <- text_allow_overlap
  if (!is.null(text_anchor)) layout[["text-anchor"]] <- text_anchor
  if (!is.null(text_color)) paint[["text-color"]] <- text_color
  if (!is.null(text_emissive_strength)) paint[["text-emissive-strength"]] <- text_emissive_strength
  if (!is.null(text_field)) layout[["text-field"]] <- text_field
  if (!is.null(text_font)) layout[["text-font"]] <- text_font
  if (!is.null(text_halo_blur)) paint[["text-halo-blur"]] <- text_halo_blur
  if (!is.null(text_halo_color)) paint[["text-halo-color"]] <- text_halo_color
  if (!is.null(text_halo_width)) paint[["text-halo-width"]] <- text_halo_width
  if (!is.null(text_ignore_placement)) layout[["text-ignore-placement"]] <- text_ignore_placement
  if (!is.null(text_justify)) layout[["text-justify"]] <- text_justify
  if (!is.null(text_keep_upright)) layout[["text-keep-upright"]] <- text_keep_upright
  if (!is.null(text_letter_spacing)) layout[["text-letter-spacing"]] <- text_letter_spacing
  if (!is.null(text_line_height)) layout[["text-line-height"]] <- text_line_height
  if (!is.null(text_max_angle)) layout[["text-max-angle"]] <- text_max_angle
  if (!is.null(text_max_width)) layout[["text-max-width"]] <- text_max_width
  if (!is.null(text_offset)) layout[["text-offset"]] <- text_offset
  if (!is.null(text_opacity)) paint[["text-opacity"]] <- text_opacity
  if (!is.null(text_optional)) layout[["text-optional"]] <- text_optional
  if (!is.null(text_padding)) layout[["text-padding"]] <- text_padding
  if (!is.null(text_pitch_alignment)) layout[["text-pitch-alignment"]] <- text_pitch_alignment
  if (!is.null(text_radial_offset)) layout[["text-radial-offset"]] <- text_radial_offset
  if (!is.null(text_rotate)) layout[["text-rotate"]] <- text_rotate
  if (!is.null(text_rotation_alignment)) layout[["text-rotation-alignment"]] <- text_rotation_alignment
  if (!is.null(text_size)) layout[["text-size"]] <- text_size
  if (!is.null(text_transform)) layout[["text-transform"]] <- text_transform
  if (!is.null(text_translate)) paint[["text-translate"]] <- text_translate
  if (!is.null(text_translate_anchor)) paint[["text-translate-anchor"]] <- text_translate_anchor
  if (!is.null(text_variable_anchor)) layout[["text-variable-anchor"]] <- text_variable_anchor
  if (!is.null(text_writing_mode)) layout[["text-writing-mode"]] <- text_writing_mode

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(map, id, "symbol", source, source_layer, paint, layout, slot, min_zoom, max_zoom, popup, tooltip, hover_options, before_id, filter)

  return(map)
}
