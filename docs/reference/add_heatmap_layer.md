# Add a heatmap layer to a Mapbox GL map

Add a heatmap layer to a Mapbox GL map

## Usage

``` r
add_heatmap_layer(
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

- heatmap_color:

  The color of the heatmap points.

- heatmap_intensity:

  The intensity of the heatmap points.

- heatmap_opacity:

  The opacity of the heatmap layer.

- heatmap_radius:

  The radius of influence of each individual heatmap point.

- heatmap_weight:

  The weight of each individual heatmap point.

- visibility:

  Whether this layer is displayed.

- slot:

  An optional slot for layer order.

- min_zoom:

  The minimum zoom level for the layer.

- max_zoom:

  The maximum zoom level for the layer.

- before_id:

  The name of the layer that this layer appears "before", allowing you
  to insert layers below other layers in your basemap (e.g. labels).

- filter:

  An optional filter expression to subset features in the layer.

## Value

The modified map object with the new heatmap layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl(
    style = mapbox_style("dark"),
    center = c(-120, 50),
    zoom = 2
) |>
    add_heatmap_layer(
        id = "earthquakes-heat",
        source = list(
            type = "geojson",
            data = "https://docs.mapbox.com/mapbox-gl-js/assets/earthquakes.geojson"
        ),
        heatmap_weight = interpolate(
            column = "mag",
            values = c(0, 6),
            stops = c(0, 1)
        ),
        heatmap_intensity = interpolate(
            property = "zoom",
            values = c(0, 9),
            stops = c(1, 3)
        ),
        heatmap_color = interpolate(
            property = "heatmap-density",
            values = seq(0, 1, 0.2),
            stops = c(
                "rgba(33,102,172,0)", "rgb(103,169,207)",
                "rgb(209,229,240)", "rgb(253,219,199)",
                "rgb(239,138,98)", "rgb(178,24,43)"
            )
        ),
        heatmap_opacity = 0.7
    )
} # }
```
