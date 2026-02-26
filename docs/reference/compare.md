# Create a Compare widget

This function creates a comparison view between two Mapbox GL or
Maplibre GL maps, allowing users to either swipe between the two maps or
view them side-by-side with synchronized navigation.

## Usage

``` r
compare(
  map1,
  map2,
  width = "100%",
  height = NULL,
  elementId = NULL,
  mousemove = FALSE,
  orientation = "vertical",
  mode = "swipe",
  swiper_color = NULL
)
```

## Arguments

- map1:

  A `mapboxgl` or `maplibre` object representing the first map.

- map2:

  A `mapboxgl` or `maplibre` object representing the second map.

- width:

  Width of the map container.

- height:

  Height of the map container.

- elementId:

  An optional string specifying the ID of the container for the
  comparison. If NULL, a unique ID will be generated.

- mousemove:

  A logical value indicating whether to enable swiping during cursor
  movement (rather than only when clicked). Only applicable when
  `mode="swipe"`.

- orientation:

  A string specifying the orientation of the swiper or the side-by-side
  layout, either "horizontal" or "vertical".

- mode:

  A string specifying the comparison mode: "swipe" (default) for a
  swipeable comparison with a slider, or "sync" for synchronized maps
  displayed next to each other.

- swiper_color:

  An optional CSS color value (e.g., "#000000", "rgb(0,0,0)", "black")
  to customize the color of the swiper handle. Only applicable when
  `mode="swipe"`.

## Value

A comparison widget.

## Details

### Comparison modes

The `compare()` function supports two modes:

- `mode="swipe"` (default) - Creates a swipeable interface with a slider
  to reveal portions of each map

- `mode="sync"` - Places the maps next to each other with synchronized
  navigation

In both modes, navigation (panning, zooming, rotating, tilting) is
synchronized between the maps.

### Using the compare widget in Shiny

The compare widget can be used in Shiny applications with the following
functions:

- [`mapboxglCompareOutput()`](https://walker-data.com/mapgl/reference/mapboxglCompareOutput.md)
  /
  [`renderMapboxglCompare()`](https://walker-data.com/mapgl/reference/renderMapboxglCompare.md) -
  For Mapbox GL comparisons

- [`maplibreCompareOutput()`](https://walker-data.com/mapgl/reference/maplibreCompareOutput.md)
  /
  [`renderMaplibreCompare()`](https://walker-data.com/mapgl/reference/renderMaplibreCompare.md) -
  For Maplibre GL comparisons

- [`mapboxgl_compare_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_compare_proxy.md)
  /
  [`maplibre_compare_proxy()`](https://walker-data.com/mapgl/reference/maplibre_compare_proxy.md) -
  For updating maps in a compare widget

After creating a compare widget in a Shiny app, you can use the proxy
functions to update either the "before" (left/top) or "after"
(right/bottom) map. The proxy objects work with all the regular map
update functions like
[`set_style()`](https://walker-data.com/mapgl/reference/set_style.md),
[`set_paint_property()`](https://walker-data.com/mapgl/reference/set_paint_property.md),
etc.

To get a proxy that targets a specific map in the comparison:

    # Access the left/top map
    left_proxy <- maplibre_compare_proxy("compare_id", map_side = "before")

    # Access the right/bottom map
    right_proxy <- maplibre_compare_proxy("compare_id", map_side = "after")

The compare widget also provides Shiny input values for view state and
clicks. For a compare widget with ID "mycompare", you'll have:

- `input$mycompare_before_view` - View state (center, zoom, bearing,
  pitch) of the left/top map

- `input$mycompare_after_view` - View state of the right/bottom map

- `input$mycompare_before_click` - Click events on the left/top map

- `input$mycompare_after_click` - Click events on the right/bottom map

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

m1 <- mapboxgl(style = mapbox_style("light"))
m2 <- mapboxgl(style = mapbox_style("dark"))

# Default swipe mode
compare(m1, m2)

# Synchronized side-by-side mode
compare(m1, m2, mode = "sync")

# Custom swiper color
compare(m1, m2, swiper_color = "#FF0000")  # Red swiper

# Shiny example
library(shiny)

ui <- fluidPage(
  maplibreCompareOutput("comparison")
)

server <- function(input, output, session) {
  output$comparison <- renderMaplibreCompare({
    compare(
      maplibre(style = carto_style("positron")),
      maplibre(style = carto_style("dark-matter")),
      mode = "sync"
    )
  })

# Update the right map
  observe({
    right_proxy <- maplibre_compare_proxy("comparison", map_side = "after")
    set_style(right_proxy, carto_style("voyager"))
  })
  
  # Example with custom swiper color
  output$comparison2 <- renderMaplibreCompare({
    compare(
      maplibre(style = carto_style("positron")),
      maplibre(style = carto_style("dark-matter")),
      swiper_color = "#3498db"  # Blue swiper
    )
  })
}
} # }
```
