# Add a vector tile source to a Mapbox GL or Maplibre GL map

Add a vector tile source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_vector_source(map, id, url = NULL, tiles = NULL, promote_id = NULL, ...)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- url:

  A URL pointing to the vector tile source.

- tiles:

  A vector of tile URLs, typically in the format
  "https://example.com/{z}/{x}/{y}.mvt" or similar.

- promote_id:

  An optional property name to use as the feature ID. This is required
  for hover effects on vector tiles.

- ...:

  Additional arguments to be passed to the JavaScript addSource method.

## Value

The modified map object with the new source added.
