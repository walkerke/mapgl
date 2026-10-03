# Configure the Terra Draw provider for the draw control

This helper builds the `options` argument for
[`add_draw_control()`](https://walker-data.com/mapgl/reference/add_draw_control.md)
with `provider = "terra-draw"`. All arguments are optional; the defaults
give a fully editable select mode without snapping.

## Usage

``` r
terradraw_options(
  drag_features = TRUE,
  rotate_features = FALSE,
  scale_features = FALSE,
  drag_vertices = TRUE,
  delete_vertices = TRUE,
  midpoints = TRUE,
  resize = NULL,
  snap_to_coordinates = FALSE,
  snap_to_lines = FALSE,
  editable_while_drawing = FALSE,
  show_coordinate_points = FALSE,
  drag_interaction = NULL,
  pointer_distance = NULL,
  keep_mode_active = FALSE,
  modes = NULL
)
```

## Arguments

- drag_features:

  Logical, whether selected features can be moved by dragging. Default
  is `TRUE`.

- rotate_features:

  Logical, whether selected features can be rotated by holding Control+R
  while dragging the feature in select mode. This uses the Control key
  on macOS as well as Windows and Linux. Default is `FALSE`.

- scale_features:

  Logical, whether selected features can be scaled by holding Control+S
  while dragging the feature in select mode. This uses the Control key
  on macOS as well as Windows and Linux. Default is `FALSE`.

- drag_vertices:

  Logical, whether individual vertices of a selected feature can be
  dragged. Default is `TRUE`.

- delete_vertices:

  Logical, whether individual vertices of a selected feature can be
  deleted. Default is `TRUE`.

- midpoints:

  Logical, whether midpoints are shown between vertices so new vertices
  can be inserted. Default is `TRUE`. Ignored (treated as `FALSE`) when
  `resize` is set, as Terra Draw does not support both.

- resize:

  How selected features may be resized by dragging their selection
  points: one of `"center"`, `"opposite"`, `"center-fixed"`, or
  `"opposite-fixed"`. Default `NULL` disables resizing.

- snap_to_coordinates:

  Logical, whether drawing and editing snap to existing feature
  coordinates. Default is `FALSE`.

- snap_to_lines:

  Logical, whether drawing and editing snap to existing feature lines.
  Default is `FALSE`.

- editable_while_drawing:

  Logical, whether features can be edited (vertices dragged) while still
  being drawn, for the point, linestring, and polygon modes. Default is
  `FALSE`.

- show_coordinate_points:

  Logical, whether coordinate points are displayed on linestring and
  polygon features while drawing. Default is `FALSE`.

- drag_interaction:

  How rectangle and circle drawing works: one of `"click-move"` (click,
  move, click), `"click-drag"`, or `"click-move-or-drag"`. Default
  `NULL` uses the Terra Draw default.

- pointer_distance:

  Pointer tolerance in pixels for drawing interactions. Default `NULL`
  uses the Terra Draw default.

- keep_mode_active:

  Logical. By default (`FALSE`) the toolbar returns to the select tool
  after a shape is finished, matching the mapbox-gl-draw workflow; set
  to `TRUE` to stay in the active drawing mode instead.

- modes:

  Advanced escape hatch: a named list keyed by mode name whose entries
  are raw Terra Draw mode constructor options (in Terra Draw's own
  camelCase naming, e.g. `list(polygon = list(pointerDistance = 30))`).
  These are merged over what mapgl generates, with `styles` entries
  merged key by key. `modeName` overrides are not allowed.

## Value

A list of class `"mapgl_terradraw_options"` for use as the `options`
argument of
[`add_draw_control()`](https://walker-data.com/mapgl/reference/add_draw_control.md).

## Details

Rotation and scaling use keyboard-modified feature dragging rather than
visible handles. First select a feature and ensure the map has keyboard
focus. Hold Control+R while dragging to rotate, or Control+S while
dragging to scale. Release the pointer to finish the transformation. The
`resize` option is separate and provides visible selection points that
can be dragged to resize a feature.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

maplibre() |>
    add_draw_control(
        provider = "terra-draw",
        options = terradraw_options(
            snap_to_coordinates = TRUE,
            rotate_features = TRUE,
            scale_features = TRUE
        )
    )
# In select mode, select a feature and hold Control+R or Control+S while
# dragging it to rotate or scale, respectively.
} # }
```
