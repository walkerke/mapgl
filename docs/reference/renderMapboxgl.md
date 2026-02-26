# Render a Mapbox GL output element in Shiny

Render a Mapbox GL output element in Shiny

## Usage

``` r
renderMapboxgl(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- expr:

  An expression that generates a Mapbox GL map

- env:

  The environment in which to evaluate `expr`

- quoted:

  Is `expr` a quoted expression

## Value

A rendered Mapbox GL map for use in a Shiny server
