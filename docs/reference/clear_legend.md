# Clear legends from a map

Remove one or more legends from a Mapbox GL or MapLibre GL map in a
Shiny application.

## Usage

``` r
clear_legend(map, legend_ids = NULL)
```

## Arguments

- map:

  A map proxy object created by
  [`mapboxgl_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_proxy.md)
  or
  [`maplibre_proxy()`](https://walker-data.com/mapgl/reference/maplibre_proxy.md).

- legend_ids:

  Optional. A character vector of legend IDs to clear. If not provided,
  all legends will be cleared.

## Value

The updated map proxy object with the specified legend(s) cleared.

## Note

This function can only be used with map proxy objects in Shiny
applications. It cannot be used with static map objects.

## Examples

``` r
if (FALSE) { # \dontrun{
# In a Shiny server function:

# Clear all legends
observeEvent(input$clear_all, {
  mapboxgl_proxy("map") %>%
    clear_legend()
})

# Clear specific legends by ID
observeEvent(input$clear_specific, {
  mapboxgl_proxy("map") %>%
    clear_legend(legend_ids = c("legend-1", "legend-2"))
})

# Clear legend after removing a layer
observeEvent(input$remove_layer, {
  mapboxgl_proxy("map") %>%
    remove_layer("my_layer") %>%
    clear_legend(legend_ids = "my_layer_legend")
})
} # }
```
