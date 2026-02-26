# Create Voronoi diagram

This function creates a Voronoi diagram from a set of points. The result
is added as a source to the map, which can then be styled using
add_fill_layer(), etc.

## Usage

``` r
turf_voronoi(
  map,
  layer_id = NULL,
  data = NULL,
  coordinates = NULL,
  bbox = NULL,
  property = NULL,
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

- bbox:

  Optional. Can be: (1) A numeric vector of length 4, in format
  \`c(xmin, ymin, xmax, ymax)', (2) An sf object to extract bbox from,
  or (3) A layer_id string to extract bbox from and clip results to.

- property:

  Optional. Character string specifying a column name from the input
  points to transfer to the Voronoi polygons using spatial collection.

- source_id:

  The ID for the new source containing the Voronoi diagram. Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.
