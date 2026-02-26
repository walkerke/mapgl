# Set tooltip on a map layer

Set tooltip on a map layer

## Usage

``` r
set_tooltip(map, layer_id = NULL, tooltip, layer = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to update.

- tooltip:

  The name of the tooltip to set.

- layer:

  Deprecated. Use `layer_id` instead.

## Value

The updated map object.
