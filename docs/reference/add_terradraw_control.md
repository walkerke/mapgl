# Add a Terra Draw control to a map

A convenience wrapper around
[`add_draw_control()`](https://walker-data.com/mapgl/reference/add_draw_control.md)
with `provider = "terra-draw"`, exposing only the arguments that apply
to the Terra Draw engine. The two forms are equivalent; see
[`add_draw_control()`](https://walker-data.com/mapgl/reference/add_draw_control.md)
for full details of the terra-draw provider's behavior, and
[`terradraw_options()`](https://walker-data.com/mapgl/reference/terradraw_options.md)
for advanced configuration.

## Usage

``` r
add_terradraw_control(
  map,
  position = "top-left",
  modes = NULL,
  options = NULL,
  source = NULL,
  attributes = NULL,
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
  orientation = "vertical"
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  A string specifying the position of the draw control. One of
  "top-right", "top-left", "bottom-right", or "bottom-left".

- modes:

  A character vector of drawing modes to expose as toolbar buttons: any
  of `"point"`, `"linestring"`, `"polygon"`, `"rectangle"`, `"circle"`,
  `"freehand"`, `"freehand-linestring"`, `"angled-rectangle"`,
  `"sector"`, `"sensor"`, `"curve"`, `"curve-linestring"`, and
  `"select"`. When `NULL` (the default), the control shows `"point"`,
  `"linestring"`, `"polygon"`, and `"select"`.

- options:

  An object created by
  [`terradraw_options()`](https://walker-data.com/mapgl/reference/terradraw_options.md)
  with advanced Terra Draw settings (snapping, select-mode editing
  flags, per-mode overrides).

- source:

  A character string specifying a source ID to add to the draw control.
  Default is NULL.

- attributes:

  Optional named list defining editable feature attributes. Use
  [`draw_attribute()`](https://walker-data.com/mapgl/reference/draw_attribute.md)
  to define fields.

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

- orientation:

  A string specifying the orientation of the draw control. Either
  "vertical" (default) or "horizontal".

## Value

The modified map object with the draw control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

maplibre() |>
    add_terradraw_control()

maplibre() |>
    add_terradraw_control(
        modes = c("polygon", "rectangle", "circle", "freehand", "select"),
        options = terradraw_options(snap_to_coordinates = TRUE),
        download_button = TRUE
    )
} # }
```
