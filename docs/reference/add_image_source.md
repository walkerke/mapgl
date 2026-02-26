# Add an image source to a Mapbox GL or Maplibre GL map

Add an image source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_image_source(
  map,
  id,
  url = NULL,
  data = NULL,
  coordinates = NULL,
  colors = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- url:

  A URL pointing to the image source.

- data:

  A `SpatRaster` object from the `terra` package or a `RasterLayer`
  object.

- coordinates:

  A list of coordinates specifying the image corners in clockwise order:
  top left, top right, bottom right, bottom left. For `SpatRaster` or
  `RasterLayer` objects, this will be extracted for you.

- colors:

  A vector of colors to use for the raster image.

## Value

The modified map object with the new source added.
