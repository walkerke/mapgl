# Create a bivariate color scale

Create a bivariate color scale

## Usage

``` r
bivariate_scale(
  data = NULL,
  x,
  y,
  x_values = NULL,
  y_values = NULL,
  x_breaks = NULL,
  y_breaks = NULL,
  method = "quantile",
  colors = NULL,
  palette = "blue_pink",
  na_color = "lightgrey"
)
```

## Arguments

- data:

  A data frame or sf object containing the variables.

- x:

  The name of the first numeric column.

- y:

  The name of the second numeric column.

- x_values:

  Optional numeric vector for the first variable.

- y_values:

  Optional numeric vector for the second variable.

- x_breaks:

  Optional numeric vector of four increasing break values for the x
  variable. If NULL, breaks are computed from `x_values`.

- y_breaks:

  Optional numeric vector of four increasing break values for the y
  variable. If NULL, breaks are computed from `y_values`.

- method:

  Classification method. The MVP supports `"quantile"`.

- colors:

  A 3 by 3 matrix or 9-color vector. If NULL, a built-in palette is
  used.

- palette:

  Built-in palette name. Defaults to `"blue_pink"`. Use
  [`bivariate_palettes()`](https://walker-data.com/mapgl/reference/bivariate_palettes.md)
  to inspect available palettes.

- na_color:

  Color for missing values. Defaults to `"lightgrey"`.

## Value

A `mapgl_bivariate_scale` object.
