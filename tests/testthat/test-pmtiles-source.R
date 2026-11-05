test_that("mapbox pmtiles sources pass the url through for the JS to resolve", {
  rel <- mapboxgl() |> add_pmtiles_source("w", url = "tiles/wells.pmtiles")
  expect_equal(rel$x$sources[[1]]$type, "vector")
  expect_equal(rel$x$sources[[1]]$url, "tiles/wells.pmtiles")

  ras <- mapboxgl() |> add_pmtiles_source("r", url = "tiles/topo.pmtiles", source_type = "raster")
  expect_equal(ras$x$sources[[1]]$type, "raster")
  expect_equal(ras$x$sources[[1]]$url, "tiles/topo.pmtiles")
})

test_that("maplibre pmtiles sources keep the pmtiles:// protocol", {
  m <- maplibre() |> add_pmtiles_source("w", url = "tiles/wells.pmtiles")
  expect_equal(m$x$sources[[1]]$url, "pmtiles://tiles/wells.pmtiles")
})
