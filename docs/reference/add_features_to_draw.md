# Add features to an existing draw control

This function adds features from an existing source to a draw control on
a map.

## Usage

``` r
add_features_to_draw(map, source, clear_existing = FALSE)
```

## Arguments

- map:

  A map object with a draw control already added

- source:

  Character string specifying a source ID to get features from

- clear_existing:

  Logical, whether to clear existing drawn features before adding new
  ones. Default is FALSE.

## Value

The modified map object

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)
library(tigris)

# Add features from an existing source
tx <- counties(state = "TX", cb = TRUE)
mapboxgl(bounds = tx) |>
  add_source(id = "tx", data = tx) |>
  add_draw_control() |>
  add_features_to_draw(source = "tx")

# In a Shiny app
observeEvent(input$load_data, {
  mapboxgl_proxy("map") |>
    add_features_to_draw(
      source = "dynamic_data",
      clear_existing = TRUE
    )
})
} # }
```
