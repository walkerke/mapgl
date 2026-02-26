# Add a geolocate control to a map

This function adds a Geolocate control to a Mapbox GL or MapLibre GL
map. The geolocate control allows users to track their current location
on the map.

## Usage

``` r
add_geolocate_control(
  map,
  position = "top-right",
  track_user = FALSE,
  show_accuracy_circle = TRUE,
  show_user_location = TRUE,
  show_user_heading = FALSE,
  fit_bounds_options = list(maxZoom = 15),
  position_options = list(enableHighAccuracy = FALSE, timeout = 6000)
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "top-right".

- track_user:

  Whether to actively track the user's location. If TRUE, the map will
  continuously update as the user moves. Default is FALSE.

- show_accuracy_circle:

  Whether to show a circle indicating the accuracy of the location.
  Default is TRUE.

- show_user_location:

  Whether to show a dot at the user's location. Default is TRUE.

- show_user_heading:

  Whether to show an arrow indicating the device's heading when tracking
  location. Only works when track_user is TRUE. Default is FALSE.

- fit_bounds_options:

  A list of options for fitting bounds when panning to the user's
  location. Default maxZoom is 15.

- position_options:

  A list of Geolocation API position options. Default has
  enableHighAccuracy=FALSE and timeout=6000.

## Value

The modified map object with the geolocate control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl() |>
    add_geolocate_control(
        position = "top-right",
        track_user = TRUE,
        show_user_heading = TRUE
    )
} # }
```
