# Render a map as a static image

Renders a mapgl map as a static PNG image for display. When called
inside a knitr/Quarto document, the map is included as a static figure
via
[`knitr::include_graphics()`](https://rdrr.io/pkg/knitr/man/include_graphics.html).
In an interactive session, the image is displayed in the R graphics
device.

## Usage

``` r
print_map(
  map,
  width = 900,
  height = 500,
  include_legend = TRUE,
  hide_controls = TRUE,
  include_scale_bar = TRUE,
  basemap_color = NULL,
  image_scale = 1,
  background = "white",
  delay = NULL
)
```

## Arguments

- map:

  A map object created by
  [`mapboxgl()`](https://walker-data.com/mapgl/reference/mapboxgl.md) or
  [`maplibre()`](https://walker-data.com/mapgl/reference/maplibre.md).

- width:

  Integer. The width of the map viewport in pixels. Always overrides any
  `width` configured when the map widget was created.

- height:

  Integer. The height of the map viewport in pixels. Always overrides
  any `height` configured when the map widget was created.

- include_legend:

  Logical. Include the legend in the output? Default `TRUE`.

- hide_controls:

  Logical. Hide navigation and other interactive controls? Default
  `TRUE`.

- include_scale_bar:

  Logical. Include the scale bar? Default `TRUE`.

- basemap_color:

  Character string or `NULL`. If specified, basemap tiles are removed
  and replaced with this background color (e.g., `"white"`,
  `"lightgrey"`, `"#f0f0f0"`). Use `"transparent"` for no background.
  Default `NULL` (keep basemap).

- image_scale:

  Numeric. Scale factor for the output image. Use `2` for retina/HiDPI
  output. Default `1`.

- background:

  Character string or `NULL`. Background color for the output image.
  Default `"white"`. Set to `NULL` for a transparent background. Ignored
  when `basemap_color` is set (basemap_color controls the background in
  that case).

- delay:

  Numeric or `NULL`. Additional delay in seconds to wait after the map
  reports idle, before capturing. Useful for maps with complex
  rendering. Default `NULL` (no extra delay).

## Value

In a knitr context, the result of
[`knitr::include_graphics()`](https://rdrr.io/pkg/knitr/man/include_graphics.html).
In an interactive session, the image is displayed and the temporary file
path is returned invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

map <- maplibre(
  center = c(-96, 37.8),
  zoom = 3
)

# In a Quarto document chunk
print_map(map)

# With custom dimensions
print_map(map, width = 1200, height = 800, image_scale = 2)
} # }
```
