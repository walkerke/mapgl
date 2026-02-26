# Set Projection for a Mapbox/Maplibre Map

This function sets the projection dynamically after map initialization.

## Usage

``` r
set_projection(map, projection)
```

## Arguments

- map:

  A map object created by mapboxgl() or maplibre() functions, or their
  respective proxy objects

- projection:

  A string representing the projection name (e.g., "mercator", "globe",
  "albers", "equalEarth", etc.)

## Value

The modified map object
