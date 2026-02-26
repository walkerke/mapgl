# Add a fill-extrusion layer to a Mapbox GL map

Add a fill-extrusion layer to a Mapbox GL map

## Usage

``` r
add_fill_extrusion_layer(
  map,
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
  filter = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function.

- id:

  A unique ID for the layer.

- source:

  The ID of the source, alternatively an sf object (which will be
  converted to a GeoJSON source) or a named list that specifies `type`
  and `url` for a remote source.

- source_layer:

  The source layer (for vector sources).

- fill_extrusion_base:

  The base height of the fill extrusion.

- fill_extrusion_color:

  The color of the fill extrusion.

- fill_extrusion_height:

  The height of the fill extrusion.

- fill_extrusion_opacity:

  The opacity of the fill extrusion.

- fill_extrusion_pattern:

  Name of image in sprite to use for drawing image fills.

- fill_extrusion_translate:

  The geometry's offset. Values are `c(x, y)` where negatives indicate
  left and up.

- fill_extrusion_translate_anchor:

  Controls the frame of reference for `fill-extrusion-translate`.

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

The modified map object with the new fill-extrusion layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

maplibre(
    style = maptiler_style("basic"),
    center = c(-74.0066, 40.7135),
    zoom = 15.5,
    pitch = 45,
    bearing = -17.6
) |>
    add_vector_source(
        id = "openmaptiles",
        url = paste0(
            "https://api.maptiler.com/tiles/v3/tiles.json?key=",
            Sys.getenv("MAPTILER_API_KEY")
        )
    ) |>
    add_fill_extrusion_layer(
        id = "3d-buildings",
        source = "openmaptiles",
        source_layer = "building",
        fill_extrusion_color = interpolate(
            column = "render_height",
            values = c(0, 200, 400),
            stops = c("lightgray", "royalblue", "lightblue")
        ),
        fill_extrusion_height = list(
            "interpolate",
            list("linear"),
            list("zoom"),
            15,
            0,
            16,
            list("get", "render_height")
        )
    )
} # }
```
