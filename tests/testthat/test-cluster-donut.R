donut_points <- function(n = 20) {
  set.seed(42)
  sf::st_as_sf(
    data.frame(
      x = runif(n, -80, -79),
      y = runif(n, 35, 36),
      race = sample(c("White", "Black", "Hispanic", "Asian"), n, TRUE),
      code = sample(c(100000, 2, 3), n, TRUE),
      pop = runif(n, 0, 100)
    ),
    coords = c("x", "y"),
    crs = 4326
  )
}

race_colors <- function(default = "#cccccc") {
  match_expr(
    "race",
    values = c("White", "Black", "Hispanic"),
    stops = c("#1b9e77", "#d95f02", "#7570b3"),
    default = default
  )
}

find_layer <- function(map, id) {
  Filter(function(layer) identical(layer$id, id), map$x$layers)[[1]]
}

to_json <- function(x) as.character(htmlwidgets:::toJSON2(x))

test_that("default cluster_options() output is unchanged", {
  opts <- cluster_options()
  expect_named(
    opts,
    c(
      "max_zoom",
      "cluster_radius",
      "color_stops",
      "radius_stops",
      "count_stops",
      "circle_blur",
      "circle_opacity",
      "circle_stroke_color",
      "circle_stroke_opacity",
      "circle_stroke_width",
      "text_color",
      "count_format"
    )
  )
  m <- maplibre() |>
    add_circle_layer("p", donut_points(), cluster_options = opts)
  clusters <- find_layer(m, "p-clusters")
  expect_equal(clusters$type, "circle")
  expect_null(clusters$metadata)
  expect_null(m$x$sources[[1]]$clusterProperties)
})

test_that("add_layer(metadata = NULL) adds no metadata field", {
  m <- maplibre() |> add_layer("f", "fill", source = "s")
  expect_false("metadata" %in% names(m$x$layers[[1]]))
  m <- maplibre() |>
    add_layer("f", "fill", source = "s", metadata = list(note = "x"))
  expect_equal(m$x$layers[[1]]$metadata, list(note = "x"))
})

test_that("donut settings come from a match_expr() circle_color", {
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      circle_color = race_colors(),
      cluster_options = cluster_options(donut_column = "race")
    )
  props <- m$x$sources[[1]]$clusterProperties
  expect_named(
    props,
    c("race:White", "race:Black", "race:Hispanic", "race:_other")
  )
  clusters <- find_layer(m, "p-clusters")
  expect_equal(clusters$type, "symbol")
  expect_true(clusters$layout[["icon-allow-overlap"]])
  spec <- clusters$metadata[["mapgl:donut"]]
  expect_equal(
    unlist(spec$colors),
    c("#1B9E77", "#D95F02", "#7570B3", "#CCCCCC")
  )
  expect_match(spec$fp, "^[0-9a-f]{10}$")
  expect_match(
    to_json(clusters$layout[["icon-image"]]),
    paste0("mapgl-donut|", spec$fp, "|"),
    fixed = TRUE
  )
  expect_match(
    to_json(clusters$layout[["icon-image"]]),
    "|p-clusters\"",
    fixed = TRUE
  )
  # count label and unclustered layers keep their ids
  expect_equal(
    vapply(m$x$layers, `[[`, "", "id"),
    c("p-clusters", "p-cluster-count", "p")
  )
})

test_that("the fingerprint changes with the palette and styling", {
  build <- function(...) {
    m <- maplibre() |>
      add_circle_layer(
        "p",
        donut_points(),
        cluster_options = cluster_options(
          donut_column = "race",
          donut_values = c("White", "Black"),
          ...
        )
      )
    find_layer(m, "p-clusters")$metadata[["mapgl:donut"]]$fp
  }
  base <- build(donut_colors = c("red", "blue"))
  expect_equal(base, build(donut_colors = c("red", "blue")))
  expect_false(base == build(donut_colors = c("red", "green")))
  expect_false(base == build(donut_colors = c("red", "blue"), donut_width = 0.5))
  expect_false(
    base == build(donut_colors = c("red", "blue"), circle_stroke_color = "black")
  )
})

test_that("cluster expressions serialize as GL arrays", {
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      cluster_options = cluster_options(
        donut_column = "race",
        donut_values = "White",
        donut_colors = "red"
      )
    )
  json <- to_json(m$x$sources[[1]]$clusterProperties)
  expect_equal(
    json,
    '{"race:White":["+",["case",["==",["get","race"],"White"],1,0]]}'
  )
  spec <- find_layer(m, "p-clusters")$metadata[["mapgl:donut"]]
  expect_match(to_json(spec), '"colors":["#FF0000"]', fixed = TRUE)

  # "other" uses a bare label array, even for a single category
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      circle_color = match_expr("race", values = "White", stops = "red"),
      cluster_options = cluster_options(donut_column = "race")
    )
  expect_equal(
    to_json(m$x$sources[[1]]$clusterProperties[["race:_other"]]),
    '["+",["match",["get","race"],["White"],0,1]]'
  )
})

test_that("weights add a total and weighted label", {
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      circle_color = race_colors(default = NULL),
      cluster_options = cluster_options(
        donut_column = "race",
        donut_weight = "pop"
      )
    )
  props <- m$x$sources[[1]]$clusterProperties
  expect_named(
    props,
    c("race:White", "race:Black", "race:Hispanic", "race:_total")
  )
  expect_equal(
    to_json(props[["race:_total"]]),
    '["+",["coalesce",["get","pop"],0]]'
  )
  label <- to_json(find_layer(m, "p-cluster-count")$layout[["text-field"]])
  expect_match(label, '["get","race:_total"]', fixed = TRUE)
})

test_that("grouped match_expr() labels expand into shared-color categories", {
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      circle_color = match_expr(
        "race",
        values = list(c("White", "Black"), "Hispanic"),
        stops = c("red", "blue"),
        default = NULL
      ),
      cluster_options = cluster_options(donut_column = "race")
    )
  expect_named(
    m$x$sources[[1]]$clusterProperties,
    c("race:White", "race:Black", "race:Hispanic")
  )
  spec <- find_layer(m, "p-clusters")$metadata[["mapgl:donut"]]
  expect_equal(unlist(spec$colors), c("#FF0000", "#FF0000", "#0000FF"))
})

test_that("explicit donut colors keep alpha without touching col2hex", {
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      cluster_options = cluster_options(
        donut_column = "race",
        donut_values = c("White", "Black"),
        donut_colors = c("#FF000080", "rgba(0, 0, 255, 0.25)"),
        donut_fill = NA
      )
    )
  spec <- find_layer(m, "p-clusters")$metadata[["mapgl:donut"]]
  expect_equal(unlist(spec$colors), c("#FF0000", "#0000FF"))
  expect_equal(unlist(spec$alphas), c(0.502, 0.25))
  expect_null(spec$fill)
  expect_equal(mapgl:::.mapgl_col2hex("#FF000080"), "#FF0000")
})

test_that("category types are normalized", {
  pts <- donut_points()
  pts$race_f <- factor(pts$race)
  m <- maplibre() |>
    add_circle_layer(
      "p",
      pts,
      cluster_options = cluster_options(
        donut_column = "race_f",
        donut_values = factor(c("White", "Black")),
        donut_colors = c("red", "blue")
      )
    )
  expect_named(
    m$x$sources[[1]]$clusterProperties,
    c("race_f:White", "race_f:Black")
  )

  m <- maplibre() |>
    add_circle_layer(
      "p",
      pts,
      cluster_options = cluster_options(
        donut_column = "code",
        donut_values = c(100000, 2),
        donut_colors = c("red", "blue")
      )
    )
  props <- m$x$sources[[1]]$clusterProperties
  expect_named(props, c("code:100000", "code:2"))
  # numeric labels stay numeric in the expression
  expect_equal(
    to_json(props[["code:100000"]]),
    '["+",["case",["==",["get","code"],100000],1,0]]'
  )
  big <- mapgl:::.donut_normalize_values(9007199254740991, "x")
  expect_equal(big$keys, "9007199254740991")
})

test_that("donut arguments are validated", {
  expect_error(
    cluster_options(donut_values = "a", donut_colors = "red"),
    "require `donut_column`"
  )
  expect_error(
    cluster_options(donut_column = "race", donut_values = "a"),
    "both"
  )
  expect_error(
    cluster_options(
      donut_column = "race",
      donut_values = c("a", "b"),
      donut_colors = "red"
    ),
    "same length"
  )
  expect_error(
    cluster_options(
      donut_column = "race",
      donut_values = c("a", "a"),
      donut_colors = c("red", "red")
    ),
    "duplicate"
  )
  expect_error(
    cluster_options(
      donut_column = "race",
      donut_values = c("a", "_other"),
      donut_colors = c("red", "blue")
    ),
    "reserved"
  )
  expect_error(
    cluster_options(
      donut_column = "code",
      donut_values = c(1.5, 2),
      donut_colors = c("red", "blue")
    ),
    "whole numbers"
  )
  expect_error(
    cluster_options(
      donut_column = "code",
      donut_values = 2^53,
      donut_colors = "red"
    ),
    "whole numbers"
  )
  expect_error(
    mapgl:::.donut_normalize_values(list("a", 1), "x"),
    "all character or all numeric"
  )
  expect_error(
    cluster_options(donut_column = "race", donut_resolution = 0),
    "donut_resolution"
  )
  expect_error(
    cluster_options(donut_column = "race", donut_width = 1),
    "donut_width"
  )
  expect_error(
    cluster_options(
      donut_column = "race",
      circle_stroke_color = list("get", "x")
    ),
    "expressions aren't supported"
  )
  expect_error(
    cluster_options(
      donut_column = "race",
      donut_values = "a",
      donut_colors = "notacolor"
    ),
    "Invalid color"
  )
  # no colors available for a plain circle_color
  expect_error(
    maplibre() |>
      add_circle_layer(
        "p",
        donut_points(),
        circle_color = "red",
        cluster_options = cluster_options(donut_column = "race")
      ),
    "need category colors"
  )
  # column checks against sf data
  expect_error(
    maplibre() |>
      add_circle_layer(
        "p",
        donut_points(),
        circle_color = race_colors(),
        cluster_options = cluster_options(donut_column = "missing")
      ),
    "isn't a column"
  )
  pts <- donut_points()
  pts$bad <- -1
  expect_error(
    maplibre() |>
      add_circle_layer(
        "p",
        pts,
        circle_color = race_colors(),
        cluster_options = cluster_options(
          donut_column = "race",
          donut_weight = "bad"
        )
      ),
    "non-negative"
  )
  expect_error(
    maplibre() |>
      add_circle_layer(
        "p",
        pts,
        cluster_options = cluster_options(
          donut_column = "race",
          donut_values = c(1, 2),
          donut_colors = c("red", "blue")
        )
      ),
    "numeric column"
  )
})

test_that("symbol layers and pre-clustered tiles build donut layers", {
  m <- maplibre() |>
    add_symbol_layer(
      "s",
      donut_points(),
      text_field = get_column("race"),
      cluster_options = cluster_options(
        donut_column = "race",
        donut_values = c("White", "Black"),
        donut_colors = c("red", "blue")
      )
    )
  expect_equal(find_layer(m, "s-clusters")$type, "symbol")
  expect_equal(find_layer(m, "s")$type, "symbol")
  expect_length(m$x$sources[[1]]$clusterProperties, 2)

  m <- maplibre() |>
    add_circle_layer(
      "t",
      "tiles",
      source_layer = "pts",
      cluster_options = cluster_options(
        donut_column = "race",
        donut_values = c("White", "Black"),
        donut_colors = c("red", "blue")
      )
    )
  expect_length(m$x$sources, 0)
  clusters <- find_layer(m, "t-clusters")
  expect_equal(clusters$source_layer, "pts")
  expect_match(
    to_json(clusters$layout[["icon-image"]]),
    '["coalesce",["get","race:White"],0]',
    fixed = TRUE
  )
})

test_that("slot, before_id, and zoom range reach all cluster layers", {
  m <- mapboxgl() |>
    add_circle_layer(
      "p",
      donut_points(),
      circle_color = race_colors(),
      slot = "top",
      before_id = "labels",
      min_zoom = 3,
      max_zoom = 12,
      cluster_options = cluster_options(donut_column = "race")
    )
  for (layer in m$x$layers) {
    expect_equal(layer$slot, "top")
    expect_equal(layer$before_id, "labels")
    expect_equal(layer$minzoom, 3)
    expect_equal(layer$maxzoom, 12)
  }
})

test_that("proxy messages carry cluster properties, paint, and metadata", {
  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- message$message
    }
  )
  proxy <- structure(
    list(id = "map", session = session),
    class = "maplibre_proxy"
  )
  add_circle_layer(
    proxy,
    "p",
    donut_points(),
    circle_color = race_colors(),
    cluster_options = cluster_options(
      donut_column = "race",
      circle_opacity = 0.7
    )
  )
  types <- vapply(messages, `[[`, "", "type")
  expect_equal(types, c("add_source", "add_layer", "add_layer", "add_layer"))
  expect_named(
    messages[[1]]$source$clusterProperties,
    c("race:White", "race:Black", "race:Hispanic", "race:_other")
  )
  clusters <- messages[[2]]$layer
  expect_equal(clusters$paint[["icon-opacity"]], 0.7)
  expect_false(is.null(clusters$layout[["icon-image"]]))
  expect_false(is.null(clusters$metadata[["mapgl:donut"]]$fp))

  # circle clusters now send their optional paint with the layer
  messages <- list()
  add_circle_layer(
    proxy,
    "q",
    donut_points(),
    cluster_options = cluster_options(circle_stroke_width = 2)
  )
  expect_equal(messages[[2]]$layer$paint[["circle-stroke-width"]], 2)
})

test_that("donut clusters default to a wider cluster radius", {
  expect_equal(cluster_options()$cluster_radius, 50)
  expect_equal(cluster_options(donut_column = "race")$cluster_radius, 60)
  expect_equal(
    cluster_options(donut_column = "race", radius_stops = c(10, 20))$cluster_radius,
    30
  )
  expect_equal(
    cluster_options(donut_column = "race", cluster_radius = 45)$cluster_radius,
    45
  )
})

test_that("abbreviated cluster labels switch to millions", {
  m <- maplibre() |>
    add_circle_layer("p", donut_points(), cluster_options = cluster_options())
  label <- find_layer(m, "p-cluster-count")$layout[["text-field"]]
  json <- to_json(label)
  expect_false(grepl("point_count_abbreviated", json, fixed = TRUE))
  expect_match(json, '[">=",["get","point_count"],999500]', fixed = TRUE)
  expect_match(json, '"M"]', fixed = TRUE)
})

test_that("weighted labels keep decimals", {
  build <- function(format) {
    m <- maplibre() |>
      add_circle_layer(
        "p",
        donut_points(),
        circle_color = race_colors(),
        cluster_options = cluster_options(
          donut_column = "race",
          donut_weight = "pop",
          count_format = format
        )
      )
    to_json(find_layer(m, "p-cluster-count")$layout[["text-field"]])
  }
  expect_equal(
    build("raw"),
    '["to-string",["coalesce",["get","race:_total"],0]]'
  )
  expect_false(grepl('["round",["coalesce"', build("grouped"), fixed = TRUE))
  expect_false(grepl('["round",["coalesce"', build("abbreviated"), fixed = TRUE))
})

test_that("explicit grouped donut_values expand their colors", {
  m <- maplibre() |>
    add_circle_layer(
      "p",
      donut_points(),
      cluster_options = cluster_options(
        donut_column = "race",
        donut_values = list(c("White", "Black"), "Hispanic"),
        donut_colors = c("red", "blue")
      )
    )
  expect_named(
    m$x$sources[[1]]$clusterProperties,
    c("race:White", "race:Black", "race:Hispanic")
  )
  spec <- find_layer(m, "p-clusters")$metadata[["mapgl:donut"]]
  expect_equal(unlist(spec$colors), c("#FF0000", "#FF0000", "#0000FF"))
  expect_error(
    cluster_options(
      donut_column = "race",
      donut_values = list(c("White", "Black"), "Hispanic"),
      donut_colors = c("red", "blue", "green")
    ),
    "same length"
  )
})


test_that("cluster labels round across million and billion boundaries", {
  node <- Sys.which("node")
  skip_if(node == "", "node is not available")
  lib <- system.file("htmlwidgets/lib/mapgl-expressions/mapgl-expressions.js",
    package = "mapgl")
  script <- tempfile(fileext = ".js")
  on.exit(unlink(script), add = TRUE)
  counts <- c(42, 1200, 999499, 999500, 999499999, 999500000,
    1470295708, 9949999999, 9950000000)
  writeLines(c(
    paste0("require(", jsonlite::toJSON(lib, auto_unbox = TRUE), ");"),
    paste0("const expr = ", jsonlite::toJSON(.cluster_count_label_expr(), auto_unbox = TRUE), ";"),
    paste0("const counts = ", jsonlite::toJSON(counts, digits = NA), ";"),
    "console.log(JSON.stringify(counts.map(point_count =>",
    "  globalThis._mapglEvaluateExpression(expr, {point_count}))));"
  ), script)
  labels <- jsonlite::fromJSON(system2(node, shQuote(script), stdout = TRUE))
  expect_equal(labels, c("42", "1.2k", "999k", "1M", "999M", "1B", "1.5B", "9.9B", "10B"))
})
