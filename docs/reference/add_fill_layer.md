# Add a fill layer to a map

Add a fill layer to a map

## Usage

``` r
add_fill_layer(
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
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
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

- fill_antialias:

  Whether or not the fill should be antialiased.

- fill_color:

  The color of the filled part of this layer.

- fill_emissive_strength:

  Controls the intensity of light emitted on the source features.

- fill_opacity:

  The opacity of the entire fill layer.

- fill_outline_color:

  The outline color of the fill.

- fill_pattern:

  Name of image in sprite to use for drawing image fills.

- fill_sort_key:

  Sorts features in ascending order based on this value.

- fill_translate:

  The geometry's offset. Values are `c(x, y)` where negatives indicate
  left and up.

- fill_translate_anchor:

  Controls the frame of reference for `fill-translate`.

- fill_z_offset:

  Specifies an uniform elevation in meters.

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
  hover.

- before_id:

  The name of the layer that this layer appears "before", allowing you
  to insert layers below other layers in your basemap (e.g. labels).

- filter:

  An optional filter expression to subset features in the layer.

## Value

The modified map object with the new fill layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(tidycensus)

fl_age <- get_acs(
    geography = "tract",
    variables = "B01002_001",
    state = "FL",
    year = 2022,
    geometry = TRUE
)

mapboxgl() |>
    fit_bounds(fl_age, animate = FALSE) |>
    add_fill_layer(
        id = "fl_tracts",
        source = fl_age,
        fill_color = interpolate(
            column = "estimate",
            values = c(20, 80),
            stops = c("lightblue", "darkblue"),
            na_color = "lightgrey"
        ),
        fill_opacity = 0.5
    )
} # }
```
