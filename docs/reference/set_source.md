# Set source of a map layer

Set source of a map layer

## Usage

``` r
set_source(map, layer_id = NULL, source, layer = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to update.

- source:

  An sf object (which will be converted to a GeoJSON source).

- layer:

  Deprecated. Use `layer_id` instead.

## Value

The updated map object.
