# Create a proxy object for a Maplibre GL map in Shiny

This function allows updates to be sent to an existing Maplibre GL map
in a Shiny application without redrawing the entire map.

## Usage

``` r
maplibre_proxy(mapId, session = shiny::getDefaultReactiveDomain())
```

## Arguments

- mapId:

  The ID of the map output element.

- session:

  The Shiny session object.

## Value

A proxy object for the Maplibre GL map.
