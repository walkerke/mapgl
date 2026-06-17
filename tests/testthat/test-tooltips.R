test_that("tooltip_style() builds a spec and presets/overrides resolve", {
  s <- tooltip_style("dark", border_radius = 10)
  expect_s3_class(s, "mapgl_tooltip_style")
  expect_equal(s$preset, "dark")
  expect_equal(s$border_radius, 10)

  # popup_style() is an alias producing the same class
  expect_s3_class(popup_style("light"), "mapgl_tooltip_style")

  # Resolution: preset fills the base, overrides win
  resolved <- mapgl_normalize_tooltip_style(tooltip_style("dark", border_radius = 10))
  expect_equal(resolved$background_color, "rgba(35, 35, 35, 0.94)")
  expect_equal(resolved$border_radius, 10)

  # A bare preset string resolves too
  light <- mapgl_normalize_tooltip_style("light")
  expect_equal(light$text_color, "#222222")

  # "auto" resolves against dark_mode
  expect_equal(
    mapgl_normalize_tooltip_style("auto", dark_mode = TRUE)$background_color,
    "rgba(35, 35, 35, 0.94)"
  )
  expect_equal(
    mapgl_normalize_tooltip_style("auto", dark_mode = FALSE)$background_color,
    "rgba(255, 255, 255, 0.96)"
  )

  # NULL -> NULL (no styling)
  expect_null(mapgl_normalize_tooltip_style(NULL))

  # Custom-only (no preset) keeps just the overrides
  custom <- mapgl_normalize_tooltip_style(
    tooltip_style(background_color = "navy", text_color = "white")
  )
  expect_equal(custom, list(background_color = "navy", text_color = "white"))

  # Invalid input errors clearly
  expect_error(mapgl_normalize_tooltip_style(42), "preset string")
  expect_error(tooltip_style("sepia"), "should be one of")
})

test_that("layer tooltip/popup content and style serialize", {
  pts <- data.frame(lon = 0, lat = 0, name = "x", value = 1)
  pts <- sf::st_as_sf(pts, coords = c("lon", "lat"), crs = 4326)

  m <- maplibre() |>
    add_circle_layer(
      id = "c",
      source = pts,
      tooltip = "{name}: {value}",
      tooltip_style = "dark",
      popup = "name",
      popup_style = tooltip_style(background_color = "navy")
    )
  layer <- m$x$layers[[1]]

  # Content travels through untouched (the JS resolver handles it).
  expect_equal(layer$tooltip, "{name}: {value}")
  expect_equal(layer$popup, "name")

  # Style is normalized to a serialized spec.
  expect_equal(layer$tooltip_style$background_color, "rgba(35, 35, 35, 0.94)")
  expect_equal(layer$popup_style$background_color, "navy")
})

test_that("an expression tooltip serializes as an expression", {
  pts <- sf::st_as_sf(
    data.frame(lon = 0, lat = 0, value = 1000),
    coords = c("lon", "lat"),
    crs = 4326
  )
  m <- maplibre() |>
    add_circle_layer(
      id = "c",
      source = pts,
      tooltip = concat("Value: ", number_format("value"))
    )
  tt <- m$x$layers[[1]]$tooltip
  expect_true(is.list(tt))
  expect_equal(tt[[1]], "concat")
})

test_that("omitting tooltip_style leaves layers unchanged (opt-in)", {
  pts <- sf::st_as_sf(
    data.frame(lon = 0, lat = 0, name = "x"),
    coords = c("lon", "lat"),
    crs = 4326
  )
  m <- maplibre() |>
    add_circle_layer(id = "c", source = pts, tooltip = "name")
  layer <- m$x$layers[[1]]
  expect_null(layer$tooltip_style)
  expect_null(layer$popup_style)
  # Content path is untouched
  expect_equal(layer$tooltip, "name")
})

test_that("set_tooltip()/set_popup() accept and serialize a style", {
  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- list(type = type, message = message)
    }
  )
  proxy <- structure(
    list(id = "map", session = session),
    class = "maplibre_proxy"
  )

  set_tooltip(proxy, "c", tooltip = "{name}", style = "dark")
  msg <- messages[[1]]$message$message
  expect_equal(msg$type, "set_tooltip")
  expect_equal(msg$tooltip, "{name}")
  expect_equal(msg$tooltip_style$background_color, "rgba(35, 35, 35, 0.94)")

  # No style -> NULL spec (native appearance, unchanged behavior)
  set_popup(proxy, "c", popup = "name")
  msg2 <- messages[[2]]$message$message
  expect_equal(msg2$type, "set_popup")
  expect_null(msg2$popup_style)
})
