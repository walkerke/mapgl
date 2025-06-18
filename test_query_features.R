library(shiny)
library(bslib)
library(mapgl)
library(sf)

# Create some sample data
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

ui <- page_sidebar(
  title = "Test Query Features",
  sidebar = sidebar(
    tags$p("Click buttons to test query functionality"),
    actionButton("query_all", "Query All Counties"),
    actionButton("query_bbox", "Query Bbox"),
    actionButton("query_point", "Query Point"),
    tags$hr(),
    verbatimTextOutput("query_result")
  ),
  card(
    full_screen = TRUE,
    maplibreOutput("map")
  )
)

server <- function(input, output, session) {
  output$map <- renderMaplibre({
    maplibre(style = carto_style("positron")) |>
      fit_bounds(nc, animate = FALSE) |>
      add_fill_layer(
        id = "nc_counties",
        source = nc,
        fill_color = "lightblue",
        fill_opacity = 0.5,
        fill_outline_color = "white"
      ) |>
      add_fill_layer(
        id = "nc_selected",
        source = nc,
        fill_color = "orange",
        fill_opacity = 0.8,
        fill_outline_color = "darkorange",
        filter = c("in", "FIPS", "")
      )
  })

  # Query all counties in viewport
  observeEvent(input$query_all, {
    query_features(maplibre_proxy("map"), layers = "nc_counties", callback = function(features) {
      query_result(paste("Found", nrow(features), "features (all viewport)"))
      if (nrow(features) > 0) {
        # Highlight all queried features
        fips_codes <- features$FIPS
        maplibre_proxy("map") |>
          set_filter("nc_selected", c("in", "FIPS", fips_codes))
      }
    })
  })

  # Query a specific bounding box
  observeEvent(input$query_bbox, {
    # Query a small area (this should only get a few counties)
    query_features(
      maplibre_proxy("map"),
      geometry = c(200, 200, 400, 400),
      layers = "nc_counties",
      callback = function(features) {
        query_result(paste("Found", nrow(features), "features (bbox)"))
        if (nrow(features) > 0) {
          fips_codes <- features$FIPS
          maplibre_proxy("map") |>
            set_filter("nc_selected", c("in", "FIPS", fips_codes))
        }
      }
    )
  })

  # Query at a point
  observeEvent(input$query_point, {
    # Query at center of map view
    query_features(
      maplibre_proxy("map"),
      geometry = c(300, 300),
      layers = "nc_counties",
      callback = function(features) {
        query_result(paste("Found", nrow(features), "features (point)"))
        if (nrow(features) > 0) {
          fips_codes <- features$FIPS
          maplibre_proxy("map") |>
            set_filter("nc_selected", c("in", "FIPS", fips_codes))
        }
      }
    )
  })

  # Track query results with a reactive value
  query_result <- reactiveVal("No query run yet")
  
  # Display query results
  output$query_result <- renderPrint({
    query_result()
  })
}

shinyApp(ui, server)
