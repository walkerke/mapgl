#' Add an image to the map
#'
#' This function adds an image to the map's style. The image can be used with
#' icon-image, background-pattern, fill-pattern, or line-pattern.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A string specifying the ID of the image.
#' @param url A string specifying the URL of the image to be loaded.
#' @param content A vector of four numbers `c(x1, y1, x2, y2)` defining the part of the image
#'        that can be covered by the content in text-field if icon-text-fit is used.
#' @param pixel_ratio A number specifying the ratio of pixels in the image to physical pixels on the screen.
#' @param sdf A logical value indicating whether the image should be interpreted as an SDF image.
#' @param stretch_x A list of number pairs defining the part(s) of the image that can be stretched horizontally.
#' @param stretch_y A list of number pairs defining the part(s) of the image that can be stretched vertically.
#'
#' @return The modified map object with the image added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' map <- mapboxgl() |>
#'     add_image("cat", "https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Cat_silhouette.svg/400px-Cat_silhouette.svg.png") |>
#'     add_image("border-image", "https://upload.wikimedia.org/wikipedia/commons/8/89/Black_and_White_Boxed_%28bordered%29.png",
#'         content = c(16, 16, 300, 384),
#'         stretch_x = list(c(16, 584)),
#'         stretch_y = list(c(16, 384))
#'     )
#' }
add_image <- function(map, id, url, content = NULL, pixel_ratio = 1, sdf = FALSE,
                      stretch_x = NULL, stretch_y = NULL) {
    options <- list(
        pixelRatio = pixel_ratio,
        sdf = sdf
    )

    if (!is.null(content)) options$content <- content
    if (!is.null(stretch_x)) options$stretchX <- stretch_x
    if (!is.null(stretch_y)) options$stretchY <- stretch_y

    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"

        map$session$sendCustomMessage(proxy_class, list(
            id = map$id,
            message = list(
                type = "add_image",
                imageId = id,
                url = url,
                options = options
            )
        ))
    } else {
        if (is.null(map$x$images)) {
            map$x$images <- list()
        }
        map$x$images <- append(map$x$images, list(list(
            id = id,
            url = url,
            options = options
        )))
    }

    return(map)
}
