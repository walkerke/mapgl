# Get queried features from a map as an sf object

This function retrieves the results of a feature query triggered by
[`query_rendered_features()`](https://walker-data.com/mapgl/reference/query_rendered_features.md).
It returns the features as a deduplicated sf object. Note that only
features that were visible in the viewport at the time of the query will
be included.

## Usage

``` r
get_queried_features(map)
```

## Arguments

- map:

  A map object (mapboxgl, maplibre) or proxy object (mapboxgl_proxy,
  maplibre_proxy, mapboxgl_compare_proxy, maplibre_compare_proxy)

## Value

An sf object containing the queried features, or an empty sf object if
no features were found

## Examples

``` r
if (FALSE) { # \dontrun{
# In a Shiny server function:
observeEvent(input$query_button, {
    proxy <- maplibre_proxy("map")
    query_rendered_features(proxy, layer_id = "counties")
    features <- get_queried_features(proxy)
    print(nrow(features))
})
} # }
```
