# Spatial filter features by predicate

This function filters features from the first layer based on their
spatial relationship with features in the second layer using various
spatial predicates.

## Usage

``` r
turf_filter(
  map,
  layer_id = NULL,
  filter_layer_id = NULL,
  data = NULL,
  filter_data = NULL,
  predicate = c("intersects", "within", "contains", "crosses", "disjoint"),
  source_id,
  input_id = NULL
)
```

## Arguments

- map:

  A mapboxgl, maplibre, mapboxgl_proxy, or maplibre_proxy object.

- layer_id:

  The ID of the layer or source to filter (mutually exclusive with
  data).

- filter_layer_id:

  The ID of the layer or source to filter against (mutually exclusive
  with filter_data).

- data:

  An sf object containing features to filter (mutually exclusive with
  layer_id).

- filter_data:

  An sf object containing the filter geometry (mutually exclusive with
  filter_layer_id).

- predicate:

  The spatial relationship to test. One of: "intersects", "within",
  "contains", "crosses", "disjoint".

- source_id:

  The ID for the new source containing the filtered results. Required.

- input_id:

  Optional. Character string specifying the Shiny input ID suffix for
  storing results. If NULL (default), no input is registered. For proxy
  operations, the result will be available as
  `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The map or proxy object for method chaining.
