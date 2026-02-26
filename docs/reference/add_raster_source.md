# Add a raster tile source to a Mapbox GL or Maplibre GL map

Add a raster tile source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_raster_source(
  map,
  id,
  url = NULL,
  tiles = NULL,
  tileSize = 256,
  maxzoom = 22,
  ...
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- url:

  A URL pointing to the raster tile source. (optional)

- tiles:

  A vector of tile URLs for the raster source. (optional)

- tileSize:

  The size of the raster tiles.

- maxzoom:

  The maximum zoom level for the raster tiles.

- ...:

  Additional arguments to be passed to the JavaScript addSource method.

## Value

The modified map object with the new source added.
