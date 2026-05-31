test_that("add_flowmap serializes all new customization settings", {
  locations <- data.frame(
    id = c("a", "b"),
    lat = c(40, 41),
    lon = c(-74, -75)
  )
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  map <- maplibre() |>
    add_flowmap(
      id = "flows",
      locations = locations,
      flows = flows,
      flow_fade_amount = 75,
      flow_highlight_color = "red",
      flow_locations_enabled = FALSE,
      flow_location_totals_enabled = FALSE,
      flow_location_labels_enabled = TRUE,
      flow_lines_rendering_mode = "animated-straight",
      flow_clustering_enabled = FALSE,
      flow_clustering_auto = FALSE,
      flow_clustering_level = 5,
      flow_fade_enabled = FALSE,
      flow_fade_opacity_enabled = TRUE,
      flow_adaptive_scales_enabled = FALSE,
      flow_temporal_scale_domain = "all",
      flow_max_top_flows_display_num = 1000,
      flow_endpoints_in_viewport_mode = "both"
    )

  expect_length(map$x$flowmaps, 1)
  settings <- map$x$flowmaps[[1]]$settings

  expect_equal(settings$fadeAmount, 75)
  expect_equal(settings$highlightColor, "red")
  expect_false(settings$locationsEnabled)
  expect_false(settings$locationTotalsEnabled)
  expect_true(settings$locationLabelsEnabled)
  expect_equal(settings$flowLinesRenderingMode, "animated-straight")
  expect_false(settings$clusteringEnabled)
  expect_false(settings$clusteringAuto)
  expect_equal(settings$clusteringLevel, 5)
  expect_false(settings$fadeEnabled)
  expect_true(settings$fadeOpacityEnabled)
  expect_false(settings$adaptiveScalesEnabled)
  expect_equal(settings$temporalScaleDomain, "all")
  expect_equal(settings$flowLinesRenderingMode, "animated-straight")
  expect_equal(settings$maxTopFlowsDisplayNum, 1000)
  expect_equal(settings$flowEndpointsInViewportMode, "both")
})

test_that("add_flowmap validates new parameters", {
  locations <- data.frame(id = c("a", "b"), lat = c(40, 41), lon = c(-74, -75))
  flows <- data.frame(origin = "a", dest = "b", count = 10)

  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_fade_amount = -1), "between 0 and 100")
  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_fade_amount = 101), "between 0 and 100")
  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_max_top_flows_display_num = 0), "positive number")
  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_clustering_level = "a"), "number or NULL")
  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_locations_enabled = "TRUE"), "TRUE or FALSE")
  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_highlight_color = 123), "single string")
  expect_error(add_flowmap(maplibre(), "id", locations, flows, flow_temporal_scale_domain = "hour"), "'arg' should be one of")
})
