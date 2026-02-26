# Get drawn features from the map

Get drawn features from the map

## Usage

``` r
get_drawn_features(map)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function, or a mapboxgl proxy.

## Value

An sf object containing the drawn features.

## Examples

``` r
if (FALSE) { # \dontrun{
# In a Shiny application
library(shiny)
library(mapgl)

ui <- fluidPage(
    mapboxglOutput("map"),
    actionButton("get_features", "Get Drawn Features"),
    verbatimTextOutput("feature_output")
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

    observeEvent(input$get_features, {
        drawn_features <- get_drawn_features(mapboxgl_proxy("map"))
        output$feature_output <- renderPrint({
            print(drawn_features)
        })
    })
}

shinyApp(ui, server)
} # }
```
