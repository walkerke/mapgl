library(shiny)
library(mapgl)

# Sample data
sample_data <- data.frame(
  id = 1:5,
  lat = c(40.7128, 40.7589, 40.7831, 40.7505, 40.7282),
  lng = c(-74.0060, -73.9851, -73.9712, -73.9934, -73.9942),
  value = c(10, 20, 30, 40, 50),
  category = c("A", "B", "A", "B", "A")
)

# Convert to sf object
sample_sf <- sf::st_as_sf(sample_data, coords = c("lng", "lat"), crs = 4326)

ui <- fluidPage(
  titlePanel("Test mapgl Shiny Functions"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Layer Controls"),
      actionButton("add_layers", "Add Test Layers"),
      br(), br(),
      
      h4("Single Layer Operations"),
      actionButton("clear_single", "Clear Layer 1"),
      actionButton("update_paint", "Update Layer 1 Paint"),
      actionButton("update_layout", "Update Layer 1 Layout"),
      br(), br(),
      
      h4("Multiple Layer Operations"),
      actionButton("clear_multiple", "Clear Layers 2 & 3"),
      actionButton("clear_all", "Clear All Layers"),
      br(), br(),
      
      h4("Backwards Compatibility Test"),
      actionButton("test_deprecated", "Test Deprecated 'layer' Parameter"),
      br(), br(),
      
      verbatimTextOutput("status")
    ),
    
    mainPanel(
      maplibreOutput("map", height = "600px")
    )
  )
)

server <- function(input, output, session) {
  
  # Initialize map
  output$map <- renderMaplibre({
    maplibre(
      style = carto_style("positron"),
      center = c(-73.9851, 40.7589),
      zoom = 10
    )
  })
  
  # Status messages
  status_msg <- reactiveVal("Ready")
  
  output$status <- renderText({
    status_msg()
  })
  
  # Add test layers
  observeEvent(input$add_layers, {
    maplibre_proxy("map") |>
      add_circle_layer(
        id = "layer1",
        source = sample_sf,
        circle_color = "red",
        circle_radius = 8
      ) |>
      add_circle_layer(
        id = "layer2", 
        source = sample_sf,
        circle_color = "blue",
        circle_radius = 6
      ) |>
      add_circle_layer(
        id = "layer3",
        source = sample_sf, 
        circle_color = "green",
        circle_radius = 4
      )
    
    status_msg("Added 3 test layers")
  })
  
  # Clear single layer
  observeEvent(input$clear_single, {
    maplibre_proxy("map") |>
      clear_layer("layer1")
    
    status_msg("Cleared layer1")
  })
  
  # Update paint property (new layer_id parameter)
  observeEvent(input$update_paint, {
    maplibre_proxy("map") |>
      set_paint_property(
        layer_id = "layer1",
        name = "circle-color",
        value = "orange"
      )
    
    status_msg("Updated layer1 paint property")
  })
  
  # Update layout property (new layer_id parameter)
  observeEvent(input$update_layout, {
    maplibre_proxy("map") |>
      set_layout_property(
        layer_id = "layer1",
        name = "visibility",
        value = "visible"
      )
    
    status_msg("Updated layer1 layout property")
  })
  
  # Clear multiple layers (new vector capability)
  observeEvent(input$clear_multiple, {
    maplibre_proxy("map") |>
      clear_layer(c("layer2", "layer3"))
    
    status_msg("Cleared layers 2 & 3 with vector input")
  })
  
  # Clear all layers
  observeEvent(input$clear_all, {
    maplibre_proxy("map") |>
      clear_layer(c("layer1", "layer2", "layer3"))
    
    status_msg("Cleared all layers")
  })
  
  # Test backwards compatibility
  observeEvent(input$test_deprecated, {
    # This should work but show a deprecation warning
    tryCatch({
      maplibre_proxy("map") |>
        set_paint_property(
          layer = "layer1",  # Using deprecated parameter
          name = "circle-color",
          value = "purple"
        )
      
      status_msg("Tested deprecated 'layer' parameter - check console for warning")
    }, error = function(e) {
      status_msg(paste("Error:", e$message))
    })
  })
}

# Run the app
shinyApp(ui = ui, server = server)