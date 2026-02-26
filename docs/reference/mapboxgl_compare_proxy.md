# Create a proxy object for a Mapbox GL Compare widget in Shiny

This function allows updates to be sent to an existing Mapbox GL Compare
widget in a Shiny application.

## Usage

``` r
mapboxgl_compare_proxy(
  compareId,
  session = shiny::getDefaultReactiveDomain(),
  map_side = "before"
)
```

## Arguments

- compareId:

  The ID of the compare output element.

- session:

  The Shiny session object.

- map_side:

  Which map side to target in the compare widget, either "before" or
  "after".

## Value

A proxy object for the Mapbox GL Compare widget.
