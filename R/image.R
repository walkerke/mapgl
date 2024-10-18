#' Add an image to the map
#'
#' This function adds an image to the map's style. The image can be used with
#' icon-image, background-pattern, fill-pattern, or line-pattern.
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` functions.
#' @param id A string specifying the ID of the image.
#' @param url A string specifying the URL of the image to be loaded or a path
#'        to a local image file. Must be PNG or JPEG format.
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
#' # Path to your local image file OR a URL to a remote image file
#' # that is not blocked by CORS restrictions
#' image_path <- "/path/to/your/image.png"
#'
#' pts <- tigris::landmarks("DE")[1:100, ]
#'
#' maplibre(bounds = pts) |>
#'     add_image("local_icon", image_path) |>
#'     add_symbol_layer(
#'         id = "local_icons",
#'         source = pts,
#'         icon_image = "local_icon",
#'         icon_size = 0.5,
#'         icon_allow_overlap = TRUE
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

    # Check if the URL is a local file path
    if (file.exists(url)) {
        # Read the image file and encode it as a data URI
        file_ext <- tolower(tools::file_ext(url))
        if (file_ext == "png") {
            mime_type <- "image/png"
        } else if (file_ext %in% c("jpg", "jpeg")) {
            mime_type <- "image/jpeg"
        } else {
            stop("Image must be PNG or JPEG format")
        }
        url <- base64enc::dataURI(file = url, mime = mime_type)
    }

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
