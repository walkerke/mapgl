# Format numbers for legend labels

Internal helper function to format numeric values for display in
legends.

## Usage

``` r
format_numbers(x, format, currency_symbol, digits, big_mark, suffix, prefix)
```

## Arguments

- x:

  Numeric vector to format.

- format:

  Format type.

- currency_symbol:

  Currency symbol for currency formatting.

- digits:

  Number of decimal places.

- big_mark:

  Thousands separator.

- suffix:

  Suffix to append.

- prefix:

  Prefix to prepend.

## Value

Character vector of formatted numbers.
