library(testthat)
library(mapgl)

# Tests are for local development only. They call out to the network and
# node, so they never run on CRAN. devtools::test()/check() set NOT_CRAN.
if (identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_check("mapgl")
}
