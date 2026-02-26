# Create a concatenation expression

This function creates a concatenation expression that combines multiple
values or expressions into a single string. Useful for creating dynamic
tooltips or labels.

## Usage

``` r
concat(...)
```

## Arguments

- ...:

  Values or expressions to concatenate. Can be strings, numbers, or
  other expressions like
  [`get_column()`](https://walker-data.com/mapgl/reference/get_column.md).

## Value

A list representing the concatenation expression.

## Examples

``` r
# Create a dynamic tooltip
concat("<strong>Name:</strong> ", get_column("name"), "<br>Value: ", get_column("value"))
#> [[1]]
#> [1] "concat"
#> 
#> [[2]]
#> [1] "<strong>Name:</strong> "
#> 
#> [[3]]
#> [[3]][[1]]
#> [1] "get"
#> 
#> [[3]][[2]]
#> [1] "name"
#> 
#> 
#> [[4]]
#> [1] "<br>Value: "
#> 
#> [[5]]
#> [[5]][[1]]
#> [1] "get"
#> 
#> [[5]][[2]]
#> [1] "value"
#> 
#> 
```
