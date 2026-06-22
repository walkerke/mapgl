# Create a Compare widget

This function creates a comparison view between two or more Mapbox GL or
Maplibre GL maps, allowing users to either swipe between two maps or
view multiple maps side-by-side with synchronized navigation.

## Usage

``` r
compare(
  map1,
  map2,
  ...,
  width = "100%",
  height = NULL,
  elementId = NULL,
  mousemove = FALSE,
  orientation = "vertical",
  mode = "swipe",
  ncol = NULL,
  swiper_color = NULL,
  laser = FALSE,
  laser_color = "#ff2d55",
  laser_size = 14
)
```

## Arguments

- map1:

  A `mapboxgl` or `maplibre` object representing the first map.

- map2:

  A `mapboxgl` or `maplibre` object representing the second map.

- ...:

  Additional `mapboxgl` or `maplibre` objects to include in the
  comparison. Supplying more than two maps requires `mode = "sync"`, and
  the synced maps are arranged in a grid controlled by `ncol`. When
  extra maps are supplied, all other arguments (`width`, `height`, etc.)
  must be passed by name.

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

- ncol:

  Number of columns in the synced map grid. Defaults to
  `ceiling(sqrt(n))` for more than two maps; for two maps, `orientation`
  controls the layout unless `ncol` is given. Only applicable when
  `mode = "sync"`.

- swiper_color:

  An optional CSS color value (e.g., "#000000", "rgb(0,0,0)", "black")
  to customize the color of the swiper handle. Only applicable when
  `mode="swipe"`.

- laser:

  Logical; if `TRUE`, show a laser pointer on the other maps that
  follows the cursor location. Only applies when `mode = "sync"`.

- laser_color:

  CSS color for the laser pointer.

- laser_size:

  Size of the laser pointer in pixels.

## Value

A comparison widget.

## Details

### Comparison modes

The `compare()` function supports two modes:

- `mode="swipe"` (default) - Creates a swipeable interface with a slider
  to reveal portions of each map. Swipe mode supports exactly two maps.

- `mode="sync"` - Places the maps next to each other with synchronized
  navigation. Sync mode supports two or more maps; pass additional maps
  after `map1` and `map2` and control the grid layout with `ncol`.

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

### Comparing more than two maps

When more than two maps are supplied with `mode = "sync"`, the maps are
identified as "map1", "map2", "map3", and so on, in the order they were
passed to `compare()`. Use these identifiers (or their position as an
integer) as `map_side` in the proxy functions, e.g.
`maplibre_compare_proxy("mycompare", map_side = "map3")` or
`map_side = 3`. Shiny input values follow the same naming:
`input$mycompare_map1_view`, `input$mycompare_map3_click`, etc. Legends
can be targeted at individual maps in the grid with
`add_legend(..., target = "map3")`.

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

# Synchronized maps with a laser pointer
compare(m1, m2, mode = "sync", laser = TRUE)

# Synchronize four maps in a 2 x 2 grid
m3 <- mapboxgl(style = mapbox_style("streets"))
m4 <- mapboxgl(style = mapbox_style("satellite"))
compare(m1, m2, m3, m4, mode = "sync", ncol = 2)

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
