# Find intersection of two geometries

This function finds the intersection between geometries in two layers or
sf objects. The result is added as a source to the map, which can then
be styled using add_fill_layer(), etc.

## Usage

``` r
turf_intersect(
  map,
  layer_id = NULL,
  layer_id_2 = NULL,
  data = NULL,
  data_2 = NULL,
  source_id,
  input_id = NULL
)
```

## Arguments

- map:

  A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.

- layer_id:

  The ID of the first layer or source (mutually exclusive with data).

- layer_id_2:

  The ID of the second layer or source (mutually exclusive with data_2).

- data:

  An sf object for the first geometry (mutually exclusive with
  layer_id).

- data_2:

  An sf object for the second geometry (mutually exclusive with
  layer_id_2).

- source_id:

  The ID for the new source containing the intersection result.
  Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.
