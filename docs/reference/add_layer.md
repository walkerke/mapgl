# Add a layer to a map from a source

In many cases, you will use `add_layer()` internal to other
layer-specific functions in mapgl. Advanced users will want to use
`add_layer()` for more fine-grained control over the appearance of their
layers.

## Usage

``` r
add_layer(
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
  filter = NULL
)
```

## Arguments

- map:

  A map object created by the
  [`mapboxgl()`](https://walker-data.com/mapgl/reference/mapboxgl.md) or
  [`maplibre()`](https://walker-data.com/mapgl/reference/maplibre.md)
  functions.

- id:

  A unique ID for the layer.

- type:

  The type of the layer (e.g., "fill", "line", "circle").

- source:

  The ID of the source, alternatively an sf object (which will be
  converted to a GeoJSON source) or a named list that specifies `type`
  and `url` for a remote source.

- source_layer:

  The source layer (for vector sources).

- paint:

  A list of paint properties for the layer.

- layout:

  A list of layout properties for the layer.

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

The modified map object with the new layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
# Load necessary libraries
library(mapgl)
library(tigris)

# Load geojson data for North Carolina tracts
nc_tracts <- tracts(state = "NC", cb = TRUE)

# Create a Mapbox GL map
map <- mapboxgl(
    style = mapbox_style("light"),
    center = c(-79.0193, 35.7596),
    zoom = 7
)

# Add a source and fill layer for North Carolina tracts
map %>%
    add_source(
        id = "nc-tracts",
        data = nc_tracts
    ) %>%
    add_layer(
        id = "nc-layer",
        type = "fill",
        source = "nc-tracts",
        paint = list(
            "fill-color" = "#888888",
            "fill-opacity" = 0.4
        )
    )
} # }
```
