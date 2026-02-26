# Create a number formatting expression

This function creates a number formatting expression that formats
numeric values according to locale-specific conventions. It can be used
in tooltips, popups, and text fields for symbol layers.

## Usage

``` r
number_format(
  column,
  locale = "en-US",
  style = "decimal",
  currency = NULL,
  unit = NULL,
  minimum_fraction_digits = NULL,
  maximum_fraction_digits = NULL,
  minimum_integer_digits = NULL,
  use_grouping = NULL,
  notation = NULL,
  compact_display = NULL
)
```

## Arguments

- column:

  The name of the column containing the numeric value to format. Can
  also be an expression that evaluates to a number.

- locale:

  A string specifying the locale to use for formatting (e.g., "en-US",
  "de-DE", "fr-FR"). Defaults to "en-US".

- style:

  The formatting style to use. Options include:

  - "decimal" (default): Plain number formatting

  - "currency": Currency formatting (requires `currency` parameter)

  - "percent": Percentage formatting (multiplies by 100 and adds %)

  - "unit": Unit formatting (requires `unit` parameter)

- currency:

  For style = "currency", the ISO 4217 currency code (e.g., "USD",
  "EUR", "GBP").

- unit:

  For style = "unit", the unit to use (e.g., "kilometer", "mile",
  "liter").

- minimum_fraction_digits:

  The minimum number of fraction digits to display.

- maximum_fraction_digits:

  The maximum number of fraction digits to display.

- minimum_integer_digits:

  The minimum number of integer digits to display.

- use_grouping:

  Whether to use grouping separators (e.g., thousands separators).
  Defaults to TRUE.

- notation:

  The formatting notation. Options include:

  - "standard" (default): Regular notation

  - "scientific": Scientific notation

  - "engineering": Engineering notation

  - "compact": Compact notation (e.g., "1.2K", "3.4M")

- compact_display:

  For notation = "compact", whether to use "short" (default) or "long"
  form.

## Value

A list representing the number-format expression.

## Examples

``` r
# Basic number formatting with thousands separators
number_format("population")
#> [[1]]
#> [1] "number-format"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "population"
#> 
#> 
#> [[3]]
#> [[3]]$locale
#> [1] "en-US"
#> 
#> [[3]]$style
#> [1] "decimal"
#> 
#> 

# Currency formatting
number_format("income", style = "currency", currency = "USD")
#> [[1]]
#> [1] "number-format"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "income"
#> 
#> 
#> [[3]]
#> [[3]]$locale
#> [1] "en-US"
#> 
#> [[3]]$style
#> [1] "currency"
#> 
#> [[3]]$currency
#> [1] "USD"
#> 
#> 

# Percentage with 1 decimal place
number_format("rate", style = "percent", maximum_fraction_digits = 1)
#> [[1]]
#> [1] "number-format"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "rate"
#> 
#> 
#> [[3]]
#> [[3]]$locale
#> [1] "en-US"
#> 
#> [[3]]$style
#> [1] "percent"
#> 
#> [[3]]$`max-fraction-digits`
#> [1] 1
#> 
#> 

# Compact notation for large numbers
number_format("population", notation = "compact")
#> [[1]]
#> [1] "number-format"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "population"
#> 
#> 
#> [[3]]
#> [[3]]$locale
#> [1] "en-US"
#> 
#> [[3]]$style
#> [1] "decimal"
#> 
#> [[3]]$notation
#> [1] "compact"
#> 
#> 

# Using within a tooltip
concat("Population: ", number_format("population", notation = "compact"))
#> [[1]]
#> [1] "concat"
#> 
#> [[2]]
#> [1] "Population: "
#> 
#> [[3]]
#> [[3]][[1]]
#> [1] "number-format"
#> 
#> [[3]][[2]]
#> [[3]][[2]][[1]]
#> [1] "get"
#> 
#> [[3]][[2]][[2]]
#> [1] "population"
#> 
#> 
#> [[3]][[3]]
#> [[3]][[3]]$locale
#> [1] "en-US"
#> 
#> [[3]][[3]]$style
#> [1] "decimal"
#> 
#> [[3]][[3]]$notation
#> [1] "compact"
#> 
#> 
#> 

# Using with get_column()
number_format(get_column("value"), style = "currency", currency = "EUR")
#> [[1]]
#> [1] "number-format"
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
#> [[3]]$locale
#> [1] "en-US"
#> 
#> [[3]]$style
#> [1] "currency"
#> 
#> [[3]]$currency
#> [1] "EUR"
#> 
#> 
```
