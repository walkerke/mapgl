# ====================================================================
# TURF.JS TESTING SUITE FOR MAPGL
# ====================================================================
# This file systematically tests all turf functions in non-Shiny mode
# We test each function with all supported input types:
# 1. layer_id (reference to existing map layer)
# 2. data (sf object)
# 3. coordinates (numeric vector or matrix)
# ====================================================================

library(mapgl)
library(sf)

# ====================================================================
# TEST DATA SETUP
# ====================================================================

# Create test point
test_point <- st_sf(
  id = 1,
  name = "Test Point",
  geometry = st_sfc(st_point(c(-74.006, 40.7128)), crs = 4326)
)

# Create test polygon (small square around NYC)
test_polygon <- st_sf(
  id = 1,
  name = "Test Polygon",
  geometry = st_sfc(
    st_polygon(list(
      cbind(
        c(-74.1, -74.1, -73.9, -73.9, -74.1),
        c(40.6, 40.8, 40.8, 40.6, 40.6)
      )
    )),
    crs = 4326
  )
)

# Test coordinates
test_coords <- c(-74.006, 40.7128)

# ====================================================================
# PART 1: TESTING turf_buffer()
# ====================================================================

cat("========================================\n")
cat("TESTING: turf_buffer()\n")
cat("========================================\n\n")

# --------------------------------------------------------------------
# Test 1.1: Buffer with layer_id
# --------------------------------------------------------------------
cat("Test 1.1: Buffer with layer_id\n")
cat("Creating map with point layer, then buffering it...\n\n")

map1 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.006, 40.7128),
  zoom = 10
) |>
  # Add point as a source and layer
  add_source(id = "test_point_source", data = test_point) |>
  add_circle_layer(
    id = "test_point_layer",
    source = "test_point_source",
    circle_color = "red",
    circle_radius = 8
  ) |>
  # Buffer the layer
  turf_buffer(
    layer_id = "test_point_source",  # Reference the source, not the layer
    radius = 5,
    units = "kilometers",
    source_id = "buffer_from_layer"
  ) |>
  # Visualize the buffer
  add_fill_layer(
    id = "buffer_layer_1",
    source = "buffer_from_layer",
    fill_color = "blue",
    fill_opacity = 0.3
  )

print("Map 1 created: Buffer from layer_id")
# Uncomment to display: map1

# --------------------------------------------------------------------
# Test 1.2: Buffer with data (sf object)
# --------------------------------------------------------------------
cat("\nTest 1.2: Buffer with data (sf object)\n")
cat("Creating map and buffering an sf object directly...\n\n")

map2 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.006, 40.7128),
  zoom = 10
) |>
  # Buffer sf object directly (no need to add as source first)
  turf_buffer(
    data = test_point,
    radius = 3,
    units = "kilometers",
    source_id = "buffer_from_sf"
  ) |>
  # Visualize the buffer
  add_fill_layer(
    id = "buffer_layer_2",
    source = "buffer_from_sf",
    fill_color = "green",
    fill_opacity = 0.3
  )

print("Map 2 created: Buffer from sf object")
# Uncomment to display: map2

# --------------------------------------------------------------------
# Test 1.3: Buffer with coordinates
# --------------------------------------------------------------------
cat("\nTest 1.3: Buffer with coordinates\n")
cat("Creating map and buffering from coordinates...\n\n")

map3 <- maplibre(
  style = carto_style("positron"),
  center = test_coords,
  zoom = 10
) |>
  # Buffer coordinates directly (creates point internally)
  turf_buffer(
    coordinates = test_coords,
    radius = 2,
    units = "kilometers",
    source_id = "buffer_from_coords"
  ) |>
  # Visualize the buffer
  add_fill_layer(
    id = "buffer_layer_3",
    source = "buffer_from_coords",
    fill_color = "purple",
    fill_opacity = 0.3
  )

print("Map 3 created: Buffer from coordinates")
# Uncomment to display: map3

# --------------------------------------------------------------------
# Test 1.4: Multiple buffers on same map
# --------------------------------------------------------------------
cat("\nTest 1.4: Multiple buffers on same map\n")
cat("Creating map with multiple buffer operations...\n\n")

map4 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.006, 40.7128),
  zoom = 9
) |>
  # First buffer - from coordinates
  turf_buffer(
    coordinates = c(-74.006, 40.7128),
    radius = 5,
    units = "kilometers",
    source_id = "buffer_1"
  ) |>
  # Second buffer - from different coordinates
  turf_buffer(
    coordinates = c(-73.95, 40.75),
    radius = 3,
    units = "kilometers",
    source_id = "buffer_2"
  ) |>
  # Add layers for both buffers
  add_fill_layer(
    id = "buffer_layer_4a",
    source = "buffer_1",
    fill_color = "red",
    fill_opacity = 0.3
  ) |>
  add_fill_layer(
    id = "buffer_layer_4b",
    source = "buffer_2",
    fill_color = "blue",
    fill_opacity = 0.3
  )

print("Map 4 created: Multiple buffers")
# Uncomment to display: map4

cat("\n========================================\n")
cat("TURF_BUFFER TESTS COMPLETE\n")
cat("========================================\n")
cat("\nTo test each map, uncomment the map variable at the end of each test\n")
cat("Check that:\n")
cat("1. Buffers appear at the correct locations\n")
cat("2. Buffer sizes match the specified radius\n")
cat("3. All three input methods work correctly\n")
cat("\nOnce verified, we can proceed to test the next function.\n")

# ====================================================================
# PART 2: TESTING turf_union()
# ====================================================================

cat("\n\n========================================\n")
cat("TESTING: turf_union()\n")
cat("========================================\n\n")

# Create test data for union operations
# Multiple overlapping polygons
union_polys <- st_sf(
  id = 1:3,
  name = c("Poly A", "Poly B", "Poly C"),
  geometry = st_sfc(
    # Polygon A (left)
    st_polygon(list(cbind(
      c(-74.05, -74.05, -74.01, -74.01, -74.05),
      c(40.70, 40.74, 40.74, 40.70, 40.70)
    ))),
    # Polygon B (right, overlapping with A)
    st_polygon(list(cbind(
      c(-74.03, -74.03, -73.99, -73.99, -74.03),
      c(40.71, 40.75, 40.75, 40.71, 40.71)
    ))),
    # Polygon C (bottom, overlapping with both)
    st_polygon(list(cbind(
      c(-74.04, -74.04, -74.00, -74.00, -74.04),
      c(40.69, 40.73, 40.73, 40.69, 40.69)
    ))),
    crs = 4326
  )
)

# --------------------------------------------------------------------
# Test 2.1: Union with layer_id
# --------------------------------------------------------------------
cat("Test 2.1: Union with layer_id\n")
cat("Creating map with multiple polygons, then unioning them...\n\n")

map5 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 12
) |>
  # Add polygons as a source and layer
  add_source(id = "union_polys_source", data = union_polys) |>
  add_fill_layer(
    id = "union_polys_layer",
    source = "union_polys_source",
    fill_color = "red",
    fill_opacity = 0.3,
    fill_outline_color = "red"
  ) |>
  # Union all polygons in the layer
  turf_union(
    layer_id = "union_polys_source",
    source_id = "unioned_from_layer"
  ) |>
  # Visualize the union result
  add_fill_layer(
    id = "union_result_1",
    source = "unioned_from_layer",
    fill_color = "blue",
    fill_opacity = 0.5,
    fill_outline_color = "darkblue"
  )

print("Map 5 created: Union from layer_id")
print("You should see overlapping red polygons and their blue union")
# Uncomment to display: map5

# --------------------------------------------------------------------
# Test 2.2: Union with data (sf object)
# --------------------------------------------------------------------
cat("\nTest 2.2: Union with data (sf object)\n")
cat("Creating map and unioning sf object directly...\n\n")

map6 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 12
) |>
  # Show original polygons for reference
  add_source(id = "original_polys", data = union_polys) |>
  add_fill_layer(
    id = "original_layer",
    source = "original_polys",
    fill_color = "green",
    fill_opacity = 0.2,
    fill_outline_color = "darkgreen"
  ) |>
  # Union sf object directly
  turf_union(
    data = union_polys,
    source_id = "unioned_from_sf"
  ) |>
  # Visualize the union result
  add_fill_layer(
    id = "union_result_2",
    source = "unioned_from_sf",
    fill_color = "purple",
    fill_opacity = 0.5,
    fill_outline_color = "purple"
  )

print("Map 6 created: Union from sf object")
print("Green = original polygons, Purple = union result")
# Uncomment to display: map6

# --------------------------------------------------------------------
# Test 2.3: Union single polygon (edge case)
# --------------------------------------------------------------------
cat("\nTest 2.3: Union single polygon (edge case)\n")
cat("Testing union operation on single polygon...\n\n")

single_poly <- union_polys[1,]  # Just the first polygon

map7 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.03, 40.72),
  zoom = 13
) |>
  # Union single polygon (should return the same polygon)
  turf_union(
    data = single_poly,
    source_id = "single_union"
  ) |>
  # Visualize the result
  add_fill_layer(
    id = "single_union_layer",
    source = "single_union",
    fill_color = "orange",
    fill_opacity = 0.5
  )

print("Map 7 created: Union of single polygon")
print("Should show single orange polygon (unchanged)")
# Uncomment to display: map7

# --------------------------------------------------------------------
# Test 2.4: Complex union with North Carolina counties
# --------------------------------------------------------------------
cat("\nTest 2.4: Complex union with NC counties\n")
cat("Testing union on more complex real-world data...\n\n")

# Load NC counties and select a few adjacent ones
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
selected_counties <- nc[nc$NAME %in% c("Wake", "Durham", "Orange", "Chatham"), ]

# Get center of selected counties
counties_center <- st_bbox(selected_counties) |>
  st_as_sfc() |>
  st_centroid() |>
  st_coordinates()

map8 <- maplibre(
  style = carto_style("positron"),
  center = c(counties_center[1], counties_center[2]),
  zoom = 8
) |>
  # Show original counties
  add_source(id = "counties", data = selected_counties) |>
  add_fill_layer(
    id = "counties_layer",
    source = "counties",
    fill_color = "brown",
    fill_opacity = 0.2,
    fill_outline_color = "brown"
  ) |>
  # Union the counties
  turf_union(
    data = selected_counties,
    source_id = "unioned_counties"
  ) |>
  # Show union result
  add_fill_layer(
    id = "union_counties_result",
    source = "unioned_counties",
    fill_color = "navy",
    fill_opacity = 0.4,
    fill_outline_color = "darkblue"
  )

print("Map 8 created: Union of NC counties")
print("Brown = individual counties, Navy = unioned region")
# Uncomment to display: map8

cat("\n========================================\n")
cat("TURF_UNION TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Union correctly merges overlapping polygons\n")
cat("2. Single polygon union returns the same polygon\n")
cat("3. Complex unions (NC counties) work properly\n")
cat("4. Both layer_id and data inputs work\n")

# ====================================================================
# PART 3: TESTING turf_intersect()
# ====================================================================
library(mapgl)
cat("\n\n========================================\n")
cat("TESTING: turf_intersect()\n")
cat("========================================\n\n")

# Create overlapping test polygons for intersection
intersect_poly1 <- st_sf(
  id = 1,
  name = "Left Polygon",
  geometry = st_sfc(
    st_polygon(list(cbind(
      c(-74.05, -74.05, -74.01, -74.01, -74.05),
      c(40.70, 40.74, 40.74, 40.70, 40.70)
    ))),
    crs = 4326
  )
)

intersect_poly2 <- st_sf(
  id = 2,
  name = "Right Polygon",
  geometry = st_sfc(
    st_polygon(list(cbind(
      c(-74.03, -74.03, -73.99, -73.99, -74.03),
      c(40.71, 40.75, 40.75, 40.71, 40.71)
    ))),
    crs = 4326
  )
)

# Non-overlapping polygons for testing no intersection
no_overlap_poly <- st_sf(
  id = 3,
  name = "Far Polygon",
  geometry = st_sfc(
    st_polygon(list(cbind(
      c(-73.95, -73.95, -73.91, -73.91, -73.95),
      c(40.65, 40.69, 40.69, 40.65, 40.65)
    ))),
    crs = 4326
  )
)

# --------------------------------------------------------------------
# Test 3.1: Intersect with layer_id (overlapping polygons)
# --------------------------------------------------------------------
cat("Test 3.1: Intersect with layer_id (overlapping polygons)\n")
cat("Creating map with two overlapping polygons and finding intersection...\n\n")

map9 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 12
) |>
  # Add first polygon
  add_source(id = "poly1_source", data = intersect_poly1) |>
  add_fill_layer(
    id = "poly1_layer",
    source = "poly1_source",
    fill_color = "red",
    fill_opacity = 0.3,
    fill_outline_color = "darkred"
  ) |>
  # Add second polygon
  add_source(id = "poly2_source", data = intersect_poly2) |>
  add_fill_layer(
    id = "poly2_layer",
    source = "poly2_source",
    fill_color = "blue",
    fill_opacity = 0.3,
    fill_outline_color = "darkblue"
  ) |>
  # Find intersection
  turf_intersect(
    layer_id = "poly1_source",      # First polygon source
    layer_id_2 = "poly2_source",    # Second polygon source
    source_id = "intersection_result"
  ) |>
  # Show intersection result
  add_fill_layer(
    id = "intersection_layer",
    source = "intersection_result",
    fill_color = "purple",
    fill_opacity = 0.8,
    fill_outline_color = "black"
  )

print("Map 9 created: Intersection from layer_id")
print("Red + Blue polygons, Purple = intersection area")
# Uncomment to display: map9

# --------------------------------------------------------------------
# Test 3.2: Intersect with data (sf objects)
# --------------------------------------------------------------------
cat("\nTest 3.2: Intersect with data (sf objects)\n")
cat("Using sf objects directly for intersection...\n\n")

map10 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 12
) |>
  # Show original polygons for reference
  add_source(id = "ref_poly1", data = intersect_poly1) |>
  add_fill_layer(
    id = "ref_layer1",
    source = "ref_poly1",
    fill_color = "green",
    fill_opacity = 0.2,
    fill_outline_color = "darkgreen"
  ) |>
  add_source(id = "ref_poly2", data = intersect_poly2) |>
  add_fill_layer(
    id = "ref_layer2",
    source = "ref_poly2",
    fill_color = "orange",
    fill_opacity = 0.2,
    fill_outline_color = "darkorange"
  ) |>
  # Intersect using sf data directly
  turf_intersect(
    data = intersect_poly1,               # First polygon as sf object
    layer_id_2 = "ref_poly2",            # Second polygon as layer reference
    source_id = "intersection_from_data"
  ) |>
  # Show intersection
  add_fill_layer(
    id = "intersection_data_layer",
    source = "intersection_from_data",
    fill_color = "navy",
    fill_opacity = 0.8
  )

print("Map 10 created: Intersection mixing data and layer_id")
print("Green + Orange polygons, Navy = intersection")
# Uncomment to display: map10

# --------------------------------------------------------------------
# Test 3.3: No intersection case
# --------------------------------------------------------------------
cat("\nTest 3.3: No intersection case\n")
cat("Testing with non-overlapping polygons...\n\n")

map11 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.70),
  zoom = 11
) |>
  # Add first polygon
  add_source(id = "poly_a", data = intersect_poly1) |>
  add_fill_layer(
    id = "poly_a_layer",
    source = "poly_a",
    fill_color = "red",
    fill_opacity = 0.5
  ) |>
  # Add non-overlapping polygon
  add_source(id = "poly_far", data = no_overlap_poly) |>
  add_fill_layer(
    id = "poly_far_layer",
    source = "poly_far",
    fill_color = "blue",
    fill_opacity = 0.5
  ) |>
  # Try to intersect (should result in empty)
  turf_intersect(
    layer_id = "poly_a",
    layer_id_2 = "poly_far",
    source_id = "no_intersection"
  ) |>
  # This layer should be empty/invisible
  add_fill_layer(
    id = "no_intersection_layer",
    source = "no_intersection",
    fill_color = "yellow",
    fill_opacity = 0.8
  )

print("Map 11 created: No intersection case")
print("Should see red and blue polygons with no yellow intersection")
# Uncomment to display: map11

# --------------------------------------------------------------------
# Test 3.4: Complex intersection with buffered points
# --------------------------------------------------------------------
cat("\nTest 3.4: Complex intersection with buffered points\n")
cat("Creating buffers and finding their intersection...\n\n")

# Create two points for buffering
point1 <- st_sf(geometry = st_sfc(st_point(c(-74.02, 40.72)), crs = 4326))
point2 <- st_sf(geometry = st_sfc(st_point(c(-74.015, 40.718)), crs = 4326))

map12 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 13
) |>
  # Create first buffer
  turf_buffer(
    data = point1,
    radius = 2,
    units = "kilometers",
    source_id = "buffer_1"
  ) |>
  # Create second buffer
  turf_buffer(
    data = point2,
    radius = 1.5,
    units = "kilometers",
    source_id = "buffer_2"
  ) |>
  # Show buffers
  add_fill_layer(
    id = "buffer_1_layer",
    source = "buffer_1",
    fill_color = "red",
    fill_opacity = 0.3
  ) |>
  add_fill_layer(
    id = "buffer_2_layer",
    source = "buffer_2",
    fill_color = "blue",
    fill_opacity = 0.3
  ) |>
  # Find intersection of the two buffers
  turf_intersect(
    layer_id = "buffer_1",
    layer_id_2 = "buffer_2",
    source_id = "buffer_intersection"
  ) |>
  # Show intersection
  add_fill_layer(
    id = "buffer_intersection_layer",
    source = "buffer_intersection",
    fill_color = "green",
    fill_opacity = 0.8
  ) |>
  add_layers_control()

print("Map 12 created: Buffer intersection")
print("Red + Blue buffers, Green = intersection area")
# Uncomment to display: map12

cat("\n========================================\n")
cat("TURF_INTERSECT TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Overlapping polygons show correct intersection area\n")
cat("2. Non-overlapping polygons show no intersection\n")
cat("3. Both layer_id and data inputs work\n")
cat("4. Complex intersections (buffers) work correctly\n")

# ====================================================================
# PART 4: TESTING turf_difference()
# ====================================================================

cat("\n\n========================================\n")
cat("TESTING: turf_difference()\n")
cat("========================================\n\n")

# --------------------------------------------------------------------
# Test 4.1: Difference with layer_id (overlapping polygons)
# --------------------------------------------------------------------
cat("Test 4.1: Difference with layer_id (overlapping polygons)\n")
cat("Creating map with two overlapping polygons and subtracting second from first...\n\n")

map13 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 12
) |>
  # Add first polygon
  add_source(id = "diff_poly1", data = intersect_poly1) |>
  add_fill_layer(
    id = "diff_poly1_layer",
    source = "diff_poly1",
    fill_color = "red",
    fill_opacity = 0.3,
    fill_outline_color = "darkred"
  ) |>
  # Add second polygon
  add_source(id = "diff_poly2", data = intersect_poly2) |>
  add_fill_layer(
    id = "diff_poly2_layer",
    source = "diff_poly2",
    fill_color = "blue",
    fill_opacity = 0.3,
    fill_outline_color = "darkblue"
  ) |>
  # Calculate difference (poly1 minus poly2)
  turf_difference(
    layer_id = "diff_poly1",      # Polygon to subtract from
    layer_id_2 = "diff_poly2",    # Polygon to subtract
    source_id = "difference_result"
  ) |>
  # Show difference result
  add_fill_layer(
    id = "difference_layer",
    source = "difference_result",
    fill_color = "purple",
    fill_opacity = 0.8,
    fill_outline_color = "black"
  )

print("Map 13 created: Difference from layer_id")
print("Red polygon minus Blue polygon = Purple result")
# Uncomment to display: map13

# --------------------------------------------------------------------
# Test 4.2: Difference with data (sf objects)
# --------------------------------------------------------------------
cat("\nTest 4.2: Difference with data (sf objects)\n")
cat("Using sf objects directly for difference...\n\n")

map14 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 12
) |>
  # Show original polygons for reference
  add_source(id = "diff_ref1", data = intersect_poly1) |>
  add_fill_layer(
    id = "diff_ref1_layer",
    source = "diff_ref1",
    fill_color = "green",
    fill_opacity = 0.2,
    fill_outline_color = "darkgreen"
  ) |>
  add_source(id = "diff_ref2", data = intersect_poly2) |>
  add_fill_layer(
    id = "diff_ref2_layer",
    source = "diff_ref2",
    fill_color = "orange",
    fill_opacity = 0.2,
    fill_outline_color = "darkorange"
  ) |>
  # Difference using sf data directly
  turf_difference(
    data = intersect_poly1,               # First polygon as sf object
    layer_id_2 = "diff_ref2",            # Second polygon as layer reference
    source_id = "difference_from_data"
  ) |>
  # Show difference
  add_fill_layer(
    id = "difference_data_layer",
    source = "difference_from_data",
    fill_color = "navy",
    fill_opacity = 0.8
  )

print("Map 14 created: Difference mixing data and layer_id")
print("Green polygon minus Orange polygon = Navy result")
# Uncomment to display: map14

# --------------------------------------------------------------------
# Test 4.3: Difference creating holes (buffer minus point buffer)
# --------------------------------------------------------------------
cat("\nTest 4.3: Difference creating holes\n")
cat("Creating a donut shape by subtracting small buffer from large buffer...\n\n")

# Create center point
center_point <- st_sf(geometry = st_sfc(st_point(c(-74.02, 40.72)), crs = 4326))

map15 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.72),
  zoom = 13
) |>
  # Create large buffer
  turf_buffer(
    data = center_point,
    radius = 3,
    units = "kilometers",
    source_id = "large_buffer"
  ) |>
  # Create small buffer
  turf_buffer(
    data = center_point,
    radius = 1,
    units = "kilometers",
    source_id = "small_buffer"
  ) |>
  # Show original buffers
  add_fill_layer(
    id = "large_buffer_layer",
    source = "large_buffer",
    fill_color = "red",
    fill_opacity = 0.2
  ) |>
  add_fill_layer(
    id = "small_buffer_layer",
    source = "small_buffer",
    fill_color = "blue",
    fill_opacity = 0.3
  ) |>
  # Create donut (large minus small)
  turf_difference(
    layer_id = "large_buffer",
    layer_id_2 = "small_buffer",
    source_id = "donut_shape"
  ) |>
  # Show donut
  add_fill_layer(
    id = "donut_layer",
    source = "donut_shape",
    fill_color = "green",
    fill_opacity = 0.8
  )

print("Map 15 created: Donut shape via difference")
print("Large red buffer minus small blue buffer = Green donut")
# Uncomment to display: map15

# --------------------------------------------------------------------
# Test 4.4: No difference case (non-overlapping)
# --------------------------------------------------------------------
cat("\nTest 4.4: No difference case (non-overlapping)\n")
cat("Testing difference with non-overlapping polygons...\n\n")

map16 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.70),
  zoom = 11
) |>
  # Add first polygon
  add_source(id = "diff_poly_a", data = intersect_poly1) |>
  add_fill_layer(
    id = "diff_poly_a_layer",
    source = "diff_poly_a",
    fill_color = "red",
    fill_opacity = 0.5
  ) |>
  # Add non-overlapping polygon
  add_source(id = "diff_poly_far", data = no_overlap_poly) |>
  add_fill_layer(
    id = "diff_poly_far_layer",
    source = "diff_poly_far",
    fill_color = "blue",
    fill_opacity = 0.5
  ) |>
  # Try difference (should result in original first polygon)
  turf_difference(
    layer_id = "diff_poly_a",
    layer_id_2 = "diff_poly_far",
    source_id = "no_difference"
  ) |>
  # Show result (should look like original red polygon)
  add_fill_layer(
    id = "no_difference_layer",
    source = "no_difference",
    fill_color = "yellow",
    fill_opacity = 0.8
  )

print("Map 16 created: No overlap difference case")
print("Yellow result should match red polygon (no subtraction occurred)")
# Uncomment to display: map16

# --------------------------------------------------------------------
# Test 4.5: Complex difference with NC counties
# --------------------------------------------------------------------
cat("\nTest 4.5: Complex difference with NC counties\n")
cat("Subtracting one county from a group of counties...\n\n")

# Get a few counties including Wake
wake_and_neighbors <- nc[nc$NAME %in% c("Wake", "Durham", "Orange"), ]
wake_only <- nc[nc$NAME == "Wake", ]

counties_center2 <- st_bbox(wake_and_neighbors) |>
  st_as_sfc() |>
  st_centroid() |>
  st_coordinates()

map17 <- maplibre(
  style = carto_style("positron"),
  center = c(counties_center2[1], counties_center2[2]),
  zoom = 9
) |>
  # Show original counties
  add_source(id = "counties_group", data = wake_and_neighbors) |>
  add_fill_layer(
    id = "counties_group_layer",
    source = "counties_group",
    fill_color = "brown",
    fill_opacity = 0.2,
    fill_outline_color = "darkbrown"
  ) |>
  add_source(id = "wake_county", data = wake_only) |>
  add_fill_layer(
    id = "wake_county_layer",
    source = "wake_county",
    fill_color = "red",
    fill_opacity = 0.3,
    fill_outline_color = "darkred"
  ) |>
  # Union the group first, then subtract Wake
  turf_union(
    data = wake_and_neighbors,
    source_id = "counties_union"
  ) |>
  turf_difference(
    layer_id = "counties_union",
    layer_id_2 = "wake_county",
    source_id = "counties_minus_wake"
  ) |>
  # Show result
  add_fill_layer(
    id = "result_counties",
    source = "counties_minus_wake",
    fill_color = "navy",
    fill_opacity = 0.6
  )

print("Map 17 created: Counties minus Wake County")
print("Brown = all counties, Red = Wake, Navy = result (Durham + Orange)")
# Uncomment to display: map17

cat("\n========================================\n")
cat("TURF_DIFFERENCE TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Overlapping polygons show correct difference area\n")
cat("2. Non-overlapping polygons show original first polygon\n")
cat("3. Both layer_id and data inputs work\n")
cat("4. Complex differences (donut shapes, counties) work correctly\n")
cat("5. Difference creates holes when appropriate\n")

# ====================================================================
# PART 5: TESTING turf_convex_hull()
# ====================================================================

cat("\n\n========================================\n")
cat("TESTING: turf_convex_hull()\n")
cat("========================================\n\n")

# Create scattered points for hull operations
scattered_points <- st_sf(
  id = 1:8,
  name = paste("Point", 1:8),
  geometry = st_sfc(
    st_point(c(-74.05, 40.70)),
    st_point(c(-74.02, 40.73)),
    st_point(c(-73.98, 40.71)),
    st_point(c(-74.01, 40.69)),
    st_point(c(-74.03, 40.72)),
    st_point(c(-73.99, 40.74)),
    st_point(c(-74.04, 40.68)),
    st_point(c(-73.97, 40.70)),
    crs = 4326
  )
)

# R-friendly coordinate list format
hull_coords <- list(
  c(-74.05, 40.70),  # Point 1
  c(-74.02, 40.73),  # Point 2
  c(-73.98, 40.71),  # Point 3
  c(-74.01, 40.69),  # Point 4
  c(-74.03, 40.72),  # Point 5
  c(-73.99, 40.74),  # Point 6
  c(-74.04, 40.68),  # Point 7
  c(-73.97, 40.70)   # Point 8
)

# --------------------------------------------------------------------
# Test 5.1: Convex hull with layer_id
# --------------------------------------------------------------------
cat("Test 5.1: Convex hull with layer_id\n")
cat("Creating map with scattered points and finding convex hull...\n\n")

map18 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.01, 40.71),
  zoom = 13
) |>
  # Add scattered points
  add_source(id = "points_source", data = scattered_points) |>
  add_circle_layer(
    id = "points_layer",
    source = "points_source",
    circle_color = "red",
    circle_radius = 6,
    circle_stroke_color = "darkred",
    circle_stroke_width = 2
  ) |>
  # Calculate convex hull
  turf_convex_hull(
    layer_id = "points_source",
    source_id = "convex_hull_result"
  ) |>
  # Show convex hull
  add_fill_layer(
    id = "convex_hull_layer",
    source = "convex_hull_result",
    fill_color = "blue",
    fill_opacity = 0.3,
    fill_outline_color = "darkblue"
  )

print("Map 18 created: Convex hull from layer_id")
print("Red points with blue convex hull boundary")
# Uncomment to display: map18

# --------------------------------------------------------------------
# Test 5.2: Convex hull with data (sf object)
# --------------------------------------------------------------------
cat("\nTest 5.2: Convex hull with data (sf object)\n")
cat("Using sf object directly for convex hull...\n\n")

map19 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.01, 40.71),
  zoom = 13
) |>
  # Show original points for reference
  add_source(id = "ref_points", data = scattered_points) |>
  add_circle_layer(
    id = "ref_points_layer",
    source = "ref_points",
    circle_color = "green",
    circle_radius = 5
  ) |>
  # Convex hull using sf data directly
  turf_convex_hull(
    data = scattered_points,
    source_id = "hull_from_data"
  ) |>
  # Show hull
  add_fill_layer(
    id = "hull_data_layer",
    source = "hull_from_data",
    fill_color = "purple",
    fill_opacity = 0.4,
    fill_outline_color = "purple"
  )

print("Map 19 created: Convex hull from sf object")
print("Green points with purple convex hull")
# Uncomment to display: map19

# --------------------------------------------------------------------
# Test 5.3: Convex hull with coordinates (R list format)
# --------------------------------------------------------------------
cat("\nTest 5.3: Convex hull with coordinates (R list format)\n")
cat("Using list(c(lng,lat), c(lng,lat), ...) format...\n\n")

map20 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.01, 40.71),
  zoom = 13
) |>
  # Create convex hull from coordinate list
  turf_convex_hull(
    coordinates = hull_coords,
    source_id = "hull_from_coords"
  ) |>
  # Show hull
  add_fill_layer(
    id = "hull_coords_layer",
    source = "hull_from_coords",
    fill_color = "orange",
    fill_opacity = 0.5,
    fill_outline_color = "darkorange"
  )

print("Map 20 created: Convex hull from coordinates")
print("Orange convex hull from R list format coordinates")
print("Coordinates used:")
print(hull_coords)
# Uncomment to display: map20

# --------------------------------------------------------------------
# Test 5.4: Complex convex hull with NC counties centroids
# --------------------------------------------------------------------
cat("\nTest 5.4: Complex convex hull with NC county centroids\n")
cat("Finding convex hull of county centroids...\n\n")

# Get centroids of some NC counties
selected_nc <- nc[1:10, ]  # First 10 counties
county_centroids <- st_centroid(selected_nc)

nc_bbox_center <- st_bbox(county_centroids) |>
  st_as_sfc() |>
  st_centroid() |>
  st_coordinates()

map21 <- maplibre(
  style = carto_style("positron"),
  center = c(nc_bbox_center[1], nc_bbox_center[2]),
  zoom = 7
) |>
  # Show original counties
  add_source(id = "nc_counties", data = selected_nc) |>
  add_fill_layer(
    id = "nc_counties_layer",
    source = "nc_counties",
    fill_color = "lightgray",
    fill_opacity = 0.3,
    fill_outline_color = "gray"
  ) |>
  # Show centroids
  add_source(id = "centroids", data = county_centroids) |>
  add_circle_layer(
    id = "centroids_layer",
    source = "centroids",
    circle_color = "red",
    circle_radius = 5
  ) |>
  # Convex hull of centroids
  turf_convex_hull(
    data = county_centroids,
    source_id = "centroids_hull"
  ) |>
  # Show hull
  add_fill_layer(
    id = "centroids_hull_layer",
    source = "centroids_hull",
    fill_color = "navy",
    fill_opacity = 0.4,
    fill_outline_color = "darkblue"
  )

print("Map 21 created: Convex hull of county centroids")
print("Gray counties, red centroids, navy convex hull")
# Uncomment to display: map21

cat("\n========================================\n")
cat("TURF_CONVEX_HULL TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Convex hull correctly encloses all points\n")
cat("2. All three input types work (layer_id, data, coordinates)\n")
cat("3. R list format coordinates work properly\n")
cat("4. Complex hull operations work correctly\n")

# ====================================================================
# PART 6: TESTING turf_concave_hull()
# ====================================================================

cat("\n\n========================================\n")
cat("TESTING: turf_concave_hull()\n")
cat("========================================\n\n")

# --------------------------------------------------------------------
# Test 6.1: Concave hull with layer_id
# --------------------------------------------------------------------
cat("Test 6.1: Concave hull with layer_id\n")
cat("Creating concave hull that follows point distribution more closely...\n\n")

map22 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.01, 40.71),
  zoom = 13
) |>
  # Add scattered points
  add_source(id = "concave_points", data = scattered_points) |>
  add_circle_layer(
    id = "concave_points_layer",
    source = "concave_points",
    circle_color = "red",
    circle_radius = 6
  ) |>
  # Calculate concave hull with max edge
  turf_concave_hull(
    layer_id = "concave_points",
    units = "kilometers",
    source_id = "concave_hull_result"
  ) |>
  # Show concave hull
  add_fill_layer(
    id = "concave_hull_layer",
    source = "concave_hull_result",
    fill_color = "green",
    fill_opacity = 0.4,
    fill_outline_color = "darkgreen"
  )

print("Map 22 created: Concave hull from layer_id")
print("Red points with green concave hull (3km max edge)")
# Uncomment to display: map22

# --------------------------------------------------------------------
# Test 6.2: Concave hull with coordinates and different max edges
# --------------------------------------------------------------------
cat("\nTest 6.2: Concave hull with coordinates and different max edges\n")
cat("Comparing different max edge lengths...\n\n")

map23 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.01, 40.71),
  zoom = 13
) |>
  # Loose concave hull (larger max edge)
  turf_concave_hull(
    coordinates = hull_coords,
    max_edge = 10,  # 10 km max edge
    units = "kilometers",
    source_id = "loose_concave"
  ) |>
  # Tight concave hull (smaller max edge)
  turf_concave_hull(
    coordinates = hull_coords,
    max_edge = 2,   # 2 km max edge
    units = "kilometers",
    source_id = "tight_concave"
  ) |>
  # Show loose hull
  add_fill_layer(
    id = "loose_concave_layer",
    source = "loose_concave",
    fill_color = "blue",
    fill_opacity = 0.2,
    fill_outline_color = "darkblue"
  ) |>
  # Show tight hull
  add_fill_layer(
    id = "tight_concave_layer",
    source = "tight_concave",
    fill_color = "red",
    fill_opacity = 0.3,
    fill_outline_color = "darkred"
  )

print("Map 23 created: Concave hulls with different max edges")
print("Blue = loose (10km), Red = tight (2km)")
# Uncomment to display: map23

# --------------------------------------------------------------------
# Test 6.3: Concave hull vs Convex hull comparison
# --------------------------------------------------------------------
cat("\nTest 6.3: Concave hull vs Convex hull comparison\n")
cat("Side-by-side comparison of concave vs convex hulls...\n\n")

map24 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.01, 40.71),
  zoom = 13
) |>
  # Show points
  add_source(id = "comparison_points", data = scattered_points) |>
  add_circle_layer(
    id = "comparison_points_layer",
    source = "comparison_points",
    circle_color = "black",
    circle_radius = 4
  ) |>
  # Convex hull
  turf_convex_hull(
    data = scattered_points,
    source_id = "comparison_convex"
  ) |>
  # Concave hull
  turf_concave_hull(
    data = scattered_points,
    source_id = "comparison_concave"
  ) |>
  # Show convex hull (transparent)
  add_fill_layer(
    id = "comparison_convex_layer",
    source = "comparison_convex",
    fill_color = "blue",
    fill_opacity = 0.15,
    fill_outline_color = "blue"
  ) |>
  # Show concave hull (more opaque)
  add_fill_layer(
    id = "comparison_concave_layer",
    source = "comparison_concave",
    fill_color = "red",
    fill_opacity = 0.3,
    fill_outline_color = "red"
  )

print("Map 24 created: Convex vs Concave hull comparison")
print("Black points, Blue = convex hull, Red = concave hull")
# Uncomment to display: map24

cat("\n========================================\n")
cat("TURF_CONCAVE_HULL TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Concave hull follows point distribution more closely than convex\n")
cat("2. Different max_edge values produce different hull shapes\n")
cat("3. All input types work (layer_id, data, coordinates)\n")
cat("4. Concave hulls are visibly different from convex hulls\n")


# ========================================
# TESTING: turf_voronoi()
# ========================================

cat("\n\n========================================\n")
cat("TESTING: turf_voronoi()\n")
cat("========================================\n")

# Test 7.1: Voronoi with layer_id (no bbox)
cat("\nTest 7.1: Voronoi with layer_id (no bbox)\n")
cat("Creating Voronoi diagram from point layer...\n\n")

points_data <- data.frame(
  lng = c(-74.0, -74.1, -73.9, -74.05, -73.95),
  lat = c(40.7, 40.8, 40.75, 40.72, 40.78)
)
points_sf <- st_as_sf(points_data, coords = c("lng", "lat"), crs = 4326) %>%
  mutate(id = 1:nrow(.))

map25 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.75),
  zoom = 10
) |>
  add_circle_layer(
    id = "voronoi_points",
    source = points_sf,
    circle_color = "red",
    circle_radius = 8
  ) |>
  turf_voronoi(
    layer_id = "voronoi_points",
    source_id = "voronoi_result"
  ) |>
  add_line_layer(
    id = "voronoi_lines",
    source = "voronoi_result",
    line_color = "blue",
    line_width = 2
  ) |>
  add_fill_layer(
    id = "voronoi_fill",
    source = "voronoi_result",
    fill_color = "blue",
    fill_opacity = 0.1
  )

print("Map 25 created: Voronoi diagram from layer_id")
print("Red points with blue Voronoi cells")
# Uncomment to display: map25


# Test 7.2: Voronoi with custom bbox
cat("\nTest 7.2: Voronoi with custom bbox\n")
cat("Using explicit bbox to limit Voronoi diagram...\n\n")

# Define a tighter bounding box
tight_bbox <- c(-74.08, 40.71, -73.92, 40.79)

map26 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.75),
  zoom = 10
) |>
  add_circle_layer(
    id = "voronoi_points2",
    source = points_sf,
    circle_color = "green",
    circle_radius = 8
  ) |>
  turf_voronoi(
    data = points_sf,
    bbox = tight_bbox,
    source_id = "voronoi_bbox_result"
  ) |>
  add_line_layer(
    id = "voronoi_bbox_lines",
    source = "voronoi_bbox_result",
    line_color = "green",
    line_width = 2
  ) |>
  add_fill_layer(
    id = "voronoi_bbox_fill",
    source = "voronoi_bbox_result",
    fill_color = "green",
    fill_opacity = 0.1
  )

print("Map 26 created: Voronoi with custom bbox")
print("Green points with constrained Voronoi cells")
# Uncomment to display: map26


# Test 7.3: Voronoi with sf object as bbox
cat("\nTest 7.3: Voronoi with sf object as bbox\n")
cat("Using an sf polygon to constrain Voronoi diagram...\n\n")

# Create a polygon to use as bbox
bbox_polygon <- st_polygon(list(rbind(
  c(-74.07, 40.71),
  c(-74.07, 40.78),
  c(-73.93, 40.78),
  c(-73.93, 40.71),
  c(-74.07, 40.71)
)))
bbox_sf <- st_sfc(bbox_polygon, crs = 4326) |> st_as_sf()

map27 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.0, 40.75),
  zoom = 10
) |>
  # Show the bbox polygon
  add_fill_layer(
    id = "bbox_polygon",
    source = bbox_sf,
    fill_color = "yellow",
    fill_opacity = 0.2
  ) |>
  add_line_layer(
    id = "bbox_outline",
    source = bbox_sf,
    line_color = "orange",
    line_width = 2
  ) |>
  # Add points
  add_circle_layer(
    id = "voronoi_points3",
    source = points_sf,
    circle_color = "purple",
    circle_radius = 8
  ) |>
  # Create Voronoi constrained by sf bbox
  turf_voronoi(
    data = points_sf,
    bbox = bbox_sf,
    source_id = "voronoi_sf_bbox_result"
  ) |>
  add_line_layer(
    id = "voronoi_sf_lines",
    source = "voronoi_sf_bbox_result",
    line_color = "purple",
    line_width = 2
  )

print("Map 27 created: Voronoi with sf object as bbox")
print("Purple points, yellow bbox polygon, purple Voronoi cells")
# Uncomment to display: map27


# Test 7.4: Voronoi clipped to NC counties
cat("\nTest 7.4: Voronoi clipped to NC counties\n")
cat("Using layer_id as bbox to clip Voronoi to county boundaries...\n\n")

nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
# Get a few adjacent counties
adjacent_counties <- nc[c(1, 2, 3, 4, 5), ]
county_points <- st_centroid(adjacent_counties)

map28 <- maplibre(
  style = carto_style("positron"),
  bounds = unname(st_bbox(adjacent_counties))
) |>
  # Add county polygons
  add_fill_layer(
    id = "counties",
    source = adjacent_counties,
    fill_color = "lightgray",
    fill_opacity = 0.5
  ) |>
  add_line_layer(
    id = "county_borders",
    source = adjacent_counties,
    line_color = "darkgray",
    line_width = 1
  ) |>
  # Add county centroids
  add_circle_layer(
    id = "county_centroids",
    source = county_points,
    circle_color = "red",
    circle_radius = 8
  ) |>
  # Create Voronoi clipped to county boundaries
  turf_voronoi(
    data = county_points,
    bbox = "counties",  # Use layer_id as bbox
    source_id = "voronoi_counties_result"
  ) |>
  add_line_layer(
    id = "voronoi_county_lines",
    source = "voronoi_counties_result",
    line_color = "red",
    line_width = 2
  )

print("Map 28 created: Voronoi clipped to county boundaries")
print("Red centroids with Voronoi cells clipped to gray county boundaries")
suppressWarnings(print("Note: bbox as layer_id will clip Voronoi to layer extent"))
# Uncomment to display: map28

library(tigris)
options(tigris_use_cache = TRUE)

tx <- states(cb = TRUE, resolution = "20m") |> filter(NAME == "Texas")

co <- counties("TX", cb = TRUE, resolution = "20m") |> sf::st_centroid()

mapboxgl(bounds = tx) |>
  add_circle_layer(
    "tx-centers",
    source = co
  ) |>
  add_line_layer(
    id = "tx-border",
    source = tx
  ) |>
  turf_voronoi(
    layer_id = "tx-centers",
    bbox = "tx-border",
    source_id = "tx-voronoi",
    property = "NAME"
  ) |>
  add_fill_layer(
    "tx-voronoi-layer",
    source = "tx-voronoi",
    fill_color = "green",
    fill_opacity = 0.5,
    tooltip = "NAME"
  ) |>
  add_line_layer(
    "tx-voronoi-outlines",
    source = "tx-voronoi",
    line_color = "darkgreen",
    line_width = 2
  )

mapboxgl(bounds = tx) |>
  add_circle_layer(
    "tx-centers",
    source = co
  ) |>
  turf_buffer(
    "tx-centers",
    radius = 10000,
    source_id = "tx-buffers"
  ) |>
  add_fill_layer(
    "tx-buffer-layer",
    source = "tx-buffers",
    fill_color = "green",
    fill_opacity = 0.5,
    tooltip = "NAME"
  )

cat("\n========================================\n")
cat("TURF_VORONOI TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Basic Voronoi diagrams are created correctly\n")
cat("2. Custom bbox constrains the Voronoi cells\n")
cat("3. sf object bbox extraction works\n")
cat("4. Layer_id as bbox clips Voronoi to layer boundaries\n")


# ========================================
# TESTING: turf_distance()
# ========================================

cat("\n\n========================================\n")
cat("TESTING: turf_distance() - PROXY ONLY\n")
cat("========================================\n")
cat("\nNote: turf_distance only works with proxy objects in Shiny apps\n")
cat("It calculates distance between features and returns the value to R\n")

# Example code for Shiny apps:
cat("\nExample usage in Shiny:\n")
cat("\nlibrary(shiny)\n")
cat("library(mapgl)\n\n")
cat("ui <- fluidPage(\n")
cat("  maplibreOutput(\"map\"),\n")
cat("  verbatimTextOutput(\"distance\")\n")
cat(")\n\n")
cat("server <- function(input, output, session) {\n")
cat("  output$map <- renderMaplibre({\n")
cat("    maplibre() |>\n")
cat("      add_circle_layer(id = \"point1\", ...) |>\n")
cat("      add_circle_layer(id = \"point2\", ...)\n")
cat("  })\n\n")
cat("  observeEvent(input$calculate_distance, {\n")
cat("    maplibre_proxy(\"map\") |>\n")
cat("      turf_distance(\n")
cat("        layer_id = \"point1\",\n")
cat("        layer_id_2 = \"point2\",\n")
cat("        units = \"kilometers\"\n")
cat("      )\n")
cat("  })\n\n")
cat("  output$distance <- renderPrint({\n")
cat("    input$map_turf_result\n")
cat("  })\n")
cat("}\n")


# ========================================
# TESTING: turf_area()
# ========================================

cat("\n\n========================================\n")
cat("TESTING: turf_area() - PROXY ONLY\n")
cat("========================================\n")
cat("\nNote: turf_area only works with proxy objects in Shiny apps\n")
cat("It calculates the area of features and returns the value to R\n")

# Example code for Shiny apps:
cat("\nExample usage in Shiny:\n")
cat("\nobserveEvent(input$calculate_area, {\n")
cat("  maplibre_proxy(\"map\") |>\n")
cat("    turf_area(\n")
cat("      layer_id = \"polygon_layer\"\n")
cat("    )\n")
cat("})\n\n")
cat("# Result available in input$map_turf_result\n")
cat("# Area is returned in square meters\n")


# ========================================
# TESTING: turf_centroid()
# ========================================

cat("\n\n========================================\n")
cat("TESTING: turf_centroid()\n")
cat("========================================\n")

# Test 8.1: Centroid of polygon
cat("\nTest 8.1: Centroid of polygon\n")
cat("Finding centroid of a single polygon...\n\n")

# Create a polygon
polygon_coords <- rbind(
  c(-74.05, 40.70),
  c(-74.05, 40.75),
  c(-74.00, 40.75),
  c(-74.00, 40.70),
  c(-74.05, 40.70)
)
polygon <- st_polygon(list(polygon_coords))
polygon_sf <- st_sfc(polygon, crs = 4326) |> st_as_sf()

map29 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.025, 40.725),
  zoom = 12
) |>
  add_fill_layer(
    id = "test_polygon",
    source = polygon_sf,
    fill_color = "lightblue",
    fill_opacity = 0.5
  ) |>
  add_line_layer(
    id = "polygon_outline",
    source = polygon_sf,
    line_color = "blue",
    line_width = 2
  ) |>
  turf_centroid(
    layer_id = "test_polygon",
    source_id = "polygon_centroid"
  ) |>
  add_circle_layer(
    id = "centroid_point",
    source = "polygon_centroid",
    circle_color = "red",
    circle_radius = 8
  )

print("Map 29 created: Polygon centroid")
print("Blue polygon with red centroid point")
# Uncomment to display: map29


# Test 8.2: Centroid of complex multipolygon
cat("\nTest 8.2: Centroid of complex multipolygon\n")
cat("Finding centroid of NC counties...\n\n")

nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
# Union multiple counties into one multipolygon
multi_counties <- nc[c(1, 2, 3), ]
unioned_counties <- st_union(multi_counties)

map30 <- maplibre(
  style = carto_style("positron"),
  bounds = unname(st_bbox(multi_counties))
) |>
  add_fill_layer(
    id = "multi_counties",
    source = multi_counties,
    fill_color = "lightgreen",
    fill_opacity = 0.5
  ) |>
  turf_centroid(
    data = multi_counties,
    source_id = "counties_centroid"
  ) |>
  add_circle_layer(
    id = "centroid_marker",
    source = "counties_centroid",
    circle_color = "red",
    circle_radius = 10
  )

print("Map 30 created: Multipolygon centroid")
print("Green counties with red centroid of union")
# Uncomment to display: map30


# Test 8.3: Centroid of point collection
cat("\nTest 8.3: Centroid of point collection\n")
cat("Finding centroid (center of mass) of points...\n\n")

# Create scattered points
scattered_points_2 <- data.frame(
  lng = c(-74.05, -74.02, -73.98, -74.01, -74.03, -73.99),
  lat = c(40.70, 40.73, 40.71, 40.69, 40.72, 40.74)
)
scattered_sf <- st_as_sf(scattered_points_2, coords = c("lng", "lat"), crs = 4326)

map31 <- maplibre(
  style = carto_style("positron"),
  center = c(-74.02, 40.715),
  zoom = 12
) |>
  add_circle_layer(
    id = "scattered_points",
    source = scattered_sf,
    circle_color = "blue",
    circle_radius = 6
  ) |>
  turf_centroid(
    data = scattered_sf,
    source_id = "points_centroid"
  ) |>
  add_circle_layer(
    id = "centroid_of_points",
    source = "points_centroid",
    circle_color = "red",
    circle_radius = 10,
    circle_stroke_color = "darkred",
    circle_stroke_width = 2
  )

print("Map 31 created: Point collection centroid")
print("Blue points with red centroid (center of mass)")
# Uncomment to display: map31

cat("\n========================================\n")
cat("TURF_CENTROID TESTS COMPLETE\n")
cat("========================================\n")
cat("\nCheck that:\n")
cat("1. Polygon centroids are calculated correctly\n")
cat("2. Multipolygon centroids work properly\n")
cat("3. Point collection centroids (center of mass) are accurate\n")
cat("4. All input types work (layer_id, data)\n")


cat("\n\n========================================\n")
cat("ALL TURF FUNCTION TESTS COMPLETE!\n")
cat("========================================\n")
cat("\nSummary of tested functions:\n")
cat("✓ turf_buffer - Creates buffers around features\n")
cat("✓ turf_union - Unions multiple polygons\n")
cat("✓ turf_intersect - Finds intersection of two features\n")
cat("✓ turf_difference - Subtracts one feature from another\n")
cat("✓ turf_convex_hull - Creates convex hull around points\n")
cat("✓ turf_concave_hull - Creates concave hull with smart max_edge\n")
cat("✓ turf_voronoi - Creates Voronoi diagrams with bbox support\n")
cat("✓ turf_centroid - Finds centroid of features\n")
cat("✓ turf_distance - Calculates distance (proxy only)\n")
cat("✓ turf_area - Calculates area (proxy only)\n")
cat("\nAll functions support flexible inputs:\n")
cat("- layer_id: Reference existing map layers\n")
cat("- data: Use sf objects directly\n")
cat("- coordinates: Provide raw coordinates (where applicable)\n")
cat("\nNext steps:\n")
cat("1. Test in Shiny apps for proxy functionality\n")
cat("2. Create vignettes with real-world examples\n")
cat("3. Add more advanced turf operations as needed\n")
