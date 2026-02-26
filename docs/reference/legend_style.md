# Create custom styling for map legends

This function creates a styling object that can be passed to legend
functions to customize the appearance of legends, including colors,
fonts, borders, and shadows.

## Usage

``` r
legend_style(
  background_color = NULL,
  background_opacity = NULL,
  border_color = NULL,
  border_width = NULL,
  border_radius = NULL,
  text_color = NULL,
  text_size = NULL,
  title_color = NULL,
  title_size = NULL,
  font_family = NULL,
  title_font_family = NULL,
  font_weight = NULL,
  title_font_weight = NULL,
  element_border_color = NULL,
  element_border_width = NULL,
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  padding = NULL
)
```

## Arguments

- background_color:

  Background color for the legend container (e.g., "white", "#ffffff").

- background_opacity:

  Opacity of the legend background (0-1, where 1 is fully opaque).

- border_color:

  Color of the legend border (e.g., "black", "#000000").

- border_width:

  Width of the legend border in pixels.

- border_radius:

  Border radius for rounded corners in pixels.

- text_color:

  Color of the legend text (e.g., "black", "#000000").

- text_size:

  Size of the legend text in pixels.

- title_color:

  Color of the legend title text.

- title_size:

  Size of the legend title text in pixels.

- font_family:

  Font family for legend text (e.g., "Arial", "Times New Roman", "Open
  Sans").

- title_font_family:

  Font family for legend title (defaults to font_family if not
  specified).

- font_weight:

  Font weight for legend text (e.g., "normal", "bold", "lighter", or
  numeric like 400, 700).

- title_font_weight:

  Font weight for legend title (defaults to font_weight if not
  specified).

- element_border_color:

  Color for borders around legend elements (color bar for continuous,
  patches/circles for categorical).

- element_border_width:

  Width in pixels for borders around legend elements.

- shadow:

  Logical, whether to add a drop shadow to the legend.

- shadow_color:

  Color of the drop shadow (e.g., "black", "rgba(0,0,0,0.3)").

- shadow_size:

  Size/blur radius of the drop shadow in pixels.

- padding:

  Internal padding of the legend container in pixels.

## Value

A list of class "mapgl_legend_style" containing the styling options.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a dark theme legend style
dark_style <- legend_style(
  background_color = "#2c3e50",
  text_color = "white",
  title_color = "white",
  font_family = "Arial",
  title_font_weight = "bold",
  element_border_color = "white",
  element_border_width = 1,
  shadow = TRUE,
  shadow_color = "rgba(0,0,0,0.3)",
  shadow_size = 6
)

# Use the style in a legend
add_categorical_legend(
  map = map,
  legend_title = "Categories",
  values = c("A", "B", "C"),
  colors = c("red", "green", "blue"),
  style = dark_style
)

# Create a minimal style with just borders
minimal_style <- legend_style(
  element_border_color = "gray",
  element_border_width = 1
)
} # }
```
