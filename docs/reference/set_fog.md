# Set fog on a Mapbox GL map

Set fog on a Mapbox GL map

## Usage

``` r
set_fog(
  map,
  range = NULL,
  color = NULL,
  horizon_blend = NULL,
  high_color = NULL,
  space_color = NULL,
  star_intensity = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function or a proxy object.

- range:

  A numeric vector of length 2 defining the minimum and maximum range of
  the fog.

- color:

  A string specifying the color of the fog.

- horizon_blend:

  A number between 0 and 1 controlling the blending of the fog at the
  horizon.

- high_color:

  A string specifying the color of the fog at higher elevations.

- space_color:

  A string specifying the color of the fog in space.

- star_intensity:

  A number between 0 and 1 controlling the intensity of the stars in the
  fog.

## Value

The updated map object.
