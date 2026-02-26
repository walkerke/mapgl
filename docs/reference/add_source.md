# Add a GeoJSON or sf source to a Mapbox GL or Maplibre GL map

Add a GeoJSON or sf source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_source(map, id, data, ...)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- data:

  An sf object or a URL pointing to a remote GeoJSON file.

- ...:

  Additional arguments to be passed to the JavaScript addSource method.

## Value

The modified map object with the new source added.
