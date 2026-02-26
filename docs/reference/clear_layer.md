# Clear layers from a map using a proxy

This function allows one or more layers to be removed from an existing
Mapbox GL map using a proxy object.

## Usage

``` r
clear_layer(proxy, layer_id)
```

## Arguments

- proxy:

  A proxy object created by `mapboxgl_proxy` or `maplibre_proxy`.

- layer_id:

  A character vector of layer IDs to be removed. Can be a single layer
  ID or multiple layer IDs.

## Value

The updated proxy object.
