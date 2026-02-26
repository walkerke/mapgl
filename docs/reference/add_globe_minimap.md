# Add a Globe Minimap to a map

This function adds a globe minimap control to a Mapbox GL or Maplibre
map.

## Usage

``` r
add_globe_minimap(
  map,
  position = "bottom-right",
  globe_size = 82,
  land_color = "white",
  water_color = "rgba(30 40 70/60%)",
  marker_color = "#ff2233",
  marker_size = 1
)
```

## Arguments

- map:

  A `mapboxgl` or `maplibre` object.

- position:

  A string specifying the position of the minimap.

- globe_size:

  Number of pixels for the diameter of the globe. Default is 82.

- land_color:

  HTML color to use for land areas on the globe. Default is 'white'.

- water_color:

  HTML color to use for water areas on the globe. Default is 'rgba(30 40
  70/60%)'.

- marker_color:

  HTML color to use for the center point marker. Default is '#ff2233'.

- marker_size:

  Scale ratio for the center point marker. Default is 1.

## Value

The modified map object with the globe minimap added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)

m <- mapboxgl() %>%
    add_globe_minimap()

m <- maplibre() %>%
    add_globe_minimap()
} # }
```
