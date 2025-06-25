# Internal utility functions for mapgl

# Internal function to convert sf objects to SVG paths
.sf_to_svg <- function(sf_obj, simplify = TRUE, tolerance = 0.01, fit_viewbox = FALSE) {
  # Ensure sf is loaded
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for sf object patch shapes. Please install it with: install.packages('sf')")
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
    coords[, "Y"] <- (bbox["ymax"] - coords[, "Y"]) * scale_factor  # Flip Y axis for SVG
    
    viewbox_string <- paste0('viewBox="0 0 ', round(final_width, 2), ' ', round(final_height, 2), '"')
    
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
    coords[, "X"] <- ((coords[, "X"] - bbox["xmin"]) / width) * scale_width + offset_x
    coords[, "Y"] <- ((bbox["ymax"] - coords[, "Y"]) / height) * scale_height + offset_y  # Flip Y axis for SVG
    
    viewbox_string <- 'viewBox="0 0 100 100"'
  }
  
  # Handle different geometry types - only accept polygon types
  geom_type <- as.character(sf::st_geometry_type(sf_obj))[1]  # Take first element to avoid issues
  
  if (is.na(geom_type) || !geom_type %in% c("POLYGON", "MULTIPOLYGON")) {
    stop("Only POLYGON and MULTIPOLYGON geometries are supported for legend patch shapes. Found: ", 
         if(is.na(geom_type)) "unknown/invalid geometry" else geom_type)
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
    return(paste0('<svg ', viewbox_string, '><path d="', path_data, '" /></svg>'))
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