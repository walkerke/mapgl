# Add a reset control to a map

This function adds a reset control to a Mapbox GL or MapLibre GL map.
The reset control allows users to return to the original zoom level and
center.

## Usage

``` r
add_reset_control(map, position = "top-right", animate = TRUE, duration = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "top-right".

- animate:

  Whether or not to animate the transition to the original map view;
  defaults to `TRUE`. If `FALSE`, the view will "jump" to the original
  view with no transition.

- duration:

  The length of the transition from the current view to the original
  view, specified in milliseconds. This argument only works with
  `animate` is `TRUE`.

## Value

The modified map object with the reset control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl() |>
    add_reset_control(position = "top-left")
} # }
```
