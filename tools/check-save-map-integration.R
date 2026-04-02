#!/usr/bin/env Rscript

`%||%` <- function(x, y) if (is.null(x)) y else x

assert_that <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

log_step <- function(label) {
  cat("\n==", label, "==\n")
}

count_color_pixels <- function(img, color, tol = 0.15, row_frac = c(0, 1), col_frac = c(0, 1)) {
  n_rows <- dim(img)[1]
  n_cols <- dim(img)[2]

  row_idx <- seq.int(
    max(1L, floor(row_frac[1] * n_rows) + 1L),
    min(n_rows, ceiling(row_frac[2] * n_rows))
  )
  col_idx <- seq.int(
    max(1L, floor(col_frac[1] * n_cols) + 1L),
    min(n_cols, ceiling(col_frac[2] * n_cols))
  )

  region <- img[row_idx, col_idx, 1:3, drop = FALSE]
  dist <- sqrt(
    (region[, , 1] - color[1])^2 +
      (region[, , 2] - color[2])^2 +
      (region[, , 3] - color[3])^2
  )

  sum(dist <= tol)
}

make_test_polygon <- function() {
  coords <- matrix(
    c(
      -96.7, 37.4,
      -95.3, 37.4,
      -95.3, 38.2,
      -96.7, 38.2,
      -96.7, 37.4
    ),
    ncol = 2,
    byrow = TRUE
  )

  sf::st_as_sf(
    data.frame(id = 1L),
    geometry = sf::st_sfc(sf::st_polygon(list(coords)), crs = 4326)
  )
}

check_png_created <- function(path, min_size = 1000) {
  info <- file.info(path)
  assert_that(file.exists(path), paste("Expected file to exist:", path))
  assert_that(!is.na(info$size) && info$size > min_size, paste("PNG is too small:", info$size %||% NA))
}

run_default_smoke <- function() {
  log_step("Default Basemap Smoke Test")
  out_file <- tempfile(fileext = ".png")

  map <- mapgl::maplibre(
    center = c(-96, 37.8),
    zoom = 3
  )

  mapgl::save_map(map, out_file, width = 900, height = 500)
  check_png_created(out_file, min_size = 3000)

  cat("default_smoke_size=", file.info(out_file)$size, "\n", sep = "")
}

run_content_preservation <- function() {
  log_step("Legend And Layer Preservation Test")
  out_with_legend <- tempfile(fileext = ".png")
  out_no_legend <- tempfile(fileext = ".png")

  polygon <- make_test_polygon()

  map <- mapgl::maplibre(
    style = mapgl::basemap_style("white"),
    projection = "mercator",
    center = c(-96, 37.8),
    zoom = 5
  ) |>
    mapgl::add_fill_layer(
      id = "test-fill",
      source = polygon,
      fill_color = "#ff0000",
      fill_outline_color = "#ff0000",
      fill_opacity = 1
    ) |>
    mapgl::add_legend(
      legend_title = "Layer Check",
      values = c("Blue key", "Green key"),
      colors = c("#0000ff", "#00aa00"),
      type = "categorical",
      patch_shape = "square",
      sizes = 22,
      position = "top-left",
      width = "180px",
      style = list(
        background_color = "#ffffff",
        background_opacity = 1,
        text_color = "#111111",
        title_color = "#111111"
      )
    )

  mapgl::save_map(map, out_with_legend, width = 800, height = 500)
  mapgl::save_map(map, out_no_legend, width = 800, height = 500, include_legend = FALSE)

  check_png_created(out_with_legend)
  check_png_created(out_no_legend)

  img_with <- png::readPNG(out_with_legend)
  img_without <- png::readPNG(out_no_legend)

  red_with <- count_color_pixels(
    img_with,
    c(1, 0, 0),
    tol = 0.18,
    row_frac = c(0.15, 0.85),
    col_frac = c(0.15, 0.85)
  )
  red_without <- count_color_pixels(
    img_without,
    c(1, 0, 0),
    tol = 0.18,
    row_frac = c(0.15, 0.85),
    col_frac = c(0.15, 0.85)
  )
  blue_with <- count_color_pixels(
    img_with,
    c(0, 0, 1),
    tol = 0.18,
    row_frac = c(0, 0.35),
    col_frac = c(0, 0.35)
  )
  green_with <- count_color_pixels(
    img_with,
    c(0, 170 / 255, 0),
    tol = 0.18,
    row_frac = c(0, 0.35),
    col_frac = c(0, 0.35)
  )
  blue_without <- count_color_pixels(
    img_without,
    c(0, 0, 1),
    tol = 0.18,
    row_frac = c(0, 0.35),
    col_frac = c(0, 0.35)
  )
  green_without <- count_color_pixels(
    img_without,
    c(0, 170 / 255, 0),
    tol = 0.18,
    row_frac = c(0, 0.35),
    col_frac = c(0, 0.35)
  )

  cat(
    paste(
      "red_with=", red_with,
      "red_without=", red_without,
      "blue_with=", blue_with,
      "green_with=", green_with,
      "blue_without=", blue_without,
      "green_without=", green_without
    ),
    "\n"
  )

  assert_that(red_with > 1500, paste("Expected strong red layer signal, got", red_with))
  assert_that(red_without > 1500, paste("Expected strong red layer signal without legend, got", red_without))
  assert_that(blue_with > 100, paste("Expected blue legend pixels, got", blue_with))
  assert_that(green_with > 100, paste("Expected green legend pixels, got", green_with))
  assert_that(blue_without < blue_with / 4, "Legend suppression did not materially reduce blue legend pixels")
  assert_that(green_without < green_with / 4, "Legend suppression did not materially reduce green legend pixels")
}

log_step("Environment")
cat("sysname=", Sys.info()[["sysname"]], "\n", sep = "")
cat("release=", Sys.info()[["release"]] %||% "", "\n", sep = "")
cat("chromote_chrome=", Sys.getenv("CHROMOTE_CHROME", unset = ""), "\n", sep = "")

run_default_smoke()
run_content_preservation()

log_step("Done")
cat("save_map integration checks passed\n")
