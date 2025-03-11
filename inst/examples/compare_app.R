library(shiny)
library(mapgl)
library(colourpicker)
library(magrittr)

ui <- fluidPage(
  titlePanel("Maplibre Compare Widget Example"),

  sidebarLayout(
    sidebarPanel(
      # Left (before) map controls
      h4("Left Map Controls"),
      selectInput("left_style", "Left Map Style:",
                  c("Positron" = "positron",
                    "Voyager" = "voyager",
                    "Dark Matter" = "dark-matter")),

      sliderInput("left_opacity", "Country Fill Opacity:",
                  min = 0, max = 1, value = 0.7, step = 0.1),

      colourInput("left_fill", "Country Fill Color:", value = "#1e88e5"),

      # Right (after) map controls
      h4("Right Map Controls"),
      selectInput("right_style", "Right Map Style:",
                  c("Positron" = "positron",
                    "Voyager" = "voyager",
                    "Dark Matter" = "dark-matter")),

      sliderInput("right_opacity", "Country Fill Opacity:",
                  min = 0, max = 1, value = 0.7, step = 0.1),

      colourInput("right_fill", "Country Fill Color:", value = "#d81b60"),

      # Compare controls
      h4("Compare Controls"),
      selectInput("orientation", "Orientation:",
                  c("Vertical" = "vertical", "Horizontal" = "horizontal")),
      checkboxInput("mousemove", "Enable mousemove", TRUE)
    ),

    mainPanel(
      maplibreCompareOutput("compare", height = "600px"),

      verbatimTextOutput("click_info")
    )
  )
)

server <- function(input, output, session) {
  # Create the world countries data
  world <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

  # Create the left map
  left_map <- reactive({
    maplibre(style = carto_style(input$left_style)) %>%
      add_navigation_control() %>%
      add_fill_layer(
        id = "counties-fill1",
        source = world,
        fill_color = input$left_fill,
        fill_opacity = input$left_opacity
      )
  })

  # Create the right map
  right_map <- reactive({
    maplibre(style = carto_style(input$right_style)) %>%
      add_navigation_control() %>%
      add_fill_layer(
        id = "counties-fill2",
        source = world,
        fill_color = input$right_fill,
        fill_opacity = input$right_opacity
      )
  })

  # Render the compare widget
  output$compare <- renderMaplibreCompare({
    compare(
      map1 = left_map(),
      map2 = right_map(),
      orientation = input$orientation,
      mousemove = input$mousemove
    )
  })

  # Update the left (before) map
  observe({
    # Only make updates after compare widget is created
    req(input$compare_before_view)

    # Create proxy for the left map
    proxy <- maplibre_compare_proxy("compare", session, map_side = "before")

    # Update the left map style
    set_style(proxy, carto_style(input$left_style))

    # Update the fill color and opacity for the left map
    set_paint_property(proxy, "counties-fill1", "fill-color", input$left_fill)
    set_paint_property(proxy, "counties-fill1", "fill-opacity", input$left_opacity)
  })

  # Update the right (after) map
  observe({
    # Only make updates after compare widget is created
    req(input$compare_after_view)

    # Create proxy for the right map
    proxy <- maplibre_compare_proxy("compare", session, map_side = "after")

    # Update the right map style
    set_style(proxy, carto_style(input$right_style))

    # Update the fill color and opacity for the right map
    set_paint_property(proxy, "counties-fill2", "fill-color", input$right_fill)
    set_paint_property(proxy, "counties-fill2", "fill-opacity", input$right_opacity)
  })

  # Display click information
  output$click_info <- renderPrint({
    # Show click info from both maps
    list(
      left_map_click = input$compare_before_click,
      right_map_click = input$compare_after_click
    )
  })
}

shinyApp(ui = ui, server = server)
