# Add a fullscreen control to a map

Add a fullscreen control to a map

## Usage

``` r
add_fullscreen_control(map, position = "top-right")
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  A string specifying the position of the fullscreen control. One of
  "top-right", "top-left", "bottom-right", or "bottom-left".

## Value

The modified map object with the fullscreen control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

maplibre(
    style = maptiler_style("streets"),
    center = c(11.255, 43.77),
    zoom = 13
) |>
    add_fullscreen_control(position = "top-right")
} # }
```
