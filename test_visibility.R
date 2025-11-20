library(shiny)
library(mapgl)

# Create sample data
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

ui <- fluidPage(
  titlePanel("Test Visibility Preservation with set_style"),
  sidebarPanel(
    actionButton("switch_style", "Switch to Dark Style"),
    p("Toggle layers off, then click button - they should stay off")
  ),
  mainPanel(
    mapboxglOutput("map", height = "600px")
  )
)

server <- function(input, output, session) {
  output$map <- renderMapboxgl({
    mapboxgl(
      style = mapbox_style("standard"),
      center = c(-79.5, 35.5),
      zoom = 6
    ) |>
      add_fill_layer(
        id = "counties",
        source = nc,
        fill_color = "blue",
        fill_opacity = 0.5
      ) |>
      add_circle_layer(
        id = "centroids",
        source = sf::st_centroid(nc),
        circle_color = "red",
        circle_radius = 5
      ) |>
      add_layers_control(
        layers = c("counties", "centroids")
      )
  })

  observeEvent(input$switch_style, {
    mapboxgl_proxy("map") |>
      set_style(mapbox_style("standard-satellite"))
  })
}

shinyApp(ui, server)
