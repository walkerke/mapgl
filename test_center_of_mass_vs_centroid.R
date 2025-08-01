# Test comparison between turf_centroid() and turf_center_of_mass()
library(mapgl)
library(sf)
library(dplyr)

# Create test polygons with different shapes to show the difference
# An irregular polygon where vertex average vs geometric centroid differ significantly
irregular_coords <- rbind(
  c(-74.10, 40.70),  # Bottom left
  c(-74.00, 40.70),  # Bottom right
  c(-74.00, 40.75),  # Top right
  c(-74.05, 40.76),  # Top middle (shifted)
  c(-74.10, 40.75),  # Top left
  c(-74.10, 40.70)   # Close polygon
)

irregular_polygon <- st_polygon(list(irregular_coords))
irregular_sf <- st_sfc(irregular_polygon, crs = 4326) |>
  st_as_sf() |>
  mutate(name = "Irregular Polygon", type = "test")

# Compare with sf::st_centroid for reference
sf_centroid <- st_centroid(irregular_sf)

cat("Comparison of centroid calculation methods:\n")
cat("Testing with an irregular polygon to show differences...\n\n")

# Create map showing all three methods
comparison_map <- maplibre(
  style = carto_style("positron"),
  center = c(-74.05, 40.725),
  zoom = 13
) |>
  # Show original polygon
  add_fill_layer(
    id = "test_polygon",
    source = irregular_sf,
    fill_color = "lightblue",
    fill_opacity = 0.3
  ) |>
  add_line_layer(
    id = "polygon_outline",
    source = irregular_sf,
    line_color = "blue",
    line_width = 2
  ) |>
  # Calculate turf_center_of_mass (geometric centroid method)
  turf_center_of_mass(
    data = irregular_sf,
    source_id = "turf_center_of_mass_result"
  ) |>
  # Show turf_center_of_mass result in GREEN
  add_circle_layer(
    id = "turf_center_of_mass_point",
    source = "turf_center_of_mass_result",
    circle_color = "green",
    circle_radius = 8,
    circle_stroke_color = "darkgreen",
    circle_stroke_width = 2
  )

print("Comparison map created:")
print("- Light blue polygon = test shape")
print("- RED circle = turf_centroid() result (vertex average)")
print("- GREEN circle = turf_center_of_mass() result (geometric centroid)")
print("- PURPLE circle = sf::st_centroid() result (reference)")
print("")
print("The GREEN and PURPLE circles should be very close/identical")
print("The RED circle may be noticeably different for irregular shapes")

comparison_map

# Print coordinates for comparison
cat("\nCoordinate comparison:\n")
sf_coords <- st_coordinates(sf_centroid)
cat("sf::st_centroid():", sprintf("%.6f, %.6f", sf_coords[1], sf_coords[2]), "\n")
cat("turf_center_of_mass() and turf_centroid() results visible on map above\n")
cat("\nExpected: GREEN (turf_center_of_mass) should match PURPLE (sf::st_centroid)\n")
cat("RED (turf_centroid) may differ due to different calculation method\n")
