# Create an interpolation expression

This function generates an interpolation expression that can be used to
style your data.

## Usage

``` r
interpolate(
  column = NULL,
  property = NULL,
  type = "linear",
  values,
  stops,
  na_color = NULL
)
```

## Arguments

- column:

  The name of the column to use for the interpolation. If specified,
  `property` should be NULL.

- property:

  The name of the property to use for the interpolation. If specified,
  `column` should be NULL.

- type:

  The interpolation type. Can be one of `"linear"`,
  `list("exponential", base)` where `base` specifies the rate at which
  the output increases, or `list("cubic-bezier", x1, y1, x2, y2)` where
  you define a cubic bezier curve with control points.

- values:

  A numeric vector of values at which stops occur.

- stops:

  A vector of corresponding stops (colors, sizes, etc.) for the
  interpolation.

- na_color:

  The color to use for missing values. Mapbox GL JS defaults to black if
  this is not supplied.

## Value

A list representing the interpolation expression.

## Examples

``` r
interpolate(
    column = "estimate",
    type = "linear",
    values = c(1000, 200000),
    stops = c("#eff3ff", "#08519c")
)
#> [[1]]
#> [1] "interpolate"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "linear"
#> 
#> 
#> [[3]]
#> [[3]][[1]]
#> [1] "get"
#> 
#> [[3]][[2]]
#> [1] "estimate"
#> 
#> 
#> [[4]]
#> [1] 1000
#> 
#> [[5]]
#> [1] "#eff3ff"
#> 
#> [[6]]
#> [1] 2e+05
#> 
#> [[7]]
#> [1] "#08519c"
#> 
```
