# Create a blank basemap style

Creates a minimal map style with only a solid background color (or
pattern) and no basemap tiles. Useful when you want to display data
layers without any underlying map features.

## Usage

``` r
basemap_style(color = "white", pattern = NULL)
```

## Arguments

- color:

  Character string. The background color. Default `"white"`. Accepts any
  CSS color value (e.g., `"#f0f0f0"`, `"lightgrey"`, `"rgba(0,0,0,0)"`).
  Also used as a fallback behind transparent areas of a `pattern`.

- pattern:

  Character string or `NULL`. The ID of an image to use as a repeating
  background pattern. The image must be loaded with
  [`add_image()`](https://walker-data.com/mapgl/reference/add_image.md)
  before it can be referenced. Default `NULL` (solid color only).

## Value

A list representing a minimal map style, suitable for passing to the
`style` parameter of
[`maplibre()`](https://walker-data.com/mapgl/reference/maplibre.md) or
[`mapboxgl()`](https://walker-data.com/mapgl/reference/mapboxgl.md).

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

# Solid color background
maplibre(style = basemap_style("lightgrey")) |>
  add_fill_layer(
    id = "data",
    source = my_sf_data,
    fill_color = "steelblue"
  )

# Background pattern (image must be loaded with add_image())
maplibre(style = basemap_style(pattern = "parchment")) |>
  add_image("parchment", "parchment.jpg") |>
  add_line_layer(
    id = "borders",
    source = my_sf_data,
    line_color = "#2c1810"
  )
} # }
```
