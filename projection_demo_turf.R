library(shiny)
library(mapgl)
library(sf)
library(dplyr)

mb_token <- Sys.getenv("MAPBOX_PUBLIC_TOKEN")

ui <- fluidPage(
  # Remove default padding/margin for full screen map
  tags$head(
    tags$style(HTML(
      "
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
    "
    ))
  ),

  # Full screen map
  mapboxglOutput("map", height = "100vh"),

  # Floating panel in top-left
  absolutePanel(
    top = 20,
    left = 20,
    width = 250,
    style = "background-color: rgba(255, 255, 255, 0.85); padding: 15px; border-radius: 5px;",

    h4("Map Projection Demo"),
    selectInput(
      "projection",
      "Choose Projection:",
      choices = c(
        "Mercator" = "mercator",
        "Natural Earth" = "naturalEarth",
        "Winkel Tripel" = "winkelTripel",
        "Equal Earth" = "equalEarth",
        "Equirectangular" = "equirectangular",
        "Globe" = "globe"
      ),
      selected = "mercator"
    ),
    p(
      "Hover to see how a 500km circle distorts across different projections (client-side buffering).",
      style = "font-size: 12px; color: #666;"
    )
  )
)

server <- function(input, output, session) {
  # Render initial map
  output$map <- renderMapboxgl({
    mapboxgl(
      zoom = 1.5,
      center = c(0, 33),
      projection = "mercator",
      hash = TRUE,
      access_token = mb_token
    ) |>
      enable_shiny_hover(coordinates = TRUE, features = FALSE) |>
      # Create empty buffer source and layer upfront
      turf_buffer(
        coordinates = c(0, 0),
        radius = 0,  # Start with 0 radius (invisible)
        units = "kilometers",
        source_id = "hover_buffer"
      ) |>
      add_fill_layer(
        id = "hover_circle",
        source = "hover_buffer",
        fill_color = "magenta",
        fill_opacity = 0.4
      )
  })

  # Update projection when changed
  observeEvent(input$projection, {
    mapboxgl_proxy("map") |>
      set_projection(input$projection)
  })

  # Update circle on hover - pure client-side!
  observeEvent(input$map_hover, {
    hover_data <- input$map_hover

    if (!is.null(hover_data$lng) && !is.null(hover_data$lat)) {
      # Create 500km buffer circle client-side
      mapboxgl_proxy("map") |>
        turf_buffer(
          coordinates = c(hover_data$lng, hover_data$lat),
          radius = 500,
          units = "kilometers",
          source_id = "hover_buffer"  # Updates existing source
        )
    }
  })
}

shinyApp(ui, server)