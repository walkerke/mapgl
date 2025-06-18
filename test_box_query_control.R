library(shiny)
library(bslib)
library(mapgl)
library(sf)

# Create sample data - use NC counties
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

ui <- page_sidebar(
  title = "Test Box Query Control",
  sidebar = sidebar(
    tags$p("Click the box query control button in the top-right corner of the map"),
    tags$p("Then hold Shift+Click and drag to draw a selection box"),
    tags$hr(),
    h4("Instructions:"),
    tags$ul(
      tags$li("Click the dashed box icon to activate box query mode"),
      tags$li("Hold Shift and click-drag to select features"),
      tags$li("Selected counties will be highlighted in orange"),
      tags$li("Press ESC to cancel a selection"),
      tags$li("Click the box icon again to deactivate")
    ),
    tags$hr(),
    h4("Selection Summary:"),
    verbatimTextOutput("selection_summary")
  ),
  card(
    full_screen = TRUE,
    maplibreOutput("map")
  )
)

server <- function(input, output, session) {
  # Reactive value to track selected features
  selected_features <- reactiveVal(data.frame())

  output$map <- renderMaplibre({
    maplibre(style = carto_style("positron")) |>
      fit_bounds(nc, animate = FALSE) |>
      add_fill_layer(
        id = "counties",
        source = nc,
        fill_color = "lightblue",
        fill_opacity = 0.5,
        fill_outline_color = "white"
      ) |>
      add_fill_layer(
        id = "counties_highlighted", 
        source = nc,
        fill_color = "orange",
        fill_opacity = 0.8,
        fill_outline_color = "darkorange",
        filter = c("in", "FIPS", "")  # Start with no counties selected
      ) |>
      add_box_query_control(
        position = "top-right",
        layers = "counties",
        highlighted_layer = "counties_highlighted",
        filter_property = "FIPS",  # Specify which property to use for filtering
        highlight_color = "#ff6600",
        highlight_opacity = 0.8,
        highlight_outline_color = "#cc5200",
        box_color = "#3887be",
        box_opacity = 0.2,
        box_border_color = "#2c6899",
        box_border_width = 3,
        max_features = 100
      )
  })

  # Monitor box query results
  observeEvent(input$map_box_query_features, {
    if (!is.null(input$map_box_query_features) && 
        input$map_box_query_features != "null" && 
        nchar(input$map_box_query_features) > 0) {
      
      # Parse the GeoJSON results
      features <- sf::st_read(input$map_box_query_features, quiet = TRUE)
      selected_features(features)
      
      # Update summary
      if (nrow(features) > 0) {
        message(paste("Box query found", nrow(features), "counties"))
      }
    } else {
      selected_features(data.frame())
    }
  })

  # Display selection summary
  output$selection_summary <- renderPrint({
    features <- selected_features()
    
    if (nrow(features) == 0) {
      cat("No counties selected")
    } else {
      cat("Selected Counties:", nrow(features), "\n\n")
      
      # Show basic statistics
      if ("POP1990" %in% names(features)) {
        cat("Total 1990 Population:", format(sum(features$POP1990, na.rm = TRUE), big.mark = ","), "\n")
        cat("Average Population:", format(round(mean(features$POP1990, na.rm = TRUE)), big.mark = ","), "\n")
      }
      
      if ("AREA" %in% names(features)) {
        total_area <- sum(features$AREA, na.rm = TRUE)
        cat("Total Area:", round(total_area, 2), "\n")
      }
      
      cat("\nCounty Names:\n")
      if ("NAME" %in% names(features)) {
        cat(paste(features$NAME, collapse = ", "))
      }
    }
  })
}

shinyApp(ui, server)