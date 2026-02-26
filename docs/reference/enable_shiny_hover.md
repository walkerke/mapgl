# Enable hover events for Shiny applications

This function enables hover functionality for maplibre and mapboxgl
widgets in Shiny applications, providing `_hover` and `_feature_hover`
input values.

## Usage

``` r
enable_shiny_hover(map, coordinates = TRUE, features = TRUE, layer_id = NULL)
```

## Arguments

- map:

  A maplibre or mapboxgl widget object.

- coordinates:

  Logical. If TRUE, provides general mouse coordinates via `_hover`
  input. Defaults to TRUE.

- features:

  Logical. If TRUE, provides feature information via `_feature_hover`
  input when hovering over map features. Defaults to TRUE.

- layer_id:

  Character. If provided, only features from the specified layer will be
  included in the `_feature_hover` input. Defaults to NULL. For multiple
  layers, provide a vector of layer IDs.

## Value

The modified map object with hover events enabled.

## Examples

``` r
if (FALSE) { # \dontrun{
library(shiny)
library(mapgl)

ui <- fluidPage(
  maplibreOutput("map"),
  verbatimTextOutput("hover_info")
)

server <- function(input, output) {
  output$map <- renderMaplibre({
    maplibre() |>
      enable_shiny_hover()
  })

  output$hover_info <- renderText({
    paste("Mouse at:", input$map_hover$lng, input$map_hover$lat)
  })
}

shinyApp(ui, server)
} # }
```
