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

- ...:

  Additional named arguments. See
  <https://github.com/mapbox/mapbox-gl-draw/blob/main/docs/API.md#options>
  for a list of options.

## Value

The modified map object with the draw control added.

## Details

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
} # }
```
