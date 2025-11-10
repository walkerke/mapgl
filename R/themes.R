#' Convert R color palette to mapgl LUT
#'
#' This function takes an R color palette and converts it into a base64-encoded
#' LUT (Look-Up Table) image that can be used with Mapbox GL JS v3+ for custom
#' map themes. The LUT applies color transformations to the basemap.
#'
#' @param colors Character vector of colors (hex or R color names) or a function
#'   that generates colors (like viridis)
#' @param n Number of colors to sample from the palette (if colors is a function)
#' @param method Method for applying colors to the LUT:
#'   - `"tint"`: Applies palette as a color tint/overlay
#'   - `"replace"`: Maps grayscale values to palette colors
#'   - `"duotone"`: Creates duotone effect with first two colors
#'   - `"tritone"`: Creates tritone effect with first three colors
#'   - `"luminosity"`: Applies palette based on pixel luminosity
#' @param intensity Strength of the effect (0-1)
#' @param lut_size Size of the LUT (16, 32, or 64)
#' @param reverse Logical; whether to reverse the color palette
#' @return Base64-encoded PNG data URI string
#' @examples
#' \dontrun{
#' # Using viridis palette
#' theme_data <- palette_to_lut(viridisLite::viridis(5))
#'
#' # Using a palette function directly
#' theme_data <- palette_to_lut(viridisLite::plasma, n = 7)
#'
#' # Using RColorBrewer
#' theme_data <- palette_to_lut(RColorBrewer::brewer.pal(9, "YlOrRd"))
#'
#' # Use in mapboxgl (requires Mapbox GL JS v3+)
#' mapboxgl(
#'   center = c(139.7, 35.7),
#'   zoom = 10,
#'   config = list(
#'     basemap = list(
#'       theme = "custom",
#'       "theme-data" = theme_data
#'     )
#'   )
#' )
#' }
#' @export
palette_to_lut <- function(colors,
                            n = 5,
                            method = c("tint", "replace", "duotone", "tritone", "luminosity"),
                            intensity = 0.5,
                            lut_size = 32,
                            reverse = FALSE) {

  # Validate inputs
  method <- match.arg(method)
  if (!lut_size %in% c(16, 32, 64)) {
    stop("lut_size must be 16, 32, or 64")
  }
  if (intensity < 0 || intensity > 1) {
    stop("intensity must be between 0 and 1")
  }

  # Handle color input - could be a function or vector
  if (is.function(colors)) {
    color_vec <- colors(n)
  } else {
    color_vec <- colors
  }

  # Reverse if requested
  if (reverse) {
    color_vec <- rev(color_vec)
  }

  # Ensure we have enough colors for the chosen method
  if (method == "duotone" && length(color_vec) < 2) {
    stop("Duotone method requires at least 2 colors")
  }
  if (method == "tritone" && length(color_vec) < 3) {
    stop("Tritone method requires at least 3 colors")
  }

  # Convert colors to RGB (0-1 scale)
  rgb_matrix <- col2rgb(color_vec, alpha = FALSE) / 255

  # Create the LUT array
  # Dimensions: width = lut_size^2, height = lut_size, channels = 3
  lut_array <- array(0, dim = c(lut_size, lut_size * lut_size, 3))

  # Generate LUT pixels
  for (tile in 1:lut_size) {
    for (y in 1:lut_size) {
      for (x in 1:lut_size) {
        # Calculate position in the array
        pixel_x <- (tile - 1) * lut_size + x

        # Original RGB values (0-1)
        r <- (x - 1) / (lut_size - 1)
        g <- (y - 1) / (lut_size - 1)
        b <- (tile - 1) / (lut_size - 1)

        # Apply transformation based on method
        new_rgb <- apply_palette_transform(r, g, b, rgb_matrix, method, intensity)

        # Store in array
        lut_array[y, pixel_x, 1] <- new_rgb[1]
        lut_array[y, pixel_x, 2] <- new_rgb[2]
        lut_array[y, pixel_x, 3] <- new_rgb[3]
      }
    }
  }

  # Convert to PNG and base64
  lut_base64 <- array_to_base64_png(lut_array)

  return(paste0("data:image/png;base64,", lut_base64))
}

#' Apply palette transformation to RGB values
#' @noRd
apply_palette_transform <- function(r, g, b, palette_rgb, method, intensity) {

  switch(method,
    "tint" = {
      # Mix original color with palette colors based on luminosity
      lum <- 0.299 * r + 0.587 * g + 0.114 * b

      # Select color from palette based on luminosity
      palette_idx <- ceiling(lum * ncol(palette_rgb))
      palette_idx <- max(1, min(palette_idx, ncol(palette_rgb)))

      tint_r <- palette_rgb[1, palette_idx]
      tint_g <- palette_rgb[2, palette_idx]
      tint_b <- palette_rgb[3, palette_idx]

      # Mix with original color
      new_r <- r * (1 - intensity) + tint_r * intensity * lum
      new_g <- g * (1 - intensity) + tint_g * intensity * lum
      new_b <- b * (1 - intensity) + tint_b * intensity * lum
    },

    "replace" = {
      # Map grayscale to palette colors
      gray <- 0.299 * r + 0.587 * g + 0.114 * b

      # Interpolate through palette
      palette_pos <- gray * (ncol(palette_rgb) - 1) + 1
      idx_low <- floor(palette_pos)
      idx_high <- ceiling(palette_pos)
      frac <- palette_pos - idx_low

      idx_low <- max(1, min(idx_low, ncol(palette_rgb)))
      idx_high <- max(1, min(idx_high, ncol(palette_rgb)))

      # Interpolate between palette colors
      interp_r <- palette_rgb[1, idx_low] * (1 - frac) + palette_rgb[1, idx_high] * frac
      interp_g <- palette_rgb[2, idx_low] * (1 - frac) + palette_rgb[2, idx_high] * frac
      interp_b <- palette_rgb[3, idx_low] * (1 - frac) + palette_rgb[3, idx_high] * frac

      # Mix with original
      new_r <- r * (1 - intensity) + interp_r * intensity
      new_g <- g * (1 - intensity) + interp_g * intensity
      new_b <- b * (1 - intensity) + interp_b * intensity
    },

    "duotone" = {
      # Use first two colors for shadows and highlights
      lum <- 0.299 * r + 0.587 * g + 0.114 * b

      shadow_r <- palette_rgb[1, 1]
      shadow_g <- palette_rgb[2, 1]
      shadow_b <- palette_rgb[3, 1]

      highlight_r <- palette_rgb[1, 2]
      highlight_g <- palette_rgb[2, 2]
      highlight_b <- palette_rgb[3, 2]

      # Interpolate between shadow and highlight
      duo_r <- shadow_r * (1 - lum) + highlight_r * lum
      duo_g <- shadow_g * (1 - lum) + highlight_g * lum
      duo_b <- shadow_b * (1 - lum) + highlight_b * lum

      # Mix with original
      new_r <- r * (1 - intensity) + duo_r * intensity
      new_g <- g * (1 - intensity) + duo_g * intensity
      new_b <- b * (1 - intensity) + duo_b * intensity
    },

    "tritone" = {
      # Use three colors for shadows, midtones, and highlights
      lum <- 0.299 * r + 0.587 * g + 0.114 * b

      if (lum < 0.5) {
        # Interpolate between shadow and midtone
        t <- lum * 2
        tri_r <- palette_rgb[1, 1] * (1 - t) + palette_rgb[1, 2] * t
        tri_g <- palette_rgb[2, 1] * (1 - t) + palette_rgb[2, 2] * t
        tri_b <- palette_rgb[3, 1] * (1 - t) + palette_rgb[3, 2] * t
      } else {
        # Interpolate between midtone and highlight
        t <- (lum - 0.5) * 2
        tri_r <- palette_rgb[1, 2] * (1 - t) + palette_rgb[1, 3] * t
        tri_g <- palette_rgb[2, 2] * (1 - t) + palette_rgb[2, 3] * t
        tri_b <- palette_rgb[3, 2] * (1 - t) + palette_rgb[3, 3] * t
      }

      # Mix with original
      new_r <- r * (1 - intensity) + tri_r * intensity
      new_g <- g * (1 - intensity) + tri_g * intensity
      new_b <- b * (1 - intensity) + tri_b * intensity
    },

    "luminosity" = {
      # Preserve original luminosity but apply palette colors
      lum <- 0.299 * r + 0.587 * g + 0.114 * b

      # Get palette color based on original hue
      hue_factor <- (r + g * 2 + b * 3) / 6  # Simple hue approximation
      palette_idx <- ceiling(hue_factor * ncol(palette_rgb))
      palette_idx <- max(1, min(palette_idx, ncol(palette_rgb)))

      pal_r <- palette_rgb[1, palette_idx]
      pal_g <- palette_rgb[2, palette_idx]
      pal_b <- palette_rgb[3, palette_idx]

      # Apply luminosity preservation
      pal_lum <- 0.299 * pal_r + 0.587 * pal_g + 0.114 * pal_b
      if (pal_lum > 0) {
        lum_scale <- lum / pal_lum
        new_r <- r * (1 - intensity) + (pal_r * lum_scale) * intensity
        new_g <- g * (1 - intensity) + (pal_g * lum_scale) * intensity
        new_b <- b * (1 - intensity) + (pal_b * lum_scale) * intensity
      } else {
        new_r <- r
        new_g <- g
        new_b <- b
      }
    }
  )

  # Clamp values to 0-1
  return(c(
    max(0, min(1, new_r)),
    max(0, min(1, new_g)),
    max(0, min(1, new_b))
  ))
}

#' Convert array to base64 PNG
#' @noRd
array_to_base64_png <- function(arr) {
  # Ensure we have the png package
  if (!requireNamespace("png", quietly = TRUE)) {
    stop("Package 'png' is required but not installed. Install it with: install.packages('png')")
  }

  # Convert to raw PNG bytes
  png_raw <- png::writePNG(arr, target = raw())

  # Encode to base64 using jsonlite (already a dependency)
  jsonlite::base64_enc(png_raw)
}
