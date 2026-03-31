# reproducible examples demonstrating compare() widget bugs
# fixed in this PR — run each section to see the issue

library(mapgl)
library(sf)

# sample polygon data: NC counties
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

# --- Bug 1: layer filter not applied in compare() ----------------------------
# the compare widget's initial render ignores the `filter` parameter,
# so BOTH layers render ALL features instead of their filtered subsets.
# expected: left map shows only counties with AREA > 0.15,
#           right map shows only counties with AREA <= 0.15
# actual (before fix): both maps show all counties

map_large <- maplibre(
  style = carto_style("voyager"),
  bounds = nc) |>
  add_fill_layer(
    id               = "large-counties",
    source           = nc,
    fill_color       = "steelblue",
    fill_opacity     = 0.5,
    fill_outline_color = "white",
    filter           = list(">", list("get", "AREA"), 0.15),
    tooltip          = "NAME")

map_small <- maplibre(
  style = carto_style("voyager"),
  bounds = nc) |>
  add_fill_layer(
    id               = "small-counties",
    source           = nc,
    fill_color       = "tomato",
    fill_opacity     = 0.5,
    fill_outline_color = "white",
    filter           = list("<=", list("get", "AREA"), 0.15),
    tooltip          = "NAME")

compare(map_large, map_small)


# --- Bug 2: hover_options fails on PMTiles / vector tile sources -------------
# setFeatureState requires sourceLayer for vector sources, but the compare
# widget's initial render hover handler omits it.
# expected: yellow highlight on hover
# actual (before fix): JS error "sourceLayer parameter must be provided"

map_hover <- maplibre(
  style = carto_style("dark-matter"),
  bounds = nc) |>
  add_fill_layer(
    id               = "counties-hover",
    source           = nc,
    fill_color       = "#4a90d9",
    fill_opacity     = 0.4,
    fill_outline_color = "white",
    tooltip          = "NAME",
    hover_options    = list(
      fill_color         = "#ffeb3b",
      fill_outline_color = "#ffeb3b",
      fill_opacity       = 0.7))

compare(map_hover, map_hover)
# note: the hover bug specifically manifests with vector tile (PMTiles)
# sources where source_layer is required; GeoJSON sources may work because
# they don't need sourceLayer in setFeatureState


# --- Bug 3: layers control only toggles one map in compare() -----------------
# the onclick handler in the compare widget's layers control only calls
# setLayoutProperty on the single `map` in its closure scope, not both maps.
# expected: toggling "Counties" hides the layer on BOTH sides
# actual (before fix): only one side toggles

map_left <- maplibre(
  style = carto_style("voyager"),
  bounds = nc) |>
  add_fill_layer(
    id               = "counties-left",
    source           = nc,
    fill_color       = "steelblue",
    fill_opacity     = 0.4,
    fill_outline_color = "white") |>
  add_layers_control(
    position    = "top-right",
    layers      = list("Counties" = "counties-left"),
    collapsible = TRUE)

map_right <- maplibre(
  style = carto_style("dark-matter"),
  bounds = nc) |>
  add_fill_layer(
    id               = "counties-right",
    source           = nc,
    fill_color       = "tomato",
    fill_opacity     = 0.4,
    fill_outline_color = "white") |>
  add_layers_control(
    position    = "top-right",
    layers      = list("Counties" = "counties-right"),
    collapsible = TRUE)

compare(map_left, map_right)
# click "Counties" in the left layers control — only the left map toggles


# --- Bug 4: proxy add_layers_control doesn't support grouped layers ----------
# when dynamically rebuilding the layers control via proxy in a Shiny app,
# passing a named list (grouped layers) causes "layers.forEach is not a
# function" because the proxy handler only accepts flat arrays.
# this is a Shiny-only bug — see the PR description for the Shiny repro.
