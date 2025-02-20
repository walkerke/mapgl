
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


