test_that("categorical legends accept one patch_shape per value", {
  m <- maplibre() |>
    add_categorical_legend(
      legend_title = NULL,
      values = c("Service area", "Station", "Route"),
      colors = c("#13a38a", "#173b5c", "#1f5fbf"),
      patch_shape = c("square", "circle", "line")
    )
  html <- m$x$legend_html
  expect_match(html, "legend-shape-square", fixed = TRUE)
  expect_match(html, "legend-shape-circle", fixed = TRUE)
  expect_match(html, "legend-shape-line", fixed = TRUE)
  # the line keeps its default thickness; the other patches keep the default size
  expect_match(html, "width: 30px; height: 3px", fixed = TRUE)
  expect_match(html, "width: 20px; height: 20px; border-radius: 50%", fixed = TRUE)
})

test_that("per-value shapes can mix built-in and custom SVG patches", {
  ring <- '<circle cx="50" cy="50" r="38" fill="none" stroke="black" stroke-width="16" />'
  m <- mapboxgl() |>
    add_categorical_legend(
      legend_title = "Status",
      values = c("Operating", "Proposed"),
      colors = c("#9b8cf2", "#9b8cf2"),
      patch_shape = c("circle", ring)
    )
  html <- m$x$legend_html
  expect_match(html, "legend-shape-circle", fixed = TRUE)
  expect_match(html, "legend-shape-custom", fixed = TRUE)
})

test_that("compare legends accept one patch_shape per value", {
  cmp <- compare(mapboxgl(), mapboxgl()) |>
    add_legend(
      legend_title = NULL,
      values = c("Area", "Point"),
      colors = c("#13a38a", "#173b5c"),
      type = "categorical",
      patch_shape = c("square", "circle")
    )
  html <- cmp$x$compare_legends[[1]]$html
  expect_match(html, "legend-shape-square", fixed = TRUE)
  expect_match(html, "legend-shape-circle", fixed = TRUE)
})

test_that("patch_shape must be length one or match values", {
  expect_error(
    maplibre() |>
      add_categorical_legend(
        legend_title = "x", values = c("a", "b", "c"), colors = "red",
        patch_shape = c("square", "circle")
      ),
    "same length as 'values'"
  )
  expect_error(
    maplibre() |>
      add_categorical_legend(legend_title = "x", values = "a", colors = "red", patch_shape = "triangle"),
    "Custom SVG patch_shape appears invalid"
  )
})

test_that("custom SVG patches keep fill='none' so outline shapes stay hollow", {
  ring <- '<circle cx="50" cy="50" r="38" fill="none" stroke="black" stroke-width="16" />'
  m <- mapboxgl() |>
    add_categorical_legend(legend_title = "x", values = "Proposed", colors = "#9b8cf2", patch_shape = ring)
  html <- m$x$legend_html
  expect_match(html, 'fill="none"', fixed = TRUE)
  expect_match(html, 'stroke="#9b8cf2"', fixed = TRUE)
  expect_match(html, 'stroke-width="16"', fixed = TRUE)

  styled <- '<rect x="10" y="10" width="80" height="80" style="fill:transparent;stroke:black;stroke-width:12" />'
  m2 <- mapboxgl() |>
    add_categorical_legend(legend_title = "x", values = "Planned", colors = "#f18c70", patch_shape = styled)
  html2 <- m2$x$legend_html
  expect_match(html2, "fill:transparent", fixed = TRUE)
  expect_match(html2, "stroke:#f18c70", fixed = TRUE)
  expect_match(html2, "stroke-width:12", fixed = TRUE)
})

test_that("a list patch_shape mixes sf polygons with built-in shapes", {
  skip_if_not_installed("sf")
  poly <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(rbind(
    c(0, 0), c(2, 0.5), c(1.5, 2), c(0.3, 1.4), c(0, 0)
  )))))
  m <- mapboxgl() |>
    add_categorical_legend(
      "Mixed", values = c("Drive area", "Charger"), colors = c("#13a38a", "#173b5c"),
      patch_shape = list(poly, "circle")
    )
  html <- m$x$legend_html
  expect_match(html, "<path|<polygon")
  expect_match(html, "border-radius: 50%|<circle")
  # a bare geometry column works too
  m2 <- mapboxgl() |>
    add_categorical_legend("Geom", values = c("a", "b"), colors = c("red", "blue"),
                           patch_shape = list(sf::st_geometry(poly), "square"))
  expect_match(m2$x$legend_html, "<path|<polygon")
  expect_error(
    mapboxgl() |> add_categorical_legend("Bad", values = c("a", "b"), colors = c("red", "blue"),
                                         patch_shape = list("circle", 3)),
    "patch_shape"
  )
})
