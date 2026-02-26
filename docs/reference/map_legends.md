# Add legends to Mapbox GL and MapLibre GL maps

These functions add categorical and continuous legends to maps. Use
[`legend_style()`](https://walker-data.com/mapgl/reference/legend_style.md)
to customize appearance and
[`clear_legend()`](https://walker-data.com/mapgl/reference/clear_legend.md)
to remove legends.

## Usage

``` r
add_legend(
  map,
  legend_title,
  values = NULL,
  colors = NULL,
  type = c("continuous", "categorical"),
  circular_patches = FALSE,
  patch_shape = "square",
  position = "top-left",
  sizes = NULL,
  add = FALSE,
  unique_id = NULL,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  target = NULL,
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  classification = NULL,
  breaks = NULL,
  draggable = FALSE
)

add_categorical_legend(
  map,
  legend_title,
  values,
  colors,
  circular_patches = FALSE,
  patch_shape = "square",
  position = "top-left",
  unique_id = NULL,
  sizes = NULL,
  add = FALSE,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  breaks = NULL,
  draggable = FALSE
)

add_continuous_legend(
  map,
  legend_title,
  values,
  colors,
  position = "top-left",
  unique_id = NULL,
  add = FALSE,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  draggable = FALSE
)

# S3 method for class 'mapboxgl_compare'
add_legend(
  map,
  legend_title,
  values,
  colors,
  type = c("continuous", "categorical"),
  circular_patches = FALSE,
  patch_shape = "square",
  position = "top-left",
  sizes = NULL,
  add = FALSE,
  unique_id = NULL,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  target = "compare",
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  classification = NULL,
  breaks = NULL,
  draggable = FALSE
)

# S3 method for class 'maplibre_compare'
add_legend(
  map,
  legend_title,
  values,
  colors,
  type = c("continuous", "categorical"),
  circular_patches = FALSE,
  patch_shape = "square",
  position = "top-left",
  sizes = NULL,
  add = FALSE,
  unique_id = NULL,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  target = "compare",
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  classification = NULL,
  breaks = NULL,
  draggable = FALSE
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- legend_title:

  The title of the legend.

- values:

  The values being represented on the map (either a vector of categories
  or a vector of stops).

- colors:

  The corresponding colors for the values (either a vector of colors, a
  single color, or an interpolate function).

- type:

  One of "continuous" or "categorical" (for `add_legend` only).

- circular_patches:

  (Deprecated) Logical, whether to use circular patches in the legend.
  Use `patch_shape = "circle"` instead.

- patch_shape:

  Character or sf object, the shape of patches to use in categorical
  legends. Can be one of the built-in shapes ("square", "circle",
  "line", "hexagon"), a custom SVG string, or an sf object with POLYGON
  or MULTIPOLYGON geometry (which will be automatically converted to
  SVG). Default is "square".

- position:

  The position of the legend on the map (one of "top-left",
  "bottom-left", "top-right", "bottom-right").

- sizes:

  An optional numeric vector of sizes for the legend patches, or a
  single numeric value (only for categorical legends). For line patches,
  this controls the line thickness.

- add:

  Logical, whether to add this legend to existing legends (TRUE) or
  replace existing legends (FALSE). Default is FALSE.

- unique_id:

  Optional. A unique identifier for the legend. If not provided, a
  random ID will be generated.

- width:

  The width of the legend. Can be specified in pixels (e.g., "250px") or
  as "auto". Default is NULL, which uses the built-in default.

- layer_id:

  The ID of the layer that this legend is associated with. If provided,
  the legend will be shown/hidden when the layer visibility is toggled.

- margin_top:

  Custom top margin in pixels, allowing for fine control over legend
  positioning. Default is NULL (uses standard positioning).

- margin_right:

  Custom right margin in pixels. Default is NULL.

- margin_bottom:

  Custom bottom margin in pixels. Default is NULL.

- margin_left:

  Custom left margin in pixels. Default is NULL.

- style:

  Optional styling options created by
  [`legend_style()`](https://walker-data.com/mapgl/reference/legend_style.md)
  or a list of style options.

- target:

  For compare objects only: where to place the legend. Can be "compare"
  (attached to compare container, persists during swipe), "before"
  (attached to left/top map), or "after" (attached to right/bottom map).
  Default is "compare".

- interactive:

  Logical, whether to make the legend interactive. For categorical
  legends, clicking on legend items will toggle the visibility of the
  corresponding features. For continuous legends, a range slider will
  appear allowing users to filter features by value. Default is FALSE.
  Note: interactive legends are not yet supported for compare maps.

- filter_column:

  Character, the name of the data column to use for filtering when
  interactive is TRUE. If NULL (default), the column will be
  auto-detected from the layer's paint expression.

- filter_values:

  For interactive legends, the actual data values to filter on. For
  categorical legends, use this when your display labels differ from the
  data values (e.g., values = c("Music", "Bar") for display,
  filter_values = c("music", "bar") for filtering). For continuous
  legends, provide numeric break values when using formatted display
  labels (e.g., values = get_legend_labels(scale), filter_values =
  get_breaks(scale)). If NULL (default), uses values.

- classification:

  A mapgl_classification object (from step_quantile,
  step_equal_interval, etc.) to use for the legend. When provided,
  values and colors will be automatically extracted. For interactive
  legends, range-based filtering will be used based on the
  classification breaks.

- breaks:

  Numeric vector of break points for filtering with classification-based
  legends. Typically extracted automatically from the classification
  object. Only needed if you want to override the default breaks.

- draggable:

  Logical, whether the legend can be dragged to a new position by the
  user. Default is FALSE.

## Value

The updated map object with the legend added.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic categorical legend
add_legend(map, "Population",
          values = c("Low", "Medium", "High"),
          colors = c("blue", "yellow", "red"),
          type = "categorical")

# Continuous legend with custom styling
add_legend(map, "Income",
          values = c(0, 50000, 100000),
          colors = c("blue", "yellow", "red"),
          type = "continuous",
          style = list(
            background_color = "white",
            background_opacity = 0.9,
            border_width = 2,
            border_color = "navy",
            text_color = "darkblue",
            font_family = "Times New Roman",
            title_font_weight = "bold"
          ))

# Legend with custom styling using a list
add_legend(map, "Temperature",
          values = c(0, 50, 100),
          colors = c("blue", "yellow", "red"),
          type = "continuous",
          style = list(
            background_color = "#f0f0f0",
            title_size = 16,
            text_size = 12,
            shadow = TRUE,
            shadow_color = "rgba(0,0,0,0.1)",
            shadow_size = 8
          ))

# Dark legend with white element borders
add_legend(map, "Elevation",
          values = c(0, 1000, 2000, 3000),
          colors = c("#2c7bb6", "#abd9e9", "#fdae61", "#d7191c"),
          type = "continuous",
          style = list(
            background_color = "#2c3e50",
            text_color = "white",
            title_color = "white",
            element_border_color = "white",
            element_border_width = 1
          ))

# Categorical legend with circular patches
add_categorical_legend(
    map = map,
    legend_title = "Population",
    values = c("Low", "Medium", "High"),
    colors = c("#FED976", "#FEB24C", "#FD8D3C"),
    patch_shape = "circle",
    sizes = c(10, 15, 20),
    style = list(
      background_opacity = 0.95,
      border_width = 1,
      border_color = "gray",
      title_color = "navy",
      element_border_color = "black",
      element_border_width = 1
    )
)

# Legend with line patches for line layers
add_categorical_legend(
    map = map,
    legend_title = "Road Type",
    values = c("Highway", "Primary", "Secondary"),
    colors = c("#000000", "#333333", "#666666"),
    patch_shape = "line",
    sizes = c(5, 3, 1)  # Line thickness in pixels
)

# Legend with hexagon patches (e.g., for H3 data)
add_categorical_legend(
    map = map,
    legend_title = "H3 Hexagon Categories",
    values = c("Urban", "Suburban", "Rural"),
    colors = c("#8B0000", "#FF6347", "#90EE90"),
    patch_shape = "hexagon",
    sizes = 25
)

# Custom SVG shapes - star
add_categorical_legend(
    map = map,
    legend_title = "Ratings",
    values = c("5 Star", "4 Star", "3 Star"),
    colors = c("#FFD700", "#FFA500", "#FF6347"),
    patch_shape = paste0('<path d="M50,5 L61,35 L95,35 L68,57 L79,91 L50,70 ',
                         'L21,91 L32,57 L5,35 L39,35 Z" />')
)

# Using sf objects directly as patch shapes
library(sf)
nc <- st_read(system.file("shape/nc.shp", package = "sf"))
county_shape <- nc[1, ]  # Get first county

add_categorical_legend(
    map = map,
    legend_title = "County Types",
    values = c("Rural", "Urban", "Suburban"),
    colors = c("#228B22", "#8B0000", "#FFD700"),
    patch_shape = county_shape  # sf object automatically converted to SVG
)

# For advanced users needing custom conversion options
custom_svg <- mapgl:::.sf_to_svg(county_shape, simplify = TRUE,
                                  tolerance = 0.001, fit_viewbox = TRUE)
add_categorical_legend(
    map = map,
    legend_title = "Custom Converted Shape",
    values = c("Type A"),
    colors = c("#4169E1"),
    patch_shape = custom_svg
)

# Compare view legends
compare_view <- compare(map1, map2)

# Add persistent legend (stays visible during swipe)
compare_view |>
  add_legend("Persistent Legend",
            values = c("Low", "High"),
            colors = c("blue", "red"),
            type = "categorical",
            target = "compare",
            position = "top-left")

# Add legends to specific maps
compare_view |>
  add_legend("Left Map",
            values = c("A", "B"),
            colors = c("green", "orange"),
            type = "categorical",
            target = "before",
            position = "bottom-left") |>
  add_legend("Right Map",
            values = c("X", "Y"),
            colors = c("purple", "yellow"),
            type = "categorical",
            target = "after",
            position = "bottom-right")

} # }
```
