# Quick visualization of geometries with MapLibre GL

This function provides a quick way to visualize sf geometries and raster
data using MapLibre GL JS. It automatically detects the geometry type
and applies appropriate styling.

## Usage

``` r
maplibre_view(
  data,
  color = "navy",
  column = NULL,
  n = NULL,
  palette = viridisLite::viridis,
  style = carto_style("positron"),
  layer_id = "quickview",
  legend = TRUE,
  legend_position = "top-left",
  interactive_legend = FALSE,
  ...
)
```

## Arguments

- data:

  An sf object, SpatRaster, or RasterLayer to visualize

- color:

  The color used to visualize points, lines, or polygons if `column` is
  NULL. Defaults to `"navy"`.

- column:

  The name of the column to visualize. If NULL (default), geometries are
  shown with default styling.

- n:

  Number of quantile breaks for numeric columns. If specified, uses
  step_expr() instead of interpolate().

- palette:

  Color palette function that takes n and returns a character vector of
  colors. Defaults to viridisLite::viridis.

- style:

  The MapLibre style to use. Defaults to carto_style("positron").

- layer_id:

  The layer ID to use for the visualization. Defaults to "quickview".

- legend:

  Logical, whether to add a legend when a column is specified. Defaults
  to TRUE.

- legend_position:

  The position of the legend on the map. Defaults to "top-left".

- interactive_legend:

  Logical, whether to make the legend interactive. When TRUE,
  categorical legends allow clicking to toggle visibility, and
  continuous legends show a range slider. Defaults to FALSE.

- ...:

  Additional arguments passed to maplibre()

## Value

A MapLibre GL map object

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

# Basic view
maplibre_view(nc)

# View with column visualization
maplibre_view(nc, column = "AREA")

# View with quantile breaks
maplibre_view(nc, column = "AREA", n = 5)

# Custom palette examples
maplibre_view(nc, column = "AREA", palette = viridisLite::mako)
maplibre_view(nc, column = "AREA", palette = function(n) RColorBrewer::brewer.pal(n, "RdYlBu"))
maplibre_view(nc, column = "AREA", palette = colorRampPalette(c("red", "white", "blue")))
} # }
```
