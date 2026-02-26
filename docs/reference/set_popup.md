# Set popup on a map layer

Set popup on a map layer

## Usage

``` r
set_popup(map, layer_id = NULL, popup, layer = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to update.

- popup:

  The name of the popup property or an expression to set.

- layer:

  Deprecated. Use `layer_id` instead.

## Value

The updated map object.
