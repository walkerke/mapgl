library(shiny)
library(mapgl)
library(sf)

# Load NC counties data
nc <- tigris::counties("TX", cb = TRUE, resolution = "20m")

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      body, .container-fluid {
        padding: 0;
        margin: 0;
      }
      #map {
        position: absolute;
        top: 0;
        bottom: 0;
        width: 100%;
      }
    "))
  ),

  maplibreOutput("map", height = "100vh"),

  absolutePanel(
    top = 20,
    left = 20,
    width = 200,
    style = "background-color: rgba(255, 255, 255, 0.9); padding: 15px; border-radius: 5px;",

    h4("Eraser Demo"),
    actionButton("start_erasing", "Start Erasing"),
    br(), br(),
    sliderInput("eraser_size", "Eraser Size (km):",
                min = 10, max = 100, value = 30, step = 5)
  )
)

server <- function(input, output, session) {
  # Track erasing state
  erasing <- reactiveVal(FALSE)

  output$map <- renderMaplibre({
    # Get NC bounds for centering
    nc_bounds <- st_bbox(nc)
    center_lng <- mean(c(nc_bounds["xmin"], nc_bounds["xmax"]))
    center_lat <- mean(c(nc_bounds["ymin"], nc_bounds["ymax"]))

    maplibre(
      style = carto_style("positron"),
      center = c(center_lng, center_lat),
      zoom = 6.5
    ) |>
    # Top layer (will be erased)
      add_fill_layer(
        id = "top_layer",
        source = nc,
        fill_color = "red",
        fill_opacity = 0.5
      ) |>
      # Initialize empty eraser buffer
      turf_buffer(
        coordinates = c(0, 0),
        radius = 0,
        units = "kilometers",
        source_id = "eraser_buffer"
      ) |>
      # Visualize the eraser
      add_fill_layer(
        id = "eraser_visual",
        source = "eraser_buffer",
        fill_color = "white",
        fill_opacity = 0.5,
        fill_outline_color = "black"
      ) |>
      # Enable hover tracking
      enable_shiny_hover(coordinates = TRUE, features = FALSE)
  })

  # Toggle erasing mode
  observeEvent(input$start_erasing, {
    current <- erasing()
    erasing(!current)

    # Update button text
    if (!current) {
      updateActionButton(session, "start_erasing", label = "Stop Erasing")
    } else {
      updateActionButton(session, "start_erasing", label = "Start Erasing")
    }
  })

  # Update eraser position on hover
  observeEvent(input$map_hover, {
    if (!is.null(input$map_hover$lng)) {
      # Always update eraser position
      proxy <- maplibre_proxy("map") |>
        turf_buffer(
          coordinates = c(input$map_hover$lng, input$map_hover$lat),
          radius = input$eraser_size,
          units = "kilometers",
          source_id = "eraser_buffer"
        )

      # Only perform erasing when in erasing mode
      if (erasing()) {
        proxy |>
          turf_difference(
            layer_id = "top_layer",
            layer_id_2 = "eraser_buffer",
            source_id = "top_layer"  # Same as top layer source - should update it!
          )
      }
    }
  })
}

shinyApp(ui, server)
