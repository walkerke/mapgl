# Save a map as a static PNG image

Renders a mapgl map widget to a static PNG file using headless Chrome
via the chromote package. Uses the same html2canvas-based screenshot
infrastructure as
[`add_screenshot_control()`](https://walker-data.com/mapgl/reference/add_screenshot_control.md).

## Usage

``` r
save_map(
  map,
  filename = "map.png",
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

- filename:

  Character string. The output file path. Defaults to `"map.png"`. If
  the filename does not end in `.png`, the extension is appended
  automatically.

- width:

  Integer. The width of the map viewport in pixels.

- height:

  Integer. The height of the map viewport in pixels.

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

The output file path, invisibly.

## Details

This function requires the chromote package and a Chrome or Chromium
browser installation. Install chromote with
`install.packages("chromote")`.

The function works by:

1.  Saving the map widget to a temporary HTML file

2.  Opening it in headless Chrome

3.  Waiting for all map tiles and styles to load

4.  Using html2canvas to capture the rendered map (including legends,
    attribution, and optionally the scale bar)

5.  Decoding the captured image and writing it to the output file

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

map <- maplibre(
  center = c(-96, 37.8),
  zoom = 3
)

save_map(map, "us_map.png")
save_map(map, "us_map_retina.png", image_scale = 2)

# Remove basemap, keep only data layers on white
save_map(map, "data_only.png", basemap_color = "white")
} # }
```
