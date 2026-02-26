# Create a proxy object for a Mapbox GL map in Shiny

This function allows updates to be sent to an existing Mapbox GL map in
a Shiny application without redrawing the entire map.

## Usage

``` r
mapboxgl_proxy(mapId, session = shiny::getDefaultReactiveDomain())
```

## Arguments

- mapId:

  The ID of the map output element.

- session:

  The Shiny session object.

## Value

A proxy object for the Mapbox GL map.
