# Extracted from test-legend-patch-toggle.R:10

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "mapgl", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
node <- Sys.which("node")
skip_if(node == "", "node is not available")
js <- system.file("htmlwidgets/lib/legend-interactivity/legend-interactivity.js",
                    package = "mapgl")
expect_true(file.exists(js))
output <- system2(node, c(shQuote(test_path("fixtures", "legend-patches.cjs")),
                           shQuote(js)), stdout = TRUE, stderr = TRUE)
expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
expect_match(paste(output, collapse = "\n"), "Patch paint preserved")
