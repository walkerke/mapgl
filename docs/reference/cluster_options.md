# Prepare cluster options for circle layers

This function creates a list of options for clustering circle layers.
Clusters are drawn as circles colored by point count, or, when
`donut_column` is set, as donut charts showing the mix of categories
inside each cluster.

## Usage

``` r
cluster_options(
  max_zoom = 14,
  cluster_radius = NULL,
  color_stops = c("#51bbd6", "#f1f075", "#f28cb1"),
  radius_stops = c(20, 30, 40),
  count_stops = c(0, 100, 750),
  circle_blur = NULL,
  circle_opacity = NULL,
  circle_stroke_color = NULL,
  circle_stroke_opacity = NULL,
  circle_stroke_width = NULL,
  text_color = "black",
  count_format = c("abbreviated", "grouped", "raw"),
  donut_column = NULL,
  donut_values = NULL,
  donut_colors = NULL,
  donut_weight = NULL,
  donut_width = 0.35,
  donut_fill = "white",
  donut_resolution = 2
)
```

## Arguments

- max_zoom:

  The maximum zoom level at which to cluster points.

- cluster_radius:

  The radius of each cluster when clustering points, in pixels. Defaults
  to 50 for circle clusters and to 1.5 times the largest of
  `radius_stops` (60 by default) for donut clusters, which keeps
  neighboring donuts from piling on top of each other.

- color_stops:

  A vector of colors for the circle color step expression. Ignored for
  donut clusters.

- radius_stops:

  A vector of radii for the circle radius step expression. Also sizes
  donut clusters.

- count_stops:

  A vector of point counts for both color and radius step expressions.

- circle_blur:

  Amount to blur the circle. Ignored for donut clusters.

- circle_opacity:

  The opacity of the circle. For donut clusters, the opacity of the
  whole donut.

- circle_stroke_color:

  The color of the circle's stroke. For donut clusters, the color of the
  donut's outer edge (default `"white"`).

- circle_stroke_opacity:

  The opacity of the circle's stroke.

- circle_stroke_width:

  The width of the circle's stroke. For donut clusters, the width of the
  donut's outer edge in pixels (default `1`).

- text_color:

  The color to use for labels on the cluster circles.

- count_format:

  The formatting of the text labels on the cluster circles to represent
  the counts. `"abbreviated"` (the default) will use shortened notation,
  e.g. "11k", "1.7M", or "1.5B". `"grouped"` will show comma-separated
  numbers, e.g. "11,000". `"raw"` shows the raw value.

- donut_column:

  The name of a categorical column. When set, clusters are drawn as
  donut charts showing the share of each category within the cluster.

- donut_values, donut_colors:

  The categories to show and their colors, one color per entry of
  `donut_values`. Pass a list to group several values under one color,
  e.g. `list(c("Oil", "Gas"), "Dry Hole")`. When `NULL` (the default),
  both are taken from the layer's `circle_color` if it is a
  [`match_expr()`](https://walker-data.com/mapgl/reference/match_expr.md)
  on `donut_column`; its `default` color becomes an "other" slice for
  unlisted values. Required for
  [`add_symbol_layer()`](https://walker-data.com/mapgl/reference/add_symbol_layer.md).

- donut_weight:

  An optional numeric column to sum instead of counting points, e.g.
  population. The cluster label then shows the weighted total. Missing
  weights count as zero.

- donut_width:

  The thickness of the donut ring as a fraction of its radius, between 0
  and 1.

- donut_fill:

  The color of the donut's center, behind the count label. Use `NA` for
  a transparent center.

- donut_resolution:

  The step, in percent, to which category shares are rounded (an integer
  from 1 to 10). Categories whose share rounds to zero are not drawn.

## Value

A list of cluster options.

## Details

**Donut clusters.** Setting `donut_column` computes per-category totals
for every cluster and draws each cluster as a donut chart in the
category colors. Colors are usually taken from the unclustered layer's
`circle_color` so that clusters and points match:

    add_circle_layer(
      id = "people",
      source = dots,
      circle_color = match_expr(
        "race",
        values = c("White", "Black", "Hispanic", "Asian"),
        stops = c("#1b9e77", "#d95f02", "#7570b3", "#e7298a")
      ),
      cluster_options = cluster_options(donut_column = "race")
    )

Build a matching legend by passing the same values and colors to
[`add_categorical_legend()`](https://walker-data.com/mapgl/reference/map_legends.md).
Colors taken from
[`match_expr()`](https://walker-data.com/mapgl/reference/match_expr.md)
have already had any alpha channel removed; pass `donut_colors` to keep
transparency. The ring shares are among the categories drawn: without an
"other" slice, points with unlisted or missing categories are left out
of the ring (but still count toward `point_count`, and toward the
weighted label total when `donut_weight` is set).

Computing category totals makes clustering about two to three times
slower than plain clustering with ten categories. Each distinct mix of
rounded shares is drawn as its own small image and kept for the life of
the map, so a long session panning across many zoom levels accumulates
images (tens of MB over a wide sweep of a large dataset). A coarser
`donut_resolution` produces fewer distinct images.

**Pre-clustered vector tiles.** For tiles that are already clustered
(e.g. by freestiler), donut clusters read these properties from each
cluster feature: `point_count`, one `"<donut_column>:<value>"` total per
category (a count, or the sum of `donut_weight`),
`"<donut_column>:_other"` for the other slice when there is one, and
`"<donut_column>:_total"`, the weight summed over all points, when
`donut_weight` is set. Numeric categories must be whole numbers and are
written without exponents, e.g. `"code:100000"`. Missing properties
count as zero. `_other` and `_total` are reserved and can't be used as
category values.

## Examples

``` r
cluster_options(
    max_zoom = 14,
    cluster_radius = 50,
    color_stops = c("#51bbd6", "#f1f075", "#f28cb1"),
    radius_stops = c(20, 30, 40),
    count_stops = c(0, 100, 750),
    circle_blur = 1,
    circle_opacity = 0.8,
    circle_stroke_color = "#ffffff",
    circle_stroke_width = 2
)
#> $max_zoom
#> [1] 14
#> 
#> $cluster_radius
#> [1] 50
#> 
#> $color_stops
#> [1] "#51bbd6" "#f1f075" "#f28cb1"
#> 
#> $radius_stops
#> [1] 20 30 40
#> 
#> $count_stops
#> [1]   0 100 750
#> 
#> $circle_blur
#> [1] 1
#> 
#> $circle_opacity
#> [1] 0.8
#> 
#> $circle_stroke_color
#> [1] "#ffffff"
#> 
#> $circle_stroke_opacity
#> NULL
#> 
#> $circle_stroke_width
#> [1] 2
#> 
#> $text_color
#> [1] "black"
#> 
#> $count_format
#> [1] "abbreviated"
#> 

# Donut clusters with explicit categories and colors
cluster_options(
    donut_column = "type",
    donut_values = c("Oil", "Gas", "Dry Hole"),
    donut_colors = c("#1B5E20", "#fc8d59", "#cd5c5c")
)
#> $max_zoom
#> [1] 14
#> 
#> $cluster_radius
#> [1] 60
#> 
#> $color_stops
#> [1] "#51bbd6" "#f1f075" "#f28cb1"
#> 
#> $radius_stops
#> [1] 20 30 40
#> 
#> $count_stops
#> [1]   0 100 750
#> 
#> $circle_blur
#> NULL
#> 
#> $circle_opacity
#> NULL
#> 
#> $circle_stroke_color
#> NULL
#> 
#> $circle_stroke_opacity
#> NULL
#> 
#> $circle_stroke_width
#> NULL
#> 
#> $text_color
#> [1] "black"
#> 
#> $count_format
#> [1] "abbreviated"
#> 
#> $donut
#> $donut$column
#> [1] "type"
#> 
#> $donut$values
#> [1] "Oil"      "Gas"      "Dry Hole"
#> 
#> $donut$colors
#> [1] "#1B5E20" "#fc8d59" "#cd5c5c"
#> 
#> $donut$weight
#> NULL
#> 
#> $donut$width
#> [1] 0.35
#> 
#> $donut$fill
#> [1] "white"
#> 
#> $donut$resolution
#> [1] 2
#> 
#> 
```
