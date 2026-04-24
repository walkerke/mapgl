# Set a filter on a map layer

This function sets a filter on a map layer, working with both regular
map objects and proxy objects.

## Usage

``` r
set_filter(map, layer_id, filter)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- layer_id:

  The ID of the layer to which the filter will be applied.

- filter:

  The filter expression to apply.

## Value

The updated map object.

## Clustered layers

A layer created via the `cluster_options` shortcut in
[`add_circle_layer()`](https://walker-data.com/mapgl/reference/add_circle_layer.md)
or
[`add_symbol_layer()`](https://walker-data.com/mapgl/reference/add_symbol_layer.md)
is actually three layers over one source (`"id"`, `"id-clusters"`,
`"id-cluster-count"`). `set_filter()` targets exactly one of them, so:

- Calling `set_filter("id", ...)` applies only to the unclustered
  sub-layer. Cluster circles still show the pre-filter counts.

- Cluster points are synthetic (their only properties are `point_count`,
  `cluster_id`, etc.), so a filter that reads a feature property like
  `"year"` cannot be meaningfully applied to the `-clusters` layer — it
  would evaluate to `FALSE` and hide all clusters.

For the common "filter my data" case on a clustered map, use
[`set_source()`](https://walker-data.com/mapgl/reference/set_source.md)
instead. It replaces the source's data and Mapbox/MapLibre re-cluster
automatically:

    mapboxgl_proxy("map") |>
      set_source(layer_id = "circles", source = filtered())

`set_filter()` is still the right tool for cluster-aware filters that
read cluster-point properties, e.g. hiding clusters below a count
threshold:

    mapboxgl_proxy("map") |>
      set_filter("circles-clusters", list(">=", get_column("point_count"), 10))
