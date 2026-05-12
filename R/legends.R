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
#' @param patch_shape Character or sf object, the shape of patches to use in categorical legends. Can be one of the built-in shapes ("square", "circle", "line", "hexagon"), a custom SVG string, or an sf object with POLYGON or MULTIPOLYGON geometry (which will be automatically converted to SVG). Default is "square".
#' @param position The position of the legend on the map (one of "top-left", "bottom-left", "top-right", "bottom-right").
#' @param sizes An optional numeric vector of sizes for the legend patches, or a single numeric value (only for categorical legends). For line patches, this controls the line thickness.
#' @param add Logical, whether to add this legend to existing legends (TRUE) or replace existing legends (FALSE). Default is FALSE.
#' @param unique_id Optional. A unique identifier for the legend. If not provided, a random ID will be generated.
#' @param width The width of the legend. Can be specified in pixels (e.g., "250px") or as "auto". Default is NULL, which uses the built-in default.
#' @param layer_id The ID of the layer (or a character vector of layer IDs) that this legend is associated with. If provided, the legend will be shown/hidden when the layer visibility is toggled. When multiple layer IDs are provided with \code{interactive = TRUE}, the legend will filter all specified layers simultaneously.
#' @param margin_top Custom top margin in pixels, allowing for fine control over legend positioning. Default is NULL (uses standard positioning).
#' @param margin_left Custom left margin in pixels. Default is NULL.
#' @param margin_bottom Custom bottom margin in pixels. Default is NULL.
#' @param margin_right Custom right margin in pixels. Default is NULL.
#' @param style Optional styling options created by \code{legend_style()} or a list of style options.
#' @param target For compare objects only: where to place the legend. Can be "compare" (attached to compare container, persists during swipe), "before" (attached to left/top map), or "after" (attached to right/bottom map). Default is "compare".
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
#' # Custom SVG shapes - star
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Ratings",
#'     values = c("5 Star", "4 Star", "3 Star"),
#'     colors = c("#FFD700", "#FFA500", "#FF6347"),
#'     patch_shape = paste0('<path d="M50,5 L61,35 L95,35 L68,57 L79,91 L50,70 ',
#'                          'L21,91 L32,57 L5,35 L39,35 Z" />')
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
#' custom_svg <- mapgl:::.sf_to_svg(county_shape, simplify = TRUE,
#'                                   tolerance = 0.001, fit_viewbox = TRUE)
#' add_categorical_legend(
#'     map = map,
#'     legend_title = "Custom Converted Shape",
#'     values = c("Type A"),
#'     colors = c("#4169E1"),
#'     patch_shape = custom_svg
#' )
#'
#' # Compare view legends
#' compare_view <- compare(map1, map2)
#'
#' # Add persistent legend (stays visible during swipe)
#' compare_view |>
#'   add_legend("Persistent Legend",
#'             values = c("Low", "High"),
#'             colors = c("blue", "red"),
#'             type = "categorical",
#'             target = "compare",
#'             position = "top-left")
#'
#' # Add legends to specific maps
#' compare_view |>
#'   add_legend("Left Map",
#'             values = c("A", "B"),
#'             colors = c("green", "orange"),
#'             type = "categorical",
#'             target = "before",
#'             position = "bottom-left") |>
#'   add_legend("Right Map",
#'             values = c("X", "Y"),
#'             colors = c("purple", "yellow"),
#'             type = "categorical",
#'             target = "after",
#'             position = "bottom-right")
#'
#' }

#' @param interactive Logical, whether to make the legend interactive. For categorical legends, clicking on legend items will toggle the visibility of the corresponding features. For continuous legends, a range slider will appear allowing users to filter features by value. Default is FALSE. Note: interactive legends are not yet supported for compare maps.
#' @param filter_column Character, the name of the data column to use for filtering when interactive is TRUE. If NULL (default), the column will be auto-detected from the layer's paint expression.
#' @param filter_values For interactive legends, the actual data values to filter on. For categorical legends, use this when your display labels differ from the data values (e.g., values = c("Music", "Bar") for display, filter_values = c("music", "bar") for filtering). For continuous legends, provide numeric break values when using formatted display labels (e.g., values = get_legend_labels(scale), filter_values = get_breaks(scale)). If NULL (default), uses values.
#' @param classification A mapgl_classification object (from step_quantile, step_equal_interval, etc.) to use for the legend. When provided, values and colors will be automatically extracted. For interactive legends, range-based filtering will be used based on the classification breaks.
#' @param breaks Numeric vector of break points for filtering with classification-based legends. Typically extracted automatically from the classification object. Only needed if you want to override the default breaks.
#' @param color_ramps For continuous legends, a list of color vectors to expose in a color-ramp picker. Named lists use the names as picker labels; unnamed lists get generated labels.
#' @param selected_ramp The initially selected ramp name or index when `color_ramps` is provided.
#' @param ramp_picker Logical, whether to show the continuous legend color-ramp picker.
#' @param ramp_labels Logical, whether to show palette labels in the color-ramp picker.
#' @param color_column Character, the data column to use when restyling the layer. If NULL, mapgl attempts to auto-detect it from the layer paint expression.
#' @param color_property Character, the paint property to restyle. If NULL, mapgl attempts to auto-detect one of `fill-color`, `circle-color`, `line-color`, or `fill-extrusion-color`.
#' @param na_color Color to use for missing values when rebuilding the interpolation expression.
#' @param draggable Logical, whether the legend can be dragged to a new position by the user. Default is FALSE.
#' @param collapsible Logical, whether to render a toggle button that collapses the legend to a header-only view. Default is FALSE. Most useful for categorical legends with tall bodies on small viewports.
#' @param collapsed Logical, whether the legend starts in the collapsed state. Only applies when \code{collapsible = TRUE}. Default is FALSE.
#'
#' @details
#' \strong{Collapsible legends.} When \code{collapsible = TRUE}, a 26x26px toggle
#' button is rendered in the legend's top-right corner. Collapsed, only the
#' title heading and the toggle button remain visible; every other direct
#' child of the legend (subtitles, swatches, item labels, the reset-filter
#' button from interactive legends, any user-appended source footers) is
#' hidden via CSS. The toggle button inherits \code{border_color} and
#' \code{text_color} from \code{\link{legend_style}()} so it picks up your
#' legend theme.
#'
#' If you inject your own title block via \code{htmlwidgets::onRender()} --
#' for example, to add a styled heading above the default title -- mark that
#' element with \code{class="mapgl-legend-title"} so it stays visible when
#' collapsed.
#'
#' @export
add_legend <- function(
  map,
  legend_title,
  values = NULL,
  colors = NULL,
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
  target = NULL,
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
  type <- match.arg(type)
  if (is.null(unique_id)) {
    unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
  }

  if (type == "continuous" && inherits(colors, "mapgl_continuous_scale")) {
    scale <- colors
    if (is.null(values)) {
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

  # Handle classification object if provided
  if (!is.null(classification)) {
    if (!inherits(classification, "mapgl_classification")) {
      rlang::abort("classification must be a mapgl_classification object (from step_quantile, etc.)")
    }
    # Extract values and colors from classification if not provided
    if (is.null(values)) {
      values <- classification$labels
    }
    if (is.null(colors)) {
      colors <- classification$colors
    }
    # Store breaks for range-based filtering
    breaks <- classification$breaks
  }

  # Validate that values and colors are provided

if (is.null(values) || is.null(colors)) {
    rlang::abort("values and colors must be provided, either directly or via classification parameter")
  }

  # For compare objects, use S3 method dispatch
  if (inherits(map, "mapboxgl_compare") || inherits(map, "maplibre_compare")) {
    UseMethod("add_legend")
  } else {
    # For regular maps, ignore target parameter and use existing functions
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
        style,
        interactive,
        filter_column,
        filter_values,
        draggable,
        color_ramps,
        selected_ramp,
        ramp_picker,
        ramp_labels,
        color_column,
        color_property,
        na_color,
        collapsible = collapsible,
        collapsed = collapsed
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
        style,
        interactive,
        filter_column,
        filter_values,
        breaks,
        draggable,
        collapsible = collapsible,
        collapsed = collapsed
      )
    }
  }
}

#' Add a bivariate legend
#'
#' @param map A map object created by `mapboxgl()` or `maplibre()`, a compare
#'   object, or a proxy object.
#' @param scale A `mapgl_bivariate_scale` object from `bivariate_scale()`.
#' @param legend_title Optional legend title.
#' @param x_title Label for the horizontal axis. Defaults to the x column name.
#' @param y_title Label for the vertical axis. Defaults to the y column name.
#' @param position The legend position.
#' @param width Legend width.
#' @param style Optional styling options from `legend_style()` or a list.
#' @param add Logical, whether to add to existing legends.
#' @param unique_id Optional unique legend ID.
#' @param layer_id Optional associated layer ID for layer-control show/hide.
#' @param target For compare objects, one of `"compare"`, `"before"`, or `"after"`.
#' @param draggable Logical, whether the legend can be dragged.
#' @param collapsible Logical, whether the legend can collapse.
#' @param collapsed Logical, whether the legend starts collapsed.
#'
#' @return The updated map object.
#' @export
add_bivariate_legend <- function(
  map,
  scale,
  legend_title = NULL,
  x_title = NULL,
  y_title = NULL,
  position = "top-left",
  width = NULL,
  style = NULL,
  add = FALSE,
  unique_id = NULL,
  layer_id = NULL,
  target = "compare",
  draggable = FALSE,
  collapsible = FALSE,
  collapsed = FALSE
) {
  if (!inherits(scale, "mapgl_bivariate_scale")) {
    rlang::abort("scale must be a mapgl_bivariate_scale object from bivariate_scale().")
  }

  if (is.null(unique_id)) {
    unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
  }
  if (is.null(legend_title)) legend_title <- "Bivariate legend"
  if (is.null(x_title)) x_title <- scale$x
  if (is.null(y_title)) y_title <- scale$y

  legend_data <- build_bivariate_legend(
    legend_title = legend_title,
    x_title = x_title,
    y_title = y_title,
    colors = scale$colors,
    position = position,
    unique_id = unique_id,
    width = width,
    layer_id = layer_id,
    style = style,
    draggable = draggable,
    collapsible = collapsible,
    collapsed = collapsed
  )

  if (inherits(map, "mapboxgl_compare") || inherits(map, "maplibre_compare")) {
    if (is.null(map$x$compare_legends)) {
      map$x$compare_legends <- list()
    }
    legend_info <- list(
      html = legend_data$html,
      css = legend_data$css,
      target = target,
      add = add
    )
    if (!add && target == "compare") {
      map$x$compare_legends <- list(legend_info)
    } else {
      map$x$compare_legends <- append(map$x$compare_legends, list(legend_info))
    }
    return(map)
  }

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) "mapboxgl-proxy" else "maplibre-proxy"
    if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy")) "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
    }
    message <- list(
      type = "add_legend",
      html = legend_data$html,
      legend_css = legend_data$css,
      add = add
    )
    if (inherits(map, "mapboxgl_compare_proxy") || inherits(map, "maplibre_compare_proxy")) {
      message$map <- map$map_side
    }
    map$session$sendCustomMessage(proxy_class, list(id = map$id, message = message))
    return(map)
  }

  if (!add) {
    map$x$legend_html <- legend_data$html
    map$x$legend_css <- legend_data$css
  } else {
    map$x$legend_html <- paste(map$x$legend_html, legend_data$html)
    map$x$legend_css <- paste(map$x$legend_css, legend_data$css)
  }
  map
}

build_bivariate_legend <- function(
  legend_title,
  x_title,
  y_title,
  colors,
  position = "top-left",
  unique_id,
  width = NULL,
  layer_id = NULL,
  style = NULL,
  draggable = FALSE,
  collapsible = FALSE,
  collapsed = FALSE
) {
  width_style <- if (!is.null(width)) paste0("width: ", width, ";") else "width: 142px;"
  layer_attr <- if (!is.null(layer_id)) paste0(' data-layer-id="', paste(layer_id, collapse = " "), '"') else ""
  draggable_attr <- if (draggable) ' data-draggable="true"' else ""
  collapsible_attr <- if (collapsible) ' data-collapsible="true"' else ""
  collapsed_class <- if (collapsible && collapsed) " mapgl-legend-collapsed" else ""
  collapse_btn_html <- if (collapsible) {
    paste0(
      '<button type="button" class="mapgl-legend-collapse-btn" aria-label="',
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

  cells <- character(0)
  for (row in 3:1) {
    for (col in 1:3) {
      cells <- c(cells, paste0(
        '<div class="mapgl-bivariate-cell" style="background-color:',
        colors[row, col],
        ';"></div>'
      ))
    }
  }

  legend_html <- paste0(
    '<div id="',
    unique_id,
    '" class="mapboxgl-legend mapgl-bivariate-legend ',
    position,
    collapsed_class,
    '"',
    layer_attr,
    draggable_attr,
    collapsible_attr,
    ">",
    '<h2 class="mapgl-legend-title">',
    legend_title,
    "</h2>",
    collapse_btn_html,
    '<div class="mapgl-bivariate-body">',
    '<div class="mapgl-bivariate-y-title">',
    y_title,
    "</div>",
    '<div class="mapgl-bivariate-grid">',
    paste0(cells, collapse = ""),
    "</div>",
    '<div class="mapgl-bivariate-x-title">',
    x_title,
    "</div>",
    "</div>",
    "</div>"
  )

  legend_css <- paste0(
    "#", unique_id, " {
      position: absolute;
      border-radius: 10px;
      margin: 10px;
      ", width_style, "
      background-color: #ffffffd9;
      padding: 10px 14px 12px 14px;
      z-index: 1002;
    }
    #", unique_id, ".top-left { top: 10px; left: 10px; }
    #", unique_id, ".bottom-left { bottom: 10px; left: 10px; }
    #", unique_id, ".top-right { top: 10px; right: 10px; }
    #", unique_id, ".bottom-right { bottom: 10px; right: 10px; }
    #", unique_id, " h2 {
      font-size: 14px;
      font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
      line-height: 20px;
      margin: 0 0 10px 0;
    }
    #", unique_id, " .mapgl-bivariate-body {
      display: grid;
      grid-template-columns: 18px 96px;
      grid-template-rows: 96px auto;
      gap: 6px;
      align-items: center;
      width: 120px;
    }
    #", unique_id, " .mapgl-bivariate-y-title {
      writing-mode: vertical-rl;
      transform: rotate(180deg);
      text-align: center;
      font-size: 11px;
      color: #374151;
    }
    #", unique_id, " .mapgl-bivariate-grid {
      display: grid;
      grid-template-columns: repeat(3, 32px);
      grid-template-rows: repeat(3, 32px);
      border: 1px solid rgba(17, 24, 39, 0.18);
    }
    #", unique_id, " .mapgl-bivariate-cell {
      width: 32px;
      height: 32px;
      border: 1px solid rgba(255, 255, 255, 0.55);
      box-sizing: border-box;
    }
    #", unique_id, " .mapgl-bivariate-x-title {
      grid-column: 2;
      text-align: center;
      font-size: 11px;
      color: #374151;
    }"
  )

  legend_css <- paste0(legend_css, .translate_style_to_css(style, unique_id))
  list(html = legend_html, css = legend_css)
}

build_ramp_picker_html <- function(color_ramps, selected_ramp, ramp_labels = TRUE) {
  if (is.null(color_ramps)) {
    return("")
  }

  ramp_items <- vapply(names(color_ramps), function(ramp_name) {
    ramp <- color_ramps[[ramp_name]]
    gradient <- paste0("linear-gradient(to right, ", paste(ramp, collapse = ", "), ")")
    selected_attr <- if (identical(ramp_name, selected_ramp)) ' data-selected="true"' else ""
    label_html <- if (isTRUE(ramp_labels)) {
      paste0(
        '<span class="mapgl-ramp-picker-label">',
        ramp_name,
        "</span>"
      )
    } else {
      ""
    }
    paste0(
      '<button type="button" class="mapgl-ramp-picker-option" data-ramp-name="',
      ramp_name,
      '"',
      selected_attr,
      '>',
      '<span class="mapgl-ramp-picker-swatch" style="background:',
      gradient,
      ';"></span>',
      label_html,
      "</button>"
    )
  }, character(1))

  paste0(
    '<div class="mapgl-ramp-picker',
    if (isTRUE(ramp_labels)) "" else " mapgl-ramp-picker-no-labels",
    '">',
    '<div class="mapgl-ramp-picker-menu" role="menu">',
    paste0(ramp_items, collapse = ""),
    "</div>",
    "</div>"
  )
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
  style = NULL,
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  breaks = NULL,
  draggable = FALSE,
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

    # Add data-value attribute for interactive legends
    item_data_attr <- if (interactive) {
      paste0(' data-value="', htmltools::htmlEscape(as.character(values[i])), '" data-enabled="true"')
    } else {
      ""
    }

    paste0(
      '<div class="legend-item"', item_data_attr, '>',
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
    paste0(' data-layer-id="', paste(layer_id, collapse = " "), '"')
  } else {
    ""
  }

  # Add interactive data attributes if interactive is TRUE
  interactive_attr <- if (interactive) {
    paste0(' data-interactive="true" data-legend-type="categorical"')
  } else {
    ""
  }

  # Add draggable attribute if draggable is TRUE
  draggable_attr <- if (draggable) ' data-draggable="true"' else ""

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
    interactive_attr,
    draggable_attr,
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

  # Create interactivity config if interactive is TRUE
  interactivity_config <- NULL
  if (interactive && !is.null(layer_id)) {
    # Determine filter values: use filter_values if provided, otherwise use values
    # Preserve original types - don't coerce to character for numeric data
    actual_filter_values <- if (!is.null(filter_values)) {
      filter_values
    } else {
      values
    }

    interactivity_config <- list(
      legendId = unique_id,
      layerId = layer_id,
      type = "categorical",
      values = as.character(values),  # Display values can be strings
      colors = colors,
      filterColumn = filter_column,
      filterValues = as.list(actual_filter_values),  # Use list to preserve types in JSON
      breaks = if (!is.null(breaks)) as.numeric(breaks) else NULL
    )
  }

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_legend",
            html = legend_html,
            legend_css = legend_css,
            add = add,
            map = map$map_side,
            interactivity = interactivity_config
          )
        )
      )
    } else {
      # For regular proxies
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
            add = add,
            interactivity = interactivity_config
          )
        )
      )
    }
    map
  } else {
    if (!add) {
      map$x$legend_html <- legend_html
      map$x$legend_css <- legend_css
    } else {
      map$x$legend_html <- paste(map$x$legend_html, legend_html)
      map$x$legend_css <- paste(map$x$legend_css, legend_css)
    }

    # Store interactivity config for static widgets
    if (!is.null(interactivity_config)) {
      if (is.null(map$x$legend_interactivity)) {
        map$x$legend_interactivity <- list()
      }
      map$x$legend_interactivity <- c(map$x$legend_interactivity, list(interactivity_config))
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
  style = NULL,
  interactive = FALSE,
  filter_column = NULL,
  filter_values = NULL,
  draggable = FALSE,
  color_ramps = NULL,
  selected_ramp = NULL,
  ramp_picker = !is.null(color_ramps),
  ramp_labels = TRUE,
  color_column = NULL,
  color_property = NULL,
  na_color = NULL,
  collapsible = FALSE,
  collapsed = FALSE
) {
  if (is.null(unique_id)) {
    unique_id <- paste0("legend-", as.hexmode(sample(1:1000000, 1)))
  }

  if (inherits(colors, "mapgl_continuous_scale")) {
    scale <- colors
    if (is.null(values)) {
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

  # For interactive legends, determine numeric values for filtering
  if (interactive) {
    if (!is.null(filter_values)) {
      # Use explicitly provided filter_values
      if (!is.numeric(filter_values)) {
        rlang::abort("filter_values must be numeric for interactive continuous legends.")
      }
      numeric_values <- filter_values
    } else if (is.numeric(values)) {
      # Use values directly if numeric
      numeric_values <- values
    } else {
      rlang::abort(c(
        "Interactive continuous legends require numeric values for filtering.",
        i = "Either pass numeric values, or provide filter_values with the numeric break points.",
        i = "Example: filter_values = scale$breaks or filter_values = get_breaks(scale)"
      ))
    }
  }

  if (ramp_picker) {
    if (is.null(layer_id)) {
      rlang::abort("ramp_picker requires layer_id so mapgl knows which layer(s) to restyle.")
    }
    if (is.null(color_ramps)) {
      rlang::abort("ramp_picker requires color_ramps.")
    }
  }

  color_ramps <- normalize_color_ramps(color_ramps, selected_ramp, length(colors))
  if (!is.null(color_ramps)) {
    selected_ramp <- attr(color_ramps, "selected_ramp", exact = TRUE)
    colors <- color_ramps[[selected_ramp]]
  }

  if (!interactive && (ramp_picker || !is.null(color_ramps))) {
    if (!is.null(filter_values)) {
      if (!is.numeric(filter_values)) {
        rlang::abort("filter_values must be numeric for continuous ramp restyling.")
      }
      numeric_values <- filter_values
    } else if (is.numeric(values)) {
      numeric_values <- values
    } else {
      rlang::abort(c(
        "Continuous ramp restyling requires numeric values.",
        i = "Either pass numeric values, or provide filter_values with the numeric break points."
      ))
    }
  }

  color_gradient <- paste0(
    "linear-gradient(to right, ",
    paste(colors, collapse = ", "),
    ")"
  )

  num_values <- length(values)

  # Format values for display (K/M notation for large numbers)
  # Only format if values are numeric; if already character, use as-is
  if (is.numeric(values)) {
    display_values <- sapply(values, function(val) {
      if (is.na(val)) return(NA_character_)
      abs_val <- abs(val)
      if (abs_val >= 1e6) {
        paste0(round(val / 1e6, 1), "M")
      } else if (abs_val >= 1e3) {
        paste0(round(val / 1e3, 1), "K")
      } else if (abs_val >= 1) {
        as.character(round(val, 1))
      } else {
        as.character(round(val, 2))
      }
    })
  } else {
    display_values <- as.character(values)
  }

  value_labels <- paste0(
    '<div class="legend-labels">',
    paste0(
      '<span style="position: absolute; left: ',
      seq(0, 100, length.out = num_values),
      '%;">',
      display_values,
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

  # Add interactive data attributes if interactive is TRUE
  interactive_attr <- if (interactive) {
    paste0(
      ' data-interactive="true" data-legend-type="continuous"',
      ' data-min-value="', min(numeric_values), '"',
      ' data-max-value="', max(numeric_values), '"'
    )
  } else {
    ""
  }

  # Add draggable attribute if draggable is TRUE
  draggable_attr <- if (draggable) ' data-draggable="true"' else ""
  ramp_picker_attr <- if (ramp_picker) ' data-ramp-picker="true"' else ""
  ramp_picker_html <- if (ramp_picker) build_ramp_picker_html(color_ramps, selected_ramp, ramp_labels) else ""
  gradient_picker_attr <- if (ramp_picker) ' role="button" tabindex="0" aria-haspopup="true" aria-expanded="false" title="Change color ramp"' else ""

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
    interactive_attr,
    draggable_attr,
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

  # Create interactivity config if interactive is TRUE
  interactivity_config <- NULL
  if ((interactive || ramp_picker) && !is.null(layer_id)) {
    interactivity_config <- list(
      legendId = unique_id,
      layerId = layer_id,
      type = "continuous",
      values = numeric_values,
      colors = colors,
      filterColumn = filter_column,
      filter = interactive,
      rampPicker = ramp_picker,
      colorRamps = color_ramps,
      selectedRamp = selected_ramp,
      colorColumn = color_column,
      colorProperty = color_property,
      naColor = na_color
    )
  }

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      # For compare proxies
      proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
        "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
      map$session$sendCustomMessage(
        proxy_class,
        list(
          id = map$id,
          message = list(
            type = "add_legend",
            html = legend_html,
            legend_css = legend_css,
            add = add,
            map = map$map_side,
            interactivity = interactivity_config
          )
        )
      )
    } else {
      # For regular proxies
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
            add = add,
            interactivity = interactivity_config
          )
        )
      )
    }

    map
  } else {
    if (!add) {
      map$x$legend_html <- legend_html
      map$x$legend_css <- legend_css
    } else {
      map$x$legend_html <- paste(map$x$legend_html, legend_html)
      map$x$legend_css <- paste(map$x$legend_css, legend_css)
    }

    # Store interactivity config for static widgets
    if (!is.null(interactivity_config)) {
      if (is.null(map$x$legend_interactivity)) {
        map$x$legend_interactivity <- list()
      }
      map$x$legend_interactivity <- c(map$x$legend_interactivity, list(interactivity_config))
    }

    return(map)
  }
}
