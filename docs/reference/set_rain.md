# Set rain effect on a Mapbox GL map

Set rain effect on a Mapbox GL map

## Usage

``` r
set_rain(
  map,
  density = 0.5,
  intensity = 1,
  color = "#a8adbc",
  opacity = 0.7,
  center_thinning = 0.57,
  direction = c(0, 80),
  droplet_size = c(2.6, 18.2),
  distortion_strength = 0.7,
  vignette = 1,
  vignette_color = "#464646",
  remove = FALSE
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function or a proxy object.

- density:

  A number between 0 and 1 controlling the rain particles density.
  Default is 0.5.

- intensity:

  A number between 0 and 1 controlling the rain particles movement
  speed. Default is 1.

- color:

  A string specifying the color of the rain droplets. Default is
  "#a8adbc".

- opacity:

  A number between 0 and 1 controlling the rain particles opacity.
  Default is 0.7.

- center_thinning:

  A number between 0 and 1 controlling the thinning factor of rain
  particles from center. Default is 0.57.

- direction:

  A numeric vector of length 2 defining the azimuth and polar angles of
  the rain direction. Default is c(0, 80).

- droplet_size:

  A numeric vector of length 2 controlling the rain droplet size (x -
  normal to direction, y - along direction). Default is c(2.6, 18.2).

- distortion_strength:

  A number between 0 and 1 controlling the rain particles screen-space
  distortion strength. Default is 0.7.

- vignette:

  A number between 0 and 1 controlling the screen-space vignette rain
  tinting effect intensity. Default is 1.0.

- vignette_color:

  A string specifying the rain vignette screen-space corners tint color.
  Default is "#464646".

- remove:

  A logical value indicating whether to remove the rain effect. Default
  is FALSE.

## Value

The updated map object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Add rain effect with default values
mapboxgl(...) |> set_rain()

# Add rain effect with custom values
mapboxgl(
  style = mapbox_style("standard"),
  center = c(24.951528, 60.169573),
  zoom = 16.8,
  pitch = 74,
  bearing = 12.8
) |>
  set_rain(
    density = 0.5,
    opacity = 0.7,
    color = "#a8adbc"
  )
  
# Remove rain effect (useful in Shiny)
map_proxy |> set_rain(remove = TRUE)
} # }
```
