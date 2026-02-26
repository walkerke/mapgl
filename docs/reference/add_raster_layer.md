# Add a raster layer to a Mapbox GL map

Add a raster layer to a Mapbox GL map

## Usage

``` r
add_raster_layer(
  map,
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
  before_id = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function.

- id:

  A unique ID for the layer.

- source:

  The ID of the source.

- source_layer:

  The source layer (for vector sources).

- raster_brightness_max:

  The maximum brightness of the image.

- raster_brightness_min:

  The minimum brightness of the image.

- raster_contrast:

  Increase or reduce the brightness of the image.

- raster_fade_duration:

  The duration of the fade-in/fade-out effect.

- raster_hue_rotate:

  Rotates hues around the color wheel.

- raster_opacity:

  The opacity at which the raster will be drawn.

- raster_resampling:

  The resampling/interpolation method to use for overscaling.

- raster_saturation:

  Increase or reduce the saturation of the image.

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

## Value

The modified map object with the new raster layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
mapboxgl(
    style = mapbox_style("dark"),
    zoom = 5,
    center = c(-75.789, 41.874)
) |>
    add_image_source(
        id = "radar",
        url = "https://docs.mapbox.com/mapbox-gl-js/assets/radar.gif",
        coordinates = list(
            c(-80.425, 46.437),
            c(-71.516, 46.437),
            c(-71.516, 37.936),
            c(-80.425, 37.936)
        )
    ) |>
    add_raster_layer(
        id = "radar-layer",
        source = "radar",
        raster_fade_duration = 0
    )
} # }
```
