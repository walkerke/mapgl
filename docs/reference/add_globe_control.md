# Add a globe control to a map

This function adds a globe control to a MapLibre GL map that allows
toggling between "mercator" and "globe" projections with a single click.

## Usage

``` r
add_globe_control(map, position = "top-right")
```

## Arguments

- map:

  A map object created by the `maplibre` function.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "top-right".

## Value

The modified map object with the globe control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

maplibre() |>
    add_globe_control(position = "top-right")
} # }
```
