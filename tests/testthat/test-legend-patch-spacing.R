test_that("patch_spacing controls categorical legend row heights", {
  sizes <- c(8, 16, 32, 48)

  # proportional: each patch container's height tracks its own symbol size
  prop <- maplibre() |>
    add_categorical_legend(
      legend_title = "Population",
      values = c("Small", "Medium", "Large", "Huge"),
      colors = "#3182bd",
      patch_shape = "circle",
      sizes = sizes,
      patch_spacing = "proportional"
    )
  prop_html <- prop$x$legend_html
  for (s in sizes) {
    expect_match(prop_html, paste0("height:", s, "px"), fixed = TRUE)
  }

  # uniform (default): every row uses the largest symbol's height
  unif <- maplibre() |>
    add_categorical_legend(
      legend_title = "Population",
      values = c("Small", "Medium", "Large", "Huge"),
      colors = "#3182bd",
      patch_shape = "circle",
      sizes = sizes
    )
  unif_html <- unif$x$legend_html
  expect_no_match(unif_html, "height:8px", fixed = TRUE)
  # all four rows clamp to max(sizes)
  expect_equal(
    lengths(regmatches(unif_html, gregexpr("height:48px", unif_html, fixed = TRUE))),
    4L
  )
})

test_that("patch_spacing controls compare categorical legend row heights", {
  sizes <- c(8, 16, 32)

  widget <- compare(maplibre(), maplibre()) |>
    add_legend(
      legend_title = "Population",
      values = c("Small", "Medium", "Large"),
      colors = "#3182bd",
      type = "categorical",
      patch_shape = "circle",
      sizes = sizes,
      patch_spacing = "proportional"
    )

  legend_html <- widget$x$compare_legends[[1]]$html
  for (s in sizes) {
    expect_match(legend_html, paste0("height:", s, "px"), fixed = TRUE)
  }
})

test_that("patch_spacing rejects unknown values", {
  expect_error(
    maplibre() |>
      add_categorical_legend(
        legend_title = "x",
        values = c("a", "b"),
        colors = "#3182bd",
        sizes = c(10, 20),
        patch_spacing = "wonky"
      ),
    "should be one of"
  )
})
