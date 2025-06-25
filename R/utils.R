# Internal utility functions for mapgl

# Internal function to convert sf objects to SVG paths
.sf_to_svg <- function(
  sf_obj,
  simplify = TRUE,
  tolerance = 0.01,
  fit_viewbox = FALSE
) {
  # Ensure sf is loaded
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop(
      "Package 'sf' is required for sf object patch shapes. Please install it with: install.packages('sf')"
    )
  }

  # Take first feature if multiple
  if (nrow(sf_obj) > 1) {
    warning("Multiple features found in sf object, using first feature only")
    sf_obj <- sf_obj[1, ]
  }

  # Simplify geometry if requested
  if (simplify) {
    sf_obj <- sf::st_simplify(sf_obj, dTolerance = tolerance)
  }

  # Get coordinates
  coords <- sf::st_coordinates(sf_obj)

  if (nrow(coords) == 0) {
    stop("No coordinates found in sf object")
  }

  # Get bounding box for normalization
  bbox <- sf::st_bbox(sf_obj)
  width <- bbox["xmax"] - bbox["xmin"]
  height <- bbox["ymax"] - bbox["ymin"]

  if (fit_viewbox) {
    # Create a tight-fitting viewBox with original aspect ratio
    # Scale to a reasonable size (e.g., 1000 units for precision)
    scale_factor <- 1000 / max(width, height)
    final_width <- width * scale_factor
    final_height <- height * scale_factor

    # No centering needed - use the exact bounds
    coords[, "X"] <- (coords[, "X"] - bbox["xmin"]) * scale_factor
    coords[, "Y"] <- (bbox["ymax"] - coords[, "Y"]) * scale_factor # Flip Y axis for SVG

    viewbox_string <- paste0(
      'viewBox="0 0 ',
      round(final_width, 2),
      ' ',
      round(final_height, 2),
      '"'
    )
  } else {
    # Preserve aspect ratio by scaling to fit within 100x100 while maintaining proportions
    aspect_ratio <- width / height

    if (aspect_ratio >= 1) {
      # Wider than tall - scale to 100 width
      scale_width <- 100
      scale_height <- 100 / aspect_ratio
    } else {
      # Taller than wide - scale to 100 height
      scale_height <- 100
      scale_width <- 100 * aspect_ratio
    }

    # Center the shape in the viewbox
    offset_x <- (100 - scale_width) / 2
    offset_y <- (100 - scale_height) / 2

    # Normalize coordinates preserving aspect ratio
    coords[, "X"] <- ((coords[, "X"] - bbox["xmin"]) / width) *
      scale_width +
      offset_x
    coords[, "Y"] <- ((bbox["ymax"] - coords[, "Y"]) / height) *
      scale_height +
      offset_y # Flip Y axis for SVG

    viewbox_string <- 'viewBox="0 0 100 100"'
  }

  # Handle different geometry types - only accept polygon types
  geom_type <- as.character(sf::st_geometry_type(sf_obj))[1] # Take first element to avoid issues

  if (is.na(geom_type) || !geom_type %in% c("POLYGON", "MULTIPOLYGON")) {
    stop(
      "Only POLYGON and MULTIPOLYGON geometries are supported for legend patch shapes. Found: ",
      if (is.na(geom_type)) "unknown/invalid geometry" else geom_type
    )
  }

  # Create SVG path for polygon
  path_data <- ""

  # Group by L1 (polygon parts) if it exists
  if ("L1" %in% colnames(coords)) {
    for (l1 in unique(coords[, "L1"])) {
      l1_coords <- coords[coords[, "L1"] == l1, ]

      # Group by L2 (holes) if it exists
      if ("L2" %in% colnames(l1_coords)) {
        for (l2 in unique(l1_coords[, "L2"])) {
          l2_coords <- l1_coords[l1_coords[, "L2"] == l2, ]
          path_data <- paste0(path_data, .coords_to_path(l2_coords))
        }
      } else {
        path_data <- paste0(path_data, .coords_to_path(l1_coords))
      }
    }
  } else {
    path_data <- .coords_to_path(coords)
  }

  if (fit_viewbox) {
    return(paste0(
      '<svg ',
      viewbox_string,
      '><path d="',
      path_data,
      '" /></svg>'
    ))
  } else {
    return(paste0('<path d="', path_data, '" />'))
  }
}

# Helper function to convert coordinates to SVG path data
.coords_to_path <- function(coords, close = TRUE) {
  if (nrow(coords) == 0) return("")

  # Start with move to first point
  path <- paste0("M", coords[1, "X"], ",", coords[1, "Y"])

  # Add line to commands for remaining points
  if (nrow(coords) > 1) {
    for (i in 2:nrow(coords)) {
      path <- paste0(path, " L", coords[i, "X"], ",", coords[i, "Y"])
    }
  }

  # Close path if requested
  if (close) {
    path <- paste0(path, " Z")
  }

  return(path)
}

# Internal function to convert style options to CSS
.translate_style_to_css <- function(style, unique_id) {
  if (is.null(style) || length(style) == 0) {
    return("")
  }

  # Convert list to legend_style if needed
  if (is.list(style) && !inherits(style, "mapgl_legend_style")) {
    class(style) <- "mapgl_legend_style"
  }

  css_rules <- character(0)

  # Legend container styles
  container_styles <- character(0)

  if (!is.null(style$background_color)) {
    bg_color <- style$background_color
    if (!is.null(style$background_opacity)) {
      # Convert color to rgba if opacity is specified
      if (grepl("^#", bg_color)) {
        # Convert hex to rgb
        rgb_vals <- col2rgb(bg_color)
        bg_color <- sprintf(
          "rgba(%d, %d, %d, %.2f)",
          rgb_vals[1],
          rgb_vals[2],
          rgb_vals[3],
          style$background_opacity
        )
      } else {
        # For named colors, use rgba
        rgb_vals <- col2rgb(bg_color)
        bg_color <- sprintf(
          "rgba(%d, %d, %d, %.2f)",
          rgb_vals[1],
          rgb_vals[2],
          rgb_vals[3],
          style$background_opacity
        )
      }
    }
    container_styles <- c(
      container_styles,
      paste0("background-color: ", bg_color, " !important;")
    )
  } else if (!is.null(style$background_opacity)) {
    # If only opacity is specified, modify the default background
    container_styles <- c(
      container_styles,
      sprintf(
        "background-color: rgba(255, 255, 255, %.2f) !important;",
        style$background_opacity
      )
    )
  }

  if (!is.null(style$border_color) || !is.null(style$border_width)) {
    border_color <- if (is.null(style$border_color)) "gray" else
      style$border_color
    border_width <- if (is.null(style$border_width)) 1 else style$border_width
    container_styles <- c(
      container_styles,
      sprintf("border: %dpx solid %s !important;", border_width, border_color)
    )
  }

  if (!is.null(style$border_radius)) {
    container_styles <- c(
      container_styles,
      sprintf("border-radius: %dpx !important;", style$border_radius)
    )
  }

  if (!is.null(style$padding)) {
    container_styles <- c(
      container_styles,
      sprintf("padding: %dpx !important;", style$padding)
    )
  }

  if (!is.null(style$shadow) && style$shadow) {
    # Default shadow values
    shadow_color <- if (is.null(style$shadow_color)) "rgba(0,0,0,0.2)" else
      style$shadow_color
    shadow_size <- if (is.null(style$shadow_size)) 4 else style$shadow_size

    # Generate box-shadow CSS
    shadow_css <- sprintf(
      "box-shadow: 0 2px %dpx %s !important;",
      shadow_size,
      shadow_color
    )
    container_styles <- c(container_styles, shadow_css)
  } else if (!is.null(style$shadow_color) || !is.null(style$shadow_size)) {
    # If shadow color/size is specified but shadow is not explicitly TRUE, enable shadow
    shadow_color <- if (is.null(style$shadow_color)) "rgba(0,0,0,0.2)" else
      style$shadow_color
    shadow_size <- if (is.null(style$shadow_size)) 4 else style$shadow_size

    shadow_css <- sprintf(
      "box-shadow: 0 2px %dpx %s !important;",
      shadow_size,
      shadow_color
    )
    container_styles <- c(container_styles, shadow_css)
  }

  # Add container styles
  if (length(container_styles) > 0) {
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s {\n  %s\n}",
        unique_id,
        paste(container_styles, collapse = "\n  ")
      )
    )
  }

  # Title styles
  title_styles <- character(0)
  if (!is.null(style$title_color)) {
    title_styles <- c(
      title_styles,
      sprintf("color: %s !important;", style$title_color)
    )
  }
  if (!is.null(style$title_size)) {
    title_styles <- c(
      title_styles,
      sprintf("font-size: %dpx !important;", style$title_size)
    )
  }
  if (!is.null(style$title_font_family)) {
    title_styles <- c(
      title_styles,
      sprintf("font-family: '%s' !important;", style$title_font_family)
    )
  } else if (!is.null(style$font_family)) {
    title_styles <- c(
      title_styles,
      sprintf("font-family: '%s' !important;", style$font_family)
    )
  }
  if (!is.null(style$title_font_weight)) {
    title_styles <- c(
      title_styles,
      sprintf("font-weight: %s !important;", style$title_font_weight)
    )
  } else if (!is.null(style$font_weight)) {
    title_styles <- c(
      title_styles,
      sprintf("font-weight: %s !important;", style$font_weight)
    )
  }

  if (length(title_styles) > 0) {
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s h2 {\n  %s\n}",
        unique_id,
        paste(title_styles, collapse = "\n  ")
      )
    )
  }

  # Text styles
  text_styles <- character(0)
  if (!is.null(style$text_color)) {
    text_styles <- c(
      text_styles,
      sprintf("color: %s !important;", style$text_color)
    )
  }
  if (!is.null(style$text_size)) {
    text_styles <- c(
      text_styles,
      sprintf("font-size: %dpx !important;", style$text_size)
    )
  }
  if (!is.null(style$font_family)) {
    text_styles <- c(
      text_styles,
      sprintf("font-family: '%s' !important;", style$font_family)
    )
  }
  if (!is.null(style$font_weight)) {
    text_styles <- c(
      text_styles,
      sprintf("font-weight: %s !important;", style$font_weight)
    )
  }

  if (length(text_styles) > 0) {
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-text {\n  %s\n}",
        unique_id,
        paste(text_styles, collapse = "\n  ")
      )
    )
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-labels span {\n  %s\n}",
        unique_id,
        paste(text_styles, collapse = "\n  ")
      )
    )
  }

  # Element border styles (for patches/circles and color bars)
  if (
    !is.null(style$element_border_color) || !is.null(style$element_border_width)
  ) {
    element_border_color <- if (is.null(style$element_border_color)) "gray" else
      style$element_border_color
    element_border_width <- if (is.null(style$element_border_width)) 1 else
      style$element_border_width

    # For categorical legend patches/circles (non-SVG elements)
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-color:not(svg) {\n  border: %dpx solid %s !important;\n  box-sizing: border-box !important;\n}",
        unique_id,
        element_border_width,
        element_border_color
      )
    )

    # For SVG hexagon elements
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-shape-hexagon polygon {\n  stroke: %s !important;\n  stroke-width: %d !important;\n}",
        unique_id,
        element_border_color,
        element_border_width
      )
    )

    # For custom SVG elements (apply to all SVG child elements)
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-shape-custom * {\n  stroke: %s !important;\n  stroke-width: %d !important;\n}",
        unique_id,
        element_border_color,
        element_border_width
      )
    )

    # Adjust patch container padding to accommodate borders
    padding_adjustment <- element_border_width
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-patch-container {\n  padding: %dpx !important;\n}",
        unique_id,
        padding_adjustment
      )
    )

    # For continuous legend color bar
    css_rules <- c(
      css_rules,
      sprintf(
        "#%s .legend-gradient {\n  border: %dpx solid %s !important;\n  box-sizing: border-box !important;\n}",
        unique_id,
        element_border_width,
        element_border_color
      )
    )
  }

  if (length(css_rules) > 0) {
    return(paste0("\n", paste(css_rules, collapse = "\n"), "\n"))
  } else {
    return("")
  }
}

#' Create custom styling for map legends
#'
#' This function creates a styling object that can be passed to legend functions
#' to customize the appearance of legends, including colors, fonts, borders, and shadows.
#'
#'
#' @param background_color Background color for the legend container (e.g., "white", "#ffffff").
#' @param background_opacity Opacity of the legend background (0-1, where 1 is fully opaque).
#' @param border_color Color of the legend border (e.g., "black", "#000000").
#' @param border_width Width of the legend border in pixels.
#' @param border_radius Border radius for rounded corners in pixels.
#' @param text_color Color of the legend text (e.g., "black", "#000000").
#' @param text_size Size of the legend text in pixels.
#' @param title_color Color of the legend title text.
#' @param title_size Size of the legend title text in pixels.
#' @param font_family Font family for legend text (e.g., "Arial", "Times New Roman", "Open Sans").
#' @param title_font_family Font family for legend title (defaults to font_family if not specified).
#' @param font_weight Font weight for legend text (e.g., "normal", "bold", "lighter", or numeric like 400, 700).
#' @param title_font_weight Font weight for legend title (defaults to font_weight if not specified).
#' @param element_border_color Color for borders around legend elements (color bar for continuous, patches/circles for categorical).
#' @param element_border_width Width in pixels for borders around legend elements.
#' @param shadow Logical, whether to add a drop shadow to the legend.
#' @param shadow_color Color of the drop shadow (e.g., "black", "rgba(0,0,0,0.3)").
#' @param shadow_size Size/blur radius of the drop shadow in pixels.
#' @param padding Internal padding of the legend container in pixels.
#'
#' @return A list of class "mapgl_legend_style" containing the styling options.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a dark theme legend style
#' dark_style <- legend_style(
#'   background_color = "#2c3e50",
#'   text_color = "white",
#'   title_color = "white",
#'   font_family = "Arial",
#'   title_font_weight = "bold",
#'   element_border_color = "white",
#'   element_border_width = 1,
#'   shadow = TRUE,
#'   shadow_color = "rgba(0,0,0,0.3)",
#'   shadow_size = 6
#' )
#'
#' # Use the style in a legend
#' add_categorical_legend(
#'   map = map,
#'   legend_title = "Categories",
#'   values = c("A", "B", "C"),
#'   colors = c("red", "green", "blue"),
#'   style = dark_style
#' )
#'
#' # Create a minimal style with just borders
#' minimal_style <- legend_style(
#'   element_border_color = "gray",
#'   element_border_width = 1
#' )
#' }
legend_style <- function(
  background_color = NULL,
  background_opacity = NULL,
  border_color = NULL,
  border_width = NULL,
  border_radius = NULL,
  text_color = NULL,
  text_size = NULL,
  title_color = NULL,
  title_size = NULL,
  font_family = NULL,
  title_font_family = NULL,
  font_weight = NULL,
  title_font_weight = NULL,
  element_border_color = NULL,
  element_border_width = NULL,
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  padding = NULL
) {
  style_list <- list(
    background_color = background_color,
    background_opacity = background_opacity,
    border_color = border_color,
    border_width = border_width,
    border_radius = border_radius,
    text_color = text_color,
    text_size = text_size,
    title_color = title_color,
    title_size = title_size,
    font_family = font_family,
    title_font_family = title_font_family,
    font_weight = font_weight,
    title_font_weight = title_font_weight,
    element_border_color = element_border_color,
    element_border_width = element_border_width,
    shadow = shadow,
    shadow_color = shadow_color,
    shadow_size = shadow_size,
    padding = padding
  )

  # Remove NULL values
  style_list <- style_list[!sapply(style_list, is.null)]

  class(style_list) <- "mapgl_legend_style"
  return(style_list)
}
