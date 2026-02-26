# Clear controls from a Mapbox GL or Maplibre GL map in a Shiny app

This function allows you to remove specific controls or all controls
from a map. You can target controls by their type names, which
correspond to the function names used to add them (e.g., "navigation"
for controls added with `add_navigation_control`).

## Usage

``` r
clear_controls(map, controls = NULL)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- controls:

  A character vector of control types to remove, or NULL to remove all
  controls. Control types include: "navigation", "draw", "fullscreen",
  "scale", "geolocate", "geocoder", "layers", "reset", "globe_minimap",
  or custom control IDs. If NULL (default), all controls will be
  removed.

## Value

The modified map object with specified controls removed.

## Examples

``` r
if (FALSE) { # \dontrun{
library(shiny)
library(mapgl)

# Clear all controls
maplibre_proxy("map") |>
  clear_controls()

# Clear specific controls
maplibre_proxy("map") |>
  clear_controls("navigation")

# Clear multiple controls
maplibre_proxy("map") |>
  clear_controls(c("draw", "navigation"))

# Clear a custom control by ID
maplibre_proxy("map") |>
  clear_controls("my_custom_control")
} # }
```
