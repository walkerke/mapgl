library(shiny)
library(mapgl)

# A minimal example showing how to use the compare widget in a Shiny app

ui <- fluidPage(
  titlePanel("Maplibre Compare in Shiny"),

  fluidRow(
    column(3,
      selectInput("style", "Map Style:",
                  c("Positron" = "positron",
                    "Voyager" = "voyager",
                    "Dark Matter" = "dark-matter")),

      sliderInput("opacity", "Layer Opacity:",
                  min = 0, max = 1, value = 0.7, step = 0.1),

      checkboxInput("mousemove", "Enable Mousemove", TRUE),

      radioButtons("orientation", "Orientation:",
                  c("Vertical" = "vertical",
                    "Horizontal" = "horizontal"))
    ),
    column(9,
      maplibreCompareOutput("compare", height = "500px")
    )
  )
)

server <- function(input, output, session) {
  # Create two different maps
  map1 <- maplibre(
    style = carto_style("positron"),
    center = c(-100, 40),
    zoom = 3
  )

  map2 <- maplibre(
    style = carto_style("dark-matter"),
    center = c(-100, 40),
    zoom = 3
  )

  # Render the compare widget
  output$compare <- renderMaplibreCompare({
    compare(
      map1,
      map2,
      mousemove = input$mousemove,
      orientation = input$orientation
    )
  })

  # Update the right map based on inputs
  observeEvent(input$style, {
    # Only run after compare is initialized
    req(input$compare_after_view)

    # Get a proxy to the right (after) map
    proxy <- maplibre_compare_proxy("compare", session, map_side = "after")

    # Update the style
    set_style(proxy, carto_style(input$style))
  })

  observeEvent(input$opacity, {
    # Only run after compare is initialized
    req(input$compare_after_view)

    # Get a proxy to the right (after) map
    proxy <- maplibre_compare_proxy("compare", session, map_side = "after")

    # Update all fill layers opacity
    proxy$session$sendCustomMessage("maplibre-compare-proxy", list(
      id = proxy$id,
      message = list(
        type = "set_opacity",
        opacity = input$opacity,
        map = "after"
      )
    ))
  })

  # Print the view state for debugging
  output$debug <- renderPrint({
    list(
      before_view = input$compare_before_view,
      after_view = input$compare_after_view
    )
  })
}

shinyApp(ui = ui, server = server)
