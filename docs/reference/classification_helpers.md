# Extract information from classification and continuous scale objects

These functions extract different components from mapgl_classification
objects (created by
[`step_equal_interval()`](https://walker-data.com/mapgl/reference/step_classification.md),
[`step_quantile()`](https://walker-data.com/mapgl/reference/step_classification.md),
[`step_jenks()`](https://walker-data.com/mapgl/reference/step_classification.md))
and mapgl_continuous_scale objects (created by
[`interpolate_palette()`](https://walker-data.com/mapgl/reference/interpolate_palette.md)).

## Usage

``` r
get_legend_labels(
  scale,
  format = "none",
  currency_symbol = "$",
  digits = 2,
  big_mark = ",",
  suffix = "",
  prefix = ""
)

get_legend_colors(scale)

get_breaks(scale)

# S3 method for class 'mapgl_classification'
print(x, format = "none", ...)

# S3 method for class 'mapgl_continuous_scale'
print(x, format = "none", ...)
```

## Arguments

- scale:

  A mapgl_classification or mapgl_continuous_scale object.

- format:

  A character string specifying the format type for labels. Options
  include:

  - "none" (default): No special formatting

  - "currency": Format as currency (e.g., "\$1,234")

  - "percent": Format as percentage (e.g., "12.3%")

  - "scientific": Format in scientific notation (e.g., "1.2e+03")

  - "compact": Format with abbreviated units (e.g., "1.2K", "3.4M")

- currency_symbol:

  The currency symbol to use when format = "currency". Defaults to "\$".

- digits:

  The number of decimal places to display. Defaults to 2.

- big_mark:

  The character to use as thousands separator. Defaults to ",".

- suffix:

  An optional suffix to add to all values (e.g., "km", "mph").

- prefix:

  An optional prefix to add to all values (useful for compact currency
  like "\$1.2K").

- x:

  A mapgl_classification or mapgl_continuous_scale object to print.

- ...:

  Additional arguments passed to formatting functions.

## Value

- get_legend_labels():

  A character vector of formatted legend labels

- get_legend_colors():

  A character vector of colors

- get_breaks():

  A numeric vector of break values

## Examples

``` r
if (FALSE) { # \dontrun{
# Texas county income data
library(tidycensus)
tx <- get_acs(geography = "county", variables = "B19013_001",
              state = "TX", geometry = TRUE)

# Classification examples
eq_class <- step_equal_interval("estimate", tx$estimate, n = 4)
labels <- get_legend_labels(eq_class, format = "currency")
colors <- get_legend_colors(eq_class)
breaks <- get_breaks(eq_class)

# Continuous scale examples
scale <- interpolate_palette("estimate", tx$estimate, method = "quantile", n = 5)
labels <- get_legend_labels(scale, format = "compact", prefix = "$")
colors <- get_legend_colors(scale)
} # }
```
