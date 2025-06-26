library(mapgl)

# Test PMTiles with Mapbox GL JS and MapLibre GL JS
# Note: This requires a Mapbox access token for the Mapbox example

# Example using PMTiles with Mapbox GL JS
# The add_pmtiles_source() function automatically handles the differences
mapbox_map <- mapboxgl(
  center = c(-72.9, 41.3),
  zoom = 10
) |>
  add_pmtiles_source(
    id = "pmtiles",
    url = "https://data.source.coop/cboettig/us-boundaries/mappinginequality.pmtiles"
  ) |>
  add_fill_layer(
    id = "redlines",
    source = "pmtiles",
    source_layer = "mappinginequality",
    fill_color = list("get", "fill")
  )

# For comparison, the same with MapLibre (native PMTiles support)
# The same function works seamlessly with MapLibre
maplibre_map <- maplibre(
  center = c(-72.9, 41.3),
  zoom = 10
) |>
  add_pmtiles_source(
    id = "pmtiles",
    url = "https://data.source.coop/cboettig/us-boundaries/mappinginequality.pmtiles"
  ) |>
  add_fill_layer(
    id = "redlines",
    source = "pmtiles",
    source_layer = "mappinginequality",
    fill_color = list("get", "fill")
  )

# View the maps
mapbox_map
# maplibre_map
