# Set a layout property on a map layer

Set a layout property on a map layer

## Usage

``` r
set_layout_property(map, layer_id = NULL, name, value, layer = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to update.

- name:

  The name of the layout property to set.

- value:

  The value to set the property to.

- layer:

  Deprecated. Use `layer_id` instead.

## Value

The updated map object.
