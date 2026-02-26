# Create a step expression

This function generates a step expression that can be used in your
styles.

## Usage

``` r
step_expr(column = NULL, property = NULL, base, values, stops, na_color = NULL)
```

## Arguments

- column:

  The name of the column to use for the step expression. If specified,
  `property` should be NULL.

- property:

  The name of the property to use for the step expression. If specified,
  `column` should be NULL.

- base:

  The base value to use for the step expression.

- values:

  A numeric vector of values at which steps occur.

- stops:

  A vector of corresponding stops (colors, sizes, etc.) for the steps.

- na_color:

  The color to use for missing values. Mapbox GL JS defaults to black if
  this is not supplied.

## Value

A list representing the step expression.

## Examples

``` r
step_expr(
    column = "value",
    base = "#ffffff",
    values = c(1000, 5000, 10000),
    stops = c("#ff0000", "#00ff00", "#0000ff")
)
#> [[1]]
#> [1] "step"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "value"
#> 
#> 
#> [[3]]
#> [1] "#ffffff"
#> 
#> [[4]]
#> [1] 1000
#> 
#> [[5]]
#> [1] "#ff0000"
#> 
#> [[6]]
#> [1] 5000
#> 
#> [[7]]
#> [1] "#00ff00"
#> 
#> [[8]]
#> [1] 10000
#> 
#> [[9]]
#> [1] "#0000ff"
#> 
```
