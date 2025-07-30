library(shiny)
library(mapgl)

ui <- fluidPage(
  maplibreOutput("map", height = "400px"),
  actionButton("test", "Test Buffer")
)

server <- function(input, output, session) {
  output$map <- renderMaplibre({
    maplibre(
      style = carto_style("positron"),
      center = c(-74.006, 40.7128),
      zoom = 10
    )
  })
  
  observeEvent(input$test, {
    maplibre_proxy("map") |>
      turf_buffer(
        coordinates = c(-74.006, 40.7128),
        radius = 1000,
        units = "meters",
        source_id = "test_buffer"
      ) |>
      add_fill_layer(
        id = "buffer_layer",
        source = "test_buffer",
        fill_color = "red",
        fill_opacity = 0.5
      )
  })
}

shinyApp(ui, server)