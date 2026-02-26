# Add a visualization layer to an existing map

This function allows you to add additional data layers to existing maps
created with mapboxgl_view() or maplibre_view(), enabling composition of
multiple datasets on a single map.

## Usage

``` r
add_view(
  map,
  data,
  color = "gold",
  column = NULL,
  n = NULL,
  palette = viridisLite::viridis,
  layer_id = NULL,
  legend = FALSE,
  legend_position = "bottom-left"
)
```

## Arguments

- map:

  A map object created by mapboxgl_view(), maplibre_view(), mapboxgl(),
  or maplibre()

- data:

  An sf object, SpatRaster, or RasterLayer to visualize

- color:

  The color used to visualize points, lines, or polygons if `column` is
  NULL. Defaults to "navy".

- column:

  The name of the column to visualize. If NULL (default), geometries are
  shown with default styling.

- n:

  Number of quantile breaks for numeric columns. If specified, uses
  step_expr() instead of interpolate().

- palette:

  Color palette function that takes n and returns a character vector of
  colors. Defaults to viridisLite::viridis.

- layer_id:

  The layer ID to use for the visualization. If NULL, a unique ID will
  be auto-generated.

- legend:

  Logical, whether to add a legend when a column is specified. Defaults
  to FALSE for subsequent layers to avoid overwriting existing legends.

- legend_position:

  The position of the legend on the map. Defaults to "bottom-left".

## Value

The map object with the new layer added

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

# Basic layering
mapboxgl_view(nc) |>
  add_view(nc[1:10, ], color = "red", layer_id = "subset")

# Layer different geometries
mapboxgl_view(polygons) |>
  add_view(points, color = "blue") |>
  add_view(lines, color = "green")

# Add raster data
mapboxgl_view(boundaries) |>
  add_view(elevation_raster, layer_id = "elevation")
} # }
```
