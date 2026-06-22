# Create a proxy object for a Maplibre GL Compare widget in Shiny

This function allows updates to be sent to an existing Maplibre GL
Compare widget in a Shiny application.

## Usage

``` r
maplibre_compare_proxy(
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

  Which map to target in the compare widget: "before" or "after" for
  two-map widgets, or a map identifier such as "map3" (or its position
  as an integer, e.g. `3`) for synced grids with more than two maps.
  "before" and "after" are aliases for the first and second maps.

## Value

A proxy object for the Maplibre GL Compare widget.
