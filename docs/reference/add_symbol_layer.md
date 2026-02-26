# Add a symbol layer to a map

Add a symbol layer to a map

## Usage

``` r
add_symbol_layer(
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
  filter = NULL,
  cluster_options = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- id:

  A unique ID for the layer.

- source:

  The ID of the source, alternatively an sf object (which will be
  converted to a GeoJSON source) or a named list that specifies `type`
  and `url` for a remote source.

- source_layer:

  The source layer (for vector sources).

- icon_allow_overlap:

  If TRUE, the icon will be visible even if it collides with other
  previously drawn symbols.

- icon_anchor:

  Part of the icon placed closest to the anchor.

- icon_color:

  The color of the icon. This is not supported for many Mapbox icons;
  read more at
  <https://docs.mapbox.com/help/troubleshooting/using-recolorable-images-in-mapbox-maps/>.

- icon_color_brightness_max:

  The maximum brightness of the icon color.

- icon_color_brightness_min:

  The minimum brightness of the icon color.

- icon_color_contrast:

  The contrast of the icon color.

- icon_color_saturation:

  The saturation of the icon color.

- icon_emissive_strength:

  The strength of the icon's emissive color.

- icon_halo_blur:

  The blur applied to the icon's halo.

- icon_halo_color:

  The color of the icon's halo.

- icon_halo_width:

  The width of the icon's halo.

- icon_ignore_placement:

  If TRUE, the icon will be visible even if it collides with other
  symbols.

- icon_image:

  Name of image in sprite to use for drawing an image background. To use
  values in a column of your input dataset, use
  `get_column('YOUR_ICON_COLUMN_NAME')`. Images can also be loaded with
  the
  [`add_image()`](https://walker-data.com/mapgl/reference/add_image.md)
  function which should precede the `add_symbol_layer()` function.

- icon_image_cross_fade:

  The cross-fade parameter for the icon image.

- icon_keep_upright:

  If TRUE, the icon will be kept upright.

- icon_offset:

  Offset distance of icon.

- icon_opacity:

  The opacity at which the icon will be drawn.

- icon_optional:

  If TRUE, the icon will be optional.

- icon_padding:

  Padding around the icon.

- icon_pitch_alignment:

  Alignment of the icon with respect to the pitch of the map.

- icon_rotate:

  Rotates the icon clockwise.

- icon_rotation_alignment:

  Alignment of the icon with respect to the map.

- icon_size:

  The size of the icon, specified relative to the original size of the
  image. For example, a value of 5 would make the icon 5 times larger
  than the original size, whereas a value of 0.5 would make the icon
  half the size of the original.

- icon_text_fit:

  Scales the text to fit the icon.

- icon_text_fit_padding:

  Padding for text fitting the icon.

- icon_translate:

  The offset distance of the icon.

- icon_translate_anchor:

  Controls the frame of reference for `icon-translate`.

- symbol_avoid_edges:

  If TRUE, the symbol will be avoided when near the edges.

- symbol_placement:

  Placement of the symbol on the map.

- symbol_sort_key:

  Sorts features in ascending order based on this value.

- symbol_spacing:

  Spacing between symbols.

- symbol_z_elevate:

  If `TRUE`, positions the symbol on top of a `fill-extrusion` layer.
  Requires `symbol_placement` to be set to `"point"` and
  `symbol-z-order` to be set to `"auto"`.

- symbol_z_offset:

  The elevation of the symbol, in meters. Use
  [`get_column()`](https://walker-data.com/mapgl/reference/get_column.md)
  to get elevations from a column in the dataset.

- symbol_z_order:

  Orders the symbol z-axis.

- text_allow_overlap:

  If TRUE, the text will be visible even if it collides with other
  previously drawn symbols.

- text_anchor:

  Part of the text placed closest to the anchor.

- text_color:

  The color of the text.

- text_emissive_strength:

  The strength of the text's emissive color.

- text_field:

  Value to use for a text label.

- text_font:

  Font stack to use for displaying text.

- text_halo_blur:

  The blur applied to the text's halo.

- text_halo_color:

  The color of the text's halo.

- text_halo_width:

  The width of the text's halo.

- text_ignore_placement:

  If TRUE, the text will be visible even if it collides with other
  symbols.

- text_justify:

  The justification of the text.

- text_keep_upright:

  If TRUE, the text will be kept upright.

- text_letter_spacing:

  Spacing between text letters.

- text_line_height:

  Height of the text lines.

- text_max_angle:

  Maximum angle of the text.

- text_max_width:

  Maximum width of the text.

- text_offset:

  Offset distance of text.

- text_opacity:

  The opacity at which the text will be drawn.

- text_optional:

  If TRUE, the text will be optional.

- text_padding:

  Padding around the text.

- text_pitch_alignment:

  Alignment of the text with respect to the pitch of the map.

- text_radial_offset:

  Radial offset of the text.

- text_rotate:

  Rotates the text clockwise.

- text_rotation_alignment:

  Alignment of the text with respect to the map.

- text_size:

  The size of the text.

- text_transform:

  Transform applied to the text.

- text_translate:

  The offset distance of the text.

- text_translate_anchor:

  Controls the frame of reference for `text-translate`.

- text_variable_anchor:

  Variable anchor for the text.

- text_writing_mode:

  Writing mode for the text.

- visibility:

  Whether this layer is displayed.

- slot:

  An optional slot for layer order.

- min_zoom:

  The minimum zoom level for the layer.

- max_zoom:

  The maximum zoom level for the layer.

- popup:

  A column name containing information to display in a popup on click.
  Columns containing HTML will be parsed.

- tooltip:

  A column name containing information to display in a tooltip on hover.
  Columns containing HTML will be parsed.

- hover_options:

  A named list of options for highlighting features in the layer on
  hover. Not all elements of SVG icons can be styled.

- before_id:

  The name of the layer that this layer appears "before", allowing you
  to insert layers below other layers in your basemap (e.g. labels).

- filter:

  An optional filter expression to subset features in the layer.

- cluster_options:

  A list of options for clustering symbols, created by the
  [`cluster_options()`](https://walker-data.com/mapgl/reference/cluster_options.md)
  function.

## Value

The modified map object with the new symbol layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)
library(sf)
library(dplyr)

# Set seed for reproducibility
set.seed(1234)

# Define the bounding box for Washington DC (approximately)
bbox <- st_bbox(
    c(
        xmin = -77.119759,
        ymin = 38.791645,
        xmax = -76.909393,
        ymax = 38.995548
    ),
    crs = st_crs(4326)
)

# Generate 30 random points within the bounding box
random_points <- st_as_sf(
    data.frame(
        id = 1:30,
        lon = runif(30, bbox["xmin"], bbox["xmax"]),
        lat = runif(30, bbox["ymin"], bbox["ymax"])
    ),
    coords = c("lon", "lat"),
    crs = 4326
)

# Assign random icons
icons <- c("music", "bar", "theatre", "bicycle")
random_points <- random_points |>
    mutate(icon = sample(icons, n(), replace = TRUE))

# Map with icons
mapboxgl(style = mapbox_style("light")) |>
    fit_bounds(random_points, animate = FALSE) |>
    add_symbol_layer(
        id = "points-of-interest",
        source = random_points,
        icon_image = c("get", "icon"),
        icon_allow_overlap = TRUE,
        tooltip = "icon"
    )
} # }
```
