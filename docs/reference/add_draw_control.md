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
  bezier = FALSE,
  bezier_polygon = FALSE,
  orientation = "vertical",
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
  provider = c("mapbox-gl-draw", "terra-draw"),
  modes = NULL,
  options = NULL,
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

- bezier:

  Logical, whether to enable Bezier curve drawing mode. Default is
  FALSE.

- bezier_polygon:

  Logical, whether to enable Bezier polygon drawing mode. Default is
  FALSE.

- orientation:

  A string specifying the orientation of the draw control. Either
  "vertical" (default) or "horizontal".

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

- provider:

  The drawing engine to use: `"mapbox-gl-draw"` (the default, current
  behavior) or `"terra-draw"` to use the [Terra
  Draw](https://github.com/JamesLMilner/terra-draw) library. Terra Draw
  works identically on Mapbox and MapLibre maps and offers additional
  drawing modes plus a richer select/edit mode.

- modes:

  For `provider = "terra-draw"`, a character vector of drawing modes to
  expose as toolbar buttons. Valid modes are `"point"`, `"linestring"`,
  `"polygon"`, `"rectangle"`, `"circle"`, `"freehand"`,
  `"freehand-linestring"`, `"angled-rectangle"`, `"sector"`, `"sensor"`,
  `"curve"`, `"curve-linestring"`, and `"select"`. When `NULL` (the
  default), the mode set is derived from the legacy `freehand`,
  `rectangle`, and `radius` arguments plus `"point"`, `"linestring"`,
  `"polygon"`, and `"select"`. For `provider = "mapbox-gl-draw"`, a
  supplied `modes` value is forwarded to the MapboxDraw constructor
  unchanged (equivalent to passing it via `...`).

- options:

  For `provider = "terra-draw"`, an object created by
  [`terradraw_options()`](https://walker-data.com/mapgl/reference/terradraw_options.md)
  with advanced Terra Draw settings (snapping, select-mode editing
  flags, per-mode overrides).

- ...:

  Additional named arguments for the default `"mapbox-gl-draw"`
  provider. See
  <https://github.com/mapbox/mapbox-gl-draw/blob/main/docs/API.md#options>
  for a list of options. Not supported with `provider = "terra-draw"`;
  use `options` there instead.

## Value

The modified map object with the draw control added.

## Details

### The terra-draw provider

With `provider = "terra-draw"`, mapgl renders its own toolbar (Terra
Draw is a headless library) with one button per requested mode, a trash
button, and an optional download button.
[`add_terradraw_control()`](https://walker-data.com/mapgl/reference/add_terradraw_control.md)
is an equivalent convenience wrapper whose signature contains only the
arguments that apply to this provider. Behavioral notes:

- The trash button deletes the currently selected feature and does
  nothing when no feature is selected; use
  [`clear_drawn_features()`](https://walker-data.com/mapgl/reference/clear_drawn_features.md)
  to remove everything.

- When the mode set includes `"select"`, finishing a shape returns to
  the select tool with the new feature selected (set
  `terradraw_options(keep_mode_active = TRUE)` to keep drawing instead).

- Colors are coerced to 6-digit hex (Terra Draw requires hex), so R
  color names work but alpha channels are ignored; use `fill_opacity`
  for transparency.

- Features loaded via `source` or
  [`add_features_to_draw()`](https://walker-data.com/mapgl/reference/add_features_to_draw.md)
  are adapted to Terra Draw's constraints: Multi\* geometries are split
  into single-part features, coordinates are rounded to 9 decimal places
  (Terra Draw's precision limit, about 0.1 mm), and polygon interior
  rings (holes) are removed.

- Changing the map style preserves drawn features, but discards an
  unfinished drawing and clears the current selection and undo history.

- The `"curve"` and `"curve-linestring"` modes draw shapes that mix
  straight and curved (cubic Bezier) edges, pen-tool style: click places
  a corner point; click-and-drag places an anchor and pulls out
  symmetric curve handles (drag distance sets the curvature); moving the
  mouse previews the pending segment; click the first point (the last
  point for lines) or press Enter to finish; Escape cancels; Backspace
  removes the last point. The stored feature uses the rendered curved
  coordinates, so measurements, the download button, and
  [`get_drawn_features()`](https://walker-data.com/mapgl/reference/get_drawn_features.md)
  work unchanged, and the curve's control points are preserved in a
  `curveNodes` JSON-string property. In select mode curve features can
  be moved as a whole (their control points move with them) but vertex
  editing, rotate, and scale are disabled for them, and self-crossing
  curve outlines cannot be finished as polygons. While a curve tool is
  active, left-drag places curved anchors, so map panning is suspended
  until you switch tools.

- `bezier`, `bezier_polygon`, and `simplify_freehand` are specific to
  mapbox-gl-draw and error under terra-draw. `attributes` and
  `show_measurements` work with both providers on standalone widgets (as
  with the default provider, neither is available in compare views).

### Bezier modes (mapbox-gl-draw provider only)

Bezier drawing modes are supported when the draw control is added to the
original map widget or later through a regular Shiny map proxy. Compare
widgets and compare proxies are not yet supported for Bezier modes.

To draw Bezier curves, click the Bezier button, then use **Alt +
left-drag** to create nodes with handles. A plain left-click creates
nodes without handles. Press Enter, or click the last node, to finish
the curve. In direct select mode, select a node and drag its handles to
edit the curve; use **Alt + drag** on a handle to break handle symmetry.

Retrieved Bezier features are returned to R as standard sf geometries
using the rendered curved coordinates: Bezier curves become LineString
features and Bezier polygons become Polygon features. The Bezier control
metadata is also preserved in feature-property columns so the browser
widget can continue to edit those features as Bezier objects.

When `attributes` is supplied, selecting exactly one drawn feature opens
a small attribute editor. Click Save to write values to the feature
properties;
[`get_drawn_features()`](https://walker-data.com/mapgl/reference/get_drawn_features.md)
returns those properties as sf columns. The editor works for newly drawn
features and features loaded into the draw control with `source` or
[`add_features_to_draw()`](https://walker-data.com/mapgl/reference/add_features_to_draw.md).
Compare widgets are not yet supported for attribute editing.

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

# Enable Bezier curve drawing mode
mapboxgl() |>
    add_draw_control(bezier = TRUE)

# Add an attribute editor for classification workflows
mapboxgl() |>
    add_draw_control(
        attributes = list(
            class = draw_attribute(
                "select",
                choices = c("forest", "water", "urban"),
                required = TRUE
            ),
            notes = draw_attribute("textarea"),
            confidence = draw_attribute(
                "numeric",
                min = 0,
                max = 1,
                step = 0.1,
                default = 1
            )
        )
    )

# Enable multiple drawing modes
mapboxgl() |>
    add_draw_control(
        freehand = TRUE,
        rectangle = TRUE,
        radius = TRUE,
        bezier = TRUE
    )

# Use the Terra Draw engine (works on Mapbox and MapLibre maps)
maplibre() |>
    add_draw_control(
        provider = "terra-draw",
        modes = c("point", "polygon", "rectangle", "circle", "select"),
        options = terradraw_options(snap_to_coordinates = TRUE)
    )
} # }
```
