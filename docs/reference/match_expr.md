# Create a match expression

This function generates a match expression that can be used to style
your data.

## Usage

``` r
match_expr(column = NULL, property = NULL, values, stops, default = "#cccccc")
```

## Arguments

- column:

  The name of the column to use for the match expression. If specified,
  `property` should be NULL.

- property:

  The name of the property to use for the match expression. If
  specified, `column` should be NULL.

- values:

  A vector of values to match against.

- stops:

  A vector of corresponding stops (colors, etc.) for the matched values.

- default:

  A default value to use if no matches are found.

## Value

A list representing the match expression.

## Examples

``` r
match_expr(
    column = "category",
    values = c("A", "B", "C"),
    stops = c("#ff0000", "#00ff00", "#0000ff"),
    default = "#cccccc"
)
#> [[1]]
#> [1] "match"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "category"
#> 
#> 
#> [[3]]
#> [1] "A"
#> 
#> [[4]]
#> [1] "#ff0000"
#> 
#> [[5]]
#> [1] "B"
#> 
#> [[6]]
#> [1] "#00ff00"
#> 
#> [[7]]
#> [1] "C"
#> 
#> [[8]]
#> [1] "#0000ff"
#> 
#> [[9]]
#> [1] "#cccccc"
#> 
```
