# Calculate centroid of geometries

This function calculates the centroid of geometries in a layer or sf
object. The result is added as a source to the map, which can then be
styled using add_circle_layer(), etc.

## Usage

``` r
turf_centroid(
  map,
  layer_id = NULL,
  data = NULL,
  coordinates = NULL,
  source_id,
  input_id = NULL
)
```

## Arguments

- map:

  A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.

- layer_id:

  The ID of a layer or source containing geometries (mutually exclusive
  with data and coordinates).

- data:

  An sf object containing geometries (mutually exclusive with layer_id
  and coordinates).

- coordinates:

  A list of coordinate pairs list(c(lng,lat), c(lng,lat), ...) for
  multiple points (mutually exclusive with layer_id and data).

- source_id:

  The ID for the new source containing the centroid. Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.
