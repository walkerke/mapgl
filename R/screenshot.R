#' Save a map as a static PNG image
#'
#' @description
#' Renders a mapgl map widget to a static PNG file using headless Chrome
#' via the chromote package. Uses the same html2canvas-based screenshot
#' infrastructure as [add_screenshot_control()].
#'
#' @param map A map object created by [mapboxgl()] or [maplibre()].
#' @param filename Character string. The output file path. Defaults to
#'   `"map.png"`. If the filename does not end in `.png`, the extension is
#'   appended automatically.
#' @param width Integer. The width of the map viewport in pixels.
#' @param height Integer. The height of the map viewport in pixels.
#' @param include_legend Logical. Include the legend in the output? Default
#'   `TRUE`.
#' @param hide_controls Logical. Hide navigation and other interactive controls?
#'   Default `TRUE`.
#' @param include_scale_bar Logical. Include the scale bar? Default `TRUE`.
#' @param basemap_color Character string or `NULL`. If specified, basemap tiles
#'   are removed and replaced with this background color (e.g., `"white"`,
#'   `"lightgrey"`, `"#f0f0f0"`). Use `"transparent"` for no background.
#'   Default `NULL` (keep basemap).
#' @param image_scale Numeric. Scale factor for the output image. Use `2` for
#'   retina/HiDPI output. Default `1`.
#' @param background Character string or `NULL`. Background color for the output
#'   image. Default `"white"`. Set to `NULL` for a transparent background.
#'   Ignored when `basemap_color` is set (basemap_color controls the background
#'   in that case).
#' @param delay Numeric or `NULL`. Additional delay in seconds to wait after the
#'   map reports idle, before capturing. Useful for maps with complex rendering.
#'   Default `NULL` (no extra delay).
#'
#' @return The output file path, invisibly.
#'
#' @details
#' This function requires the \pkg{chromote} package and a Chrome or Chromium
#' browser installation. Install chromote with `install.packages("chromote")`.
#'
#' The function works by:
#' 1. Saving the map widget to a temporary HTML file
#' 2. Opening it in headless Chrome
#' 3. Waiting for all map tiles and styles to load
#' 4. Using html2canvas to capture the rendered map (including legends,
#'    attribution, and optionally the scale bar)
#' 5. Decoding the captured image and writing it to the output file
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' map <- maplibre(
#'   center = c(-96, 37.8),
#'   zoom = 3
#' )
#'
#' save_map(map, "us_map.png")
#' save_map(map, "us_map_retina.png", image_scale = 2)
#'
#' # Remove basemap, keep only data layers on white
#' save_map(map, "data_only.png", basemap_color = "white")
#' }
save_map <- function(
    map,
    filename = "map.png",
    width = 900,
    height = 500,
    include_legend = TRUE,
    hide_controls = TRUE,
    include_scale_bar = TRUE,
    basemap_color = NULL,
    image_scale = 1,
    background = "white",
    delay = NULL
) {
  check_installed("chromote", reason = "to render static map screenshots")

  if (!grepl("\\.png$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".png")
  }

  # Ensure preserveDrawingBuffer for reliable canvas capture
  if (is.null(map$x$additional_params)) {
    map$x$additional_params <- list()
  }
  map$x$additional_params$preserveDrawingBuffer <- TRUE

  # Save widget to temp directory
  tmp_dir <- tempfile("mapgl_")
  dir.create(tmp_dir)
  tmp_html <- file.path(tmp_dir, "map.html")
  htmlwidgets::saveWidget(map, tmp_html, selfcontained = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Build screenshot options
  opts <- list(
    include_legend = include_legend,
    hide_controls = hide_controls,
    include_scale_bar = include_scale_bar,
    image_scale = image_scale
  )
  if (!is.null(basemap_color)) {
    opts$basemap_color <- basemap_color
  }
  if (!is.null(background)) {
    opts$background_color <- background
  }
  options_json <- jsonlite::toJSON(opts, auto_unbox = TRUE)

  delay_ms <- if (!is.null(delay)) as.integer(delay * 1000) else 0L

  capture_js <- sprintf(
    '
    new Promise((resolve, reject) => {
      const timeout = setTimeout(
        () => reject("Screenshot timed out after 30 seconds"),
        30000
      );

      function tryCapture() {
        const el = document.querySelector("[id^=\\"htmlwidget-\\"]");
        if (!el || !el.map) {
          setTimeout(tryCapture, 100);
          return;
        }
        const map = el.map;
        const opts = %s;

        function doCapture() {
          function capture() {
            captureMapScreenshot(map, opts)
              .then(canvas => {
                clearTimeout(timeout);
                resolve(canvas.toDataURL("image/png"));
              })
              .catch(err => {
                clearTimeout(timeout);
                reject(err.message || String(err));
              });
          }
          if (%d > 0) {
            setTimeout(capture, %d);
          } else {
            capture();
          }
        }

        map.once("idle", doCapture);
        if (map.loaded()) {
          map.triggerRepaint();
        }
      }

      tryCapture();
    })
    ',
    options_json,
    delay_ms,
    delay_ms
  )

  # Launch headless Chrome and capture
  b <- chromote::ChromoteSession$new(
    width = as.integer(width),
    height = as.integer(height)
  )
  on.exit(b$close(), add = TRUE)

  b$Page$navigate(paste0("file://", normalizePath(tmp_html)))
  b$Page$loadEventFired()

  result <- b$Runtime$evaluate(capture_js, awaitPromise = TRUE)

  if (!is.null(result$exceptionDetails)) {
    stop(
      "Screenshot capture failed: ",
      result$exceptionDetails$exception$description %||%
        result$exceptionDetails$text %||%
        "unknown error"
    )
  }

  data_url <- result$result$value
  base64_data <- sub("^data:image/png;base64,", "", data_url)
  raw_png <- base64enc::base64decode(base64_data)
  writeBin(raw_png, filename)

  message("Map saved to ", filename)
  invisible(filename)
}


#' Render a map as a static image
#'
#' @description
#' Renders a mapgl map as a static PNG image for display. When called inside a
#' knitr/Quarto document, the map is included as a static figure via
#' [knitr::include_graphics()]. In an interactive session, the image is
#' displayed in the R graphics device.
#'
#' @inheritParams save_map
#' @param map A map object created by [mapboxgl()] or [maplibre()].
#'
#' @return In a knitr context, the result of [knitr::include_graphics()].
#'   In an interactive session, the image is displayed and the temporary file
#'   path is returned invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' map <- maplibre(
#'   center = c(-96, 37.8),
#'   zoom = 3
#' )
#'
#' # In a Quarto document chunk
#' print_map(map)
#'
#' # With custom dimensions
#' print_map(map, width = 1200, height = 800, image_scale = 2)
#' }
print_map <- function(
    map,
    width = 900,
    height = 500,
    include_legend = TRUE,
    hide_controls = TRUE,
    include_scale_bar = TRUE,
    basemap_color = NULL,
    image_scale = 1,
    background = "white",
    delay = NULL
) {
  if (isTRUE(getOption("knitr.in.progress"))) {
    # Save to knitr's figure directory so paths resolve in rendered output
    fig_file <- knitr::fig_path(".png")
    dir.create(dirname(fig_file), recursive = TRUE, showWarnings = FALSE)

    save_map(
      map = map,
      filename = fig_file,
      width = width,
      height = height,
      include_legend = include_legend,
      hide_controls = hide_controls,
      include_scale_bar = include_scale_bar,
      basemap_color = basemap_color,
      image_scale = image_scale,
      background = background,
      delay = delay
    )

    knitr::include_graphics(fig_file)
  } else {
    tmp_file <- tempfile(fileext = ".png")

    save_map(
      map = map,
      filename = tmp_file,
      width = width,
      height = height,
      include_legend = include_legend,
      hide_controls = hide_controls,
      include_scale_bar = include_scale_bar,
      basemap_color = basemap_color,
      image_scale = image_scale,
      background = background,
      delay = delay
    )

    img <- png::readPNG(tmp_file)
    grid::grid.raster(img)
    invisible(tmp_file)
  }
}


#' Create a blank basemap style
#'
#' @description
#' Creates a minimal map style with only a solid background color (or pattern)
#' and no basemap tiles. Useful when you want to display data layers without
#' any underlying map features.
#'
#' @param color Character string. The background color. Default `"white"`.
#'   Accepts any CSS color value (e.g., `"#f0f0f0"`, `"lightgrey"`,
#'   `"rgba(0,0,0,0)"`). Also used as a fallback behind transparent areas of
#'   a `pattern`.
#' @param pattern Character string or `NULL`. The ID of an image to use as a
#'   repeating background pattern. The image must be loaded with [add_image()]
#'   before it can be referenced. Default `NULL` (solid color only).
#'
#' @return A list representing a minimal map style, suitable for passing to
#'   the `style` parameter of [maplibre()] or [mapboxgl()].
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' # Solid color background
#' maplibre(style = basemap_style("lightgrey")) |>
#'   add_fill_layer(
#'     id = "data",
#'     source = my_sf_data,
#'     fill_color = "steelblue"
#'   )
#'
#' # Background pattern (image must be loaded with add_image())
#' maplibre(style = basemap_style(pattern = "parchment")) |>
#'   add_image("parchment", "parchment.jpg") |>
#'   add_line_layer(
#'     id = "borders",
#'     source = my_sf_data,
#'     line_color = "#2c1810"
#'   )
#' }
basemap_style <- function(color = "white", pattern = NULL) {
  paint <- list(`background-color` = color)
  if (!is.null(pattern)) {
    paint[["background-pattern"]] <- pattern
  }

  list(
    version = 8L,
    sources = structure(list(), names = character(0)),
    layers = list(
      list(
        id = "background",
        type = "background",
        paint = paint
      )
    )
  )
}
