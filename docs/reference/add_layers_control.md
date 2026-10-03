# Add a layers control to the map

The layers control is a native map control: it stacks alongside other
controls (navigation, fullscreen, etc.) in its corner rather than
overlapping them, following the order in which controls are added to the
map. Its default appearance matches the other map controls (white
background, dark monochrome items). To restore the blue active style
from earlier versions of mapgl, set `active_color = "#4a90e2"` and
`active_text_color = "#ffffff"`.

## Usage

``` r
add_layers_control(
  map,
  position = "top-left",
  layers = NULL,
  collapsible = TRUE,
  use_icon = TRUE,
  background_color = NULL,
  active_color = NULL,
  hover_color = NULL,
  active_text_color = NULL,
  inactive_text_color = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  mode = c("multiple", "single")
)
```

## Arguments

- map:

  A map object.

- position:

  The position of the control on the map (one of "top-left",
  "top-right", "bottom-left", "bottom-right").

- layers:

  Either a character vector of layer IDs to include in the control, a
  named list/vector where names are labels and values are layer IDs, or
  a named list where values can be vectors to group multiple layers
  together. If NULL, all layers will be included.

- collapsible:

  Whether the control should be collapsible.

- use_icon:

  Whether to use a stacked layers icon instead of the "Layers" text when
  collapsed. Only applies when collapsible = TRUE.

- background_color:

  The background color for the layers control; this will be the color
  used for inactive layer items.

- active_color:

  The background color for active layer items.

- hover_color:

  The background color for layer items when hovered.

- active_text_color:

  The text color for active layer items.

- inactive_text_color:

  The text color for inactive layer items.

- margin_top:

  Optional top margin in pixels, applied to the control within the
  native control stack. Rarely needed now that the control no longer
  overlaps other controls; NULL (the default) uses standard control
  spacing.

- margin_right:

  Optional right margin in pixels. Default is NULL.

- margin_bottom:

  Optional bottom margin in pixels. Default is NULL.

- margin_left:

  Optional left margin in pixels. Default is NULL.

- mode:

  How many entries can be visible at once. In `"multiple"` mode (the
  default), entries toggle independently. In `"single"` mode, activating
  an entry turns the others off — useful for flipping through
  alternative analytical layers or raster imagery where only one should
  show at a time. Clicking the active entry does nothing. When the
  control is created in `"single"` mode with several entries visible,
  the first visible entry stays on and the rest are turned off. To
  combine both behaviors on one map, add two controls: one
  `"single"`-mode control for the alternatives and one `"multiple"`-mode
  control for independent overlays.

## Value

The modified map object with the layers control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(tigris)
options(tigris_use_cache = TRUE)

rds <- roads("TX", "Tarrant")
tr <- tracts("TX", "Tarrant", cb = TRUE)
cty <- counties("TX", cb = TRUE)

maplibre() |>
    fit_bounds(rds) |>
    add_fill_layer(
        id = "Census tracts",
        source = tr,
        fill_color = "purple",
        fill_opacity = 0.6
    ) |>
    add_line_layer(
        "Local roads",
        source = rds,
        line_color = "pink"
    ) |>
    add_layers_control(
        position = "top-left",
        background_color = "#ffffff",
        active_color = "#4a90e2"
    )

# With custom labels
maplibre() |>
    add_fill_layer(id = "tract-fill", source = tr) |>
    add_line_layer(id = "tract-line", source = tr) |>
    add_layers_control(
        layers = list(
            "Census Tracts" = "tract-fill",
            "Tract Borders" = "tract-line"
        )
    )

# Group multiple layers together
maplibre(bounds = cty) |>
    add_fill_layer(id = "county-fill", source = cty, fill_opacity = 0.3) |>
    add_line_layer(
        id = "county-outline",
        source = cty,
        line_color = "yellow",
        line_width = 3
    ) |>
    add_line_layer(
        id = "roads-layer",
        source = rds,
        line_color = "blue"
    ) |>
    add_layers_control(
        layers = list(
            "Counties" = c("county-fill", "county-outline"),
            "Roads" = "roads-layer"
        )
    )
} # }
```
