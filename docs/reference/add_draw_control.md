# Add a draw control to a map

Add a draw control to a map

## Usage

``` r
add_draw_control(
  map,
  position = "top-left",
  freehand = FALSE,
  simplify_freehand = FALSE,
  rectangle = FALSE,
  radius = FALSE,
  orientation = "vertical",
  source = NULL,
  point_color = "#3bb2d0",
  line_color = "#3bb2d0",
  fill_color = "#3bb2d0",
  fill_opacity = 0.1,
  active_color = "#fbb03b",
  vertex_radius = 5,
  line_width = 2,
  download_button = FALSE,
  download_filename = "drawn-features",
  show_measurements = FALSE,
  measurement_units = "both",
  ...
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  A string specifying the position of the draw control. One of
  "top-right", "top-left", "bottom-right", or "bottom-left".

- freehand:

  Logical, whether to enable freehand drawing mode. Default is FALSE.

- simplify_freehand:

  Logical, whether to apply simplification to freehand drawings. Default
  is FALSE.

- rectangle:

  Logical, whether to enable rectangle drawing mode. Default is FALSE.

- radius:

  Logical, whether to enable radius/circle drawing mode. Default is
  FALSE.

- orientation:

  A string specifying the orientation of the draw control. Either
  "vertical" (default) or "horizontal".

- source:

  A character string specifying a source ID to add to the draw control.
  Default is NULL.

- point_color:

  Color for point features. Default is "#3bb2d0" (light blue).

- line_color:

  Color for line features. Default is "#3bb2d0" (light blue).

- fill_color:

  Fill color for polygon features. Default is "#3bb2d0" (light blue).

- fill_opacity:

  Fill opacity for polygon features. Default is 0.1.

- active_color:

  Color for active (selected) features. Default is "#fbb03b" (orange).

- vertex_radius:

  Radius of vertex points in pixels. Default is 5.

- line_width:

  Width of lines in pixels. Default is 2.

- download_button:

  Logical, whether to add a download button to export drawn features as
  GeoJSON. Default is FALSE.

- download_filename:

  Base filename for downloaded GeoJSON (without extension). Default is
  "drawn-features".

- show_measurements:

  Logical, whether to show live measurements while drawing. Default is
  FALSE.

- measurement_units:

  Units for measurements. Either "metric", "imperial", or "both".
  Default is "both".

- ...:

  Additional named arguments. See
  <https://github.com/mapbox/mapbox-gl-draw/blob/main/docs/API.md#options>
  for a list of options.

## Value

The modified map object with the draw control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl(
    style = mapbox_style("streets"),
    center = c(-74.50, 40),
    zoom = 9
) |>
    add_draw_control()

# With initial features from a source
library(tigris)
tx <- counties(state = "TX", cb = TRUE)
mapboxgl(bounds = tx) |>
    add_source(id = "tx", data = tx) |>
    add_draw_control(source = "tx")

# With custom styling
mapboxgl() |>
    add_draw_control(
        point_color = "#ff0000",
        line_color = "#00ff00",
        fill_color = "#0000ff",
        fill_opacity = 0.3,
        active_color = "#ff00ff",
        vertex_radius = 7,
        line_width = 3
    )

# Enable rectangle drawing mode
mapboxgl() |>
    add_draw_control(rectangle = TRUE)

# Enable radius/circle drawing mode
mapboxgl() |>
    add_draw_control(radius = TRUE)

# Enable multiple drawing modes
mapboxgl() |>
    add_draw_control(
        freehand = TRUE,
        rectangle = TRUE,
        radius = TRUE
    )
} # }
```
