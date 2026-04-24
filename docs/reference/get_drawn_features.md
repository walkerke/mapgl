# Get drawn features from the map

Get drawn features from the map

## Usage

``` r
get_drawn_features(map)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function, or a
  map proxy.

## Value

An sf object containing the drawn features. Feature properties are
preserved as columns and the CRS is EPSG:4326. If the drawn features do
not include an `id` property, an integer `id` column is added. If no
features are available, a 0-row sf object with an `id` column is
returned.

## Details

In non-Shiny sessions, retrieval requires a map that was built by piping
the original widget object through
[`add_draw_control()`](https://walker-data.com/mapgl/reference/add_draw_control.md).
Non-Shiny proxy updates and compare widgets are not yet supported.

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
