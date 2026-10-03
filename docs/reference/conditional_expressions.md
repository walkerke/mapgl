# Conditional expressions for popups, tooltips, and styling

These helpers build GL-style conditional expressions for use anywhere
mapgl accepts an expression - most usefully as popup or tooltip content,
where they are evaluated against each feature's properties at render
time in the browser. That makes display logic possible without
precomputing columns, which matters for remote sources (PMTiles, vector
tiles) whose attributes cannot be modified from R. They compose with
[`concat()`](https://walker-data.com/mapgl/reference/concat.md),
[`get_column()`](https://walker-data.com/mapgl/reference/get_column.md),
[`number_format()`](https://walker-data.com/mapgl/reference/number_format.md),
[`match_expr()`](https://walker-data.com/mapgl/reference/match_expr.md),
and
[`step_expr()`](https://walker-data.com/mapgl/reference/step_expr.md);
[`interpolate()`](https://walker-data.com/mapgl/reference/interpolate.md)
also works in popup/tooltip content, but only with numeric outputs
(color stops render as an empty string with a console warning -
interpolate colors in layer styling, not popups).

## Usage

``` r
if_else_expr(condition, yes, no = "")

case_expr(..., default)

coalesce_expr(...)

has_column(column)

is_blank(column)

html_escape_expr(expression)
```

## Arguments

- condition:

  For `if_else_expr()`, an expression that evaluates to `TRUE` or
  `FALSE` for a feature - e.g. `is_blank()`, `has_column()`, or a raw
  comparison like `list(">=", get_column("value"), 100)`.

- yes, no:

  The results when `condition` is true / false. Strings, numbers, or
  expressions.

- ...:

  For `case_expr()`, condition/output pairs (condition 1, output 1,
  condition 2, output 2, ...): the output for the first true condition
  is used. For `coalesce_expr()`, values or expressions; the first that
  evaluates to a non-null value is used (`0`, `FALSE`, and `""` count as
  present).

- default:

  For `case_expr()`, the result when no condition matches. Required (may
  be `NULL`).

- column:

  The name of the feature property to test.

- expression:

  For `html_escape_expr()`, the expression whose result should be
  HTML-escaped.

## Value

A list representing the expression.

## Details

Conditional branches are evaluated lazily: only the branch selected for
a feature is computed, so e.g. a
[`number_format()`](https://walker-data.com/mapgl/reference/number_format.md)
in one branch is not evaluated for features that take the other branch.

Popup/tooltip expressions follow the GL expression type system:
conditions must evaluate to booleans, math operators require numeric
operands (a numeric string from tile data must be converted explicitly,
e.g. `list("to-number", get_column("value"))`), and ordered comparisons
require two numbers or two strings. A type error, malformed expression,
or non-finite arithmetic result renders as an empty string with a
one-time console warning rather than breaking the popup.

`is_blank(column)` is true when the property is missing, null, or an
empty string (`""`). It does not detect whitespace-only strings or
sentinel values like `0` - test those explicitly with a comparison
condition.

Note that unlike `"{column}"` brace templates, expression results are
inserted into popups and tooltips as raw HTML (that is what makes
`concat("<strong>", ...)` work). Use these with trusted feature data, or
wrap untrusted values in `html_escape_expr()`, which escapes its result
at render time. `html_escape_expr()` is a mapgl extension for
popup/tooltip content only - it is not part of the GL style
specification, so don't use it in layer styling or filters.

## Examples

``` r
# Show a fallback when a property is missing or empty (e.g. parcels from
# PMTiles where some counties don't report addresses or values)
popup_content <- concat(
  "<strong>", get_column("owner_names"), "</strong><br>",
  if_else_expr(
    is_blank("situs_addr"),
    "Address not available",
    get_column("situs_addr")
  ),
  "<br>",
  case_expr(
    list("==", get_column("county"), "HUDSPETH"), "Value not reported",
    default = concat("Total value: $", number_format("total_value"))
  )
)

# First non-missing value
coalesce_expr(get_column("preferred_name"), get_column("name"), "Unnamed")
#> [[1]]
#> [1] "coalesce"
#> 
#> [[2]]
#> [[2]][[1]]
#> [1] "get"
#> 
#> [[2]][[2]]
#> [1] "preferred_name"
#> 
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
#> [1] "Unnamed"
#> 
```
