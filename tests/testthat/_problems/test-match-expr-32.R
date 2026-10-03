# Extracted from test-match-expr.R:32

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "mapgl", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
expect_message(
    expr <- match_expr(
      "zz",
      values = c("a", NA, "b"),
      stops = c("red", "green", "blue")
    ),
    "Dropped `NA`"
  )
expect_equal(expr, list("match", list("get", "zz"), "a", "red", "b", "blue", "#cccccc"))
