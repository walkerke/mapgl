# Add a scale control to a map

This function adds a scale control to a Mapbox GL or Maplibre GL map.

## Usage

``` r
add_scale_control(
  map,
  position = "bottom-left",
  unit = "metric",
  max_width = 100
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "bottom-left".

- unit:

  The unit of the scale. Can be either "imperial", "metric", or
  "nautical". Default is "metric".

- max_width:

  The maximum length of the scale control in pixels. Default is 100.

## Value

The modified map object with the scale control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl() |>
    add_scale_control(position = "bottom-right", unit = "imperial")
} # }
```
