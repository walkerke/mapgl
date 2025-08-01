# Simple test for centroid functions
library(mapgl)
library(sf)

# Create one simple polygon
simple_coords <- rbind(
  c(-74.05, 40.70),
  c(-74.05, 40.72),
  c(-74.03, 40.72),
  c(-74.03, 40.70),
  c(-74.05, 40.70)
)

simple_polygon <- st_polygon(list(simple_coords))
simple_sf <- st_sfc(simple_polygon, crs = 4326) |> 
  st_as_sf() |> 
  mutate(name = "Test Polygon")

cat("Testing simple centroid calculation...\n")

# Test turf_center_of_mass with minimal setup
test_map <- maplibre(
  style = carto_style("positron"),
  center = c(-74.04, 40.71),
  zoom = 12
) |>
  add_fill_layer(
    id = "simple_polygon",
    source = simple_sf,
    fill_color = "blue",
    fill_opacity = 0.5
  ) |>
  turf_center_of_mass(
    data = simple_sf,
    source_id = "centroid_result"
  ) |>
  add_circle_layer(
    id = "centroid_point",
    source = "centroid_result",
    circle_color = "red",
    circle_radius = 10
  )

print("Simple test completed")
test_map