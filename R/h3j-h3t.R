
# addH3JSource
#' Add a hexagon source from the H3 geospatial indexing system.
#' @references https://h3geo.org, https://github.com/INSPIDE/h3j-h3t
#' @inheritParams add_vector_source
#' @export
#' @examplesIf interactive()
#' url = "https://inspide.github.io/h3j-h3t/examples/h3j/sample.h3j"
#' maplibre(center=c(-3.704, 40.417), zoom=15, pitch=30) |>
#'   add_h3j_source("h3j_testsource",
#'                   url = url
#'   )  |>
#'   add_fill_extrusion_layer(
#'     id = "h3j_testlayer",
#'     source = "h3j_testsource",
#'     fill_extrusion_color = interpolate(
#'       column = "value",
#'       values = c(0, 21.864),
#'       stops = c("#430254", "#f83c70")
#'     ),
#'     fill_extrusion_height = list(
#'       "interpolate",
#'       list("linear"),
#'       list("zoom"),
#'       14,
#'       0,
#'       15.05,
#'       list("*", 10, list("get", "value"))
#'     ),
#'     fill_extrusion_opacity = 0.7
#'   )
#'
add_h3j_source <- function(map, id, url) {
  h3j_sources <- list(
    id = id,
    url = url
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = list(type = "add_h3j_sources", h3j_sources = h3j_sources)))
  } else {
    map$x$h3j_sources <-c(map$x$h3j_sources, list(h3j_sources))
  }

  return(map)
}


# addH3TSource
#' Add a tiled hexagon source from the H3 geospatial indexing system.
#'
#' Wraps the [h3t](https://github.com/INSPIDE/h3j-h3t) tile protocol, which
#' registers a `h3tiles://` MapLibre protocol and fetches H3J-formatted JSON
#' tiles from a `{z}/{x}/{y}` endpoint. Unlike [add_h3j_source()], which pulls
#' a single H3J file, this source lets the map request only the cells visible
#' in the current viewport — on pan/zoom the protocol handler fires a fresh
#' request per tile.
#'
#' @param map A map object created by `maplibre()` or a `maplibre_proxy`.
#' @param id Unique source ID.
#' @param tiles A character vector of tile URL templates, each using the
#'   `h3tiles://` scheme. The tokens `{z}`, `{x}`, `{y}` are substituted by
#'   MapLibre on each tile request. Example:
#'   `"h3tiles://h3t.example.com/{z}/{x}/{y}.h3t?q=..."`.
#' @param sourcelayer Name of the source layer that downstream `add_fill_layer()`
#'   (or similar) calls reference via `source_layer`. Defaults to `id`.
#' @param geometry_type Either `"Polygon"` (hex boundaries) or `"Point"` (cell
#'   centroids). Defaults to `"Polygon"`.
#' @param minzoom,maxzoom Zoom bounds for the source (MapLibre semantics).
#' @param promote_id Whether to promote the `h3id` property to the feature ID.
#' @param debug If `TRUE`, the protocol handler logs per-tile timing to the
#'   browser console.
#' @references https://github.com/INSPIDE/h3j-h3t
#' @export
#' @examplesIf interactive()
#' maplibre(center = c(-119, 34), zoom = 5) |>
#'   add_h3t_source(
#'     id = "sardine",
#'     tiles = "h3tiles://h3t.example.com/{z}/{x}/{y}.h3t?q=<base64-SELECT>"
#'   ) |>
#'   add_fill_layer(
#'     id           = "sardine",
#'     source       = "sardine",
#'     source_layer = "sardine",
#'     fill_color   = interpolate(
#'       column = "value", values = c(0, 100),
#'       stops = c("#ffffcc", "#e31a1c")
#'     ),
#'     fill_opacity = 0.7
#'   )
add_h3t_source <- function(map, id, tiles,
                           sourcelayer    = id,
                           geometry_type  = c("Polygon", "Point"),
                           minzoom        = 0,
                           maxzoom        = 14,
                           promote_id     = TRUE,
                           debug          = FALSE) {
  geometry_type <- match.arg(geometry_type)
  if (is.character(tiles)) tiles <- as.list(tiles)
  stopifnot(is.list(tiles), length(tiles) >= 1L)

  h3t_source <- list(
    id            = id,
    tiles         = tiles,
    sourcelayer   = sourcelayer,
    geometry_type = geometry_type,
    minzoom       = minzoom,
    maxzoom       = maxzoom,
    promoteId     = promote_id,
    debug         = debug
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    map$session$sendCustomMessage(
      proxy_class,
      list(
        id      = map$id,
        message = list(type = "add_h3t_sources", h3t_sources = list(h3t_source))
      )
    )
  } else {
    map$x$h3t_sources <- c(map$x$h3t_sources, list(h3t_source))
  }

  map
}


