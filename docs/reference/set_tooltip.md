# Set tooltip on a map layer

Set tooltip on a map layer

## Usage

``` r
set_tooltip(map, layer_id = NULL, tooltip, layer = NULL, style = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to update.

- tooltip:

  Tooltip content: a column name, a `{brace}` template, or a
  [`concat()`](https://walker-data.com/mapgl/reference/concat.md)/[`number_format()`](https://walker-data.com/mapgl/reference/number_format.md)
  expression.

- layer:

  Deprecated. Use `layer_id` instead.

- style:

  Optional tooltip appearance: a preset string (`"light"` or `"dark"`)
  or a
  [`tooltip_style()`](https://walker-data.com/mapgl/reference/tooltip_style.md)
  object.

## Value

The updated map object.
