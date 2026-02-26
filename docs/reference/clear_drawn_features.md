# Clear all drawn features from a map

This function removes all features that have been drawn using the draw
control on a Mapbox GL or MapLibre GL map in a Shiny application.

## Usage

``` r
clear_drawn_features(map)
```

## Arguments

- map:

  A proxy object created by the `mapboxgl_proxy` or `maplibre_proxy`
  functions.

## Value

The modified map object with all drawn features cleared.

## Examples

``` r
if (FALSE) { # \dontrun{
# In a Shiny application
library(shiny)
library(mapgl)

ui <- fluidPage(
    mapboxglOutput("map"),
    actionButton("clear_btn", "Clear Drawn Features")
)

server <- function(input, output, session) {
    output$map <- renderMapboxgl({
        mapboxgl(
            style = mapbox_style("streets"),
            center = c(-74.50, 40),
            zoom = 9
        ) |>
            add_draw_control()
    })

    observeEvent(input$clear_btn, {
        mapboxgl_proxy("map") |>
            clear_drawn_features()
    })
}

shinyApp(ui, server)
} # }
```
