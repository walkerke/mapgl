# Update the style of a map

Update the style of a map

## Usage

``` r
set_style(map, style, config = NULL, diff = TRUE, preserve_layers = TRUE)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  proxy object.

- style:

  The new style URL to be applied to the map.

- config:

  A named list of options to be passed to the style config.

- diff:

  A boolean that attempts a diff-based update rather than re-drawing the
  full style. Not available for all styles.

- preserve_layers:

  A boolean that indicates whether to preserve user-added sources and
  layers when changing styles. Defaults to TRUE.

## Value

The modified map object.

## Examples

``` r
if (FALSE) { # \dontrun{
map <- mapboxgl(
    style = mapbox_style("streets"),
    center = c(-74.006, 40.7128),
    zoom = 10,
    access_token = "your_mapbox_access_token"
)

# Update the map style in a Shiny app
observeEvent(input$change_style, {
    mapboxgl_proxy("map", session) %>%
        set_style(mapbox_style("dark"), config = list(showLabels = FALSE), diff = TRUE)
})
} # }
```
