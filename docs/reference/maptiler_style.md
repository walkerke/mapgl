# Get MapTiler Style URL

Get MapTiler Style URL

## Usage

``` r
maptiler_style(style_name, variant = NULL, api_key = NULL)
```

## Arguments

- style_name:

  The name of the style (e.g., "basic", "streets", "toner", etc.).

- variant:

  The color variant of the style. Options are "dark", "light", or
  "pastel". Default is NULL (standard variant). Not all styles support
  all variants.

- api_key:

  Your MapTiler API key (required)

## Value

The style URL corresponding to the given style name and variant.
