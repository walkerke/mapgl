#' Add legends to Mapbox GL and MapLibre GL maps
#'
#' These functions add categorical and continuous legends to maps. Use \code{legend_style()} 
#' to customize appearance and \code{clear_legend()} to remove legends.
#'
#' @name map_legends
#' @rdname map_legends
#'
#' @param map A map object created by the `mapboxgl` or `maplibre` function.
#' @param legend_title The title of the legend.
#' @param values The values being represented on the map (either a vector of categories or a vector of stops).
#' @param colors The corresponding colors for the values (either a vector of colors, a single color, or an interpolate function).
#' @param type One of "continuous" or "categorical" (for `add_legend` only).
#' @param circular_patches (Deprecated) Logical, whether to use circular patches in the legend. Use `patch_shape = "circle"` instead.
#' @param patch_shape Character or sf object, the shape of patches to use in categorical legends. Can be one of the built-in shapes ("square", "circle", "line", "hexagon"), a custom SVG string (e.g., '<polygon points="50,10 90,90 10,90" />'), or an sf object with POLYGON or MULTIPOLYGON geometry (which will be automatically converted to SVG). Default is "square".
#' @param position The position of the legend on the map (one of "top-left", "bottom-left", "top-right", "bottom-right").
#' @param sizes An optional numeric vector of sizes for the legend patches, or a single numeric value (only for categorical legends). For line patches, this controls the line thickness.
#' @param add Logical, whether to add this legend to existing legends (TRUE) or replace existing legends (FALSE). Default is FALSE.
#' @param unique_id Optional. A unique identifier for the legend. If not provided, a random ID will be generated.
#' @param width The width of the legend. Can be specified in pixels (e.g., "250px") or as "auto". Default is NULL, which uses the built-in default.
#' @param layer_id The ID of the layer that this legend is associated with. If provided, the legend will be shown/hidden when the layer visibility is toggled.
#' @param margin_top Custom top margin in pixels, allowing for fine control over legend positioning. Default is NULL (uses standard positioning).
#' @param margin_left Custom left margin in pixels. Default is NULL.
#' @param margin_bottom Custom bottom margin in pixels. Default is NULL.
#' @param margin_right Custom right margin in pixels. Default is NULL.
#' @param style Optional styling options created by \code{legend_style()} or a list of style options.
#'
#' @return The updated map object with the legend added.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic categorical legend
#' add_legend(map, "Population", 
#'           values = c("Low", "Medium", "High"),
#'           colors = c("blue", "yellow", "red"),
#'           type = "categorical")
#' 
#' # Continuous legend with custom styling
#' add_legend(map, "Income", 
#'           values = c(0, 50000, 100000),
#'           colors = c("blue", "yellow", "red"),
#'           type = "continuous",
#'           style = list(
#'             background_color = "white",
#'             background_opacity = 0.9,
#'             border_width = 2,
#'             border_color = "navy",
#'             text_color = "darkblue",
#'             font_family = "Times New Roman",
#'             title_font_weight = "bold"
#'           ))
#'           
#' # Legend with custom styling using a list
#' add_legend(map, "Temperature", 
#'           values = c(0, 50, 100),
#'           colors = c("blue", "yellow", "red"),
#'           type = "continuous",
#'           style = list(
#'             background_color = "#f0f0f0",
#'             title_size = 16,
#'             text_size = 12,
#'             shadow = TRUE,
#'             shadow_color = "rgba(0,0,0,0.1)",
#'             shadow_size = 8
#'           ))
#' 
#' # Dark legend with white element borders
#' add_legend(map, "Elevation", 
#'           values = c(0, 1000, 2000, 3000),
#'           colors = c("#2c7bb6", "#abd9e9", "#fdae61", "#d7191c"),
#'           type = "continuous",
#'           style = list(
#'             background_color = "#2c3e50",
#'             text_color = "white",
#'             title_color = "white",
#'             element_border_color = "white",
#'             element_border_width = 1
#'           ))
#'           
#' # Categorical legend with circular patches
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Population",
#'     values = c("Low", "Medium", "High"),
#'     colors = c("#FED976", "#FEB24C", "#FD8D3C"),
#'     patch_shape = "circle",
#'     sizes = c(10, 15, 20),
#'     style = list(
#'       background_opacity = 0.95,
#'       border_width = 1,
#'       border_color = "gray",
#'       title_color = "navy",
#'       element_border_color = "black",
#'       element_border_width = 1
#'     )
#' )
#' 
#' # Legend with line patches for line layers
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Road Type",
#'     values = c("Highway", "Primary", "Secondary"),
#'     colors = c("#000000", "#333333", "#666666"),
#'     patch_shape = "line",
#'     sizes = c(5, 3, 1)  # Line thickness in pixels
#' )
#' 
#' # Legend with hexagon patches (e.g., for H3 data)
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "H3 Hexagon Categories",
#'     values = c("Urban", "Suburban", "Rural"),
#'     colors = c("#8B0000", "#FF6347", "#90EE90"),
#'     patch_shape = "hexagon",
#'     sizes = 25
#' )
#' 
#' # Custom SVG shapes - triangle
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Mountain Peaks",
#'     values = c("High", "Medium", "Low"),
#'     colors = c("#8B4513", "#CD853F", "#F4A460"),
#'     patch_shape = '<polygon points="50,10 90,90 10,90" />'
#' )
#' 
#' # Custom SVG shapes - star
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Ratings",
#'     values = c("5 Star", "4 Star", "3 Star"),
#'     colors = c("#FFD700", "#FFA500", "#FF6347"),
#'     patch_shape = '<path d="M50,5 L61,35 L95,35 L68,57 L79,91 L50,70 L21,91 L32,57 L5,35 L39,35 Z" />'
#' )
#' 
#' # Custom SVG with complete SVG string
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Custom Icons",
#'     values = c("Location A", "Location B"),
#'     colors = c("#FF0000", "#0000FF"),
#'     patch_shape = '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" /></svg>'
#' )
#' 
#' # Using sf objects directly as patch shapes
#' library(sf)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"))
#' county_shape <- nc[1, ]  # Get first county
#' 
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "County Types",
#'     values = c("Rural", "Urban", "Suburban"),
#'     colors = c("#228B22", "#8B0000", "#FFD700"),
#'     patch_shape = county_shape  # sf object automatically converted to SVG
#' )
#' 
#' # For advanced users needing custom conversion options
#' custom_svg <- mapgl:::.sf_to_svg(county_shape, simplify = TRUE, tolerance = 0.001, fit_viewbox = TRUE)
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Custom Converted Shape",
#'     values = c("Type A"),
#'     colors = c("#4169E1"),
#'     patch_shape = custom_svg
#' )
#' 
#' }


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
        bg_color <- sprintf("rgba(%d, %d, %d, %.2f)", 
                           rgb_vals[1], rgb_vals[2], rgb_vals[3], style$background_opacity)
      } else {
        # For named colors, use rgba
        rgb_vals <- col2rgb(bg_color)
        bg_color <- sprintf("rgba(%d, %d, %d, %.2f)", 
                           rgb_vals[1], rgb_vals[2], rgb_vals[3], style$background_opacity)
      }
    }
    container_styles <- c(container_styles, paste0("background-color: ", bg_color, " !important;"))
  } else if (!is.null(style$background_opacity)) {
    # If only opacity is specified, modify the default background
    container_styles <- c(container_styles, 
                         sprintf("background-color: rgba(255, 255, 255, %.2f) !important;", 
                                style$background_opacity))
  }
  
  if (!is.null(style$border_color) || !is.null(style$border_width)) {
    border_color <- if (is.null(style$border_color)) "gray" else style$border_color
    border_width <- if (is.null(style$border_width)) 1 else style$border_width
    container_styles <- c(container_styles, 
                         sprintf("border: %dpx solid %s !important;", border_width, border_color))
  }
  
  if (!is.null(style$border_radius)) {
    container_styles <- c(container_styles, 
                         sprintf("border-radius: %dpx !important;", style$border_radius))
  }
  
  if (!is.null(style$padding)) {
    container_styles <- c(container_styles, 
                         sprintf("padding: %dpx !important;", style$padding))
  }
  
  if (!is.null(style$shadow) && style$shadow) {
    # Default shadow values
    shadow_color <- if (is.null(style$shadow_color)) "rgba(0,0,0,0.2)" else style$shadow_color
    shadow_size <- if (is.null(style$shadow_size)) 4 else style$shadow_size
    
    # Generate box-shadow CSS
    shadow_css <- sprintf("box-shadow: 0 2px %dpx %s !important;", shadow_size, shadow_color)
    container_styles <- c(container_styles, shadow_css)
  } else if (!is.null(style$shadow_color) || !is.null(style$shadow_size)) {
    # If shadow color/size is specified but shadow is not explicitly TRUE, enable shadow
    shadow_color <- if (is.null(style$shadow_color)) "rgba(0,0,0,0.2)" else style$shadow_color
    shadow_size <- if (is.null(style$shadow_size)) 4 else style$shadow_size
    
    shadow_css <- sprintf("box-shadow: 0 2px %dpx %s !important;", shadow_size, shadow_color)
    container_styles <- c(container_styles, shadow_css)
  }
  
  # Add container styles
  if (length(container_styles) > 0) {
    css_rules <- c(css_rules, sprintf("#%s {\n  %s\n}", 
                                     unique_id, paste(container_styles, collapse = "\n  ")))
  }
  
  # Title styles
  title_styles <- character(0)
  if (!is.null(style$title_color)) {
    title_styles <- c(title_styles, sprintf("color: %s !important;", style$title_color))
  }
  if (!is.null(style$title_size)) {
    title_styles <- c(title_styles, sprintf("font-size: %dpx !important;", style$title_size))
  }
  if (!is.null(style$title_font_family)) {
    title_styles <- c(title_styles, sprintf("font-family: '%s' !important;", style$title_font_family))
  } else if (!is.null(style$font_family)) {
    title_styles <- c(title_styles, sprintf("font-family: '%s' !important;", style$font_family))
  }
  if (!is.null(style$title_font_weight)) {
    title_styles <- c(title_styles, sprintf("font-weight: %s !important;", style$title_font_weight))
  } else if (!is.null(style$font_weight)) {
    title_styles <- c(title_styles, sprintf("font-weight: %s !important;", style$font_weight))
  }
  
  if (length(title_styles) > 0) {
    css_rules <- c(css_rules, sprintf("#%s h2 {\n  %s\n}", 
                                     unique_id, paste(title_styles, collapse = "\n  ")))
  }
  
  # Text styles
  text_styles <- character(0)
  if (!is.null(style$text_color)) {
    text_styles <- c(text_styles, sprintf("color: %s !important;", style$text_color))
  }
  if (!is.null(style$text_size)) {
    text_styles <- c(text_styles, sprintf("font-size: %dpx !important;", style$text_size))
  }
  if (!is.null(style$font_family)) {
    text_styles <- c(text_styles, sprintf("font-family: '%s' !important;", style$font_family))
  }
  if (!is.null(style$font_weight)) {
    text_styles <- c(text_styles, sprintf("font-weight: %s !important;", style$font_weight))
  }
  
  if (length(text_styles) > 0) {
    css_rules <- c(css_rules, sprintf("#%s .legend-text {\n  %s\n}", 
                                     unique_id, paste(text_styles, collapse = "\n  ")))
    css_rules <- c(css_rules, sprintf("#%s .legend-labels span {\n  %s\n}", 
                                     unique_id, paste(text_styles, collapse = "\n  ")))
  }
  
  # Element border styles (for patches/circles and color bars)
  if (!is.null(style$element_border_color) || !is.null(style$element_border_width)) {
    element_border_color <- if (is.null(style$element_border_color)) "gray" else style$element_border_color
    element_border_width <- if (is.null(style$element_border_width)) 1 else style$element_border_width
    
    # For categorical legend patches/circles (non-SVG elements)
    css_rules <- c(css_rules, sprintf("#%s .legend-color:not(svg) {\n  border: %dpx solid %s !important;\n  box-sizing: border-box !important;\n}", 
                                     unique_id, element_border_width, element_border_color))
    
    # For SVG hexagon elements
    css_rules <- c(css_rules, sprintf("#%s .legend-shape-hexagon polygon {\n  stroke: %s !important;\n  stroke-width: %d !important;\n}", 
                                     unique_id, element_border_color, element_border_width))
    
    # For custom SVG elements (apply to all SVG child elements)
    css_rules <- c(css_rules, sprintf("#%s .legend-shape-custom * {\n  stroke: %s !important;\n  stroke-width: %d !important;\n}", 
                                     unique_id, element_border_color, element_border_width))
    
    # Adjust patch container padding to accommodate borders
    padding_adjustment <- element_border_width
    css_rules <- c(css_rules, sprintf("#%s .legend-patch-container {\n  padding: %dpx !important;\n}", 
                                     unique_id, padding_adjustment))
    
    # For continuous legend color bar
    css_rules <- c(css_rules, sprintf("#%s .legend-gradient {\n  border: %dpx solid %s !important;\n  box-sizing: border-box !important;\n}", 
                                     unique_id, element_border_width, element_border_color))
  }
  
  if (length(css_rules) > 0) {
    return(paste0("\n", paste(css_rules, collapse = "\n"), "\n"))
  } else {
    return("")
  }
}

#' @rdname map_legends
#' @export
add_legend <- function(
    map,
    legend_title,
    values,
    colors,
    type = c("continuous", "categorical"),
    circular_patches = FALSE,
    patch_shape = "square",
    position = "top-left",
    sizes = NULL,
    add = FALSE,
    unique_id = NULL,
    width = NULL,
    layer_id = NULL,
    margin_top = NULL,
    margin_right = NULL,
    margin_bottom = NULL,
    margin_left = NULL,
    style = NULL
) {
    type <- match.arg(type)
    if (is.null(unique_id)) {
        unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
    }

    if (type == "continuous") {
        add_continuous_legend(
            map,
            legend_title,
            values,
            colors,
            position,
            unique_id,
            add,
            width,
            layer_id,
            margin_top,
            margin_right,
            margin_bottom,
            margin_left,
            style
        )
    } else {
        add_categorical_legend(
            map,
            legend_title,
            values,
            colors,
            circular_patches,
            patch_shape,
            position,
            unique_id,
            sizes,
            add,
            width,
            layer_id,
            margin_top,
            margin_right,
            margin_bottom,
            margin_left,
            style
        )
    }
}

#' @rdname map_legends
#' @export
add_categorical_legend <- function(
    map,
    legend_title,
    values,
    colors,
    circular_patches = FALSE,
    patch_shape = "square",
    position = "top-left",
    unique_id = NULL,
    sizes = NULL,
    add = FALSE,
    width = NULL,
    layer_id = NULL,
    margin_top = NULL,
    margin_right = NULL,
    margin_bottom = NULL,
    margin_left = NULL,
    style = NULL
) {
    # Handle deprecation of circular_patches
    if (!missing(circular_patches) && circular_patches) {
        warning("The 'circular_patches' argument is deprecated. Use 'patch_shape = \"circle\"' instead.",
                call. = FALSE)
        patch_shape <- "circle"
    }
    
    # Handle sf objects by converting to SVG
    if (inherits(patch_shape, "sf")) {
        patch_shape <- .sf_to_svg(patch_shape)
    }
    
    # Determine if patch_shape is a built-in shape or custom SVG
    built_in_shapes <- c("square", "circle", "line", "hexagon")
    is_custom_svg <- !patch_shape %in% built_in_shapes
    
    # Validate patch_shape
    if (is_custom_svg) {
        # Check if it looks like a valid SVG string
        if (!is.character(patch_shape) || nchar(patch_shape) == 0) {
            stop("'patch_shape' must be one of: ", paste(c(built_in_shapes, "a custom SVG string, or an sf object"), collapse = ", "))
        }
        
        # Basic SVG validation - should contain < and >
        if (!grepl("<.*>", patch_shape)) {
            stop("Custom SVG patch_shape appears invalid. It should contain SVG elements like '<path d=\"...\" />' or '<polygon points=\"...\" />'. Got: ", substr(patch_shape, 1, 50), if(nchar(patch_shape) > 50) "..." else "")
        }
    }
    
    # Extract SVG string for custom shapes
    svg_shape <- if (is_custom_svg) patch_shape else NULL
    
    # Set patch_shape to "custom" for processing
    if (is_custom_svg) {
        patch_shape <- "custom"
    }
    # Validate and prepare inputs
    if (length(colors) == 1) {
        colors <- rep(colors, length(values))
    } else if (length(colors) != length(values)) {
        stop(
            "'colors' must be a single value or have the same length as 'values'."
        )
    }

    # Give a default size if no size supplied
    if (is.null(sizes)) {
        sizes <- switch(patch_shape,
            "circle" = 20,
            "line" = 3,  # Default line thickness
            "hexagon" = 20,
            20  # default for square
        )
    }

    if (length(sizes) == 1) {
        sizes <- rep(sizes, length(values))
    } else if (length(sizes) != length(values)) {
        stop(
            "'sizes' must be a single value or have the same length as 'values'."
        )
    }

    max_size <- max(sizes)
    
    # Function to process custom SVG shapes
    .process_custom_svg <- function(svg_string, color, size) {
        # Remove whitespace and normalize
        svg_string <- gsub("\\s+", " ", trimws(svg_string))
        
        # Check if it's a complete SVG or just an element
        is_complete_svg <- grepl("^\\s*<svg", svg_string, ignore.case = TRUE)
        
        if (is_complete_svg) {
            # Extract viewBox and content from complete SVG
            viewbox_match <- regexpr('viewBox\\s*=\\s*["\']([^"\']+)["\']', svg_string, ignore.case = TRUE)
            if (viewbox_match != -1) {
                viewbox <- regmatches(svg_string, viewbox_match)
                viewbox <- gsub('.*viewBox\\s*=\\s*["\']([^"\']+)["\'].*', '\\1', viewbox, ignore.case = TRUE)
            } else {
                viewbox <- "0 0 100 100"  # Default viewBox
            }
            
            # Extract content between svg tags
            content_match <- regexpr('<svg[^>]*>(.*)</svg>', svg_string, ignore.case = TRUE)
            if (content_match != -1) {
                content <- gsub('<svg[^>]*>(.*)</svg>', '\\1', svg_string, ignore.case = TRUE)
            } else {
                content <- svg_string
            }
        } else {
            # It's just an SVG element, wrap it in SVG tags
            viewbox <- "0 0 100 100"  # Default viewBox
            content <- svg_string
        }
        
        # Replace colors in the content
        content <- .replace_svg_colors(content, color)
        
        # Calculate aspect ratio from viewBox
        viewbox_parts <- strsplit(trimws(viewbox), "\\s+")[[1]]
        if (length(viewbox_parts) >= 4) {
            vb_width <- as.numeric(viewbox_parts[3])
            vb_height <- as.numeric(viewbox_parts[4])
            aspect_ratio <- vb_width / vb_height
        } else {
            aspect_ratio <- 1  # Default to square
        }
        
        # Determine final dimensions maintaining aspect ratio
        if (aspect_ratio >= 1) {
            # Wider than tall
            final_width <- size
            final_height <- round(size / aspect_ratio)
        } else {
            # Taller than wide
            final_width <- round(size * aspect_ratio)
            final_height <- size
        }
        
        # Create the final SVG
        paste0(
            '<svg class="legend-color legend-shape-custom" width="', final_width, '" height="', final_height, '" ',
            'viewBox="', viewbox, '" preserveAspectRatio="xMidYMid meet">',
            content,
            '</svg>'
        )
    }
    
    # Function to replace colors in SVG content
    .replace_svg_colors <- function(svg_content, new_color) {
        # Replace common color attributes
        svg_content <- gsub('fill\\s*=\\s*["\'][^"\']*["\']', paste0('fill="', new_color, '"'), svg_content, ignore.case = TRUE)
        svg_content <- gsub('stroke\\s*=\\s*["\'][^"\']*["\']', paste0('stroke="', new_color, '"'), svg_content, ignore.case = TRUE)
        
        # Also handle fill and stroke in style attributes
        svg_content <- gsub('fill\\s*:\\s*[^;]+', paste0('fill:', new_color), svg_content, ignore.case = TRUE)
        svg_content <- gsub('stroke\\s*:\\s*[^;]+', paste0('stroke:', new_color), svg_content, ignore.case = TRUE)
        
        # If no fill or stroke found, add fill
        if (!grepl('fill\\s*[=:]', svg_content, ignore.case = TRUE)) {
            # Add fill attribute to the first element
            svg_content <- gsub('(<[^>]+)>', paste0('\\1 fill="', new_color, '">'), svg_content, perl = TRUE)
        }
        
        return(svg_content)
    }
    
    # Create a function to generate hexagon SVG
    create_hexagon_svg <- function(color, size) {
        # Flat-top hexagon coordinates (for H3 compatibility)
        # Width should be greater than height for flat-top
        # Using a viewBox with padding for stroke (4px on each side = 108x94.6)
        # Adjust polygon coordinates to account for padding
        paste0(
            '<svg class="legend-color legend-shape-hexagon" width="', size, '" height="', round(size * 0.866), '" ',
            'viewBox="0 0 108 94.6" preserveAspectRatio="xMidYMid meet">',
            '<polygon points="29,4 79,4 104,47.3 79,90.6 29,90.6 4,47.3" ',
            'fill="', color, '" />',
            '</svg>'
        )
    }

    legend_items <- lapply(seq_along(values), function(i) {
        patch_html <- switch(patch_shape,
            "square" = paste0(
                '<span class="legend-color legend-shape-square" style="background-color:',
                colors[i], '; width: ', sizes[i], 'px; height: ', sizes[i], 'px;"></span>'
            ),
            "circle" = paste0(
                '<span class="legend-color legend-shape-circle" style="background-color:',
                colors[i], '; width: ', sizes[i], 'px; height: ', sizes[i], 'px; border-radius: 50%;"></span>'
            ),
            "line" = paste0(
                '<span class="legend-color legend-shape-line" style="background-color:',
                colors[i], '; width: 30px; height: ', round(sizes[i]), 'px; display: block;"></span>'
            ),
            "hexagon" = create_hexagon_svg(colors[i], sizes[i]),
            "custom" = .process_custom_svg(svg_shape, colors[i], sizes[i])
        )
        
        # Adjust container dimensions based on shape
        if (patch_shape == "line") {
            container_width <- 30
            container_height <- max(sizes)  # Use max line thickness for consistent spacing
        } else {
            container_width <- max_size
            container_height <- max_size
        }
        
        paste0(
            '<div class="legend-item">',
            '<div class="legend-patch-container" style="width:',
            container_width,
            "px; height:",
            container_height,
            'px;">',
            patch_html,
            '</div>',
            '<span class="legend-text">',
            values[i],
            "</span>",
            "</div>"
        )
    })

    if (is.null(unique_id)) {
        unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
    }

    # Add data-layer-id attribute if layer_id is provided
    layer_attr <- if (!is.null(layer_id)) {
        paste0(' data-layer-id="', layer_id, '"')
    } else {
        ""
    }

    legend_html <- paste0(
        '<div id="',
        unique_id,
        '" class="mapboxgl-legend ',
        position,
        '"',
        layer_attr,
        ">",
        "<h2>",
        legend_title,
        "</h2>",
        paste0(legend_items, collapse = ""),
        "</div>"
    )

    width_style <- if (!is.null(width)) paste0("width: ", width, ";") else
        "max-width: 250px;"

    legend_css <- paste0(
        "
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');
    #",
        unique_id,
        " h2 {
      font-size: 14px;
      font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 20px;
      margin-bottom: 10px;
      margin-top: 0px;
      white-space: nowrap;
      max-width: 100%;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    #",
        unique_id,
        " {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      ",
        width_style,
        "
      background-color: #ffffff80;
      padding: 10px 20px;
      z-index: 1002;
    }
    #",
        unique_id,
        ".top-left {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }
    #",
        unique_id,
        ".bottom-left {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }
    #",
        unique_id,
        ".top-right {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }
    #",
        unique_id,
        ".bottom-right {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }
    #",
        unique_id,
        " .legend-item {
      display: flex;
      align-items: center;
      margin-bottom: 5px;
      font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      white-space: nowrap;
      max-width: 100%;
      overflow: hidden;
    }
    #",
        unique_id,
        " .legend-patch-container {
      display: flex;
      justify-content: center;
      align-items: center;
      margin-right: 5px;
    }
    #",
        unique_id,
        " .legend-color {
      display: inline-block;
      flex-shrink: 0;
    }
    #",
        unique_id,
        " .legend-shape-line {
      align-self: center;
      image-rendering: pixelated;
      image-rendering: -moz-crisp-edges;
      image-rendering: crisp-edges;
      transform: translateZ(0);
      -webkit-transform: translateZ(0);
    }
    #",
        unique_id,
        " .legend-shape-hexagon {
      display: block;
    }
    #",
        unique_id,
        " .legend-shape-custom {
      display: block;
    }
    #",
        unique_id,
        " .legend-text {
      flex-grow: 1;
      text-overflow: ellipsis;
      overflow: hidden;
    }
  "
    )

    # Add custom style CSS if provided
    custom_style_css <- .translate_style_to_css(style, unique_id)
    legend_css <- paste0(legend_css, custom_style_css)

    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- ifelse(
            inherits(map, "mapboxgl_proxy"),
            "mapboxgl-proxy",
            "maplibre-proxy"
        )
        map$session$sendCustomMessage(
            proxy_class,
            list(
                id = map$id,
                message = list(
                    type = "add_legend",
                    html = legend_html,
                    legend_css = legend_css,
                    add = add
                )
            )
        )
        map
    } else {
        if (!add) {
            map$x$legend_html <- legend_html
            map$x$legend_css <- legend_css
        } else {
            map$x$legend_html <- paste(map$x$legend_html, legend_html)
            map$x$legend_css <- paste(map$x$legend_css, legend_css)
        }
        return(map)
    }
}

#' @rdname map_legends
#' @export
add_continuous_legend <- function(
    map,
    legend_title,
    values,
    colors,
    position = "top-left",
    unique_id = NULL,
    add = FALSE,
    width = NULL,
    layer_id = NULL,
    margin_top = NULL,
    margin_right = NULL,
    margin_bottom = NULL,
    margin_left = NULL,
    style = NULL
) {
    if (is.null(unique_id)) {
        unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
    }

    color_gradient <- paste0(
        "linear-gradient(to right, ",
        paste(colors, collapse = ", "),
        ")"
    )

    num_values <- length(values)

    value_labels <- paste0(
        '<div class="legend-labels">',
        paste0(
            '<span style="position: absolute; left: ',
            seq(0, 100, length.out = num_values),
            '%;">',
            values,
            "</span>",
            collapse = ""
        ),
        "</div>"
    )

    # Add data-layer-id attribute if layer_id is provided
    layer_attr <- if (!is.null(layer_id)) {
        paste0(' data-layer-id="', layer_id, '"')
    } else {
        ""
    }

    legend_html <- paste0(
        '<div id="',
        unique_id,
        '" class="mapboxgl-legend ',
        position,
        '"',
        layer_attr,
        ">",
        "<h2>",
        legend_title,
        "</h2>",
        '<div class="legend-gradient" style="background:',
        color_gradient,
        '"></div>',
        '<div class="legend-labels" style="position: relative; height: 20px;">',
        value_labels,
        "</div>",
        "</div>"
    )

    width_style <- if (!is.null(width)) paste0("width: ", width, ";") else
        "width: 200px;"

    legend_css <- paste0(
        "
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

    #",
        unique_id,
        " h2 {
      font-size: 14px;
      font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 20px;
      margin-bottom: 10px;
      margin-top: 0px;
    }

    #",
        unique_id,
        " {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      ",
        width_style,
        "
      background-color: #ffffff80;
      padding: 10px 20px;
      z-index: 1002;
    }

    #",
        unique_id,
        ".top-left {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }

    #",
        unique_id,
        ".bottom-left {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      left: ",
        ifelse(is.null(margin_left), "10px", paste0(margin_left, "px")),
        ";
    }

    #",
        unique_id,
        ".top-right {
      top: ",
        ifelse(is.null(margin_top), "10px", paste0(margin_top, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }

    #",
        unique_id,
        ".bottom-right {
      bottom: ",
        ifelse(is.null(margin_bottom), "10px", paste0(margin_bottom, "px")),
        ";
      right: ",
        ifelse(is.null(margin_right), "10px", paste0(margin_right, "px")),
        ";
    }

    #",
        unique_id,
        " .legend-gradient {
      height: 20px;
      margin: 5px 10px 5px 10px;
    }

    #",
        unique_id,
        " .legend-labels {
      position: relative;
      height: 20px;
      margin: 0 10px;
    }

    #",
        unique_id,
        " .legend-labels span {
      font-size: 12px;
      position: absolute;
      transform: translateX(-50%);  /* Center all labels by default */
      white-space: nowrap;
    }

"
    )

    # Add custom style CSS if provided
    custom_style_css <- .translate_style_to_css(style, unique_id)
    legend_css <- paste0(legend_css, custom_style_css)

    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- ifelse(
            inherits(map, "mapboxgl_proxy"),
            "mapboxgl-proxy",
            "maplibre-proxy"
        )

        map$session$sendCustomMessage(
            proxy_class,
            list(
                id = map$id,
                message = list(
                    type = "add_legend",
                    html = legend_html,
                    legend_css = legend_css,
                    add = add
                )
            )
        )

        map
    } else {
        if (!add) {
            map$x$legend_html <- legend_html
            map$x$legend_css <- legend_css
        } else {
            map$x$legend_html <- paste(map$x$legend_html, legend_html)
            map$x$legend_css <- paste(map$x$legend_css, legend_css)
        }
        return(map)
    }
}

#' Create custom styling for map legends
#'
#' This function creates a styling object that can be passed to legend functions
#' to customize the appearance of legends, including colors, fonts, borders, and shadows.
#'
#' @name legend_style
#' @rdname legend_style
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

#' Clear legends from a map
#'
#' Remove one or more legends from a Mapbox GL or MapLibre GL map in a Shiny application.
#'
#' @param map A map proxy object created by \code{mapboxgl_proxy()} or \code{maplibre_proxy()}.
#' @param legend_ids Optional. A character vector of legend IDs to clear. If not provided, all legends will be cleared.
#'
#' @return The updated map proxy object with the specified legend(s) cleared.
#'
#' @note This function can only be used with map proxy objects in Shiny applications. 
#' It cannot be used with static map objects.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # In a Shiny server function:
#' 
#' # Clear all legends
#' observeEvent(input$clear_all, {
#'   mapboxgl_proxy("map") %>%
#'     clear_legend()
#' })
#' 
#' # Clear specific legends by ID
#' observeEvent(input$clear_specific, {
#'   mapboxgl_proxy("map") %>%
#'     clear_legend(legend_ids = c("legend-1", "legend-2"))
#' })
#' 
#' # Clear legend after removing a layer
#' observeEvent(input$remove_layer, {
#'   mapboxgl_proxy("map") %>%
#'     remove_layer("my_layer") %>%
#'     clear_legend(legend_ids = "my_layer_legend")
#' })
#' }
clear_legend <- function(map, legend_ids = NULL) {
    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        proxy_class <- ifelse(
            inherits(map, "mapboxgl_proxy"),
            "mapboxgl-proxy",
            "maplibre-proxy"
        )
        message <- if (is.null(legend_ids)) {
            list(type = "clear_legend")
        } else {
            list(type = "clear_legend", ids = legend_ids)
        }
        map$session$sendCustomMessage(
            proxy_class,
            list(id = map$id, message = message)
        )
    } else {
        stop(
            "clear_legend can only be used with mapboxgl_proxy or maplibre_proxy objects."
        )
    }
    return(map)
}
