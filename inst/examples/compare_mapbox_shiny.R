library(shiny)
library(mapgl)

# Example of using the mapboxgl compare widget in Shiny

ui <- fluidPage(
  titlePanel("Mapbox Compare in Shiny"),
  
  fluidRow(
    column(3,
      selectInput("style", "Map Style:",
                 c("Light" = "light",
                   "Dark" = "dark",
                   "Streets" = "streets",
                   "Outdoors" = "outdoors",
                   "Satellite" = "satellite")),
      
      sliderInput("pitch", "Map Pitch:",
                 min = 0, max = 60, value = 30, step = 5),
      
      selectInput("projection", "Projection:",
                 c("Globe" = "globe",
                   "Mercator" = "mercator",
                   "Natural Earth" = "naturalEarth",
                   "Equal Earth" = "equalEarth"))
    ),
    column(9,
      mapboxglCompareOutput("compare", height = "500px")
    )
  )
)

server <- function(input, output, session) {
  # Create two different maps
  map1 <- mapboxgl(
    style = mapbox_style("light"),
    center = c(-100, 40),
    zoom = 3,
    pitch = 0,
    projection = "mercator"
  )
  
  map2 <- mapboxgl(
    style = mapbox_style("satellite"),
    center = c(-100, 40),
    zoom = 3,
    pitch = 45,
    projection = "globe"
  )
  
  # Render the compare widget
  output$compare <- renderMapboxglCompare({
    compare(map1, map2)
  })
  
  # Update the right map based on inputs
  observe({
    # Get a proxy to the right (after) map
    proxy <- mapboxgl_compare_proxy("compare", session, map_side = "after")
    
    # Update the style
    set_style(proxy, mapbox_style(input$style))
    
    # Update the pitch
    proxy$session$sendCustomMessage("mapboxgl-compare-proxy", list(
      id = proxy$id,
      message = list(
        type = "set_pitch",
        pitch = input$pitch,
        map = "after"
      )
    ))
    
    # Update the projection
    proxy$session$sendCustomMessage("mapboxgl-compare-proxy", list(
      id = proxy$id,
      message = list(
        type = "set_projection",
        projection = input$projection,
        map = "after"
      )
    ))
  })
}

shinyApp(ui = ui, server = server)