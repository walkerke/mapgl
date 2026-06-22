# BIXI Montréal Bike Share Stations (2019)

A dataset containing the names and coordinates of BIXI bicycle sharing
stations in Montréal, Quebec, Canada.

## Usage

``` r
bixi_locations
```

## Format

A data frame with 618 rows and 4 variables:

- id:

  Unique station ID (character, e.g., `"4000"`, `"MTL-ECO5.1-01"`)

- name:

  Station name (character, e.g., `"Jeanne-d'Arc / Ontario"`)

- lat:

  Latitude coordinate (numeric)

- lon:

  Longitude coordinate (numeric)

## Source

BIXI Montréal Open Data (<https://bixi.com/fr/donnees-ouvertes>).
Prepared for <https://github.com/FlowmapBlue/FlowmapBlue> by Ilya
Boyandin (<https://github.com/ilyabo>). Data © BIXI Montréal, released
under the BIXI Montréal Open Data license
(<https://bixi.com/fr/donnees-ouvertes>).

## See also

[`bixi_flows`](https://walker-data.com/mapgl/reference/bixi_flows.md)

## Examples

``` r
# Convert to sf object to view on a map
if (requireNamespace("sf", quietly = TRUE)) {
  bixi_sf <- sf::st_as_sf(bixi_locations, coords = c("lon", "lat"), crs = 4326)
  print(head(bixi_sf))
}
#> Simple feature collection with 6 features and 2 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -73.64048 ymin: 45.47823 xmax: -73.51526 ymax: 45.5496
#> Geodetic CRS:  WGS 84
#>      id                                   name                   geometry
#> 1 10002 Métro Charlevoix (Centre / Charlevoix) POINT (-73.56965 45.47823)
#> 2  4000                 Jeanne-d'Arc / Ontario  POINT (-73.54187 45.5496)
#> 3  4001                    Graham / Brookfield POINT (-73.62978 45.52007)
#> 4  4002                     Graham / Wicksteed POINT (-73.64048 45.51694)
#> 5  5002               St-Charles / Montarville POINT (-73.51526 45.53368)
#> 6  5003                        Place Longueuil POINT (-73.51717 45.52841)
```
