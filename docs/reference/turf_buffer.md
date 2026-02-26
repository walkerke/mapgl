# Turf.js Geospatial Operations for mapgl

This module provides client-side geospatial operations using the turf.js
library. All operations work with both mapboxgl and maplibre proxies.
Create a buffer around geometries

## Usage

``` r
turf_buffer(
  map,
  layer_id = NULL,
  data = NULL,
  coordinates = NULL,
  radius,
  units = "meters",
  source_id,
  input_id = NULL
)
```

## Arguments

- map:

  A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.

- layer_id:

  The ID of a layer or source to buffer (mutually exclusive with data
  and coordinates).

- data:

  An sf object to buffer (mutually exclusive with layer_id and
  coordinates).

- coordinates:

  A numeric vector of length 2 with lng/lat coordinates to create a
  point and buffer (mutually exclusive with layer_id and data).

- radius:

  The buffer distance.

- units:

  The units for the buffer distance. One of "meters", "kilometers",
  "miles", "feet", "inches", "yards", "centimeters", "millimeters",
  "degrees", "radians".

- source_id:

  The ID for the new source containing the buffered results. Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.

## Details

This function creates a buffer around geometries at a specified
distance. The operation is performed client-side using turf.js. The
result is added as a source to the map, which can then be styled using
add_fill_layer(), add_line_layer(), etc.

## Examples

``` r
if (FALSE) { # \dontrun{
# Buffer existing layer
map |>
  turf_buffer(layer_id = "points", radius = 1000, units = "meters",
              source_id = "point_buffers") |>
  add_fill_layer(id = "buffers", source = "point_buffers", fill_color = "blue")

# Buffer sf object
map |>
  turf_buffer(data = sf_points, radius = 0.5, units = "miles",
              source_id = "buffers") |>
  add_fill_layer(id = "buffer_layer", source = "buffers")

# Buffer coordinates (great for hover events)
maplibre_proxy("map") |>
  turf_buffer(coordinates = c(-122.4, 37.7), radius = 500, units = "meters",
              source_id = "hover_buffer")
} # }
```
