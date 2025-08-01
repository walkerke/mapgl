library(shiny)
library(mapgl)
library(sf)

# Load NC counties data
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)

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
    width = 250,
    style = "background-color: rgba(255, 255, 255, 0.9); padding: 15px; border-radius: 5px;",

    h4("Looking Glass Demo"),
    p("Move your cursor to reveal the hidden layer beneath!",
      style = "font-size: 14px;"),
    sliderInput("glass_size", "Looking Glass Size (km):",
                min = 10, max = 80, value = 40, step = 5),
    br(),
    h5("Revealed County Info:"),
    textOutput("county_info"),
    br(),
    p("The looking glass preserves all original attributes from the revealed features.",
      style = "font-size: 12px; color: #666;")
  )
)

server <- function(input, output, session) {

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
      # Hidden layer (bottom) - colorful counties
      add_fill_layer(
        id = "hidden_layer",
        source = nc,
        fill_color = interpolate(
          column = "AREA",
          values = c(0, 0.5),
          stops = c("lightpink", "darkred")
        ),
        fill_opacity = 0.8
      ) |>
      # Cover layer (top) - solid dark blue
      add_fill_layer(
        id = "cover_layer",
        source = nc,
        fill_color = "#1a237e",
        fill_opacity = 1
      ) |>
      # Initialize empty looking glass
      turf_buffer(
        coordinates = c(0, 0),
        radius = 0,
        units = "kilometers",
        source_id = "looking_glass"
      ) |>
      # The revealed portion (will show colorful counties through the "lens")
      add_fill_layer(
        id = "revealed_layer",
        source = "looking_glass",
        fill_color = interpolate(
          column = "AREA",
          values = c(0, 0.5),
          stops = c("lightpink", "darkred")
        ),
        fill_opacity = 0.8
      ) |>
      # Looking glass border
      add_line_layer(
        id = "glass_border",
        source = "looking_glass",
        line_color = "white",
        line_width = 3
      ) |>
      # Enable hover tracking
      enable_shiny_hover(coordinates = TRUE, features = FALSE)
  })

  # Track revealed counties
  revealed_counties <- reactiveVal(list())

  # Update looking glass on hover
  observeEvent(input$map_hover, {
    if (!is.null(input$map_hover$lng)) {
      # Create looking glass circle
      maplibre_proxy("map") |>
        turf_buffer(
          coordinates = c(input$map_hover$lng, input$map_hover$lat),
          radius = input$glass_size,
          units = "kilometers",
          source_id = "glass_buffer"
        ) |>
        # Find intersection with hidden layer to reveal
        turf_intersect(
          layer_id = "hidden_layer",
          layer_id_2 = "glass_buffer",
          source_id = "looking_glass",
          input_id = "revealed_features"
        )
    }
  })

  # Display info about revealed counties
  observeEvent(input$map_turf_revealed_features, {
    result <- input$map_turf_revealed_features$result
    if (!is.null(result$features) && length(result$features) > 0) {
      # Extract county names and areas
      counties <- sapply(result$features, function(f) {
        name <- f$properties$NAME
        area <- round(f$properties$AREA, 3)
        paste0(name, " (Area: ", area, ")")
      })
      revealed_counties(counties)
    } else {
      revealed_counties(list())
    }
  })

  output$county_info <- renderText({
    counties <- revealed_counties()
    if (length(counties) > 0) {
      paste(counties, collapse = "\n")
    } else {
      "Move the looking glass to reveal counties..."
    }
  })
}

shinyApp(ui, server)
