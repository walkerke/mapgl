# Query rendered features on a map in a Shiny session

This function queries features that are currently rendered (visible) in
the map viewport. Only features within the current viewport bounds will
be returned - features outside the visible area or hidden due to zoom
constraints will not be included. Use
[`get_queried_features()`](https://walker-data.com/mapgl/reference/get_queried_features.md)
to retrieve the results as an sf object, or use the `callback` parameter
to handle results automatically when they're ready.

## Usage

``` r
query_rendered_features(
  proxy,
  geometry = NULL,
  layer_id = NULL,
  filter = NULL,
  callback = NULL
)
```

## Arguments

- proxy:

  A MapboxGL or Maplibre proxy object, defined with
  [`mapboxgl_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_proxy.md),
  [`maplibre_proxy()`](https://walker-data.com/mapgl/reference/maplibre_proxy.md),
  [`mapboxgl_compare_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_compare_proxy.md),
  or
  [`maplibre_compare_proxy()`](https://walker-data.com/mapgl/reference/maplibre_compare_proxy.md)

- geometry:

  The geometry to query. Can be:

  - `NULL` (default): Query the entire viewport

  - A length-2 vector `c(x, y)`: Query at a single point in pixel
    coordinates

  - A length-4 vector `c(xmin, ymin, xmax, ymax)`: Query within a
    bounding box in pixel coordinates

- layer_id:

  A character vector of layer names to include in the query. Can be a
  single layer name or multiple layer names. If `NULL` (default), all
  layers are queried.

- filter:

  A filter expression used to filter features in the query. Should be a
  list representing a Mapbox GL expression. Using this parameter applies
  the filter during the query WITHOUT changing the map display, avoiding
  race conditions. If you've called
  [`set_filter()`](https://walker-data.com/mapgl/reference/set_filter.md)
  separately, you must pass the same filter here to get aligned results.

- callback:

  A function to execute when results are ready. The function will
  receive the sf object as its argument. If provided, this avoids timing
  issues by automatically handling results when they're available.

## Value

The proxy object (invisibly). Use
[`get_queried_features()`](https://walker-data.com/mapgl/reference/get_queried_features.md)
to retrieve the query results manually, or provide a `callback` function
to handle results automatically.

## Details

### Viewport Limitation

This function only queries features that are currently rendered in the
map viewport. Features outside the visible area will not be returned,
even if they exist in the data source. This includes features that are:

- Outside the current map bounds

- Hidden due to zoom level constraints (minzoom/maxzoom)

- Not yet loaded (if using vector tiles)

### Avoiding Race Conditions

**IMPORTANT**:
[`set_filter()`](https://walker-data.com/mapgl/reference/set_filter.md)
is asynchronous while `query_rendered_features()` is synchronous.
Calling `query_rendered_features()` immediately after
[`set_filter()`](https://walker-data.com/mapgl/reference/set_filter.md)
will return features from the PREVIOUS filter state, not the new one.

#### Safe Usage Patterns:

**Pattern 1: Query First, Then Filter (Recommended)**

    query_rendered_features(proxy, layer_id = "counties", callback = function(features) {
      # Process features, then update map based on results
      proxy |> set_filter("highlight", list("in", "id", features$id))
    })

**Pattern 2: Use Filter Parameter Instead**

    # Query with filter without changing map display
    query_rendered_features(proxy, filter = list(">=", "population", 1000),
                             callback = function(features) {
      # Process filtered results without race condition
    })

#### What NOT to Do:

    # WRONG - This will return stale results!
    proxy |> set_filter("layer", new_filter)
    query_rendered_features(proxy, layer_id = "layer")  # Gets OLD filter results

## Examples

``` r
if (FALSE) { # \dontrun{
# Pattern 1: Query first, then filter (RECOMMENDED)
proxy <- maplibre_proxy("map")
query_rendered_features(proxy, layer_id = "counties", callback = function(features) {
  if (nrow(features) > 0) {
    # Filter map based on query results - no race condition
    proxy |> set_filter("selected", list("in", "id", features$id))
  }
})

# Pattern 2: Use filter parameter to avoid race conditions
query_rendered_features(proxy,
                        filter = list(">=", "population", 50000),
                        callback = function(features) {
  # These results are guaranteed to match the filter
  print(paste("Found", nrow(features), "high population areas"))
})

# Query specific bounding box with callback
query_rendered_features(proxy, geometry = c(100, 100, 200, 200),
                        layer_id = "counties", callback = function(features) {
  print(paste("Found", nrow(features), "features"))
})

# ANTI-PATTERN - Don't do this!
# proxy |> set_filter("layer", new_filter)
# query_rendered_features(proxy, layer_id = "layer")  # Will get stale results!
} # }
```
