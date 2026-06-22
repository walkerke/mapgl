# Style a tooltip or popup

Builds a styling specification for map tooltips and popups, mirroring
[`legend_style()`](https://walker-data.com/mapgl/reference/legend_style.md).
Pass the result – or simply a preset name like `"dark"` – to the
`tooltip_style` / `popup_style` argument of a layer function or
[`add_flowmap()`](https://walker-data.com/mapgl/reference/add_flowmap.md).
Start from an optional light/dark `preset` and override any individual
properties on top of it. With no styling argument supplied, tooltips
keep their default (unstyled) appearance.

## Usage

``` r
tooltip_style(
  preset = NULL,
  background_color = NULL,
  background_opacity = NULL,
  text_color = NULL,
  border_color = NULL,
  border_width = NULL,
  border_radius = NULL,
  font_family = NULL,
  font_size = NULL,
  font_weight = NULL,
  padding = NULL,
  max_width = NULL,
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  position = NULL,
  offset = NULL
)

popup_style(
  preset = NULL,
  background_color = NULL,
  background_opacity = NULL,
  text_color = NULL,
  border_color = NULL,
  border_width = NULL,
  border_radius = NULL,
  font_family = NULL,
  font_size = NULL,
  font_weight = NULL,
  padding = NULL,
  max_width = NULL,
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  position = NULL,
  offset = NULL
)
```

## Arguments

- preset:

  Optional base theme: `"light"`, `"dark"`, or `"auto"` (resolve to
  light or dark from the flowmap dark mode; ordinary layers treat
  `"auto"` as light). Individual arguments below override the preset.

- background_color:

  CSS color for the tooltip/popup background.

- background_opacity:

  Numeric in `[0, 1]` for the background opacity.

- text_color:

  CSS color for the text.

- border_color:

  CSS color for the border.

- border_width:

  Border width in pixels.

- border_radius:

  Corner radius in pixels.

- font_family:

  CSS `font-family` string.

- font_size:

  Font size in pixels.

- font_weight:

  CSS `font-weight`.

- padding:

  Internal padding in pixels.

- max_width:

  Maximum width as a CSS size (e.g. `"320px"`).

- shadow:

  Logical; whether to draw a drop shadow.

- shadow_color:

  CSS color of the drop shadow.

- shadow_size:

  Blur radius of the drop shadow in pixels.

- position:

  For flowmap tooltips/popups, `"floating"` (cursor-following) or
  `"anchored"` (pinned to the feature). Ignored by ordinary layers.

- offset:

  For floating flowmap tooltips, a numeric pixel offset or a length-2
  numeric `c(x, y)`.

## Value

A list of class `mapgl_tooltip_style`.

## Examples

``` r
if (FALSE) { # \dontrun{
# A dark preset, tweaked
tooltip_style("dark", border_radius = 8, font_size = 13)

# Fully custom
tooltip_style(
  background_color = "rgba(20,30,48,0.95)",
  text_color = "#e6edf3",
  border_radius = 6
)
} # }
```
