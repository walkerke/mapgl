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
#' @param popup Popup content shown on click: a column name, a `{brace}` template (e.g. `"{name}: {value}"`), or a `concat()`/`number_format()` expression. Columns containing HTML are parsed.
#' @param tooltip Tooltip content shown on hover; same forms as `popup`.
#' @param tooltip_style,popup_style Optional appearance for the tooltip/popup: a preset string (`"light"` or `"dark"`) or a [tooltip_style()] object. When omitted, the native (unstyled) appearance is kept.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#' @param metadata An optional named list stored as the layer's `metadata` style property. It is not rendered, but is available to JavaScript through `map.getLayer(id).metadata`.
#'
#' @return The modified map object with the new layer added.
#' @export
#'
#' @examples
#' \dontrun{
#' # Load necessary libraries
#' library(mapgl)
#' library(tigris)
#'
#' # Load geojson data for North Carolina tracts
#' nc_tracts <- tracts(state = "NC", cb = TRUE)
#'
#' # Create a Mapbox GL map
#' map <- mapboxgl(
#'     style = mapbox_style("light"),
#'     center = c(-79.0193, 35.7596),
#'     zoom = 7
#' )
#'
#' # Add a source and fill layer for North Carolina tracts
#' map %>%
#'     add_source(
#'         id = "nc-tracts",
#'         data = nc_tracts
#'     ) %>%
#'     add_layer(
#'         id = "nc-layer",
#'         type = "fill",
#'         source = "nc-tracts",
#'         paint = list(
#'             "fill-color" = "#888888",
#'             "fill-opacity" = 0.4
#'         )
#'     )
#' }
add_layer <- function(
  map,
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
  filter = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  metadata = NULL
) {
  if (length(paint) == 0) {
    paint <- NULL
  }

  if (length(layout) == 0) {
    layout <- NULL
  }

  tooltip_style <- mapgl_normalize_tooltip_style(
    tooltip_style,
    arg = "tooltip_style"
  )
  popup_style <- mapgl_normalize_tooltip_style(popup_style, arg = "popup_style")

  # Convert sfc/sf objects to GeoJSON source
  if (inherits(source, "sfc")) {
    source <- sf::st_as_sf(source)
    source$id <- seq_len(nrow(source))
  }
  if (inherits(source, "sf")) {
    if (sf::st_crs(source) != 4326) {
      source <- sf::st_transform(source, crs = 4326)
    }
    geojson <- geojsonsf::sf_geojson(source, simplify = FALSE)
    source <- list(
      type = "geojson",
      data = geojson,
      generateId = TRUE
    )
  }

  map <- mapgl_resolve_pending_flowmaps(map, before_id = id)

  map$x$layers <- c(
    map$x$layers,
    list(list(
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
      tooltip_style = tooltip_style,
      popup_style = popup_style,
      hover_options = hover_options,
      before_id = before_id,
      filter = filter
    ))
  )

  if (!is.null(metadata)) {
    map$x$layers[[length(map$x$layers)]]$metadata <- metadata
  }

  map <- mapgl_record_layer_order(map, id)

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    layer <- list(
      id = id,
      type = type,
      source = source,
      layout = layout,
      paint = paint,
      popup = popup,
      tooltip = tooltip,
      tooltip_style = tooltip_style,
      popup_style = popup_style,
      hover_options = hover_options,
      before_id = before_id
    )

    if (!is.null(source_layer)) {
      layer$`source-layer` <- source_layer
    }

    if (!is.null(filter)) {
      layer$filter <- filter
    }

    if (!is.null(slot)) {
      layer$slot <- slot
    }

    if (!is.null(min_zoom)) {
      layer$minzoom <- min_zoom
    }

    if (!is.null(max_zoom)) {
      layer$maxzoom <- max_zoom
    }

    if (!is.null(metadata)) {
      layer$metadata <- metadata
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
            type = "add_layer",
            layer = layer,
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
          message = list(type = "add_layer", layer = layer)
        )
      )
    }

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
#' @param fill_pattern_cross_fade Controls the transition progress between image variants of `fill_pattern`. Value between 0 and 1.
#' @param fill_sort_key Sorts features in ascending order based on this value.
#' @param fill_translate The geometry's offset. Values are `c(x, y)` where negatives indicate left and up.
#' @param fill_translate_anchor Controls the frame of reference for `fill-translate`.
#' @param fill_z_offset Specifies an uniform elevation in meters.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup Popup content shown on click: a column name, a `{brace}` template (e.g. `"{name}: {value}"`), or a `concat()`/`number_format()` expression. Columns containing HTML are parsed.
#' @param tooltip Tooltip content shown on hover; same forms as `popup`.
#' @param tooltip_style,popup_style Optional appearance for the tooltip/popup: a preset string (`"light"` or `"dark"`) or a [tooltip_style()] object. When omitted, the native (unstyled) appearance is kept.
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
#'     geography = "tract",
#'     variables = "B01002_001",
#'     state = "FL",
#'     year = 2022,
#'     geometry = TRUE
#' )
#'
#' mapboxgl() |>
#'     fit_bounds(fl_age, animate = FALSE) |>
#'     add_fill_layer(
#'         id = "fl_tracts",
#'         source = fl_age,
#'         fill_color = interpolate(
#'             column = "estimate",
#'             values = c(20, 80),
#'             stops = c("lightblue", "darkblue"),
#'             na_color = "lightgrey"
#'         ),
#'         fill_opacity = 0.5
#'     )
#' }
add_fill_layer <- function(
  map,
  id,
  source,
  source_layer = NULL,
  fill_antialias = TRUE,
  fill_color = NULL,
  fill_emissive_strength = NULL,
  fill_opacity = NULL,
  fill_outline_color = NULL,
  fill_pattern = NULL,
  fill_pattern_cross_fade = NULL,
  fill_sort_key = NULL,
  fill_translate = NULL,
  fill_translate_anchor = "map",
  fill_z_offset = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
) {
  paint <- list()
  layout <- list()

  if (!is.null(fill_antialias)) paint[["fill-antialias"]] <- fill_antialias
  if (!is.null(fill_color)) paint[["fill-color"]] <- fill_color
  if (!is.null(fill_emissive_strength))
    paint[["fill-emissive-strength"]] <- fill_emissive_strength
  if (!is.null(fill_opacity)) paint[["fill-opacity"]] <- fill_opacity
  if (!is.null(fill_outline_color))
    paint[["fill-outline-color"]] <- fill_outline_color
  if (!is.null(fill_pattern)) paint[["fill-pattern"]] <- fill_pattern
  if (!is.null(fill_pattern_cross_fade))
    paint[["fill-pattern-cross-fade"]] <- fill_pattern_cross_fade
  if (!is.null(fill_translate)) paint[["fill-translate"]] <- fill_translate
  if (!is.null(fill_translate_anchor))
    paint[["fill-translate-anchor"]] <- fill_translate_anchor
  if (!is.null(fill_z_offset)) paint[["fill-z-offset"]] <- fill_z_offset

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
    filter,
    tooltip_style = tooltip_style,
    popup_style = popup_style
  )

  return(map)
}

#' Add a line layer to a map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be
#'   converted to a GeoJSON source) or a named list that specifies `type` and
#'   `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param line_blur Amount to blur the line, in pixels.
#' @param line_cap The display of line endings. One of "butt", "round", "square".
#' @param line_color The color with which the line will be drawn.
#' @param line_dasharray Specifies the lengths of the alternating dashes and
#'   gaps that form the dash pattern.
#' @param line_elevation_ground_scale Controls how much the elevation of lines
#'   scales with terrain exaggeration when `line_elevation_reference` is `"sea"`.
#'   Value between 0 and 1; 0 keeps the line at fixed altitude, 1 scales proportionally.
#' @param line_elevation_reference Selects the base of line elevation. One of
#'   `"none"`, `"sea"`, `"ground"`, or `"hd-road-markup"`.
#' @param line_emissive_strength Controls the intensity of light emitted on the
#'   source features.
#' @param line_gap_width Draws a line casing outside of a line's actual path.
#'   Value indicates the width of the inner gap.
#' @param line_gradient A gradient used to color a line feature at various
#'   distances along its length.
#' @param line_join The display of lines when joining.
#' @param line_miter_limit Used to automatically convert miter joins to bevel
#'   joins for sharp angles.
#' @param line_occlusion_opacity Opacity multiplier of the line part that is
#'   occluded by 3D objects.
#' @param line_offset The line's offset.
#' @param line_opacity The opacity at which the line will be drawn.
#' @param line_pattern Name of image in sprite to use for drawing image lines.
#' @param line_pattern_cross_fade Controls the transition progress between image variants of `line_pattern`. Value between 0 and 1.
#' @param line_round_limit Used to automatically convert round joins to miter
#'   joins for shallow angles.
#' @param line_sort_key Sorts features in ascending order based on this value.
#' @param line_translate The geometry's offset. Values are `c(x, y)` where
#'   negatives indicate left and up, respectively.
#' @param line_translate_anchor Controls the frame of reference for `line-translate`.
#' @param line_trim_color The color to be used for rendering the trimmed line section.
#' @param line_trim_fade_range The fade range for the trim-start and trim-end points.
#' @param line_trim_offset The line part between `c(trim_start, trim_end)` will be
#'   painted using `line_trim_color`.
#' @param line_width Stroke thickness.
#' @param line_z_offset Vertical offset from ground, in meters.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup Popup content shown on click: a column name, a `{brace}` template (e.g. `"{name}: {value}"`), or a `concat()`/`number_format()` expression. Columns containing HTML are parsed.
#' @param tooltip Tooltip content shown on hover; same forms as `popup`.
#' @param tooltip_style,popup_style Optional appearance for the tooltip/popup: a preset string (`"light"` or `"dark"`) or a [tooltip_style()] object. When omitted, the native (unstyled) appearance is kept.
#' @param hover_options A named list of options for highlighting features in the
#'   layer on hover.
#' @param before_id The name of the layer that this layer appears "before",
#'   allowing you to insert layers below other layers in your basemap (e.g. labels)
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
#'     fit_bounds(loving_roads) |>
#'     add_line_layer(
#'         id = "tracks",
#'         source = loving_roads,
#'         line_color = "navy",
#'         line_opacity = 0.7
#'     )
#' }
add_line_layer <- function(
  map,
  id,
  source,
  source_layer = NULL,
  line_blur = NULL,
  line_cap = NULL,
  line_color = NULL,
  line_dasharray = NULL,
  line_elevation_ground_scale = NULL,
  line_elevation_reference = NULL,
  line_emissive_strength = NULL,
  line_gap_width = NULL,
  line_gradient = NULL,
  line_join = NULL,
  line_miter_limit = NULL,
  line_occlusion_opacity = NULL,
  line_offset = NULL,
  line_opacity = NULL,
  line_pattern = NULL,
  line_pattern_cross_fade = NULL,
  line_round_limit = NULL,
  line_sort_key = NULL,
  line_translate = NULL,
  line_translate_anchor = "map",
  line_trim_color = NULL,
  line_trim_fade_range = NULL,
  line_trim_offset = NULL,
  line_width = NULL,
  line_z_offset = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
) {
  paint <- list()
  layout <- list()

  if (!is.null(line_blur)) paint[["line-blur"]] <- line_blur
  if (!is.null(line_color)) paint[["line-color"]] <- line_color
  if (!is.null(line_dasharray)) paint[["line-dasharray"]] <- line_dasharray
  if (!is.null(line_emissive_strength))
    paint[["line-emissive-strength"]] <- line_emissive_strength
  if (!is.null(line_gap_width)) paint[["line-gap-width"]] <- line_gap_width
  if (!is.null(line_gradient)) paint[["line-gradient"]] <- line_gradient
  if (!is.null(line_occlusion_opacity))
    paint[["line-occlusion-opacity"]] <- line_occlusion_opacity
  if (!is.null(line_offset)) paint[["line-offset"]] <- line_offset
  if (!is.null(line_opacity)) paint[["line-opacity"]] <- line_opacity
  if (!is.null(line_pattern)) paint[["line-pattern"]] <- line_pattern
  if (!is.null(line_pattern_cross_fade))
    paint[["line-pattern-cross-fade"]] <- line_pattern_cross_fade
  if (!is.null(line_translate)) paint[["line-translate"]] <- line_translate
  if (!is.null(line_translate_anchor))
    paint[["line-translate-anchor"]] <- line_translate_anchor
  if (!is.null(line_trim_color)) paint[["line-trim-color"]] <- line_trim_color
  if (!is.null(line_trim_fade_range))
    paint[["line-trim-fade-range"]] <- line_trim_fade_range
  if (!is.null(line_trim_offset))
    paint[["line-trim-offset"]] <- line_trim_offset
  if (!is.null(line_width)) paint[["line-width"]] <- line_width

  if (!is.null(line_cap)) layout[["line-cap"]] <- line_cap
  if (!is.null(line_elevation_ground_scale))
    layout[["line-elevation-ground-scale"]] <- line_elevation_ground_scale
  if (!is.null(line_elevation_reference))
    layout[["line-elevation-reference"]] <- line_elevation_reference
  if (!is.null(line_join)) layout[["line-join"]] <- line_join
  if (!is.null(line_miter_limit))
    layout[["line-miter-limit"]] <- line_miter_limit
  if (!is.null(line_round_limit))
    layout[["line-round-limit"]] <- line_round_limit
  if (!is.null(line_sort_key)) layout[["line-sort-key"]] <- line_sort_key
  if (!is.null(line_z_offset)) layout[["line-z-offset"]] <- line_z_offset
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
    filter,
    tooltip_style = tooltip_style,
    popup_style = popup_style
  )

  return(map)
}

#' Add a heatmap layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
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
#' mapboxgl(
#'     style = mapbox_style("dark"),
#'     center = c(-120, 50),
#'     zoom = 2
#' ) |>
#'     add_heatmap_layer(
#'         id = "earthquakes-heat",
#'         source = list(
#'             type = "geojson",
#'             data = "https://docs.mapbox.com/mapbox-gl-js/assets/earthquakes.geojson"
#'         ),
#'         heatmap_weight = interpolate(
#'             column = "mag",
#'             values = c(0, 6),
#'             stops = c(0, 1)
#'         ),
#'         heatmap_intensity = interpolate(
#'             property = "zoom",
#'             values = c(0, 9),
#'             stops = c(1, 3)
#'         ),
#'         heatmap_color = interpolate(
#'             property = "heatmap-density",
#'             values = seq(0, 1, 0.2),
#'             stops = c(
#'                 "rgba(33,102,172,0)", "rgb(103,169,207)",
#'                 "rgb(209,229,240)", "rgb(253,219,199)",
#'                 "rgb(239,138,98)", "rgb(178,24,43)"
#'             )
#'         ),
#'         heatmap_opacity = 0.7
#'     )
#' }
add_heatmap_layer <- function(
  map,
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
  filter = NULL
) {
  paint <- list()
  layout <- list()

  if (!is.null(heatmap_color)) paint[["heatmap-color"]] <- heatmap_color
  if (!is.null(heatmap_intensity))
    paint[["heatmap-intensity"]] <- heatmap_intensity
  if (!is.null(heatmap_opacity)) paint[["heatmap-opacity"]] <- heatmap_opacity
  if (!is.null(heatmap_radius)) paint[["heatmap-radius"]] <- heatmap_radius
  if (!is.null(heatmap_weight)) paint[["heatmap-weight"]] <- heatmap_weight

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(
    map,
    id,
    "heatmap",
    source,
    source_layer,
    paint,
    layout,
    slot,
    min_zoom,
    max_zoom,
    before_id = before_id,
    filter = filter
  )

  return(map)
}

#' Add a fill-extrusion layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param fill_extrusion_ambient_occlusion_intensity Controls the intensity of ambient occlusion shading. Value between 0 and 1; around 0.3 provides the most plausible results for buildings.
#' @param fill_extrusion_ambient_occlusion_radius Shades area near ground and concave angles between walls. Default 3.0 corresponds to one floor height.
#' @param fill_extrusion_base The base height of the fill extrusion.
#' @param fill_extrusion_cast_shadows If `TRUE` (the default), the fill extrusion casts shadows.
#' @param fill_extrusion_color The color of the fill extrusion.
#' @param fill_extrusion_cutoff_fade_range Defines the fade-out range before automatic content cutoff on pitched views. Value between 0 and 1; 0 disables cutoff.
#' @param fill_extrusion_emissive_strength Controls the intensity of light emitted on the source features. Requires 3D lights.
#' @param fill_extrusion_height The height of the fill extrusion.
#' @param fill_extrusion_opacity The opacity of the fill extrusion.
#' @param fill_extrusion_pattern Name of image in sprite to use for drawing image fills.
#' @param fill_extrusion_translate The geometry's offset. Values are `c(x, y)` where negatives indicate left and up.
#' @param fill_extrusion_translate_anchor Controls the frame of reference for `fill-extrusion-translate`.
#' @param fill_extrusion_vertical_gradient If `TRUE` (the default), sides will be shaded slightly darker farther down.
#' @param visibility Whether this layer is displayed.
#' @param slot An optional slot for layer order.
#' @param min_zoom The minimum zoom level for the layer.
#' @param max_zoom The maximum zoom level for the layer.
#' @param popup Popup content shown on click: a column name, a `{brace}` template (e.g. `"{name}: {value}"`), or a `concat()`/`number_format()` expression. Columns containing HTML are parsed.
#' @param tooltip Tooltip content shown on hover; same forms as `popup`.
#' @param tooltip_style,popup_style Optional appearance for the tooltip/popup: a preset string (`"light"` or `"dark"`) or a [tooltip_style()] object. When omitted, the native (unstyled) appearance is kept.
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
#'     style = maptiler_style("basic"),
#'     center = c(-74.0066, 40.7135),
#'     zoom = 15.5,
#'     pitch = 45,
#'     bearing = -17.6
#' ) |>
#'     add_vector_source(
#'         id = "openmaptiles",
#'         url = paste0(
#'             "https://api.maptiler.com/tiles/v3/tiles.json?key=",
#'             Sys.getenv("MAPTILER_API_KEY")
#'         )
#'     ) |>
#'     add_fill_extrusion_layer(
#'         id = "3d-buildings",
#'         source = "openmaptiles",
#'         source_layer = "building",
#'         fill_extrusion_color = interpolate(
#'             column = "render_height",
#'             values = c(0, 200, 400),
#'             stops = c("lightgray", "royalblue", "lightblue")
#'         ),
#'         fill_extrusion_height = list(
#'             "interpolate",
#'             list("linear"),
#'             list("zoom"),
#'             15,
#'             0,
#'             16,
#'             list("get", "render_height")
#'         )
#'     )
#' }
add_fill_extrusion_layer <- function(
  map,
  id,
  source,
  source_layer = NULL,
  fill_extrusion_ambient_occlusion_intensity = NULL,
  fill_extrusion_ambient_occlusion_radius = NULL,
  fill_extrusion_base = NULL,
  fill_extrusion_cast_shadows = NULL,
  fill_extrusion_color = NULL,
  fill_extrusion_cutoff_fade_range = NULL,
  fill_extrusion_emissive_strength = NULL,
  fill_extrusion_height = NULL,
  fill_extrusion_opacity = NULL,
  fill_extrusion_pattern = NULL,
  fill_extrusion_translate = NULL,
  fill_extrusion_translate_anchor = "map",
  fill_extrusion_vertical_gradient = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
) {
  # Check if using MapLibre with globe projection and warn
  if (
    inherits(map, "maplibregl") &&
      !is.null(map$x$projection) &&
      map$x$projection == "globe"
  ) {
    warning(
      "Fill-extrusion layers may have rendering artifacts in globe projection. ",
      "Consider using projection = \"mercator\" in maplibre() for better performance. ",
      "See https://github.com/maplibre/maplibre-gl-js/issues/5025",
      call. = FALSE
    )
  }

  paint <- list()
  layout <- list()

  if (!is.null(fill_extrusion_ambient_occlusion_intensity))
    paint[[
      "fill-extrusion-ambient-occlusion-intensity"
    ]] <- fill_extrusion_ambient_occlusion_intensity
  if (!is.null(fill_extrusion_ambient_occlusion_radius))
    paint[[
      "fill-extrusion-ambient-occlusion-radius"
    ]] <- fill_extrusion_ambient_occlusion_radius
  if (!is.null(fill_extrusion_base))
    paint[["fill-extrusion-base"]] <- fill_extrusion_base
  if (!is.null(fill_extrusion_cast_shadows))
    paint[["fill-extrusion-cast-shadows"]] <- fill_extrusion_cast_shadows
  if (!is.null(fill_extrusion_color))
    paint[["fill-extrusion-color"]] <- fill_extrusion_color
  if (!is.null(fill_extrusion_cutoff_fade_range))
    paint[[
      "fill-extrusion-cutoff-fade-range"
    ]] <- fill_extrusion_cutoff_fade_range
  if (!is.null(fill_extrusion_emissive_strength))
    paint[[
      "fill-extrusion-emissive-strength"
    ]] <- fill_extrusion_emissive_strength
  if (!is.null(fill_extrusion_height))
    paint[["fill-extrusion-height"]] <- fill_extrusion_height
  if (!is.null(fill_extrusion_opacity))
    paint[["fill-extrusion-opacity"]] <- fill_extrusion_opacity
  if (!is.null(fill_extrusion_pattern))
    paint[["fill-extrusion-pattern"]] <- fill_extrusion_pattern
  if (!is.null(fill_extrusion_translate))
    paint[["fill-extrusion-translate"]] <- fill_extrusion_translate
  if (!is.null(fill_extrusion_translate_anchor))
    paint[[
      "fill-extrusion-translate-anchor"
    ]] <- fill_extrusion_translate_anchor
  if (!is.null(fill_extrusion_vertical_gradient))
    paint[[
      "fill-extrusion-vertical-gradient"
    ]] <- fill_extrusion_vertical_gradient

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(
    map,
    id,
    "fill-extrusion",
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
    filter,
    tooltip_style = tooltip_style,
    popup_style = popup_style
  )

  return(map)
}

#' Prepare cluster options for circle layers
#'
#' This function creates a list of options for clustering circle layers.
#' Clusters are drawn as circles colored by point count, or, when
#' `donut_column` is set, as donut charts showing the mix of categories
#' inside each cluster.
#'
#' @param max_zoom The maximum zoom level at which to cluster points.
#' @param cluster_radius The radius of each cluster when clustering points, in pixels. Defaults to 50 for circle clusters and to 1.5 times the largest of `radius_stops` (60 by default) for donut clusters, which keeps neighboring donuts from piling on top of each other.
#' @param color_stops A vector of colors for the circle color step expression. Ignored for donut clusters.
#' @param radius_stops A vector of radii for the circle radius step expression. Also sizes donut clusters.
#' @param count_stops A vector of point counts for both color and radius step expressions.
#' @param circle_blur Amount to blur the circle. Ignored for donut clusters.
#' @param circle_opacity The opacity of the circle. For donut clusters, the opacity of the whole donut.
#' @param circle_stroke_color The color of the circle's stroke. For donut clusters, the color of the donut's outer edge (default `"white"`).
#' @param circle_stroke_opacity The opacity of the circle's stroke.
#' @param circle_stroke_width The width of the circle's stroke. For donut clusters, the width of the donut's outer edge in pixels (default `1`).
#' @param text_color The color to use for labels on the cluster circles.
#' @param count_format The formatting of the text labels on the cluster circles to represent the counts. `"abbreviated"` (the default) will use shortened notation, e.g. "11k" or "1.7M". `"grouped"` will show comma-separated numbers, e.g. "11,000".  `"raw"` shows the raw value.
#' @param donut_column The name of a categorical column. When set, clusters are drawn as donut charts showing the share of each category within the cluster.
#' @param donut_values,donut_colors The categories to show and their colors, one color per entry of `donut_values`. Pass a list to group several values under one color, e.g. `list(c("Oil", "Gas"), "Dry Hole")`. When `NULL` (the default), both are taken from the layer's `circle_color` if it is a [match_expr()] on `donut_column`; its `default` color becomes an "other" slice for unlisted values. Required for [add_symbol_layer()].
#' @param donut_weight An optional numeric column to sum instead of counting points, e.g. population. The cluster label then shows the weighted total. Missing weights count as zero.
#' @param donut_width The thickness of the donut ring as a fraction of its radius, between 0 and 1.
#' @param donut_fill The color of the donut's center, behind the count label. Use `NA` for a transparent center.
#' @param donut_resolution The step, in percent, to which category shares are rounded (an integer from 1 to 10). Categories whose share rounds to zero are not drawn.
#'
#' @details
#' **Donut clusters.** Setting `donut_column` computes per-category totals
#' for every cluster and draws each cluster as a donut chart in the category
#' colors. Colors are usually taken from the unclustered layer's
#' `circle_color` so that clusters and points match:
#'
#' ```
#' add_circle_layer(
#'   id = "people",
#'   source = dots,
#'   circle_color = match_expr(
#'     "race",
#'     values = c("White", "Black", "Hispanic", "Asian"),
#'     stops = c("#1b9e77", "#d95f02", "#7570b3", "#e7298a")
#'   ),
#'   cluster_options = cluster_options(donut_column = "race")
#' )
#' ```
#'
#' Build a matching legend by passing the same values and colors to
#' [add_categorical_legend()]. Colors taken from `match_expr()` have already
#' had any alpha channel removed; pass `donut_colors` to keep transparency.
#' The ring shares are among the categories drawn: without an "other"
#' slice, points with unlisted or missing categories are left out of the
#' ring (but still count toward `point_count`, and toward the weighted
#' label total when `donut_weight` is set).
#'
#' Computing category totals makes clustering about two to three times
#' slower than plain clustering with ten categories. Each distinct mix of
#' rounded shares is drawn as its own small image and kept for the life of
#' the map, so a long session panning across many zoom levels accumulates
#' images (tens of MB over a wide sweep of a large dataset). A coarser
#' `donut_resolution` produces fewer distinct images.
#'
#' **Pre-clustered vector tiles.** For tiles that are already clustered
#' (e.g. by freestiler), donut clusters read these properties from each
#' cluster feature: `point_count`, one `"<donut_column>:<value>"` total per
#' category (a count, or the sum of `donut_weight`), `"<donut_column>:_other"`
#' for the other slice when there is one, and `"<donut_column>:_total"`, the
#' weight summed over all points, when `donut_weight` is set. Numeric
#' categories must be whole numbers and are written without exponents, e.g.
#' `"code:100000"`. Missing properties count as zero. `_other` and `_total`
#' are reserved and can't be used as category values.
#'
#' @return A list of cluster options.
#' @export
#'
#' @examples
#' cluster_options(
#'     max_zoom = 14,
#'     cluster_radius = 50,
#'     color_stops = c("#51bbd6", "#f1f075", "#f28cb1"),
#'     radius_stops = c(20, 30, 40),
#'     count_stops = c(0, 100, 750),
#'     circle_blur = 1,
#'     circle_opacity = 0.8,
#'     circle_stroke_color = "#ffffff",
#'     circle_stroke_width = 2
#' )
#'
#' # Donut clusters with explicit categories and colors
#' cluster_options(
#'     donut_column = "type",
#'     donut_values = c("Oil", "Gas", "Dry Hole"),
#'     donut_colors = c("#1B5E20", "#fc8d59", "#cd5c5c")
#' )
cluster_options <- function(
  max_zoom = 14,
  cluster_radius = NULL,
  color_stops = c("#51bbd6", "#f1f075", "#f28cb1"),
  radius_stops = c(20, 30, 40),
  count_stops = c(0, 100, 750),
  circle_blur = NULL,
  circle_opacity = NULL,
  circle_stroke_color = NULL,
  circle_stroke_opacity = NULL,
  circle_stroke_width = NULL,
  text_color = "black",
  count_format = c("abbreviated", "grouped", "raw"),
  donut_column = NULL,
  donut_values = NULL,
  donut_colors = NULL,
  donut_weight = NULL,
  donut_width = 0.35,
  donut_fill = "white",
  donut_resolution = 2
) {
  count_format <- match.arg(count_format)
  if (is.null(cluster_radius)) {
    cluster_radius <- if (is.null(donut_column)) 50 else 1.5 * max(radius_stops)
  }
  options <- list(
    max_zoom = max_zoom,
    cluster_radius = cluster_radius,
    color_stops = color_stops,
    radius_stops = radius_stops,
    count_stops = count_stops,
    circle_blur = circle_blur,
    circle_opacity = circle_opacity,
    circle_stroke_color = circle_stroke_color,
    circle_stroke_opacity = circle_stroke_opacity,
    circle_stroke_width = circle_stroke_width,
    text_color = text_color,
    count_format = count_format
  )

  if (!is.null(donut_column)) {
    options$donut <- .validate_donut_options(
      column = donut_column,
      values = donut_values,
      colors = donut_colors,
      weight = donut_weight,
      width = donut_width,
      fill = donut_fill,
      resolution = donut_resolution,
      stroke_color = circle_stroke_color,
      stroke_opacity = circle_stroke_opacity,
      stroke_width = circle_stroke_width
    )
  } else if (!is.null(donut_values) || !is.null(donut_colors) || !is.null(donut_weight)) {
    rlang::abort(
      "`donut_values`, `donut_colors`, and `donut_weight` require `donut_column`."
    )
  }

  options
}

# Warn when a Mapbox GL JS map is rendering a pre-clustered vector
# tile source via cluster_options(). Mapbox GL JS v3.21.0's native
# TileProvider PMTiles path currently renders features from multiple
# source zooms simultaneously at fractional camera zooms, which
# produces duplicate cluster labels during transitions. MapLibre
# (via the `pmtiles://` protocol handler) is unaffected. This helper
# only fires a warning — the feature still works, just with the
# visual artifact documented upstream.
.warn_mapbox_pmtiles_cluster <- function(map) {
  is_mapbox <- inherits(
    map,
    c(
      "mapboxgl",
      "mapboxgl_proxy",
      "mapboxgl_compare",
      "mapboxgl_compare_proxy"
    )
  )
  if (!is_mapbox) return(invisible())
  rlang::warn(
    c(
      "Clustered vector tile sources render with visual artifacts in Mapbox GL JS.",
      i = "Mapbox GL JS v3.21.0's native PMTiles path can display features from adjacent source zooms at the same time, producing duplicate cluster labels at fractional camera zooms.",
      i = "MapLibre (via `maplibre()`) renders the same tiles correctly; switching to it avoids the artifact.",
      i = "See `?cluster_options` for details."
    ),
    .frequency = "regularly",
    .frequency_id = "mapgl_mapbox_pmtiles_cluster"
  )
}

# Resolve the count-label expression for a cluster count format.
# `value` overrides the counted quantity (e.g. a weighted donut total).
.cluster_count_label <- function(count_format, value = NULL) {
  value <- value %||% list("get", "point_count")
  switch(
    count_format,
    abbreviated = .cluster_count_label_expr(value),
    grouped = number_format(column = value),
    raw = list("to-string", value)
  )
}

# Build a Mapbox/MapLibre expression that abbreviates a count the same
# way Supercluster's native `point_count_abbreviated` does, extended to
# millions (the native property stops at "k", so 1.7M reads "1735k"):
#   <1000:            "42"
#   1000-9999:        "1.2k"
#   10000-999499:     "12k"
#   999500-9949999:   "1.7M"
#   >=9950000:        "17M"
# Below 1000, non-integer values (weighted donut totals) keep one decimal.
# Rounding matches Supercluster (nearest, halves up), and the M cutoffs
# sit where the k form would round up to "1000k". GL's `number-format`
# ignores Intl's `notation = "compact"`, so this can't use number_format().
# `column` is a property name or an expression.
.cluster_count_label_expr <- function(column = "point_count") {
  col <- if (is.character(column) && length(column) == 1) {
    list("get", column)
  } else {
    column
  }
  scaled <- function(divisor, decimals) {
    if (decimals) {
      list("/", list("round", list("/", col, divisor / 10)), 10)
    } else {
      list("round", list("/", col, divisor))
    }
  }
  list(
    "case",
    list(">=", col, 9950000),
    list("concat", list("to-string", scaled(1e6, FALSE)), "M"),
    list(">=", col, 999500),
    list("concat", list("to-string", scaled(1e6, TRUE)), "M"),
    list(">=", col, 10000),
    list("concat", list("to-string", scaled(1000, FALSE)), "k"),
    list(">=", col, 1000),
    list("concat", list("to-string", scaled(1000, TRUE)), "k"),
    # One decimal for weighted totals; whole counts are unchanged
    list("to-string", list("/", list("round", list("*", col, 10)), 10))
  )
}

# ---- Donut clusters ---------------------------------------------------------
#
# Donut clusters aggregate per-category totals on each cluster (GL
# `clusterProperties` for native clusters, or precomputed properties on
# pre-clustered tiles) and draw each cluster as a symbol whose icon-image
# is built from the rounded category shares, e.g.
# "mapgl-donut|<fingerprint>|<radius>|40,30,0,30|<layer id>". The
# `styleimagemissing` handler in lib/mapgl-cluster-donut/cluster-donut.js
# draws that image on demand, reading colors from the layer's metadata.

# Validate the donut arguments of cluster_options() early so errors
# surface where they were written. Returns the stored donut options.
.validate_donut_options <- function(
  column,
  values,
  colors,
  weight,
  width,
  fill,
  resolution,
  stroke_color,
  stroke_opacity,
  stroke_width
) {
  is_name <- function(x) {
    is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)
  }
  if (!is_name(column)) {
    rlang::abort("`donut_column` must be a single column name.")
  }
  if (!is.null(weight) && !is_name(weight)) {
    rlang::abort("`donut_weight` must be a single column name.")
  }
  if (identical(weight, column)) {
    rlang::abort("`donut_weight` must be a different column from `donut_column`.")
  }
  if (xor(is.null(values), is.null(colors))) {
    rlang::abort("Supply both `donut_values` and `donut_colors`, or neither.")
  }
  if (!is.null(values)) {
    if (length(colors) != length(values)) {
      rlang::abort("`donut_colors` must be the same length as `donut_values`.")
    }
    .donut_normalize_values(
      .donut_expand_groups(values, colors)$values,
      "donut_values"
    )
    .mapgl_donut_colors(colors, "donut_colors")
  }
  if (
    !is.numeric(width) ||
      length(width) != 1 ||
      is.na(width) ||
      width <= 0 ||
      width >= 1
  ) {
    rlang::abort("`donut_width` must be a number between 0 and 1.")
  }
  if (
    !is.numeric(resolution) ||
      length(resolution) != 1 ||
      is.na(resolution) ||
      resolution != round(resolution) ||
      resolution < 1 ||
      resolution > 10
  ) {
    rlang::abort("`donut_resolution` must be a whole number from 1 to 10.")
  }
  if (length(fill) != 1 || (!is.na(fill) && !is.character(fill))) {
    rlang::abort("`donut_fill` must be a single color or `NA`.")
  }
  if (!is.na(fill)) {
    .mapgl_donut_colors(fill, "donut_fill")
  }

  # The outer edge is drawn on a canvas, so these can't be expressions
  scalar_args <- list(
    circle_stroke_color = stroke_color,
    circle_stroke_opacity = stroke_opacity,
    circle_stroke_width = stroke_width
  )
  for (arg in names(scalar_args)) {
    value <- scalar_args[[arg]]
    if (!is.null(value) && (is.list(value) || length(value) != 1)) {
      rlang::abort(paste0(
        "`",
        arg,
        "` must be a single value for donut clusters; expressions aren't supported."
      ))
    }
  }
  if (!is.null(stroke_color)) {
    .mapgl_donut_colors(stroke_color, "circle_stroke_color")
  }
  if (
    !is.null(stroke_opacity) &&
      (!is.numeric(stroke_opacity) || stroke_opacity < 0 || stroke_opacity > 1)
  ) {
    rlang::abort("`circle_stroke_opacity` must be a number between 0 and 1.")
  }
  if (
    !is.null(stroke_width) && (!is.numeric(stroke_width) || stroke_width < 0)
  ) {
    rlang::abort("`circle_stroke_width` must be a non-negative number.")
  }

  list(
    column = column,
    values = values,
    colors = colors,
    weight = weight,
    width = width,
    fill = fill,
    resolution = resolution
  )
}

# Normalize category values into match labels (character or numeric) and
# the key strings used in `<column>:<key>` property names. Accepts an
# atomic vector, a factor, or a list of scalars (from match_expr()).
.donut_normalize_values <- function(values, arg) {
  if (is.factor(values)) {
    values <- as.character(values)
  }
  if (is.list(values)) {
    types <- vapply(
      values,
      function(value) {
        if (is.character(value) || is.factor(value)) {
          "character"
        } else if (is.numeric(value)) {
          "numeric"
        } else {
          "other"
        }
      },
      character(1)
    )
    if (any(types == "other") || length(unique(types)) > 1) {
      rlang::abort(paste0(
        "`",
        arg,
        "` must be all character or all numeric category values."
      ))
    }
    values <- if (types[[1]] == "character") {
      unlist(lapply(values, as.character))
    } else {
      unlist(values)
    }
  }
  if (length(values) == 0) {
    rlang::abort(paste0("`", arg, "` must contain at least one category."))
  }
  if (anyNA(values)) {
    rlang::abort(paste0("`", arg, "` can't contain missing values."))
  }

  if (is.character(values)) {
    if (any(values %in% c("_other", "_total"))) {
      rlang::abort(
        "`_other` and `_total` are reserved and can't be used as category values."
      )
    }
    keys <- values
  } else if (is.numeric(values)) {
    if (
      any(!is.finite(values)) ||
        any(values != round(values)) ||
        any(abs(values) > 9007199254740991)
    ) {
      rlang::abort(paste0(
        "Numeric `",
        arg,
        "` must be whole numbers between -(2^53 - 1) and 2^53 - 1."
      ))
    }
    values <- as.numeric(values)
    keys <- sprintf("%.0f", values)
  } else {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be character, factor, or numeric category values."
    ))
  }

  if (anyDuplicated(keys)) {
    rlang::abort(paste0("`", arg, "` can't contain duplicate categories."))
  }

  list(labels = values, keys = keys)
}

# Read categories, colors, and the default color from a match_expr() on
# `column`. Grouped labels (`values = list(c("A", "B"), "C")`) expand into
# one category per value sharing the pair's color. Returns NULL when
# `expr` isn't a simple color match on `column`.
.donut_from_match <- function(expr, column) {
  if (!is.list(expr) || length(expr) < 4 || !identical(expr[[1]], "match")) {
    return(NULL)
  }
  input <- expr[[2]]
  if (
    !is.list(input) ||
      length(input) != 2 ||
      !identical(input[[1]], "get") ||
      !identical(input[[2]], column)
  ) {
    return(NULL)
  }

  n <- length(expr)
  has_default <- n %% 2 == 1
  last_label <- if (has_default) n - 2 else n - 1

  values <- list()
  colors <- character()
  for (i in seq(3, last_label, by = 2)) {
    label <- expr[[i]]
    color <- expr[[i + 1]]
    if (!is.character(color) || length(color) != 1) {
      return(NULL)
    }
    if (is.list(label)) {
      label <- unlist(label)
    }
    for (value in as.list(label)) {
      values <- c(values, list(value))
      colors <- c(colors, color)
    }
  }

  default <- if (has_default) expr[[n]] else NULL
  if (!is.null(default) && (!is.character(default) || length(default) != 1)) {
    return(NULL)
  }

  list(values = values, colors = colors, default = default)
}

# Expand grouped categories (`list(c("A", "B"), "C")`) into one value per
# category, each keeping its group's color, as match_expr() labels do.
.donut_expand_groups <- function(values, colors) {
  if (!is.list(values)) {
    return(list(values = values, colors = colors))
  }
  sizes <- lengths(values)
  list(
    values = unlist(lapply(values, as.list), recursive = FALSE),
    colors = rep(colors, times = sizes)
  )
}

# Normalize colors for canvas drawing: 6-digit hex plus a separate alpha
# in [0, 1]. Accepts R color names, #RGB/#RGBA/#RRGGBB/#RRGGBBAA, and CSS
# rgb()/rgba(). Unlike .mapgl_col2hex(), alpha is kept.
.mapgl_donut_colors <- function(colors, arg) {
  if (!is.character(colors) || length(colors) == 0 || anyNA(colors)) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be a character vector of colors without missing values."
    ))
  }
  rgba <- vapply(
    colors,
    function(color) {
      parsed <- mapgl_parse_rgb_css_color(color)
      if (!is.null(parsed)) {
        return(c(parsed[1:3], parsed[[4]] * 255))
      }
      color <- trimws(color)
      if (grepl("^#[0-9A-Fa-f]{3,4}$", color)) {
        digits <- strsplit(substring(color, 2), "")[[1]]
        color <- paste0("#", paste(rep(digits, each = 2), collapse = ""))
      }
      out <- tryCatch(
        as.numeric(grDevices::col2rgb(color, alpha = TRUE)),
        error = function(e) NULL
      )
      if (is.null(out)) {
        rlang::abort(paste0(
          "Invalid color `",
          color,
          "` in `",
          arg,
          "`. Use an R color name, hex value, or CSS rgb()/rgba() string."
        ))
      }
      out
    },
    numeric(4),
    USE.NAMES = FALSE
  )
  rgba <- matrix(rgba, nrow = 4)
  list(
    hex = sprintf(
      "#%02X%02X%02X",
      as.integer(round(rgba[1, ])),
      as.integer(round(rgba[2, ])),
      as.integer(round(rgba[3, ]))
    ),
    alpha = round(rgba[4, ] / 255, 3)
  )
}

# Check the donut columns against sf data before serializing, so type
# mismatches fail in R instead of silently producing empty rings.
.check_donut_columns <- function(source, column, weight, categories) {
  if (inherits(source, "sfc") || !column %in% names(source)) {
    rlang::abort(paste0(
      "`donut_column` \"",
      column,
      "\" isn't a column in `source`."
    ))
  }
  x <- source[[column]]
  if (is.character(categories$labels)) {
    if (!is.character(x) && !is.factor(x)) {
      rlang::abort(paste0(
        "`donut_column` \"",
        column,
        "\" must be a character or factor column to match character categories."
      ))
    }
  } else if (!is.numeric(x)) {
    rlang::abort(paste0(
      "`donut_column` \"",
      column,
      "\" must be a numeric column to match numeric categories."
    ))
  }

  if (!is.null(weight)) {
    if (!weight %in% names(source)) {
      rlang::abort(paste0(
        "`donut_weight` \"",
        weight,
        "\" isn't a column in `source`."
      ))
    }
    w <- source[[weight]]
    if (!is.numeric(w)) {
      rlang::abort(paste0("`donut_weight` \"", weight, "\" must be numeric."))
    }
    w <- w[!is.na(w)]
    if (any(!is.finite(w)) || any(w < 0)) {
      rlang::abort(paste0(
        "`donut_weight` \"",
        weight,
        "\" must contain finite, non-negative values."
      ))
    }
  }

  invisible(TRUE)
}

# Build everything a donut cluster layer needs: the clusterProperties for
# native clusters, the icon-image expression, the weighted label value,
# and the canvas spec stored in layer metadata.
.cluster_donut_spec <- function(
  cluster_options,
  circle_color,
  source,
  layer_id
) {
  donut <- cluster_options$donut
  column <- donut$column

  if (
    inherits(source, c("sf", "sfc")) &&
      (inherits(source, "sfc") || !column %in% names(source))
  ) {
    rlang::abort(paste0(
      "`donut_column` \"",
      column,
      "\" isn't a column in `source`."
    ))
  }

  if (!is.null(donut$values)) {
    grouped <- .donut_expand_groups(donut$values, donut$colors)
    categories <- .donut_normalize_values(grouped$values, "donut_values")
    colors <- grouped$colors
    other_color <- NULL
  } else {
    parsed <- .donut_from_match(circle_color, column)
    if (is.null(parsed)) {
      rlang::abort(c(
        "Donut clusters need category colors.",
        i = paste0(
          "Pass `donut_values` and `donut_colors` to `cluster_options()`, ",
          "or use a `match_expr()` on \"",
          column,
          "\" as the layer's `circle_color`."
        )
      ))
    }
    categories <- .donut_normalize_values(parsed$values, "circle_color")
    colors <- parsed$colors
    other_color <- parsed$default
  }

  if (inherits(source, c("sf", "sfc"))) {
    .check_donut_columns(source, column, donut$weight, categories)
  }

  slice_colors <- .mapgl_donut_colors(c(colors, other_color), "donut_colors")
  fill <- if (is.na(donut$fill)) {
    NULL
  } else {
    .mapgl_donut_colors(donut$fill, "donut_fill")
  }
  stroke <- .mapgl_donut_colors(
    cluster_options$circle_stroke_color %||% "white",
    "circle_stroke_color"
  )

  # Data-only canvas spec; its hash names the images, so any change to
  # colors or ring styling produces new images rather than stale ones.
  spec <- list(
    colors = as.list(slice_colors$hex),
    alphas = as.list(slice_colors$alpha),
    width = donut$width,
    fill = fill$hex,
    fill_alpha = fill$alpha,
    stroke = stroke$hex,
    stroke_alpha = stroke$alpha * (cluster_options$circle_stroke_opacity %||% 1),
    stroke_width = cluster_options$circle_stroke_width %||% 1
  )
  fingerprint <- substr(rlang::hash(spec), 1, 10)
  spec$fp <- fingerprint

  labels <- categories$labels
  keys <- paste0(column, ":", categories$keys)
  other_key <- paste0(column, ":_other")
  slice_keys <- if (is.null(other_color)) keys else c(keys, other_key)

  weight_expr <- if (is.null(donut$weight)) {
    1
  } else {
    list("coalesce", list("get", donut$weight), 0)
  }
  category <- list("get", column)

  cluster_properties <- lapply(seq_along(labels), function(i) {
    list("+", list("case", list("==", category, labels[[i]]), weight_expr, 0))
  })
  names(cluster_properties) <- keys
  if (!is.null(other_color)) {
    # Bare label array: `literal` isn't allowed in match label position
    cluster_properties[[other_key]] <- list(
      "+",
      list("match", category, as.list(labels), 0, weight_expr)
    )
  }

  label_value <- NULL
  if (!is.null(donut$weight)) {
    total_key <- paste0(column, ":_total")
    cluster_properties[[total_key]] <- list("+", weight_expr)
    label_value <- list("coalesce", list("get", total_key), 0)
  }

  slice_values <- lapply(slice_keys, function(key) {
    list("coalesce", list("get", key), 0)
  })
  total <- if (length(slice_values) == 1) {
    slice_values[[1]]
  } else {
    c(list("+"), slice_values)
  }
  # The total is bound once with `let` and read back per slice with `var`
  total_var <- list("var", "mapgl_total")
  units <- lapply(slice_values, function(value) {
    list(
      "case",
      list(">", total_var, 0),
      list(
        "round",
        list(
          "/",
          list("*", 100, value),
          list("*", total_var, donut$resolution)
        )
      ),
      0
    )
  })

  # Images are drawn at their display radius; drawing everything at the
  # largest radius and scaling with icon-size saves few images (each
  # cluster's mix is usually unique) but costs more bytes per image
  radius <- step_expr(
    column = "point_count",
    base = cluster_options$radius_stops[1],
    stops = cluster_options$radius_stops[-1],
    values = cluster_options$count_stops[-1]
  )

  unit_parts <- list()
  for (i in seq_along(units)) {
    if (i > 1) {
      unit_parts <- c(unit_parts, list(","))
    }
    unit_parts <- c(unit_parts, list(list("to-string", units[[i]])))
  }
  icon_image <- list(
    "let",
    "mapgl_total",
    total,
    c(
      list(
        "concat",
        paste0("mapgl-donut|", fingerprint, "|"),
        list("to-string", radius),
        "|"
      ),
      unit_parts,
      list(paste0("|", layer_id))
    )
  )

  list(
    spec = spec,
    cluster_properties = cluster_properties,
    icon_image = icon_image,
    label_value = label_value
  )
}

# Add the three layers behind the `cluster_options` shortcut of
# add_circle_layer() and add_symbol_layer(): `<id>-clusters` (circles or
# donuts), `<id>-cluster-count`, and the unclustered `<id>` layer. Paint
# and layout are complete before each add_layer() call so proxy messages
# carry every property.
.add_cluster_layers <- function(
  map,
  id,
  source,
  source_layer,
  cluster_options,
  point_type,
  paint,
  layout,
  visibility,
  circle_color = NULL,
  popup = NULL,
  tooltip = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  before_id = NULL
) {
  clusters_id <- paste0(id, "-clusters")
  is_donut <- !is.null(cluster_options$donut)
  donut <- NULL

  # Dispatch on source shape. sf/sfc takes precedence so existing
  # calls that incidentally pass `source_layer` alongside sf data
  # (silently ignored today) don't regress.
  if (inherits(source, c("sf", "sfc"))) {
    # Native live clustering: inject a clustered GeoJSON source.
    if (is_donut) {
      donut <- .cluster_donut_spec(
        cluster_options,
        circle_color,
        source,
        clusters_id
      )
      map <- add_source(
        map,
        id = id,
        data = source,
        cluster = TRUE,
        clusterMaxZoom = cluster_options$max_zoom,
        clusterRadius = cluster_options$cluster_radius,
        clusterProperties = donut$cluster_properties
      )
    } else {
      map <- add_source(
        map,
        id = id,
        data = source,
        cluster = TRUE,
        clusterMaxZoom = cluster_options$max_zoom,
        clusterRadius = cluster_options$cluster_radius
      )
    }
    cluster_source <- id
    cluster_source_layer <- NULL
  } else if (
    is.character(source) &&
      length(source) == 1 &&
      !is.null(source_layer)
  ) {
    # Pre-clustered vector tiles (e.g. PMTiles from the freestiler
    # package, or tippecanoe-clustered tiles). Use the source as-is.
    if (is_donut) {
      donut <- .cluster_donut_spec(
        cluster_options,
        circle_color,
        NULL,
        clusters_id
      )
    }
    cluster_source <- source
    cluster_source_layer <- source_layer
    .warn_mapbox_pmtiles_cluster(map)
  } else {
    rlang::abort(c(
      "`cluster_options` requires one of the following shapes:",
      i = "`source` = an sf/sfc object (live clustering is applied automatically), or",
      i = "`source` = an existing source id (string) + `source_layer` = the source-layer name, for pre-clustered vector tiles.",
      i = "To cluster against a pre-registered clustered GeoJSON source referenced by id, build the three cluster layers manually with `add_layer()`."
    ))
  }

  count_label_expr <- .cluster_count_label(
    cluster_options$count_format %||% "abbreviated",
    value = donut$label_value
  )

  if (is_donut) {
    cluster_paint <- list()
    if (!is.null(cluster_options$circle_opacity)) {
      cluster_paint[["icon-opacity"]] <- cluster_options$circle_opacity
    }
    cluster_layout <- list(
      "icon-image" = donut$icon_image,
      "icon-allow-overlap" = TRUE,
      "icon-ignore-placement" = TRUE
    )
    if (!is.null(visibility)) {
      cluster_layout$visibility <- visibility
    }
    map <- add_layer(
      map,
      id = clusters_id,
      type = "symbol",
      source = cluster_source,
      source_layer = cluster_source_layer,
      filter = c("has", "point_count"),
      paint = cluster_paint,
      layout = cluster_layout,
      slot = slot,
      min_zoom = min_zoom,
      max_zoom = max_zoom,
      before_id = before_id,
      metadata = list("mapgl:donut" = donut$spec)
    )
  } else {
    cluster_paint <- list(
      "circle-color" = step_expr(
        column = "point_count",
        base = cluster_options$color_stops[1],
        stops = cluster_options$color_stops[-1],
        values = cluster_options$count_stops[-1]
      ),
      "circle-radius" = step_expr(
        column = "point_count",
        base = cluster_options$radius_stops[1],
        stops = cluster_options$radius_stops[-1],
        values = cluster_options$count_stops[-1]
      )
    )
    optional_paint <- list(
      "circle-blur" = cluster_options$circle_blur,
      "circle-opacity" = cluster_options$circle_opacity,
      "circle-stroke-color" = cluster_options$circle_stroke_color,
      "circle-stroke-opacity" = cluster_options$circle_stroke_opacity,
      "circle-stroke-width" = cluster_options$circle_stroke_width
    )
    for (prop in names(optional_paint)) {
      if (!is.null(optional_paint[[prop]])) {
        cluster_paint[[prop]] <- optional_paint[[prop]]
      }
    }
    map <- add_layer(
      map,
      id = clusters_id,
      type = "circle",
      source = cluster_source,
      source_layer = cluster_source_layer,
      filter = c("has", "point_count"),
      paint = cluster_paint,
      layout = list(visibility = visibility),
      slot = slot,
      min_zoom = min_zoom,
      max_zoom = max_zoom,
      before_id = before_id
    )
  }

  # Add cluster count labels
  map <- add_symbol_layer(
    map,
    id = paste0(id, "-cluster-count"),
    source = cluster_source,
    source_layer = cluster_source_layer,
    filter = c("has", "point_count"),
    text_field = count_label_expr,
    text_size = 12,
    text_color = cluster_options$text_color,
    visibility = visibility,
    slot = slot,
    min_zoom = min_zoom,
    max_zoom = max_zoom,
    before_id = before_id
  )

  # Add unclustered points
  add_layer(
    map,
    id = id,
    type = point_type,
    source = cluster_source,
    source_layer = cluster_source_layer,
    filter = list("!", c("has", "point_count")),
    paint = paint,
    layout = layout,
    popup = popup,
    tooltip = tooltip,
    tooltip_style = tooltip_style,
    popup_style = popup_style,
    hover_options = hover_options,
    slot = slot,
    min_zoom = min_zoom,
    max_zoom = max_zoom,
    before_id = before_id
  )
}

#' Add a circle layer to a Mapbox GL map
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A unique ID for the layer.
#' @param source The ID of the source, alternatively an sf object (which will be converted to a GeoJSON source) or a named list that specifies `type` and `url` for a remote source.
#' @param source_layer The source layer (for vector sources).
#' @param circle_blur Amount to blur the circle.
#' @param circle_color The color of the circle.
#' @param circle_emissive_strength Controls the intensity of light emitted on the source features. Requires 3D lights.
#' @param circle_opacity The opacity at which the circle will be drawn.
#' @param circle_pitch_alignment Orientation of circles when the map is pitched. One of `"map"` or `"viewport"`.
#' @param circle_pitch_scale Controls the scaling behavior of circles when the map is pitched. One of `"map"` (scaled by distance) or `"viewport"` (not scaled).
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
#' @param popup Popup content shown on click: a column name, a `{brace}` template (e.g. `"{name}: {value}"`), or a `concat()`/`number_format()` expression. Columns containing HTML are parsed.
#' @param tooltip Tooltip content shown on hover; same forms as `popup`.
#' @param tooltip_style,popup_style Optional appearance for the tooltip/popup: a preset string (`"light"` or `"dark"`) or a [tooltip_style()] object. When omitted, the native (unstyled) appearance is kept.
#' @param hover_options A named list of options for highlighting features in the layer on hover.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#' @param cluster_options A list of options for clustering circles, created by the `cluster_options()` function. Two input shapes are supported: pass an `sf`/`sfc` object as `source` for native live clustering (a GeoJSON source is injected automatically), or pass the id of an already-registered vector source (e.g. from `add_pmtiles_source()`) along with `source_layer` to use pre-clustered vector tiles such as those produced by the freestiler package. In the latter case the cluster-count label is abbreviated client-side from `point_count`. Set `donut_column` in `cluster_options()` to draw clusters as donut charts of category shares; see [cluster_options()] for the properties pre-clustered tiles need.
#'
#'   **Updating a clustered layer in Shiny:** the shortcut creates three layers (`"id"`, `"id-clusters"`, `"id-cluster-count"`) on top of one source. For reactive data updates the recommended pattern is [set_source()], which replaces the source's data and lets Mapbox/MapLibre re-cluster automatically without tearing down the layers: `mapboxgl_proxy("map") |> set_source(layer_id = "circles", source = filtered())`. If you need to remove a clustered layer entirely (e.g. before switching backends), pass the full trio to [clear_layer()]: `clear_layer(proxy, c("circles", "circles-clusters", "circles-cluster-count"))`.
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
#' bbox <- st_bbox(
#'     c(
#'         xmin = -77.119759,
#'         ymin = 38.791645,
#'         xmax = -76.909393,
#'         ymax = 38.995548
#'     ),
#'     crs = st_crs(4326)
#' )
#'
#' # Generate 30 random points within the bounding box
#' random_points <- st_as_sf(
#'     data.frame(
#'         id = 1:30,
#'         lon = runif(30, bbox["xmin"], bbox["xmax"]),
#'         lat = runif(30, bbox["ymin"], bbox["ymax"])
#'     ),
#'     coords = c("lon", "lat"),
#'     crs = 4326
#' )
#'
#' # Assign random categories
#' categories <- c("music", "bar", "theatre", "bicycle")
#' random_points <- random_points %>%
#'     mutate(category = sample(categories, n(), replace = TRUE))
#'
#' # Map with circle layer
#' mapboxgl(style = mapbox_style("light")) %>%
#'     fit_bounds(random_points, animate = FALSE) %>%
#'     add_circle_layer(
#'         id = "poi-layer",
#'         source = random_points,
#'         circle_color = match_expr(
#'             "category",
#'             values = c(
#'                 "music", "bar", "theatre",
#'                 "bicycle"
#'             ),
#'             stops = c(
#'                 "#1f78b4", "#33a02c",
#'                 "#e31a1c", "#ff7f00"
#'             )
#'         ),
#'         circle_radius = 8,
#'         circle_stroke_color = "#ffffff",
#'         circle_stroke_width = 2,
#'         circle_opacity = 0.8,
#'         tooltip = "category",
#'         hover_options = list(
#'             circle_radius = 12,
#'             circle_color = "#ffff99"
#'         )
#'     ) %>%
#'     add_categorical_legend(
#'         legend_title = "Points of Interest",
#'         values = c("Music", "Bar", "Theatre", "Bicycle"),
#'         colors = c("#1f78b4", "#33a02c", "#e31a1c", "#ff7f00"),
#'         circular_patches = TRUE
#'     )
#' }
add_circle_layer <- function(
  map,
  id,
  source,
  source_layer = NULL,
  circle_blur = NULL,
  circle_color = NULL,
  circle_emissive_strength = NULL,
  circle_opacity = NULL,
  circle_pitch_alignment = NULL,
  circle_pitch_scale = NULL,
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
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL,
  cluster_options = NULL
) {
  paint <- list()
  layout <- list()

  if (!is.null(circle_blur)) paint[["circle-blur"]] <- circle_blur
  if (!is.null(circle_color)) paint[["circle-color"]] <- circle_color
  if (!is.null(circle_emissive_strength))
    paint[["circle-emissive-strength"]] <- circle_emissive_strength
  if (!is.null(circle_opacity)) paint[["circle-opacity"]] <- circle_opacity
  if (!is.null(circle_pitch_alignment))
    paint[["circle-pitch-alignment"]] <- circle_pitch_alignment
  if (!is.null(circle_pitch_scale))
    paint[["circle-pitch-scale"]] <- circle_pitch_scale
  if (!is.null(circle_radius)) paint[["circle-radius"]] <- circle_radius
  if (!is.null(circle_stroke_color))
    paint[["circle-stroke-color"]] <- circle_stroke_color
  if (!is.null(circle_stroke_opacity))
    paint[["circle-stroke-opacity"]] <- circle_stroke_opacity
  if (!is.null(circle_stroke_width))
    paint[["circle-stroke-width"]] <- circle_stroke_width
  if (!is.null(circle_translate))
    paint[["circle-translate"]] <- circle_translate
  if (!is.null(circle_translate_anchor))
    paint[["circle-translate-anchor"]] <- circle_translate_anchor

  if (!is.null(circle_sort_key)) layout[["circle-sort-key"]] <- circle_sort_key
  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  if (!is.null(cluster_options)) {
    map <- .add_cluster_layers(
      map,
      id = id,
      source = source,
      source_layer = source_layer,
      cluster_options = cluster_options,
      point_type = "circle",
      paint = paint,
      layout = layout,
      visibility = visibility,
      circle_color = circle_color,
      popup = popup,
      tooltip = tooltip,
      tooltip_style = tooltip_style,
      popup_style = popup_style,
      hover_options = hover_options,
      slot = slot,
      min_zoom = min_zoom,
      max_zoom = max_zoom,
      before_id = before_id
    )
  } else {
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
      filter,
      tooltip_style = tooltip_style,
      popup_style = popup_style
    )
  }

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
#' @param raster_color Defines a color map for colorizing single-band raster data, parameterized by
#'   `["raster-value"]`. Use an interpolate expression over `raster-value` to define the color ramp.
#'   Requires `raster_color_range` to be set.
#' @param raster_color_mix Specifies the combination of source RGB channels used to compute the raster
#'   value when `raster_color` is active. A numeric vector of length 4: `c(r, g, b, offset)`.
#'   Defaults to `c(0.2126, 0.7152, 0.0722, 0)` (RGB luminosity).
#' @param raster_color_range Specifies the value range over which `raster_color` is tabulated.
#'   A numeric vector of length 2: `c(min, max)`.
#' @param raster_contrast Increase or reduce the brightness of the image.
#' @param raster_emissive_strength Controls the intensity of light emitted on the source features. Requires 3D lights.
#' @param raster_fade_duration The duration of the fade-in/fade-out effect.
#' @param raster_hue_rotate Rotates hues around the color wheel.
#' @param raster_opacity The opacity at which the raster will be drawn.
#' @param raster_resampling The resampling/interpolation method to use for overscaling. Options are `"linear"` (bilinear, the MapLibre/Mapbox default) and `"nearest"` (nearest-neighbor). Use `"nearest"` for categorical or classified rasters (e.g. land cover) to preserve crisp category boundaries when zooming.
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
#' mapboxgl(
#'     style = mapbox_style("dark"),
#'     zoom = 5,
#'     center = c(-75.789, 41.874)
#' ) |>
#'     add_image_source(
#'         id = "radar",
#'         url = "https://docs.mapbox.com/mapbox-gl-js/assets/radar.gif",
#'         coordinates = list(
#'             c(-80.425, 46.437),
#'             c(-71.516, 46.437),
#'             c(-71.516, 37.936),
#'             c(-80.425, 37.936)
#'         )
#'     ) |>
#'     add_raster_layer(
#'         id = "radar-layer",
#'         source = "radar",
#'         raster_fade_duration = 0
#'     )
#' }
add_raster_layer <- function(
  map,
  id,
  source,
  source_layer = NULL,
  raster_brightness_max = NULL,
  raster_brightness_min = NULL,
  raster_color = NULL,
  raster_color_mix = NULL,
  raster_color_range = NULL,
  raster_contrast = NULL,
  raster_emissive_strength = NULL,
  raster_fade_duration = NULL,
  raster_hue_rotate = NULL,
  raster_opacity = NULL,
  raster_resampling = NULL,
  raster_saturation = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  before_id = NULL
) {
  paint <- list()
  layout <- list()

  if (!is.null(raster_brightness_max))
    paint[["raster-brightness-max"]] <- raster_brightness_max
  if (!is.null(raster_brightness_min))
    paint[["raster-brightness-min"]] <- raster_brightness_min
  if (!is.null(raster_color)) paint[["raster-color"]] <- raster_color
  if (!is.null(raster_color_mix))
    paint[["raster-color-mix"]] <- raster_color_mix
  if (!is.null(raster_color_range))
    paint[["raster-color-range"]] <- raster_color_range
  if (!is.null(raster_contrast)) paint[["raster-contrast"]] <- raster_contrast
  if (!is.null(raster_emissive_strength))
    paint[["raster-emissive-strength"]] <- raster_emissive_strength
  if (!is.null(raster_fade_duration))
    paint[["raster-fade-duration"]] <- raster_fade_duration
  if (!is.null(raster_hue_rotate))
    paint[["raster-hue-rotate"]] <- raster_hue_rotate
  if (!is.null(raster_opacity)) paint[["raster-opacity"]] <- raster_opacity
  if (!is.null(raster_resampling))
    paint[["raster-resampling"]] <- raster_resampling
  if (!is.null(raster_saturation))
    paint[["raster-saturation"]] <- raster_saturation

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  map <- add_layer(
    map,
    id,
    "raster",
    source,
    source_layer,
    paint,
    layout,
    slot,
    min_zoom,
    max_zoom,
    before_id = before_id
  )

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
#' @param icon_image Name of image in sprite to use for drawing an image background.
#'        To use values in a column of your input dataset, use `get_column('YOUR_ICON_COLUMN_NAME')`.
#'        Images can also be loaded with the `add_image()` function which should precede the `add_symbol_layer()` function.
#' @param icon_image_cross_fade The cross-fade parameter for the icon image.
#' @param icon_keep_upright If TRUE, the icon will be kept upright.
#' @param icon_occlusion_opacity The opacity at which the icon will be drawn when occluded by 3D objects. Value between 0 and 1; 0 hides occluded icons.
#' @param icon_offset Offset distance of icon.
#' @param icon_opacity The opacity at which the icon will be drawn.
#' @param icon_optional If TRUE, the icon will be optional.
#' @param icon_padding Padding around the icon.
#' @param icon_pitch_alignment Alignment of the icon with respect to the pitch of the map.
#' @param icon_rotate Rotates the icon clockwise.
#' @param icon_rotation_alignment Alignment of the icon with respect to the map.
#' @param icon_size The size of the icon, specified relative to the original size
#'        of the image. For example, a value of 5 would make the icon
#'        5 times larger than the original size, whereas a value of 0.5 would
#'        make the icon half the size of the original.
#' @param icon_text_fit Scales the text to fit the icon.
#' @param icon_text_fit_padding Padding for text fitting the icon.
#' @param icon_translate The offset distance of the icon.
#' @param icon_translate_anchor Controls the frame of reference for `icon-translate`.
#' @param symbol_avoid_edges If TRUE, the symbol will be avoided when near the edges.
#' @param symbol_placement Placement of the symbol on the map.
#' @param symbol_sort_key Sorts features in ascending order based on this value.
#' @param symbol_spacing Spacing between symbols.
#' @param symbol_z_elevate If `TRUE`, positions the symbol on top of a `fill-extrusion` layer.
#'        Requires `symbol_placement` to be set to `"point"` and `symbol-z-order` to be set to `"auto"`.
#' @param symbol_z_offset The elevation of the symbol, in meters.  Use `get_column()` to get elevations from a column in the dataset.
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
#' @param text_occlusion_opacity The opacity at which the text will be drawn when occluded by 3D objects. Value between 0 and 1; 0 hides occluded text.
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
#' @param tooltip_style,popup_style Optional appearance for the tooltip/popup: a preset string (`"light"` or `"dark"`) or a [tooltip_style()] object. When omitted, the native (unstyled) appearance is kept.
#' @param hover_options A named list of options for highlighting features in the layer on hover. Not all elements of SVG icons can be styled.
#' @param before_id The name of the layer that this layer appears "before", allowing you to insert layers below other layers in your basemap (e.g. labels).
#' @param filter An optional filter expression to subset features in the layer.
#' @param cluster_options A list of options for clustering symbols, created by the `cluster_options()` function. Two input shapes are supported: pass an `sf`/`sfc` object as `source` for native live clustering (a GeoJSON source is injected automatically), or pass the id of an already-registered vector source (e.g. from `add_pmtiles_source()`) along with `source_layer` to use pre-clustered vector tiles such as those produced by the freestiler package. In the latter case the cluster-count label is abbreviated client-side from `point_count`. Set `donut_column` in `cluster_options()` to draw clusters as donut charts of category shares; see [cluster_options()] for the properties pre-clustered tiles need.
#'
#'   **Updating a clustered layer in Shiny:** the shortcut creates three layers (`"id"`, `"id-clusters"`, `"id-cluster-count"`) on top of one source. For reactive data updates the recommended pattern is [set_source()], which replaces the source's data and lets Mapbox/MapLibre re-cluster automatically without tearing down the layers: `mapboxgl_proxy("map") |> set_source(layer_id = "pts", source = filtered())`. If you need to remove a clustered layer entirely (e.g. before switching backends), pass the full trio to [clear_layer()]: `clear_layer(proxy, c("pts", "pts-clusters", "pts-cluster-count"))`.
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
#' bbox <- st_bbox(
#'     c(
#'         xmin = -77.119759,
#'         ymin = 38.791645,
#'         xmax = -76.909393,
#'         ymax = 38.995548
#'     ),
#'     crs = st_crs(4326)
#' )
#'
#' # Generate 30 random points within the bounding box
#' random_points <- st_as_sf(
#'     data.frame(
#'         id = 1:30,
#'         lon = runif(30, bbox["xmin"], bbox["xmax"]),
#'         lat = runif(30, bbox["ymin"], bbox["ymax"])
#'     ),
#'     coords = c("lon", "lat"),
#'     crs = 4326
#' )
#'
#' # Assign random icons
#' icons <- c("music", "bar", "theatre", "bicycle")
#' random_points <- random_points |>
#'     mutate(icon = sample(icons, n(), replace = TRUE))
#'
#' # Map with icons
#' mapboxgl(style = mapbox_style("light")) |>
#'     fit_bounds(random_points, animate = FALSE) |>
#'     add_symbol_layer(
#'         id = "points-of-interest",
#'         source = random_points,
#'         icon_image = c("get", "icon"),
#'         icon_allow_overlap = TRUE,
#'         tooltip = "icon"
#'     )
#' }
add_symbol_layer <- function(
  map,
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
  icon_occlusion_opacity = NULL,
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
  symbol_z_offset = NULL,
  symbol_z_order = NULL,
  text_allow_overlap = NULL,
  text_anchor = NULL,
  text_color = "black",
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
  text_occlusion_opacity = NULL,
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
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL,
  cluster_options = NULL
) {
  paint <- list()
  layout <- list()

  if (!is.null(icon_allow_overlap))
    layout[["icon-allow-overlap"]] <- icon_allow_overlap
  if (!is.null(icon_anchor)) layout[["icon-anchor"]] <- icon_anchor
  if (!is.null(icon_color)) paint[["icon-color"]] <- icon_color
  if (!is.null(icon_color_brightness_max))
    paint[["icon-color-brightness-max"]] <- icon_color_brightness_max
  if (!is.null(icon_color_brightness_min))
    paint[["icon-color-brightness-min"]] <- icon_color_brightness_min
  if (!is.null(icon_color_contrast))
    paint[["icon-color-contrast"]] <- icon_color_contrast
  if (!is.null(icon_color_saturation))
    paint[["icon-color-saturation"]] <- icon_color_saturation
  if (!is.null(icon_emissive_strength))
    paint[["icon-emissive-strength"]] <- icon_emissive_strength
  if (!is.null(icon_halo_blur)) paint[["icon-halo-blur"]] <- icon_halo_blur
  if (!is.null(icon_halo_color)) paint[["icon-halo-color"]] <- icon_halo_color
  if (!is.null(icon_halo_width)) paint[["icon-halo-width"]] <- icon_halo_width
  if (!is.null(icon_ignore_placement))
    layout[["icon-ignore-placement"]] <- icon_ignore_placement
  if (!is.null(icon_image)) layout[["icon-image"]] <- icon_image
  if (!is.null(icon_image_cross_fade))
    layout[["icon-image-cross-fade"]] <- icon_image_cross_fade
  if (!is.null(icon_keep_upright))
    layout[["icon-keep-upright"]] <- icon_keep_upright
  if (!is.null(icon_offset)) layout[["icon-offset"]] <- icon_offset
  if (!is.null(icon_occlusion_opacity))
    paint[["icon-occlusion-opacity"]] <- icon_occlusion_opacity
  if (!is.null(icon_opacity)) paint[["icon-opacity"]] <- icon_opacity
  if (!is.null(icon_optional)) layout[["icon-optional"]] <- icon_optional
  if (!is.null(icon_padding)) layout[["icon-padding"]] <- icon_padding
  if (!is.null(icon_pitch_alignment))
    layout[["icon-pitch-alignment"]] <- icon_pitch_alignment
  if (!is.null(icon_rotate)) layout[["icon-rotate"]] <- icon_rotate
  if (!is.null(icon_rotation_alignment))
    layout[["icon-rotation-alignment"]] <- icon_rotation_alignment
  if (!is.null(icon_size)) layout[["icon-size"]] <- icon_size
  if (!is.null(icon_text_fit)) layout[["icon-text-fit"]] <- icon_text_fit
  if (!is.null(icon_text_fit_padding))
    layout[["icon-text-fit-padding"]] <- icon_text_fit_padding
  if (!is.null(icon_translate)) paint[["icon-translate"]] <- icon_translate
  if (!is.null(icon_translate_anchor))
    paint[["icon-translate-anchor"]] <- icon_translate_anchor

  if (!is.null(symbol_avoid_edges))
    layout[["symbol-avoid-edges"]] <- symbol_avoid_edges
  if (!is.null(symbol_placement))
    layout[["symbol-placement"]] <- symbol_placement
  if (!is.null(symbol_sort_key)) layout[["symbol-sort-key"]] <- symbol_sort_key
  if (!is.null(symbol_spacing)) layout[["symbol-spacing"]] <- symbol_spacing
  if (!is.null(symbol_z_elevate))
    layout[["symbol-z-elevate"]] <- symbol_z_elevate
  if (!is.null(symbol_z_order)) layout[["symbol-z-order"]] <- symbol_z_order
  if (!is.null(symbol_z_offset)) paint[["symbol-z-offset"]] <- symbol_z_offset

  if (!is.null(text_allow_overlap))
    layout[["text-allow-overlap"]] <- text_allow_overlap
  if (!is.null(text_anchor)) layout[["text-anchor"]] <- text_anchor
  if (!is.null(text_color)) paint[["text-color"]] <- text_color
  if (!is.null(text_emissive_strength))
    paint[["text-emissive-strength"]] <- text_emissive_strength
  if (!is.null(text_field)) layout[["text-field"]] <- text_field
  if (!is.null(text_font)) layout[["text-font"]] <- text_font
  if (!is.null(text_halo_blur)) paint[["text-halo-blur"]] <- text_halo_blur
  if (!is.null(text_halo_color)) paint[["text-halo-color"]] <- text_halo_color
  if (!is.null(text_halo_width)) paint[["text-halo-width"]] <- text_halo_width
  if (!is.null(text_ignore_placement))
    layout[["text-ignore-placement"]] <- text_ignore_placement
  if (!is.null(text_justify)) layout[["text-justify"]] <- text_justify
  if (!is.null(text_keep_upright))
    layout[["text-keep-upright"]] <- text_keep_upright
  if (!is.null(text_letter_spacing))
    layout[["text-letter-spacing"]] <- text_letter_spacing
  if (!is.null(text_line_height))
    layout[["text-line-height"]] <- text_line_height
  if (!is.null(text_max_angle)) layout[["text-max-angle"]] <- text_max_angle
  if (!is.null(text_max_width)) layout[["text-max-width"]] <- text_max_width
  if (!is.null(text_offset)) layout[["text-offset"]] <- text_offset
  if (!is.null(text_occlusion_opacity))
    paint[["text-occlusion-opacity"]] <- text_occlusion_opacity
  if (!is.null(text_opacity)) paint[["text-opacity"]] <- text_opacity
  if (!is.null(text_optional)) layout[["text-optional"]] <- text_optional
  if (!is.null(text_padding)) layout[["text-padding"]] <- text_padding
  if (!is.null(text_pitch_alignment))
    layout[["text-pitch-alignment"]] <- text_pitch_alignment
  if (!is.null(text_radial_offset))
    layout[["text-radial-offset"]] <- text_radial_offset
  if (!is.null(text_rotate)) layout[["text-rotate"]] <- text_rotate
  if (!is.null(text_rotation_alignment))
    layout[["text-rotation-alignment"]] <- text_rotation_alignment
  if (!is.null(text_size)) layout[["text-size"]] <- text_size
  if (!is.null(text_transform)) layout[["text-transform"]] <- text_transform
  if (!is.null(text_translate)) paint[["text-translate"]] <- text_translate
  if (!is.null(text_translate_anchor))
    paint[["text-translate-anchor"]] <- text_translate_anchor
  if (!is.null(text_variable_anchor))
    layout[["text-variable-anchor"]] <- text_variable_anchor
  if (!is.null(text_writing_mode))
    layout[["text-writing-mode"]] <- text_writing_mode

  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  if (!is.null(cluster_options)) {
    map <- .add_cluster_layers(
      map,
      id = id,
      source = source,
      source_layer = source_layer,
      cluster_options = cluster_options,
      point_type = "symbol",
      paint = paint,
      layout = layout,
      visibility = visibility,
      popup = popup,
      tooltip = tooltip,
      tooltip_style = tooltip_style,
      popup_style = popup_style,
      hover_options = hover_options,
      slot = slot,
      min_zoom = min_zoom,
      max_zoom = max_zoom,
      before_id = before_id
    )
  } else {
    map <- add_layer(
      map,
      id,
      "symbol",
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
      filter,
      tooltip_style = tooltip_style,
      popup_style = popup_style
    )
  }

  return(map)
}
