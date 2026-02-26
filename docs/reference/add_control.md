# Add a custom control to a map

This function adds a custom control to a Mapbox GL or MapLibre GL map.
It allows you to create custom HTML element controls and add them to the
map.

## Usage

``` r
add_control(
  map,
  html,
  position = "top-right",
  className = NULL,
  id = NULL,
  ...
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- html:

  Character string containing the HTML content for the control.

- position:

  The position of the control. Can be one of "top-left", "top-right",
  "bottom-left", or "bottom-right". Default is "top-right".

- className:

  Optional CSS class name for the control container.

- id:

  Optional unique identifier for the control. If not provided, defaults
  to "custom". This ID can be used with
  [`clear_controls()`](https://walker-data.com/mapgl/reference/clear_controls.md)
  to selectively remove this specific control.

- ...:

  Additional arguments passed to the JavaScript side.

## Value

The modified map object with the custom control added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

# Basic custom control
maplibre() |>
  add_control(
    html = "<div style='background-color: white; padding: 5px;'>
             <p>Custom HTML</p>
             <img src='path/to/image.png' alt='image'/>
            </div>",
    position = "top-left"
  )

# Custom control with specific ID for selective removal
maplibre() |>
  add_control(
    html = "<div style='background: blue; color: white; padding: 10px;'>
             My Control
            </div>",
    position = "top-right",
    id = "my_custom_control"
  )

# Later, remove only this specific control
maplibre_proxy("map") |>
  clear_controls("my_custom_control")
} # }
```
