# Extracted from test-match-expr.R:41

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "mapgl", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
expr <- match_expr("zz", values = factor(c("a", "b")), stops = c("red", "blue"))
expect_equal(expr[c(3, 5)], list("a", "b"))
