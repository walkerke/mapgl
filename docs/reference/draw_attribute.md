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

{"x":{"style":null,"center":[0,0],"zoom":0,"bearing":0,"pitch":0,"projection":"globe","parallels":null,"access_token":"pk.eyJ1Ijoia3dhbGtlcnRjdSIsImEiOiJMRk9JSmRvIn0.l1y2jHZ6IARHM_rA1-X45A","additional_params":[],"mapgl_id":"fa921692-5390-6552-81f7-0b06b589156b","draw_control":{"enabled":true,"position":"top-left","freehand":false,"simplify_freehand":false,"rectangle":false,"radius":false,"bezier":false,"bezier_polygon":false,"orientation":"vertical","options":[],"source":null,"attributes":[{"name":"status","type":"select","label":"status","choices":[{"value":"candidate","label":"Candidate"},{"value":"active","label":"Active"}],"required":false},{"name":"notes","type":"textarea","label":"notes","required":false},{"name":"value","type":"number","label":"value","required":false}],"download_button":false,"download_filename":"drawn-features","show_measurements":false,"measurement_units":"both","styling":{"point_color":"#3bb2d0","line_color":"#3bb2d0","fill_color":"#3bb2d0","fill_opacity":0.1,"active_color":"#fbb03b","vertex_radius":5,"line_width":2}}},"evals":[],"jsHooks":[]}
```
