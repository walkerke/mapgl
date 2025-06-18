library(shiny)
library(bslib)
library(mapgl)
library(sf)
library(dplyr)

# Create random points in Dallas area
set.seed(123)
n_points <- 50

# Dallas bounding box (approximate)
dallas_bbox <- c(
  xmin = -96.9,
  ymin = 32.7,
  xmax = -96.7,
  ymax = 32.9
)

# Generate random points
random_points <- data.frame(
  id = 1:n_points,
  lon = runif(n_points, dallas_bbox[1], dallas_bbox[3]),
  lat = runif(n_points, dallas_bbox[2], dallas_bbox[4]),
  # Add some attributes to sum
  population = sample(100:5000, n_points),
  revenue = sample(1000:50000, n_points)
) |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

ui <- page_sidebar(
  title = "Test Within Buffer Query",
  sidebar = sidebar(
    tags$p("Click to test 'within' predicate with buffers"),
    actionButton(
      "create_buffer",
      "Create Random Buffer",
      class = "btn-primary"
    ),
    actionButton("clear_buffer", "Clear Buffer", class = "btn-secondary"),
    tags$hr(),
    h4("Query Results:"),
    verbatimTextOutput("query_summary"),
    tags$hr(),
    h4("Buffer Details:"),
    verbatimTextOutput("buffer_info")
  ),
  card(
    full_screen = TRUE,
    maplibreOutput("map")
  )
)

server <- function(input, output, session) {
  # Reactive values to track state
  current_buffer <- reactiveVal(NULL)
  query_summary <- reactiveVal("No buffer created yet")
  buffer_details <- reactiveVal("No buffer created yet")

  output$map <- renderMaplibre({
    maplibre(style = carto_style("positron")) |>
      fit_bounds(random_points, animate = FALSE) |>
      # Add points layer
      add_circle_layer(
        id = "points",
        source = random_points,
        circle_color = "blue",
        circle_radius = 6,
        circle_stroke_color = "white",
        circle_stroke_width = 1,
        circle_opacity = 0.8,
        tooltip = list("population", "revenue")
      ) |>
      # Add highlighted points layer (initially empty)
      add_circle_layer(
        id = "points_within",
        source = random_points,
        circle_color = "red",
        circle_radius = 8,
        circle_stroke_color = "darkred",
        circle_stroke_width = 2,
        circle_opacity = 0.9,
        filter = c("in", "id", "") # Start with no points selected
      )
  })

  # Create random buffer
  observeEvent(input$create_buffer, {
    # Pick a random point to buffer
    random_idx <- sample(1:nrow(random_points), 1)
    center_point <- random_points[random_idx, ]

    # Create buffer (st_buffer uses meters when CRS is geographic)
    buffer_radius_m <- 10000 # Random radius between 500m-2km

    # Create buffer - st_buffer handles meters automatically for geographic CRS
    buffer_geom <- st_buffer(center_point, buffer_radius_m)

    # Store buffer info
    current_buffer(buffer_geom)
    buffer_details(paste(
      "Buffer around point",
      random_idx,
      "\n",
      "Radius:",
      buffer_radius_m,
      "meters\n",
      "Center population:",
      center_point$population,
      "\n",
      "Center revenue: $",
      format(center_point$revenue, big.mark = ","),
      "\n",
      "Buffer bbox:",
      paste(round(st_bbox(buffer_geom), 4), collapse = ", ")
    ))

    # Add buffer to map
    maplibre_proxy("map") |>
      clear_layer("buffer") |>
      add_fill_layer(
        id = "buffer",
        source = buffer_geom,
        fill_color = "rgba(255, 165, 0, 0.3)",
        fill_outline_color = "orange"
      )

    # Get the buffer geometry as GeoJSON first
    buffer_geojson <- geojsonsf::sf_geojson(buffer_geom)
    buffer_parsed <- jsonlite::fromJSON(
      buffer_geojson,
      simplifyVector = FALSE
    )

    # Apply within filter to highlight points immediately
    maplibre_proxy("map") |>
      set_filter(
        "points_within",
        list("within", buffer_parsed$features[[1]]$geometry)
      )

    # Query points within buffer to get the actual features for aggregation
    query_features(
      maplibre_proxy("map"),
      layers = "points_within",  # Query the filtered layer to get only points within buffer
      callback = function(features) {
        if (nrow(features) > 0) {
          # Calculate aggregations
          total_points <- nrow(features)
          total_population <- sum(features$population, na.rm = TRUE)
          total_revenue <- sum(features$revenue, na.rm = TRUE)
          avg_population <- round(mean(features$population, na.rm = TRUE))
          avg_revenue <- round(mean(features$revenue, na.rm = TRUE))

          # Update summary
          query_summary(paste(
            "Points within buffer:",
            total_points,
            "\n",
            "Total population:",
            format(total_population, big.mark = ","),
            "\n",
            "Total revenue: $",
            format(total_revenue, big.mark = ","),
            "\n",
            "Avg population:",
            format(avg_population, big.mark = ","),
            "\n",
            "Avg revenue: $",
            format(avg_revenue, big.mark = ",")
          ))
        } else {
          query_summary("No points found within buffer")
        }
      }
    )
  })

  # Clear buffer
  observeEvent(input$clear_buffer, {
    current_buffer(NULL)
    query_summary("No buffer created yet")
    buffer_details("No buffer created yet")

    maplibre_proxy("map") |>
      clear_layer("buffer") |>
      set_filter("points_within", c("in", "id", ""))
  })

  # Output displays
  output$query_summary <- renderPrint({
    cat(query_summary())
  })

  output$buffer_info <- renderPrint({
    cat(buffer_details())
  })
}

shinyApp(ui, server)
