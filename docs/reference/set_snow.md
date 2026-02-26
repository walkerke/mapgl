# Set snow effect on a Mapbox GL map

Set snow effect on a Mapbox GL map

## Usage

``` r
set_snow(
  map,
  density = 0.85,
  intensity = 1,
  color = "#ffffff",
  opacity = 1,
  center_thinning = 0.4,
  direction = c(0, 50),
  flake_size = 0.71,
  vignette = 0.3,
  vignette_color = "#ffffff",
  remove = FALSE
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function or a proxy object.

- density:

  A number between 0 and 1 controlling the snow particles density.
  Default is 0.85.

- intensity:

  A number between 0 and 1 controlling the snow particles movement
  speed. Default is 1.0.

- color:

  A string specifying the color of the snow particles. Default is
  "#ffffff".

- opacity:

  A number between 0 and 1 controlling the snow particles opacity.
  Default is 1.0.

- center_thinning:

  A number between 0 and 1 controlling the thinning factor of snow
  particles from center. Default is 0.4.

- direction:

  A numeric vector of length 2 defining the azimuth and polar angles of
  the snow direction. Default is c(0, 50).

- flake_size:

  A number between 0 and 5 controlling the snow flake particle size.
  Default is 0.71.

- vignette:

  A number between 0 and 1 controlling the snow vignette screen-space
  effect. Default is 0.3.

- vignette_color:

  A string specifying the snow vignette screen-space corners tint color.
  Default is "#ffffff".

- remove:

  A logical value indicating whether to remove the snow effect. Default
  is FALSE.

## Value

The updated map object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Add snow effect with default values
mapboxgl(...) |> set_snow()

# Add snow effect with custom values
mapboxgl(
  style = mapbox_style("standard"),
  center = c(24.951528, 60.169573),
  zoom = 16.8,
  pitch = 74,
  bearing = 12.8
) |>
  set_snow(
    density = 0.85,
    flake_size = 0.71,
    color = "#ffffff"
  )
  
# Remove snow effect (useful in Shiny)
map_proxy |> set_snow(remove = TRUE)
} # }
```
