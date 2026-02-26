# Fit the map to a bounding box

Fit the map to a bounding box

## Usage

``` r
fit_bounds(map, bbox, animate = FALSE, ...)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function or a
  proxy object.

- bbox:

  A bounding box specified as a numeric vector of length 4 (minLng,
  minLat, maxLng, maxLat), or an sf object from which a bounding box
  will be calculated.

- animate:

  A logical value indicating whether to animate the transition to the
  new bounds. Defaults to FALSE.

- ...:

  Additional named arguments for fitting the bounds.

## Value

The updated map object.
