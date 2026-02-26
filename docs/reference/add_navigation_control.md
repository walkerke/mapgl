# Add a navigation control to a map

Add a navigation control to a map

## Usage

``` r
add_navigation_control(
  map,
  show_compass = TRUE,
  show_zoom = TRUE,
  visualize_pitch = FALSE,
  position = "top-right",
  orientation = "vertical"
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- show_compass:

  Whether to show the compass button.

- show_zoom:

  Whether to show the zoom-in and zoom-out buttons.

- visualize_pitch:

  Whether to visualize the pitch by rotating the X-axis of the compass.

- position:

  The position on the map where the control will be added. Possible
  values are "top-left", "top-right", "bottom-left", and "bottom-right".

- orientation:

  The orientation of the navigation control. Can be "vertical" (default)
  or "horizontal".

## Value

The updated map object with the navigation control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl() |>
    add_navigation_control(visualize_pitch = TRUE)
} # }
```
