# Create concave hull

This function creates a concave hull around a set of points. The result
is added as a source to the map, which can then be styled using
add_fill_layer(), etc.

## Usage

``` r
turf_concave_hull(
  map,
  layer_id = NULL,
  data = NULL,
  coordinates = NULL,
  max_edge = NULL,
  units = "kilometers",
  source_id,
  input_id = NULL
)
```

## Arguments

- map:

  A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.

- layer_id:

  The ID of a layer or source containing points (mutually exclusive with
  data and coordinates).

- data:

  An sf object containing points (mutually exclusive with layer_id and
  coordinates).

- coordinates:

  A list of coordinate pairs list(c(lng,lat), c(lng,lat), ...) for
  multiple points (mutually exclusive with layer_id and data).

- max_edge:

  The maximum edge length for the concave hull. If NULL (default), an
  optimal value is calculated automatically.

- units:

  The units for max_edge. One of "meters", "kilometers", "miles", etc.

- source_id:

  The ID for the new source containing the concave hull. Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.

## Details

If max_edge is too small and no concave hull can be computed, the
function will automatically calculate an optimal max_edge value based on
point distances. If that fails, it falls back to a convex hull to ensure
a result is always returned.
