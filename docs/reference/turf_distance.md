# Calculate distance between two features

This function calculates the distance between the first features of two
layers or coordinates. Note: This function only works with proxy objects
as it returns a numeric value to R.

## Usage

``` r
turf_distance(
  proxy,
  layer_id = NULL,
  layer_id_2 = NULL,
  data = NULL,
  coordinates = NULL,
  coordinates_2 = NULL,
  units = "kilometers",
  input_id = "turf_distance_result"
)
```

## Arguments

- proxy:

  A mapboxgl_proxy or maplibre_proxy object.

- layer_id:

  The ID of the first layer or source (mutually exclusive with data and
  coordinates).

- layer_id_2:

  The ID of the second layer or source (required if layer_id is used).

- data:

  An sf object for the first geometry (mutually exclusive with layer_id
  and coordinates).

- coordinates:

  A numeric vector of length 2 with lng/lat coordinates for the first
  point (mutually exclusive with layer_id and data).

- coordinates_2:

  A numeric vector of length 2 with lng/lat coordinates for the second
  point (required if coordinates is used).

- units:

  The units for the distance calculation. One of "meters", "kilometers",
  "miles", etc.

- input_id:

  Character string specifying the Shiny input ID suffix for storing the
  distance result. Default is "turf_distance_result". Result will be
  available as `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The proxy object for method chaining.
