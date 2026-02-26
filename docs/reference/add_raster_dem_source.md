# Add a raster DEM source to a Mapbox GL or Maplibre GL map

Add a raster DEM source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_raster_dem_source(map, id, url, tileSize = 512, maxzoom = NULL, ...)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- url:

  A URL pointing to the raster DEM source.

- tileSize:

  The size of the raster tiles.

- maxzoom:

  The maximum zoom level for the raster tiles.

- ...:

  Additional arguments to be passed to the JavaScript addSource method.

## Value

The modified map object with the new source added.
