# Union geometries

This function unions all polygons in a layer into a single geometry. The
result is added as a source to the map, which can then be styled using
add_fill_layer(), etc.

## Usage

``` r
turf_union(map, layer_id = NULL, data = NULL, source_id, input_id = NULL)
```

## Arguments

- map:

  A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.

- layer_id:

  The ID of a layer or source to union (mutually exclusive with data).

- data:

  An sf object to union (mutually exclusive with layer_id).

- source_id:

  The ID for the new source containing the union result. Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.
