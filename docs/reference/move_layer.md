# Move a layer to a different z-position

This function allows a layer to be moved to a different z-position in a
Mapbox GL or Maplibre GL map. For initial maps, the operation is queued
and executed during map initialization. For proxy objects, the operation
is executed immediately.

## Usage

``` r
move_layer(map, layer_id, before_id = NULL)
```

## Arguments

- map:

  A map object created by `mapboxgl` or `maplibre`, or a proxy object
  created by `mapboxgl_proxy` or `maplibre_proxy`.

- layer_id:

  The ID of the layer to move.

- before_id:

  The ID of an existing layer to insert the new layer before.
  **Important**: this means that the layer will appear *immediately
  behind* the layer defined in `before_id`. If omitted, the layer will
  be appended to the end of the layers array and appear above all other
  layers.

## Value

The updated map or proxy object.
