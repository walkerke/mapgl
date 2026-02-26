# Convert R color palette to mapgl LUT

This function takes an R color palette and converts it into a
base64-encoded LUT (Look-Up Table) image that can be used with Mapbox GL
JS v3+ for custom map themes. The LUT applies color transformations to
the basemap.

## Usage

``` r
palette_to_lut(
  colors,
  n = 5,
  method = c("tint", "replace", "duotone", "tritone", "luminosity"),
  intensity = 0.5,
  lut_size = 32,
  reverse = FALSE
)
```

## Arguments

- colors:

  Character vector of colors (hex or R color names) or a function that
  generates colors (like viridis)

- n:

  Number of colors to sample from the palette (if colors is a function)

- method:

  Method for applying colors to the LUT:

  - `"tint"`: Applies palette as a color tint/overlay

  - `"replace"`: Maps grayscale values to palette colors

  - `"duotone"`: Creates duotone effect with first two colors

  - `"tritone"`: Creates tritone effect with first three colors

  - `"luminosity"`: Applies palette based on pixel luminosity

- intensity:

  Strength of the effect (0-1)

- lut_size:

  Size of the LUT (16, 32, or 64)

- reverse:

  Logical; whether to reverse the color palette

## Value

Base64-encoded PNG data URI string

## Examples

``` r
if (FALSE) { # \dontrun{
# Using viridis palette
theme_data <- palette_to_lut(viridisLite::viridis(5))

# Using a palette function directly
theme_data <- palette_to_lut(viridisLite::plasma, n = 7)

# Using RColorBrewer
theme_data <- palette_to_lut(RColorBrewer::brewer.pal(9, "YlOrRd"))

# Use in mapboxgl (requires Mapbox GL JS v3+)
mapboxgl(
  center = c(139.7, 35.7),
  zoom = 10,
  config = list(
    basemap = list(
      theme = "custom",
      "theme-data" = theme_data
    )
  )
)
} # }
```
