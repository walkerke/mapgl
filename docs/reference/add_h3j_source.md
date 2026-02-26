# Add a hexagon source from the H3 geospatial indexing system.

Add a hexagon source from the H3 geospatial indexing system.

## Usage

``` r
add_h3j_source(map, id, url)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` function.

- id:

  A unique ID for the source.

- url:

  A URL pointing to the vector tile source.

## References

https://h3geo.org, https://github.com/INSPIDE/h3j-h3t

## Examples

``` r
if (FALSE) { # interactive()
url = "https://inspide.github.io/h3j-h3t/examples/h3j/sample.h3j"
maplibre(center=c(-3.704, 40.417), zoom=15, pitch=30) |>
  add_h3j_source("h3j_testsource",
                  url = url
  )  |>
  add_fill_extrusion_layer(
    id = "h3j_testlayer",
    source = "h3j_testsource",
    fill_extrusion_color = interpolate(
      column = "value",
      values = c(0, 21.864),
      stops = c("#430254", "#f83c70")
    ),
    fill_extrusion_height = list(
      "interpolate",
      list("linear"),
      list("zoom"),
      14,
      0,
      15.05,
      list("*", 10, list("get", "value"))
    ),
    fill_extrusion_opacity = 0.7
  )
}
```
