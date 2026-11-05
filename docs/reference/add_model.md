# Add a 3D model to a Mapbox GL map

Registers a glTF or GLB model with the map so that
[`add_model_layer()`](https://walker-data.com/mapgl/reference/add_model_layer.md)
can draw it. Mapbox GL JS only; MapLibre has no model layer.

## Usage

``` r
add_model(map, id, url)
```

## Arguments

- map:

  A map object created by
  [`mapboxgl()`](https://walker-data.com/mapgl/reference/mapboxgl.md),
  or a proxy created by
  [`mapboxgl_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_proxy.md).

- id:

  A string; the model ID that `model_id` in
  [`add_model_layer()`](https://walker-data.com/mapgl/reference/add_model_layer.md)
  refers to.

- url:

  The URL of a `.glb` or `.gltf` file, or the path to a local `.glb`
  file, which is embedded in the map as a data URI. A local `.gltf` file
  that refers to external buffers or textures can't be embedded; convert
  it to `.glb` first.

## Value

The modified map object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

turbines <- sf::st_as_sf(
  data.frame(lon = c(-100.40, -100.41), lat = c(32.30, 32.31)),
  coords = c("lon", "lat"), crs = 4326
)

mapboxgl(center = c(-100.405, 32.305), zoom = 15, pitch = 70) |>
  add_model("turbine", "turbine.glb") |>
  add_model_layer("turbines", turbines, model_id = "turbine")
} # }
```
