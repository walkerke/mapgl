# Add a PMTiles source to a Mapbox GL or Maplibre GL map

Add a PMTiles source to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_pmtiles_source(
  map,
  id,
  url,
  source_type = "vector",
  maxzoom = 22,
  tilesize = 256,
  promote_id = NULL,
  ...
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- url:

  A URL pointing to the PMTiles archive.

- source_type:

  The source type for MapLibre maps. Either "vector" (default) or
  "raster".

- maxzoom:

  Only used when source_type is "raster". The maximum zoom level for the
  PMTiles source. Defaults to 22.

- tilesize:

  Only used when source_type is "raster". The size of the tiles in the
  PMTiles source. Defaults to 256.

- promote_id:

  An optional property name to use as the feature ID. This is required
  for hover effects on vector sources.

- ...:

  Additional arguments to be passed to the JavaScript addSource method.

## Value

The modified map object with the new source added.

## Examples

``` r
if (FALSE) { # \dontrun{

# Visualize the Overture Maps places data as PMTiles
# Works with either `maplibre()` or `mapboxgl()`

library(mapgl)

maplibre(style = maptiler_style("basic", variant = "dark")) |>
  set_projection("globe") |>
  add_pmtiles_source(
    id = "places-source",
    url = "https://overturemaps-tiles-us-west-2-beta.s3.amazonaws.com/2025-06-25/places.pmtiles"
  ) |>
  add_circle_layer(
    id = "places-layer",
    source = "places-source",
    source_layer = "place",
    circle_color = "cyan",
    circle_opacity = 0.7,
    circle_radius = 4,
    tooltip = concat(
      "Name: ",
      get_column("@name"),
      "<br>Confidence: ",
      number_format(get_column("confidence"), maximum_fraction_digits = 2)
    )
  )
} # }
```
