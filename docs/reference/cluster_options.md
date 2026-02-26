# Prepare cluster options for circle layers

This function creates a list of options for clustering circle layers.

## Usage

``` r
cluster_options(
  max_zoom = 14,
  cluster_radius = 50,
  color_stops = c("#51bbd6", "#f1f075", "#f28cb1"),
  radius_stops = c(20, 30, 40),
  count_stops = c(0, 100, 750),
  circle_blur = NULL,
  circle_opacity = NULL,
  circle_stroke_color = NULL,
  circle_stroke_opacity = NULL,
  circle_stroke_width = NULL,
  text_color = "black"
)
```

## Arguments

- max_zoom:

  The maximum zoom level at which to cluster points.

- cluster_radius:

  The radius of each cluster when clustering points.

- color_stops:

  A vector of colors for the circle color step expression.

- radius_stops:

  A vector of radii for the circle radius step expression.

- count_stops:

  A vector of point counts for both color and radius step expressions.

- circle_blur:

  Amount to blur the circle.

- circle_opacity:

  The opacity of the circle.

- circle_stroke_color:

  The color of the circle's stroke.

- circle_stroke_opacity:

  The opacity of the circle's stroke.

- circle_stroke_width:

  The width of the circle's stroke.

- text_color:

  The color to use for labels on the cluster circles.

## Value

A list of cluster options.

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
```
