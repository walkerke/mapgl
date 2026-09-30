test_that("interactive legend toggles preserve SVG and CSS patch paints", {
  node <- Sys.which("node")
  skip_if(node == "", "node is not available")
  js <- system.file("htmlwidgets/lib/legend-interactivity/legend-interactivity.js",
                    package = "mapgl")
  expect_true(file.exists(js))
  output <- system2(node, c(shQuote(test_path("fixtures", "legend-patches.cjs")),
                           shQuote(js)), stdout = TRUE, stderr = TRUE)
  expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
  expect_match(paste(output, collapse = "\n"), "Patch paint preserved")
})
