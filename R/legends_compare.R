#' @rdname map_legends
#' @export
add_legend.mapboxgl_compare <- function(
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
  style = NULL,
  target = "compare",
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  classification = NULL,
  breaks = NULL,
  color_ramps = NULL,
  selected_ramp = NULL,
  ramp_picker = !is.null(color_ramps),
  ramp_labels = TRUE,
  color_column = NULL,
  color_property = NULL,
  na_color = NULL,
  draggable = FALSE,
  collapsible = FALSE,
  collapsed = FALSE
) {

  # Warn if interactive features are requested (not yet supported for compare maps)
  if (interactive) {
    warning(
      "Interactive legends are not yet supported for compare maps. The legend will be displayed without interactivity.",
      call. = FALSE
    )
  }

  # Store the legend information in the widget's x data
  if (is.null(map$x$compare_legends)) {
    map$x$compare_legends <- list()
  }
  
  # Generate the legend HTML and CSS
  type <- match.arg(type)
  if (is.null(unique_id)) {
    unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
  }

  if (type == "continuous" && inherits(colors, "mapgl_continuous_scale")) {
    scale <- colors
    if (missing(values) || is.null(values)) {
      values <- get_legend_labels(scale)
    }
    if (is.null(filter_values)) {
      filter_values <- get_breaks(scale)
    }
    if (is.null(color_ramps)) {
      color_ramps <- scale$color_ramps
    }
    if (is.null(selected_ramp)) {
      selected_ramp <- scale$selected_ramp
    }
    if (is.null(color_column)) {
      color_column <- scale$column
    }
    if (is.null(na_color)) {
      na_color <- scale$na_color
    }
    colors <- scale$colors
  }

  interactivity_config <- NULL
  
  if (type == "continuous") {
    legend_data <- build_continuous_legend(
      legend_title, values, colors, position, unique_id,
      width, layer_id, margin_top, margin_right,
      margin_bottom, margin_left, style,
      color_ramps = color_ramps,
      selected_ramp = selected_ramp,
      ramp_picker = ramp_picker,
      ramp_labels = ramp_labels,
      collapsible = collapsible, collapsed = collapsed
    )

    if (ramp_picker) {
      if (is.null(layer_id)) {
        rlang::abort("ramp_picker requires layer_id so mapgl knows which layer(s) to restyle.")
      }
      numeric_values <- if (!is.null(filter_values)) {
        filter_values
      } else if (is.numeric(values)) {
        values
      } else {
        rlang::abort("Continuous ramp restyling requires numeric values or filter_values.")
      }
      interactivity_config <- list(
        legendId = unique_id,
        layerId = layer_id,
        type = "continuous",
        values = numeric_values,
        colors = legend_data$colors,
        filterColumn = filter_column,
        filter = FALSE,
        rampPicker = TRUE,
        colorRamps = legend_data$color_ramps,
        selectedRamp = legend_data$selected_ramp,
        colorColumn = color_column,
        colorProperty = color_property,
        naColor = na_color
      )
    }
  } else {
    legend_data <- build_categorical_legend(
      legend_title, values, colors, circular_patches,
      patch_shape, position, unique_id, sizes, width,
      layer_id, margin_top, margin_right, margin_bottom,
      margin_left, style,
      collapsible = collapsible, collapsed = collapsed
    )
  }
  
  # Add the legend to the appropriate target
  legend_info <- list(
    html = legend_data$html,
    css = legend_data$css,
    target = target,
    add = add,
    interactivity = interactivity_config
  )
  
  if (!add && target == "compare") {
    # Replace all compare-level legends
    map$x$compare_legends <- list(legend_info)
  } else {
    # Add to existing legends
    map$x$compare_legends <- append(map$x$compare_legends, list(legend_info))
  }
  
  return(map)
}

#' @rdname map_legends
#' @export
add_legend.maplibre_compare <- add_legend.mapboxgl_compare

# Helper functions to build legend HTML/CSS without attaching to a map
build_continuous_legend <- function(
  legend_title,
  values,
  colors,
  position = "top-left",
  unique_id = NULL,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  color_ramps = NULL,
  selected_ramp = NULL,
  ramp_picker = !is.null(color_ramps),
  ramp_labels = TRUE,
  collapsible = FALSE,
  collapsed = FALSE
) {
  if (is.null(unique_id)) {
    unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
  }

  color_ramps <- normalize_color_ramps(color_ramps, selected_ramp, length(colors))
  if (!is.null(color_ramps)) {
    selected_ramp <- attr(color_ramps, "selected_ramp", exact = TRUE)
    colors <- color_ramps[[selected_ramp]]
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
    paste0(' data-layer-id="', paste(layer_id, collapse = " "), '"')
  } else {
    ""
  }

  # Collapsible pieces
  ramp_picker_attr <- if (ramp_picker) ' data-ramp-picker="true"' else ""
  ramp_picker_html <- if (ramp_picker) build_ramp_picker_html(color_ramps, selected_ramp, ramp_labels) else ""
  gradient_picker_attr <- if (ramp_picker) ' role="button" tabindex="0" aria-haspopup="true" aria-expanded="false" title="Change color ramp"' else ""
  collapsible_attr <- if (collapsible) ' data-collapsible="true"' else ""
  collapsed_class <- if (collapsible && collapsed) " mapgl-legend-collapsed" else ""
  collapse_btn_html <- if (collapsible) {
    paste0(
      '<button type="button" class="mapgl-legend-collapse-btn" ',
      'aria-label="',
      if (collapsed) "Expand legend" else "Collapse legend",
      '" aria-expanded="',
      if (collapsed) "false" else "true",
      '">',
      if (collapsed) "+" else "\u2013",
      "</button>"
    )
  } else {
    ""
  }

  legend_html <- paste0(
    '<div id="',
    unique_id,
    '" class="mapboxgl-legend ',
    position,
    collapsed_class,
    '"',
    layer_attr,
    ramp_picker_attr,
    collapsible_attr,
    ">",
    '<h2 class="mapgl-legend-title">',
    legend_title,
    "</h2>",
    collapse_btn_html,
    ramp_picker_html,
    '<div class="legend-gradient" ',
    gradient_picker_attr,
    ' style="background:',
    color_gradient,
    '"></div>',
    ramp_picker_html,
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
      border-radius: 3px;
    }

    #",
    unique_id,
    "[data-ramp-picker='true'] .legend-gradient {
      cursor: pointer;
      outline: 1px solid rgba(17, 24, 39, 0.16);
      outline-offset: 0;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker {
      position: relative;
      height: 0;
      margin: 0 10px;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-swatch {
      display: inline-block;
      height: 14px;
      border-radius: 3px;
      border: 1px solid rgba(17, 24, 39, 0.16);
      flex: 1 1 auto;
      min-width: 64px;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-label {
      flex: 0 0 auto;
      white-space: nowrap;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-no-labels .mapgl-ramp-picker-swatch {
      min-width: 100%;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-no-labels .mapgl-ramp-picker-option {
      padding: 6px;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-menu {
      position: absolute;
      top: 4px;
      left: 0;
      right: 0;
      display: none;
      flex-direction: column;
      gap: 4px;
      padding: 6px;
      border: 1px solid rgba(17, 24, 39, 0.14);
      border-radius: 8px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: 0 8px 24px rgba(15, 23, 42, 0.18);
      z-index: 1004;
    }

    #",
    unique_id,
    ".bottom-left .mapgl-ramp-picker-menu,
    #",
    unique_id,
    ".bottom-right .mapgl-ramp-picker-menu {
      top: auto;
      bottom: 4px;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker.mapgl-ramp-picker-open .mapgl-ramp-picker-menu {
      display: flex;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-option {
      display: flex;
      align-items: center;
      gap: 8px;
      border: 0;
      border-radius: 5px;
      background: transparent;
      cursor: pointer;
      font: inherit;
      font-size: 12px;
      padding: 5px 6px;
      text-align: left;
    }

    #",
    unique_id,
    " .mapgl-ramp-picker-option:hover,
    #",
    unique_id,
    " .mapgl-ramp-picker-option[data-selected='true'] {
      background: rgba(15, 23, 42, 0.08);
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

  list(
    html = legend_html,
    css = legend_css,
    colors = colors,
    color_ramps = color_ramps,
    selected_ramp = selected_ramp
  )
}

build_categorical_legend <- function(
  legend_title,
  values,
  colors,
  circular_patches = FALSE,
  patch_shape = "square",
  position = "top-left",
  unique_id = NULL,
  sizes = NULL,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL,
  style = NULL,
  collapsible = FALSE,
  collapsed = FALSE
) {
  # Handle deprecation of circular_patches
  if (!missing(circular_patches) && circular_patches) {
    warning(
      "The 'circular_patches' argument is deprecated. Use 'patch_shape = \"circle\"' instead.",
      call. = FALSE
    )
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
      stop(
        "'patch_shape' must be one of: ",
        paste(
          c(built_in_shapes, "a custom SVG string, or an sf object"),
          collapse = ", "
        )
      )
    }

    # Basic SVG validation - should contain < and >
    if (!grepl("<.*>", patch_shape)) {
      stop(
        "Custom SVG patch_shape appears invalid. It should contain SVG elements like '<path d=\"...\" />' or '<polygon points=\"...\" />'. Got: ",
        substr(patch_shape, 1, 50),
        if (nchar(patch_shape) > 50) "..." else ""
      )
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
    sizes <- switch(
      patch_shape,
      "circle" = 20,
      "line" = 3, # Default line thickness
      "hexagon" = 20,
      20 # default for square
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
      viewbox_match <- regexpr(
        'viewBox\\s*=\\s*["\']([^"\']+)["\']',
        svg_string,
        ignore.case = TRUE
      )
      if (viewbox_match != -1) {
        viewbox <- regmatches(svg_string, viewbox_match)
        viewbox <- gsub(
          '.*viewBox\\s*=\\s*["\']([^"\']+)["\'].*',
          '\\1',
          viewbox,
          ignore.case = TRUE
        )
      } else {
        viewbox <- "0 0 100 100" # Default viewBox
      }

      # Extract content between svg tags
      content_match <- regexpr(
        '<svg[^>]*>(.*)</svg>',
        svg_string,
        ignore.case = TRUE
      )
      if (content_match != -1) {
        content <- gsub(
          '<svg[^>]*>(.*)</svg>',
          '\\1',
          svg_string,
          ignore.case = TRUE
        )
      } else {
        content <- svg_string
      }
    } else {
      # It's just an SVG element, wrap it in SVG tags
      viewbox <- "0 0 100 100" # Default viewBox
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
      aspect_ratio <- 1 # Default to square
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
      '<svg class="legend-color legend-shape-custom" width="',
      final_width,
      '" height="',
      final_height,
      '" ',
      'viewBox="',
      viewbox,
      '" preserveAspectRatio="xMidYMid meet">',
      content,
      '</svg>'
    )
  }

  # Function to replace colors in SVG content
  .replace_svg_colors <- function(svg_content, new_color) {
    # Replace common color attributes
    svg_content <- gsub(
      'fill\\s*=\\s*["\'][^"\']*["\']',
      paste0('fill="', new_color, '"'),
      svg_content,
      ignore.case = TRUE
    )
    svg_content <- gsub(
      'stroke\\s*=\\s*["\'][^"\']*["\']',
      paste0('stroke="', new_color, '"'),
      svg_content,
      ignore.case = TRUE
    )

    # Also handle fill and stroke in style attributes
    svg_content <- gsub(
      'fill\\s*:\\s*[^;]+',
      paste0('fill:', new_color),
      svg_content,
      ignore.case = TRUE
    )
    svg_content <- gsub(
      'stroke\\s*:\\s*[^;]+',
      paste0('stroke:', new_color),
      svg_content,
      ignore.case = TRUE
    )

    # If no fill or stroke found, add fill
    if (!grepl('fill\\s*[=:]', svg_content, ignore.case = TRUE)) {
      # Add fill attribute to the first element
      svg_content <- gsub(
        '(<[^>]+)>',
        paste0('\\1 fill="', new_color, '">'),
        svg_content,
        perl = TRUE
      )
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
      '<svg class="legend-color legend-shape-hexagon" width="',
      size,
      '" height="',
      round(size * 0.866),
      '" ',
      'viewBox="0 0 108 94.6" preserveAspectRatio="xMidYMid meet">',
      '<polygon points="29,4 79,4 104,47.3 79,90.6 29,90.6 4,47.3" ',
      'fill="',
      color,
      '" />',
      '</svg>'
    )
  }

  legend_items <- lapply(seq_along(values), function(i) {
    patch_html <- switch(
      patch_shape,
      "square" = paste0(
        '<span class="legend-color legend-shape-square" style="background-color:',
        colors[i],
        '; width: ',
        sizes[i],
        'px; height: ',
        sizes[i],
        'px;"></span>'
      ),
      "circle" = paste0(
        '<span class="legend-color legend-shape-circle" style="background-color:',
        colors[i],
        '; width: ',
        sizes[i],
        'px; height: ',
        sizes[i],
        'px; border-radius: 50%;"></span>'
      ),
      "line" = paste0(
        '<span class="legend-color legend-shape-line" style="background-color:',
        colors[i],
        '; width: 30px; height: ',
        round(sizes[i]),
        'px; display: block;"></span>'
      ),
      "hexagon" = create_hexagon_svg(colors[i], sizes[i]),
      "custom" = .process_custom_svg(svg_shape, colors[i], sizes[i])
    )

    # Adjust container dimensions based on shape
    if (patch_shape == "line") {
      container_width <- 30
      container_height <- max(sizes) # Use max line thickness for consistent spacing
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

  # Collapsible pieces
  collapsible_attr <- if (collapsible) ' data-collapsible="true"' else ""
  collapsed_class <- if (collapsible && collapsed) " mapgl-legend-collapsed" else ""
  collapse_btn_html <- if (collapsible) {
    paste0(
      '<button type="button" class="mapgl-legend-collapse-btn" ',
      'aria-label="',
      if (collapsed) "Expand legend" else "Collapse legend",
      '" aria-expanded="',
      if (collapsed) "false" else "true",
      '">',
      if (collapsed) "+" else "\u2013",
      "</button>"
    )
  } else {
    ""
  }

  legend_html <- paste0(
    '<div id="',
    unique_id,
    '" class="mapboxgl-legend ',
    position,
    collapsed_class,
    '"',
    layer_attr,
    collapsible_attr,
    ">",
    '<h2 class="mapgl-legend-title">',
    legend_title,
    "</h2>",
    collapse_btn_html,
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
  
  list(html = legend_html, css = legend_css)
}
