# Test script for legend patch shapes
library(mapgl)
library(sf)

# Create sample data
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

# Test 1: Square patches (default)
map1 <- maplibre() |>
  add_fill_layer(
    id = "nc_fill",
    source = nc,
    fill_color = interpolate(
      column = "BIR74",
      values = c(0, 5000, 10000),
      stops = c("#ffffcc", "#41b6c4", "#2c7fb8")
    )
  ) |>
  add_categorical_legend(
    legend_title = "Square Patches",
    values = c("Low", "Medium", "High"),
    colors = c("#ffffcc", "#41b6c4", "#2c7fb8"),
    patch_shape = "square",
    position = "top-left"
  )

# Test 2: Circle patches
map2 <- maplibre() |>
  add_fill_layer(
    id = "nc_fill",
    source = nc,
    fill_color = interpolate(
      column = "BIR74",
      values = c(0, 5000, 10000),
      stops = c("#fee0d2", "#fc9272", "#de2d26")
    )
  ) |>
  add_categorical_legend(
    legend_title = "Circle Patches",
    values = c("Small", "Medium", "Large"),
    colors = c("#fee0d2", "#fc9272", "#de2d26"),
    patch_shape = "circle",
    sizes = c(10, 15, 20),
    position = "top-right"
  )

# Test 3: Line patches
map3 <- maplibre() |>
  add_line_layer(
    id = "nc_lines",
    source = nc,
    line_color = "#000000",
    line_width = 2
  ) |>
  add_categorical_legend(
    legend_title = "Line Patches",
    values = c("Highway", "Primary", "Secondary"),
    colors = c("#000000", "navy", "#cccccc"),
    patch_shape = "line",
    position = "bottom-left"
  )

# Test 4: Hexagon patches
map4 <- maplibre() |>
  add_fill_layer(
    id = "nc_fill",
    source = nc,
    fill_color = interpolate(
      column = "BIR74",
      values = c(0, 5000, 10000),
      stops = c("#d9f0a3", "#78c679", "#238443")
    )
  ) |>
  add_categorical_legend(
    legend_title = "Hexagon Patches",
    values = c("Urban", "Suburban", "Rural"),
    colors = c("#d9f0a3", "#78c679", "#238443"),
    patch_shape = "hexagon",
    sizes = c(15, 20, 25),  # Different sizes to show scaling
    position = "bottom-right",
    style = legend_style(
      element_border_color = "black",
      element_border_width = 1,
      background_opacity = 0.8,
      title_color = "darkgreen",
      title_font_weight = "bold"
    )
  )

# Test 5: Mixed patches with element borders
map5 <- maplibre() |>
  add_fill_layer(
    id = "nc_fill",
    source = nc,
    fill_color = "#e5f5f9"
  ) |>
  add_categorical_legend(
    legend_title = "All Shapes with Borders",
    values = c("Square", "Circle", "Line", "Hexagon"),
    colors = c("#a50f15", "#de2d26", "#fb6a4a", "#fcae91"),
    patch_shape = "square",
    position = "top-left",
    style = legend_style(
      element_border_color = "black",
      element_border_width = 2,
      background_opacity = 0.9,
      title_color = "darkblue",
      title_font_weight = "bold"
    )
  ) |>
  add_categorical_legend(
    legend_title = "Circle",
    values = c("A", "B", "C"),
    colors = c("#08519c", "#3182bd", "#6baed6"),
    patch_shape = "circle",
    position = "top-right",
    add = TRUE,
    style = legend_style(
      element_border_color = "white",
      element_border_width = 1
    )
  ) |>
  add_categorical_legend(
    legend_title = "Line",
    values = c("Type 1", "Type 2"),
    colors = c("#000000", "#cccccc"),
    patch_shape = "line",
    position = "bottom-left",
    add = TRUE
  ) |>
  add_categorical_legend(
    legend_title = "Hexagon",
    values = c("H3 Cell 1", "H3 Cell 2"),
    colors = c("#238b45", "#74c476"),
    patch_shape = "hexagon",
    position = "bottom-right",
    add = TRUE,
    style = legend_style(
      element_border_color = "navy",
      element_border_width = 1
    )
  )

# Test 6: Deprecation warning
map6 <- maplibre() |>
  add_categorical_legend(
    legend_title = "Testing Deprecation",
    values = c("A", "B"),
    colors = c("red", "blue"),
    circular_patches = TRUE  # Should trigger warning
  )

# Print each map to view
map1
map2
map3
map4
map5
map6
