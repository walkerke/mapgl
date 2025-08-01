# Test turf_centroid() with multiple polygons and attributes
library(mapgl)
library(sf)

# Create test polygons with attributes
polygons_data <- list(
  # Polygon 1: Rectangle
  list(
    coords = rbind(c(-74.05, 40.70), c(-74.05, 40.72), c(-74.03, 40.72), c(-74.03, 40.70), c(-74.05, 40.70)),
    name = "Building A",
    type = "commercial",
    area_sqft = 5000
  ),
  # Polygon 2: Triangle  
  list(
    coords = rbind(c(-74.01, 40.73), c(-74.01, 40.75), c(-73.99, 40.74), c(-74.01, 40.73)),
    name = "Park B", 
    type = "recreation",
    area_sqft = 2500
  ),
  # Polygon 3: Pentagon
  list(
    coords = rbind(c(-73.97, 40.71), c(-73.97, 40.73), c(-73.95, 40.73), c(-73.94, 40.71), c(-73.96, 40.70), c(-73.97, 40.71)),
    name = "School C",
    type = "education", 
    area_sqft = 8000
  )
)

# Convert to sf polygons
polygons_list <- list()
attributes_df <- data.frame(
  name = character(),
  type = character(), 
  area_sqft = numeric(),
  stringsAsFactors = FALSE
)

for (i in seq_along(polygons_data)) {
  poly_data <- polygons_data[[i]]
  polygon <- st_polygon(list(poly_data$coords))
  polygons_list[[i]] <- polygon
  
  attributes_df[i, ] <- list(
    name = poly_data$name,
    type = poly_data$type,
    area_sqft = poly_data$area_sqft
  )
}

polygons_sf <- st_sfc(polygons_list, crs = 4326) |>
  st_as_sf() |>
  cbind(attributes_df)

cat("Created", nrow(polygons_sf), "test polygons with attributes:\n")
print(polygons_sf)

# Test: Get centroids with attributes preserved
cat("\nTesting turf_centroid() with multiple attributed polygons...\n")

map_centroids <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.72),
  zoom = 12
) |>
  # Show original polygons
  add_fill_layer(
    id = "original_polygons",
    source = polygons_sf,
    fill_color = "lightblue",
    fill_opacity = 0.5
  ) |>
  add_line_layer(
    id = "polygon_outlines", 
    source = polygons_sf,
    line_color = "blue",
    line_width = 2
  ) |>
  # Calculate centroids
  turf_centroid(
    data = polygons_sf,
    source_id = "polygon_centroids"
  ) |>
  # Show centroids
  add_circle_layer(
    id = "centroid_points",
    source = "polygon_centroids",
    circle_color = "red",
    circle_radius = 8,
    circle_stroke_color = "darkred",
    circle_stroke_width = 2
  )

print("Map created with polygons and their individual centroids")
print("Each centroid should preserve attributes (name, type, area_sqft) from its polygon")
print("Check browser console and inspect 'polygon_centroids' source for preserved attributes")

# Display the map
map_centroids

# Test comparison with sf::st_centroid() for validation
cat("\nComparison with sf::st_centroid():\n")
sf_centroids <- st_centroid(polygons_sf)
cat("sf::st_centroid() returns", nrow(sf_centroids), "centroids\n")
cat("turf_centroid() should also return", nrow(polygons_sf), "centroids\n")
print("sf centroids attributes:")
print(sf_centroids[c("name", "type", "area_sqft")])