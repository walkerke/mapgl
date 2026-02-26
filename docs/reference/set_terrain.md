# Set terrain properties on a map

Set terrain properties on a map

## Usage

``` r
set_terrain(map, source, exaggeration = 1)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- source:

  The ID of the raster DEM source.

- exaggeration:

  The terrain exaggeration factor.

## Value

The modified map object with the terrain settings applied.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

mapboxgl(
  style = mapbox_style("standard-satellite"),
  center = c(-114.26608, 32.7213),
  zoom = 14,
  pitch = 80,
  bearing = 41
) |>
  add_raster_dem_source(
    id = "mapbox-dem",
    url = "mapbox://mapbox.mapbox-terrain-dem-v1",
    tileSize = 512,
    maxzoom = 14
  ) |>
  set_terrain(
    source = "mapbox-dem",
    exaggeration = 1.5
  )
} # }
```
