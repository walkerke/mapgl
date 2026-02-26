# Step expressions with automatic classification

These functions create step expressions using different classification
methods, similar to choropleth mapping in GIS software. They
automatically calculate break points and generate appropriate step
expressions for styling map layers.

## Usage

``` r
step_equal_interval(
  data = NULL,
  column,
  data_values = NULL,
  n = 5,
  palette = NULL,
  colors = NULL,
  na_color = "grey"
)

step_quantile(
  data = NULL,
  column,
  data_values = NULL,
  n = 5,
  palette = NULL,
  colors = NULL,
  na_color = "grey"
)

step_jenks(
  data = NULL,
  column,
  data_values = NULL,
  n = 5,
  palette = NULL,
  colors = NULL,
  na_color = "grey"
)
```

## Arguments

- data:

  A data frame or sf object containing the data. If provided,
  data_values will be extracted from `data[[column]]`. Either data or
  data_values must be provided.

- column:

  The name of the column to use for the step expression.

- data_values:

  A numeric vector of the actual data values used to calculate breaks.
  If NULL and data is provided, will be extracted from `data[[column]]`.

- n:

  The number of classes/intervals to create. Defaults to 5.

- palette:

  A function that takes n and returns a character vector of colors. If
  NULL and colors is also NULL, defaults to
  [`viridisLite::viridis`](https://sjmgarnier.github.io/viridisLite/reference/viridis.html).

- colors:

  A character vector of colors to use. Must have exactly n colors for
  step classification functions. Either palette or colors should be
  provided, but not both.

- na_color:

  The color to use for missing values. Defaults to "grey".

## Value

A list of class "mapgl_classification" containing the step expression
and metadata.

## Details

- step_equal_interval():

  Creates equal interval breaks by dividing the data range into equal
  parts

- step_quantile():

  Creates quantile breaks ensuring approximately equal numbers of
  observations in each class

- step_jenks():

  Creates Jenks natural breaks using Fisher-Jenks optimization to
  minimize within-class variance

## See also

[`interpolate_palette()`](https://walker-data.com/mapgl/reference/interpolate_palette.md)
for continuous color scales

## Examples

``` r
if (FALSE) { # \dontrun{
# Texas county income data
library(tidycensus)
tx <- get_acs(geography = "county", variables = "B19013_001",
              state = "TX", geometry = TRUE)

# Using palette function (recommended)
eq_class <- step_equal_interval(data = tx, column = "estimate", n = 5,
                                palette = viridisLite::plasma)
# Or with piping
eq_class <- tx |> step_equal_interval("estimate", n = 5)

# Using specific colors
qt_class <- step_quantile(data = tx, column = "estimate", n = 3,
                         colors = c("red", "yellow", "blue"))

# Jenks natural breaks with default viridis
jk_class <- step_jenks(data = tx, column = "estimate", n = 5)

# Use in a map with formatted legend
maplibre() |>
  add_fill_layer(source = tx, fill_color = eq_class$expression) |>
  add_legend(
    legend_title = "Median Income",
    values = get_legend_labels(eq_class, format = "currency"),
    colors = get_legend_colors(eq_class),
    type = "categorical"
  )

# Compare different methods
print(eq_class, format = "currency")
print(qt_class, format = "compact", prefix = "$")
} # }
```
