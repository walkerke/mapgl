# Quick visualization of geometries with Mapbox GL

This function provides a quick way to visualize sf geometries and raster
data using Mapbox GL JS. It automatically detects the geometry type and
applies appropriate styling.

## Usage

``` r
mapboxgl_view(
  data,
  color = "navy",
  column = NULL,
  n = NULL,
  palette = viridisLite::viridis,
  style = mapbox_style("light"),
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

  The Mapbox style to use. Defaults to mapbox_style("light").

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

  Additional arguments passed to mapboxgl()

## Value

A Mapbox GL map object

## Examples

``` r
if (FALSE) { # \dontrun{
library(sf)
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

# Basic view
mapboxgl_view(nc)

# View with column visualization
mapboxgl_view(nc, column = "AREA")

# View with quantile breaks
mapboxgl_view(nc, column = "AREA", n = 5)

# Custom palette examples
mapboxgl_view(nc, column = "AREA", palette = viridisLite::mako)
mapboxgl_view(nc, column = "AREA", palette = function(n) RColorBrewer::brewer.pal(n, "RdYlBu"))
mapboxgl_view(nc, column = "AREA", palette = colorRampPalette(c("red", "white", "blue")))
} # }
```
