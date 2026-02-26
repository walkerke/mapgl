# Add a screenshot control to a map

This function adds a screenshot control to a Mapbox GL or MapLibre GL
map. The screenshot control allows users to capture the map along with
legends and attribution as a PNG image download.

## Usage

``` r
add_screenshot_control(
  map,
  position = "top-right",
  filename = "map-screenshot",
  include_legend = TRUE,
  hide_controls = TRUE,
  include_scale_bar = TRUE,
  image_scale = 1,
  button_title = "Capture screenshot"
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "top-right".

- filename:

  The base filename for the downloaded image (without extension).
  Default is "map-screenshot".

- include_legend:

  Logical, whether to include legends in the screenshot. Default is
  TRUE.

- hide_controls:

  Logical, whether to hide interactive controls (navigation, fullscreen,
  etc.) during screenshot capture. Default is TRUE.

- include_scale_bar:

  Logical, whether to keep the scale bar visible in the screenshot when
  `hide_controls = TRUE`. Default is TRUE. The scale bar is the only
  interactive control that renders correctly and provides useful context
  in static images.

- image_scale:

  Numeric, the scale factor for the output image resolution. Default
  is 1. Higher values (2 or 3) produce sharper text and legend elements
  but increase file size. Scale 2 produces 4x larger files, scale 3
  produces 9x larger files.

- button_title:

  The tooltip title for the button. Default is "Capture screenshot".

## Value

The modified map object with the screenshot control added.

## Details

The screenshot is captured using html2canvas, which renders the map
container including legends and attribution. Attribution is always
included in screenshots to comply with map provider terms of service.

Most interactive controls (navigation, fullscreen, etc.) do not render
correctly in screenshots due to SVG rendering limitations and will
appear as blank boxes. The scale bar is an exception and renders
correctly, which is why it is preserved by default via
`include_scale_bar = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

# Basic usage
maplibre(style = carto_style("positron")) |>
  add_screenshot_control()

# With scale control (recommended for screenshots)
maplibre() |>
  add_scale_control(position = "bottom-left") |>
  add_screenshot_control()

# With custom filename
maplibre() |>
  add_fill_layer(
    id = "counties",
    source = list(type = "geojson", data = counties_sf)
  ) |>
  add_legend("Median Income", values = c("Low", "High")) |>
  add_screenshot_control(
    filename = "county-map",
    position = "top-left"
  )

# Exclude legend from screenshot
maplibre() |>
  add_screenshot_control(include_legend = FALSE)
} # }
```
