# Render a Maplibre GL output element in Shiny

Render a Maplibre GL output element in Shiny

## Usage

``` r
renderMaplibre(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- expr:

  An expression that generates a Maplibre GL map

- env:

  The environment in which to evaluate `expr`

- quoted:

  Is `expr` a quoted expression

## Value

A rendered Maplibre GL map for use in a Shiny server
