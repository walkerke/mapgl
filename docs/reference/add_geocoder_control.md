# Add a geocoder control to a map

This function adds a Geocoder search bar to a Mapbox GL or MapLibre GL
map. By default, a marker will be added at the selected location and the
map will fly to that location. The results of the geocode are accessible
in a Shiny session at `input$MAPID_geocoder$result`, where `MAPID` is
the name of your map.

## Usage

``` r
add_geocoder_control(
  map,
  position = "top-right",
  placeholder = "Search",
  collapsed = FALSE,
  provider = NULL,
  maptiler_api_key = NULL,
  ...
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "top-right".

- placeholder:

  A string to use as placeholder text for the search bar. Default is
  "Search".

- collapsed:

  Whether the control should be collapsed until hovered or clicked.
  Default is FALSE.

- provider:

  The geocoding provider to use for MapLibre maps. Either "osm" for
  OpenStreetMap/Nominatim or "maptiler" for MapTiler geocoding. If NULL
  (default), MapLibre maps will use "osm". Mapbox maps will always use
  the Mapbox geocoder, regardless of this parameter.

- maptiler_api_key:

  Your MapTiler API key (required when provider is "maptiler" for
  MapLibre maps). Can also be set with `MAPTILER_API_KEY` environment
  variable. Mapbox maps will always use the Mapbox API key set at the
  map level.

- ...:

  Additional parameters to pass to the Geocoder.

## Value

The modified map object with the geocoder control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl() |>
    add_geocoder_control(position = "top-left", placeholder = "Enter an address")

maplibre() |>
    add_geocoder_control(position = "top-right", placeholder = "Search location")

# Using MapTiler geocoder
maplibre() |>
    add_geocoder_control(provider = "maptiler", maptiler_api_key = "YOUR_API_KEY")
} # }
```
