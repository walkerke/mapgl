# Add a coordinates control to a map

This function adds a compact control that displays the cursor position
as longitude and latitude in WGS84 coordinates.

## Usage

``` r
add_coordinates_control(
  map,
  position = "bottom-right",
  format = c("decimal", "dms"),
  precision = NULL,
  label = NULL,
  empty_text = "Move cursor over map",
  wrap = TRUE
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "bottom-right".

- format:

  Coordinate display format. One of `"decimal"` for decimal degrees or
  `"dms"` for degrees, minutes, and seconds.

- precision:

  Number of decimal places to display. If `NULL`, defaults to 5 for
  decimal degrees and 1 for DMS seconds. For `format = "dms"`, this
  controls decimal places for seconds.

- label:

  Optional label shown above the coordinates. Default is `NULL`.

- empty_text:

  Text shown before the cursor enters the map, and after it leaves the
  map.

- wrap:

  Logical. If `TRUE`, longitudes are wrapped to the standard
  `[-180, 180]` range. Default is `TRUE`.

## Value

The modified map object with the coordinates control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

maplibre() |>
  add_coordinates_control()

mapboxgl() |>
  add_coordinates_control(
    position = "bottom-left",
    format = "dms",
    precision = 2,
    label = "Longitude, latitude"
  )
} # }
```
