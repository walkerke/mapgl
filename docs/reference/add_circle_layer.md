# Add a circle layer to a Mapbox GL map

Add a circle layer to a Mapbox GL map

## Usage

``` r
add_circle_layer(
  map,
  id,
  source,
  source_layer = NULL,
  circle_blur = NULL,
  circle_color = NULL,
  circle_opacity = NULL,
  circle_radius = NULL,
  circle_sort_key = NULL,
  circle_stroke_color = NULL,
  circle_stroke_opacity = NULL,
  circle_stroke_width = NULL,
  circle_translate = NULL,
  circle_translate_anchor = "map",
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL,
  cluster_options = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function.

- id:

  A unique ID for the layer.

- source:

  The ID of the source, alternatively an sf object (which will be
  converted to a GeoJSON source) or a named list that specifies `type`
  and `url` for a remote source.

- source_layer:

  The source layer (for vector sources).

- circle_blur:

  Amount to blur the circle.

- circle_color:

  The color of the circle.

- circle_opacity:

  The opacity at which the circle will be drawn.

- circle_radius:

  Circle radius.

- circle_sort_key:

  Sorts features in ascending order based on this value.

- circle_stroke_color:

  The color of the circle's stroke.

- circle_stroke_opacity:

  The opacity of the circle's stroke.

- circle_stroke_width:

  The width of the circle's stroke.

- circle_translate:

  The geometry's offset. Values are `c(x, y)` where negatives indicate
  left and up.

- circle_translate_anchor:

  Controls the frame of reference for `circle-translate`.

- visibility:

  Whether this layer is displayed.

- slot:

  An optional slot for layer order.

- min_zoom:

  The minimum zoom level for the layer.

- max_zoom:

  The maximum zoom level for the layer.

- popup:

  A column name containing information to display in a popup on click.
  Columns containing HTML will be parsed.

- tooltip:

  A column name containing information to display in a tooltip on hover.
  Columns containing HTML will be parsed.

- hover_options:

  A named list of options for highlighting features in the layer on
  hover.

- before_id:

  The name of the layer that this layer appears "before", allowing you
  to insert layers below other layers in your basemap (e.g. labels).

- filter:

  An optional filter expression to subset features in the layer.

- cluster_options:

  A list of options for clustering circles, created by the
  [`cluster_options()`](https://walker-data.com/mapgl/reference/cluster_options.md)
  function.

## Value

The modified map object with the new circle layer added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)
library(sf)
library(dplyr)

# Set seed for reproducibility
set.seed(1234)

# Define the bounding box for Washington DC (approximately)
bbox <- st_bbox(
    c(
        xmin = -77.119759,
        ymin = 38.791645,
        xmax = -76.909393,
        ymax = 38.995548
    ),
    crs = st_crs(4326)
)

# Generate 30 random points within the bounding box
random_points <- st_as_sf(
    data.frame(
        id = 1:30,
        lon = runif(30, bbox["xmin"], bbox["xmax"]),
        lat = runif(30, bbox["ymin"], bbox["ymax"])
    ),
    coords = c("lon", "lat"),
    crs = 4326
)

# Assign random categories
categories <- c("music", "bar", "theatre", "bicycle")
random_points <- random_points %>%
    mutate(category = sample(categories, n(), replace = TRUE))

# Map with circle layer
mapboxgl(style = mapbox_style("light")) %>%
    fit_bounds(random_points, animate = FALSE) %>%
    add_circle_layer(
        id = "poi-layer",
        source = random_points,
        circle_color = match_expr(
            "category",
            values = c(
                "music", "bar", "theatre",
                "bicycle"
            ),
            stops = c(
                "#1f78b4", "#33a02c",
                "#e31a1c", "#ff7f00"
            )
        ),
        circle_radius = 8,
        circle_stroke_color = "#ffffff",
        circle_stroke_width = 2,
        circle_opacity = 0.8,
        tooltip = "category",
        hover_options = list(
            circle_radius = 12,
            circle_color = "#ffff99"
        )
    ) %>%
    add_categorical_legend(
        legend_title = "Points of Interest",
        values = c("Music", "Bar", "Theatre", "Bicycle"),
        colors = c("#1f78b4", "#33a02c", "#e31a1c", "#ff7f00"),
        circular_patches = TRUE
    )
} # }
```
