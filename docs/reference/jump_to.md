# Jump to a given view

Jump to a given view

## Usage

``` r
jump_to(map, center, zoom = NULL, ...)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function or a
  proxy object.

- center:

  A numeric vector of length 2 specifying the target center of the map
  (longitude, latitude).

- zoom:

  The target zoom level.

- ...:

  Additional named arguments for jumping to the view.

## Value

The updated map object.
