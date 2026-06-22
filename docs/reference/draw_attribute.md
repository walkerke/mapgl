# Define an editable draw attribute

This helper creates one field definition for the `attributes` argument
in
[`add_draw_control()`](https://walker-data.com/mapgl/reference/add_draw_control.md).
The field name comes from the name used in the `attributes` list.

## Usage

``` r
draw_attribute(
  type = NULL,
  label = NULL,
  choices = NULL,
  default = NULL,
  required = FALSE,
  placeholder = NULL,
  min = NULL,
  max = NULL,
  step = NULL
)
```

## Arguments

- type:

  Input type for the editor. Supported values are `"text"`,
  `"textarea"`, `"select"`, `"number"`, and `"checkbox"`. `"numeric"` is
  an alias for `"number"`; `"logical"`, `"bool"`, and `"boolean"` are
  aliases for `"checkbox"`. If `NULL`, the type is inferred from
  `choices` or `default`.

- label:

  Optional label shown in the editor. Defaults to the field name.

- choices:

  Values for `"select"` fields. Names, if present, are used as labels
  and values are written to feature properties.

- default:

  Optional default value. Defaults are applied to newly drawn features
  only; existing feature properties are preserved.

- required:

  Logical; whether the browser should require a value before saving.

- placeholder:

  Optional placeholder for text, textarea, and number inputs.

- min, max, step:

  Optional numeric input constraints for `"number"` fields.

## Value

A list suitable for one entry in `add_draw_control(attributes = )`.

## Examples

``` r
draw_attribute("select", choices = c("candidate", "active", "rejected"))
#> $type
#> [1] "select"
#> 
#> $label
#> NULL
#> 
#> $choices
#> [1] "candidate" "active"    "rejected" 
#> 
#> $default
#> NULL
#> 
#> $required
#> [1] FALSE
#> 
#> $placeholder
#> NULL
#> 
#> $min
#> NULL
#> 
#> $max
#> NULL
#> 
#> $step
#> NULL
#> 
draw_attribute("textarea", label = "Notes")
#> $type
#> [1] "textarea"
#> 
#> $label
#> [1] "Notes"
#> 
#> $choices
#> NULL
#> 
#> $default
#> NULL
#> 
#> $required
#> [1] FALSE
#> 
#> $placeholder
#> NULL
#> 
#> $min
#> NULL
#> 
#> $max
#> NULL
#> 
#> $step
#> NULL
#> 
draw_attribute("numeric", min = 0, max = 1, step = 0.1, default = 1)
#> $type
#> [1] "numeric"
#> 
#> $label
#> NULL
#> 
#> $choices
#> NULL
#> 
#> $default
#> [1] 1
#> 
#> $required
#> [1] FALSE
#> 
#> $placeholder
#> NULL
#> 
#> $min
#> [1] 0
#> 
#> $max
#> [1] 1
#> 
#> $step
#> [1] 0.1
#> 

if (FALSE) { # \dontrun{
mapboxgl() |>
  add_draw_control(
    attributes = list(
      status = draw_attribute(
        "select",
        choices = c(Candidate = "candidate", Active = "active")
      ),
      notes = draw_attribute("textarea"),
      value = draw_attribute("numeric")
    )
  )
} # }
```
