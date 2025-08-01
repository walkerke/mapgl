# Test turf_voronoi with property parameter  
library(mapgl)
library(sf)

# Create test points with attributes
facilities <- data.frame(
  lng = c(-74.0, -74.1, -73.9, -74.05, -73.95),
  lat = c(40.7, 40.8, 40.75, 40.72, 40.78),
  facility_name = c("Hospital A", "School B", "Fire Station C", "Library D", "Park E"),
  type = c("medical", "education", "emergency", "education", "recreation"),
  capacity = c(200, 500, 50, 100, 1000)
)

facilities_sf <- st_as_sf(facilities, coords = c("lng", "lat"), crs = 4326)

# Test 1: Voronoi with property parameter to transfer facility_name
cat("Testing turf_voronoi with property = 'facility_name'...\n")

map_tagged <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.75),
  zoom = 10
) |>
  add_circle_layer(
    id = "facilities",
    source = facilities_sf,
    circle_color = "red",
    circle_radius = 8
  ) |>
  turf_voronoi(
    data = facilities_sf,
    property = "facility_name",  # This should transfer facility_name to polygons
    source_id = "voronoi_tagged"
  ) |>
  add_line_layer(
    id = "voronoi_lines",
    source = "voronoi_tagged",
    line_color = "blue",
    line_width = 2
  ) |>
  add_fill_layer(
    id = "voronoi_fill",
    source = "voronoi_tagged",
    fill_color = "blue",
    fill_opacity = 0.1
  )

print("Map created with tagged Voronoi polygons")
print("Check browser console and inspect 'voronoi_tagged' source for facility_name properties")

# Display the map
map_tagged

# Test 2: Voronoi with property parameter to transfer type
cat("\nTesting turf_voronoi with property = 'type'...\n")

map_tagged_type <- maplibre(
  style = carto_style("positron"),  
  center = c(-74.0, 40.75),
  zoom = 10
) |>
  add_circle_layer(
    id = "facilities2",
    source = facilities_sf,
    circle_color = "green",
    circle_radius = 8
  ) |>
  turf_voronoi(
    data = facilities_sf,
    property = "type",  # This should transfer type to polygons
    source_id = "voronoi_by_type"
  ) |>
  add_line_layer(
    id = "voronoi_type_lines",
    source = "voronoi_by_type", 
    line_color = "green",
    line_width = 2
  )

print("Second map created with type-tagged Voronoi polygons")
map_tagged_type