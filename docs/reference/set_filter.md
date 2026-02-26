# Set a filter on a map layer

This function sets a filter on a map layer, working with both regular
map objects and proxy objects.

## Usage

``` r
set_filter(map, layer_id, filter)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to which the filter will be applied.

- filter:

  The filter expression to apply.

## Value

The updated map object.
