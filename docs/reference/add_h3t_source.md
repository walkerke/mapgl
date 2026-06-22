# Add a tiled hexagon source from the H3 geospatial indexing system.

Wraps the [h3t](https://github.com/INSPIDE/h3j-h3t) tile protocol, which
registers a `h3tiles://` MapLibre protocol and fetches H3J-formatted
JSON tiles from a `{z}/{x}/{y}` endpoint. Unlike
[`add_h3j_source()`](https://walker-data.com/mapgl/reference/add_h3j_source.md),
which pulls a single H3J file, this source lets the map request only the
cells visible in the current viewport — on pan/zoom the protocol handler
fires a fresh request per tile.

## Usage

``` r
add_h3t_source(
  map,
  id,
  tiles,
  sourcelayer = id,
  geometry_type = c("Polygon", "Point"),
  minzoom = 0,
  maxzoom = 14,
  promote_id = TRUE,
  debug = FALSE
)
```

## Arguments

- map:

  A map object created by
  [`maplibre()`](https://walker-data.com/mapgl/reference/maplibre.md) or
  a `maplibre_proxy`.

- id:

  Unique source ID.

- tiles:

  A character vector of tile URL templates, each using the `h3tiles://`
  scheme. The tokens `{z}`, `{x}`, `{y}` are substituted by MapLibre on
  each tile request. Example:
  `"h3tiles://h3t.example.com/{z}/{x}/{y}.h3t?q=..."`.

- sourcelayer:

  Name of the source layer that downstream
  [`add_fill_layer()`](https://walker-data.com/mapgl/reference/add_fill_layer.md)
  (or similar) calls reference via `source_layer`. Defaults to `id`.

- geometry_type:

  Either `"Polygon"` (hex boundaries) or `"Point"` (cell centroids).
  Defaults to `"Polygon"`.

- minzoom, maxzoom:

  Zoom bounds for the source (MapLibre semantics).

- promote_id:

  Whether to promote the `h3id` property to the feature ID.

- debug:

  If `TRUE`, the protocol handler logs per-tile timing to the browser
  console.

## References

https://github.com/INSPIDE/h3j-h3t

## Examples

``` r
if (FALSE) { # interactive()
maplibre(center = c(-119, 34), zoom = 5) |>
  add_h3t_source(
    id = "sardine",
    tiles = "h3tiles://h3t.example.com/{z}/{x}/{y}.h3t?q=<base64-SELECT>"
  ) |>
  add_fill_layer(
    id           = "sardine",
    source       = "sardine",
    source_layer = "sardine",
    fill_color   = interpolate(
      column = "value", values = c(0, 100),
      stops = c("#ffffcc", "#e31a1c")
    ),
    fill_opacity = 0.7
  )
}
```
