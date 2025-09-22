library(mapgl)

# Test measurement functionality with different positioning
test_map <- mapboxgl() |>
  add_draw_control(
    position = "top-left",
    rectangle = TRUE,
    radius = TRUE,
    freehand = FALSE,
    show_measurements = TRUE,
    measurement_units = "imperial"
  )

print("Created test map with measurements enabled")
print("Measurement box should appear at bottom-left (65px from bottom to avoid logo)")
print("Test by drawing rectangles and circles to see live measurements")

test_map
