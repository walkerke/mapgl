# Calculate area of geometries

This function calculates the area of polygons in a layer or sf object.
Note: This function only works with proxy objects as it returns a
numeric value to R.

## Usage

``` r
turf_area(proxy, layer_id = NULL, data = NULL, input_id = "turf_area_result")
```

## Arguments

- proxy:

  A mapboxgl_proxy or maplibre_proxy object.

- layer_id:

  The ID of the layer or source containing the polygons (mutually
  exclusive with data).

- data:

  An sf object containing polygons (mutually exclusive with layer_id).

- input_id:

  Character string specifying the Shiny input ID suffix for storing the
  area result. Default is "turf_area_result". Result will be available
  as `input[[paste0(map_id, "_turf_", input_id)]]`.

## Value

The proxy object for method chaining.
