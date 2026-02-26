# Add an image to the map

This function adds an image to the map's style. The image can be used
with icon-image, background-pattern, fill-pattern, or line-pattern.

## Usage

``` r
add_image(
  map,
  id,
  url,
  content = NULL,
  pixel_ratio = 1,
  sdf = FALSE,
  stretch_x = NULL,
  stretch_y = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- id:

  A string specifying the ID of the image.

- url:

  A string specifying the URL of the image to be loaded or a path to a
  local image file. Must be PNG or JPEG format.

- content:

  A vector of four numbers `c(x1, y1, x2, y2)` defining the part of the
  image that can be covered by the content in text-field if
  icon-text-fit is used.

- pixel_ratio:

  A number specifying the ratio of pixels in the image to physical
  pixels on the screen.

- sdf:

  A logical value indicating whether the image should be interpreted as
  an SDF image.

- stretch_x:

  A list of number pairs defining the part(s) of the image that can be
  stretched horizontally.

- stretch_y:

  A list of number pairs defining the part(s) of the image that can be
  stretched vertically.

## Value

The modified map object with the image added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

# Path to your local image file OR a URL to a remote image file
# that is not blocked by CORS restrictions
image_path <- "/path/to/your/image.png"

pts <- tigris::landmarks("DE")[1:100, ]

maplibre(bounds = pts) |>
    add_image("local_icon", image_path) |>
    add_symbol_layer(
        id = "local_icons",
        source = pts,
        icon_image = "local_icon",
        icon_size = 0.5,
        icon_allow_overlap = TRUE
    )
} # }
```
