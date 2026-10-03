# Extracted from test-filter-slots.R:16

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "mapgl", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
node <- Sys.which("node")
skip_if(node == "", "node is not available")
for (binding in c("mapboxgl", "maplibregl")) {
    js <- system.file(
      "htmlwidgets", paste0(binding, ".js"),
      package = "mapgl"
    )
    expect_true(file.exists(js))
    output <- system2(
      node,
      c(shQuote(test_path("fixtures", "filter-slots.cjs")), shQuote(js)),
      stdout = TRUE,
      stderr = TRUE
    )
    expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
    expect_match(
      paste(output, collapse = "\n"),
      "Filter slots compose correctly",
      info = binding
    )
  }
