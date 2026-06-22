# Style a slider control

Builds an appearance specification for
[`add_slider_control()`](https://walker-data.com/mapgl/reference/add_slider_control.md).
Use a preset string (`"light"`, `"dark"`, or `"auto"`) as a starting
point and override individual pieces of the control on top of it. The
older `background_color`, `text_color`, `accent_color`, and `width`
arguments on
[`add_slider_control()`](https://walker-data.com/mapgl/reference/add_slider_control.md)
continue to work for simple styling; use `slider_style()` when you need
control over the container, play button, track, thumb, and histogram.

## Usage

``` r
slider_style(
  preset = NULL,
  width = NULL,
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
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  title_color = NULL,
  title_size = NULL,
  title_weight = NULL,
  value_color = NULL,
  value_size = NULL,
  value_weight = NULL,
  accent_color = NULL,
  play_button_background = NULL,
  play_button_color = NULL,
  play_button_border_color = NULL,
  track_color = NULL,
  active_color = NULL,
  track_height = NULL,
  thumb_color = NULL,
  thumb_border_color = NULL,
  thumb_size = NULL,
  histogram_height = NULL,
  histogram_bar_color = NULL,
  histogram_active_opacity = NULL,
  histogram_inactive_opacity = NULL
)
```

## Arguments

- preset:

  Optional base theme: `"light"`, `"dark"`, or `"auto"`. `"auto"`
  currently resolves to the light preset.

- width:

  Slider container width in pixels.

- background_color:

  CSS color for the control background.

- background_opacity:

  Numeric in `[0, 1]` for background opacity.

- text_color:

  CSS color for general text.

- border_color:

  CSS color for the container border.

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

  Internal padding as a CSS size string or numeric pixels.

- shadow:

  Logical; whether to draw a drop shadow.

- shadow_color:

  CSS color of the drop shadow.

- shadow_size:

  Blur radius of the drop shadow in pixels.

- title_color, title_size, title_weight:

  Styling for the optional title.

- value_color, value_size, value_weight:

  Styling for the current value label.

- accent_color:

  Main accent color. Used as the default active track, thumb, play
  hover, and histogram color.

- play_button_background, play_button_color, play_button_border_color:

  Styling for the play/pause button.

- track_color, active_color:

  CSS colors for the inactive and active track.

- track_height:

  Track height in pixels.

- thumb_color, thumb_border_color:

  CSS colors for the slider thumb.

- thumb_size:

  Thumb diameter in pixels.

- histogram_height:

  Histogram height in pixels.

- histogram_bar_color:

  Histogram bar color.

- histogram_active_opacity, histogram_inactive_opacity:

  Bar opacity for selected and unselected histogram bins.

## Value

A list of class `mapgl_slider_style`.

## Examples

``` r
if (FALSE) { # \dontrun{
slider_style("dark", accent_color = "#9fd3ff")

slider_style(
  background_color = "rgba(20, 30, 48, 0.92)",
  text_color = "#f8fafc",
  active_color = "#7dd3fc",
  thumb_size = 18
)
} # }
```
