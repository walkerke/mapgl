library(shiny)
library(mapgl)
library(colourpicker)
library(magrittr)

ui <- fluidPage(
  titlePanel("Compare North Carolina Counties"),

  sidebarLayout(
    sidebarPanel(
      # Left (before) map controls
      h4("Left Map Controls"),
      selectInput("left_style", "Left Map Style:",
                  c("Positron" = "positron",
                    "Voyager" = "voyager",
                    "Dark Matter" = "dark-matter")),

      sliderInput("left_opacity", "County Fill Opacity:",
                  min = 0, max = 1, value = 0.7, step = 0.1),

      colourInput("left_fill", "County Fill Color:", value = "#1e88e5"),

      # Right (after) map controls
      h4("Right Map Controls"),
      selectInput("right_style", "Right Map Style:",
                  c("Positron" = "positron",
                    "Voyager" = "voyager",
                    "Dark Matter" = "dark-matter")),

      sliderInput("right_opacity", "County Fill Opacity:",
                  min = 0, max = 1, value = 0.7, step = 0.1),

      colourInput("right_fill", "County Fill Color:", value = "#d81b60"),

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
  # Load North Carolina counties data
  nc_counties <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

  # Create the left map
  left_map <- reactive({
    maplibre(style = carto_style("positron"), bounds = nc_counties) %>%
      add_navigation_control() %>%
      add_fill_layer(
        id = "counties-fill1",
        source = nc_counties,
        fill_color = "red",
        fill_opacity = 0.7
      )
  })

  # Create the right map
  right_map <- reactive({
    maplibre(style = carto_style("dark-matter"), bounds = nc_counties) %>%
      add_navigation_control() %>%
      add_fill_layer(
        id = "counties-fill2",
        source = nc_counties,
        fill_color = "blue",
        fill_opacity = 0.7
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

  # Update the left map style when style selection changes
  # observe({
  #   # Create proxy for the left map
  #   proxy1 <- maplibre_compare_proxy("compare", session, map_side = "before")
  #   # Update the style
  #   set_style(proxy1, carto_style(input$left_style))
  # }) %>% bindEvent(input$left_style)

  # Update the left map fill color when color selection changes
  observe({
    proxy1 <- maplibre_compare_proxy("compare", session, map_side = "before")
    set_paint_property(proxy1, "counties-fill1", "fill-color", input$left_fill)
  }) %>% bindEvent(input$left_fill)

  # Update the left map opacity when opacity slider changes
  observe({
    proxy1 <- maplibre_compare_proxy("compare", session, map_side = "before")
    set_paint_property(proxy1, "counties-fill1", "fill-opacity", input$left_opacity)
  }) %>% bindEvent(input$left_opacity)

  # Update the right map style when style selection changes
  # observe({
  #   proxy2 <- maplibre_compare_proxy("compare", session, map_side = "after")
  #   set_style(proxy2, carto_style(input$right_style))
  # }) %>% bindEvent(input$right_style)

  # Update the right map fill color when color selection changes
  observe({
    proxy2 <- maplibre_compare_proxy("compare", session, map_side = "after")
    set_paint_property(proxy2, "counties-fill2", "fill-color", input$right_fill)
  }) %>% bindEvent(input$right_fill)

  # Update the right map opacity when opacity slider changes
  observe({
    proxy2 <- maplibre_compare_proxy("compare", session, map_side = "after")
    set_paint_property(proxy2, "counties-fill2", "fill-opacity", input$right_opacity)
  }) %>% bindEvent(input$right_opacity)

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
