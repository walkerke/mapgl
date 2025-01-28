
# addH3JSource


#' @export
add_h3j_sources <- function(map, id, url) {
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
