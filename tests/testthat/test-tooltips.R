test_that("tooltip_style() builds a spec and presets/overrides resolve", {
  s <- tooltip_style("dark", border_radius = 10)
  expect_s3_class(s, "mapgl_tooltip_style")
  expect_equal(s$preset, "dark")
  expect_equal(s$border_radius, 10)

  # popup_style() is an alias producing the same class
  expect_s3_class(popup_style("light"), "mapgl_tooltip_style")

  # Resolution: preset fills the base, overrides win
  resolved <- mapgl_normalize_tooltip_style(tooltip_style("dark", border_radius = 10))
  expect_equal(resolved$background_color, "rgba(35, 35, 35, 0.94)")
  expect_equal(resolved$border_radius, 10)

  # A bare preset string resolves too
  light <- mapgl_normalize_tooltip_style("light")
  expect_equal(light$text_color, "#222222")

  # "auto" resolves against dark_mode
  expect_equal(
    mapgl_normalize_tooltip_style("auto", dark_mode = TRUE)$background_color,
    "rgba(35, 35, 35, 0.94)"
  )
  expect_equal(
    mapgl_normalize_tooltip_style("auto", dark_mode = FALSE)$background_color,
    "rgba(255, 255, 255, 0.96)"
  )

  # NULL -> NULL (no styling)
  expect_null(mapgl_normalize_tooltip_style(NULL))

  # Custom-only (no preset) keeps just the overrides
  custom <- mapgl_normalize_tooltip_style(
    tooltip_style(background_color = "navy", text_color = "white")
  )
  expect_equal(custom, list(background_color = "navy", text_color = "white"))

  # Invalid input errors clearly
  expect_error(mapgl_normalize_tooltip_style(42), "preset string")
  expect_error(tooltip_style("sepia"), "should be one of")
})

test_that("layer tooltip/popup content and style serialize", {
  pts <- data.frame(lon = 0, lat = 0, name = "x", value = 1)
  pts <- sf::st_as_sf(pts, coords = c("lon", "lat"), crs = 4326)

  m <- maplibre() |>
    add_circle_layer(
      id = "c",
      source = pts,
      tooltip = "{name}: {value}",
      tooltip_style = "dark",
      popup = "name",
      popup_style = tooltip_style(background_color = "navy")
    )
  layer <- m$x$layers[[1]]

  # Content travels through untouched (the JS resolver handles it).
  expect_equal(layer$tooltip, "{name}: {value}")
  expect_equal(layer$popup, "name")

  # Style is normalized to a serialized spec.
  expect_equal(layer$tooltip_style$background_color, "rgba(35, 35, 35, 0.94)")
  expect_equal(layer$popup_style$background_color, "navy")
})

test_that("an expression tooltip serializes as an expression", {
  pts <- sf::st_as_sf(
    data.frame(lon = 0, lat = 0, value = 1000),
    coords = c("lon", "lat"),
    crs = 4326
  )
  m <- maplibre() |>
    add_circle_layer(
      id = "c",
      source = pts,
      tooltip = concat("Value: ", number_format("value"))
    )
  tt <- m$x$layers[[1]]$tooltip
  expect_true(is.list(tt))
  expect_equal(tt[[1]], "concat")
})

test_that("omitting tooltip_style leaves layers unchanged (opt-in)", {
  pts <- sf::st_as_sf(
    data.frame(lon = 0, lat = 0, name = "x"),
    coords = c("lon", "lat"),
    crs = 4326
  )
  m <- maplibre() |>
    add_circle_layer(id = "c", source = pts, tooltip = "name")
  layer <- m$x$layers[[1]]
  expect_null(layer$tooltip_style)
  expect_null(layer$popup_style)
  # Content path is untouched
  expect_equal(layer$tooltip, "name")
})

test_that("conditional expression builders emit the expected structures", {
  e <- if_else_expr(has_column("x"), "yes", "no")
  expect_equal(e, list("case", list("has", "x"), "yes", "no"))

  # no supplied -> empty-string fallback
  expect_equal(if_else_expr(has_column("x"), "yes")[[4]], "")

  ce <- case_expr(
    list("==", get_column("a"), 1), "one",
    list("==", get_column("a"), 2), "two",
    default = "other"
  )
  expect_equal(ce[[1]], "case")
  expect_length(ce, 6)
  expect_equal(ce[[6]], "other")

  # default is required but may be NULL (serializes to JSON null)
  ce_null <- case_expr(list("has", "a"), "present", default = NULL)
  expect_length(ce_null, 4)
  expect_null(ce_null[[4]])

  expect_error(case_expr(default = "x"), "condition/output pairs")
  expect_error(case_expr(list("has", "a"), default = "x"), "condition/output pairs")
  expect_error(case_expr(list("has", "a"), "out"), "`default` is required")

  co <- coalesce_expr(get_column("a"), get_column("b"), "fallback")
  expect_equal(co[[1]], "coalesce")
  expect_length(co, 4)
  expect_error(coalesce_expr(), "at least one argument")

  expect_equal(has_column("x"), list("has", "x"))

  blank <- is_blank("addr")
  expect_equal(blank[[1]], "any")
  expect_equal(blank[[2]], list("!", list("has", "addr")))
  # the null comparison keeps its NULL (serializes to JSON null)
  expect_length(blank[[3]], 3)
  expect_null(blank[[3]][[3]])
  expect_equal(blank[[4]], list("==", list("get", "addr"), ""))

  expect_equal(
    html_escape_expr(get_column("x")),
    list("mapgl-html-escape", list("get", "x"))
  )

  # nested expressions and NULLs survive JSON serialization
  json <- jsonlite::toJSON(blank, auto_unbox = TRUE, null = "null")
  expect_match(as.character(json), '["==",["get","addr"],null]', fixed = TRUE)
})

test_that("a conditional popup travels untouched into the layer payload", {
  pts <- sf::st_as_sf(
    data.frame(lon = 0, lat = 0, name = "x"),
    coords = c("lon", "lat"),
    crs = 4326
  )
  popup <- concat(
    "<strong>", get_column("name"), "</strong>",
    if_else_expr(is_blank("addr"), "Address not available", get_column("addr"))
  )
  m <- maplibre() |>
    add_circle_layer(id = "c", source = pts, popup = popup)
  expect_identical(m$x$layers[[1]]$popup, popup)
})

test_that("hex trimming only touches genuine 8-digit hex colors", {
  # viridisLite-style alpha hex is trimmed
  expect_equal(mapgl:::trim_hex_colors("#440154FF"), "#440154")
  expect_equal(
    mapgl:::trim_hex_colors(c("#440154FF", "#21918c")),
    c("#440154", "#21918c")
  )
  # 9-character text starting with # is preserved
  expect_equal(mapgl:::trim_hex_colors("#Missing!"), "#Missing!")
  # NULL and non-character values pass through
  expect_null(mapgl:::trim_hex_colors(NULL))
  expect_equal(mapgl:::trim_hex_colors(5), 5)
  # list stops: scalar strings trimmed, expression lists untouched
  stops <- list("#440154FF", concat("a", "b"), "text")
  trimmed <- mapgl:::trim_hex_colors(stops)
  expect_equal(trimmed[[1]], "#440154")
  expect_equal(trimmed[[2]], concat("a", "b"))
  expect_equal(trimmed[[3]], "text")
})

test_that("match_expr accepts expression stops and defaults for popups", {
  e <- match_expr(
    column = "county",
    values = "HUDSPETH",
    stops = list("Value not reported"),
    default = concat("Total value: $", number_format("total_value"))
  )
  expect_equal(e[[1]], "match")
  expect_equal(e[[3]], "HUDSPETH")
  expect_equal(e[[4]], "Value not reported")
  expect_equal(e[[5]][[1]], "concat")
})

test_that("every local evaluateExpression copy delegates to the shared evaluator", {
  js_dir <- system.file("htmlwidgets", package = "mapgl")
  delegation_count <- function(file) {
    src <- readLines(file.path(js_dir, file), warn = FALSE)
    sum(grepl("window._mapglEvaluateExpression(expression, properties)", src, fixed = TRUE))
  }
  expect_equal(delegation_count("maplibregl.js"), 1)
  expect_equal(delegation_count("mapboxgl.js"), 1)
  expect_equal(delegation_count("mapboxgl_compare.js"), 1)
  # top-of-file copy plus the nested shadow copy in the modification handler
  expect_equal(delegation_count("maplibregl_compare.js"), 2)
  expect_equal(delegation_count("flowmap.js"), 1)
  # the shared lib itself ships
  expect_true(file.exists(
    file.path(js_dir, "lib", "mapgl-expressions", "mapgl-expressions.js")
  ))
})

test_that("the expression evaluator honors the GL operator contract (Node, DOM-free)", {
  node <- Sys.which("node")
  skip_if(node == "", "node is not available")

  lib <- system.file(
    "htmlwidgets/lib/mapgl-expressions/mapgl-expressions.js",
    package = "mapgl"
  )
  expect_true(file.exists(lib))

  script <- tempfile(fileext = ".js")
  writeLines(c(
    "const warnings = [];",
    "console.warn = (m) => warnings.push(String(m));",
    paste0("require(", jsonlite::toJSON(lib, auto_unbox = TRUE), ");"),
    "const ev = globalThis._mapglEvaluateExpression;",
    "const out = {};",
    "",
    "// ---- lazy conditionals produce no warnings for unselected branches ----",
    "out.caseFirst = ev(['case', ['==', ['get','x'], 1], 'one', ['bogus-op']], {x: 1});",
    "out.lazyNumberFormat = ev(['case', ['==', ['get','x'], 1], 'ok',",
    "  ['number-format', ['get','v'], {style: 'currency'}]], {x: 1});",
    "out.anyShortCircuit = ev(['any', ['==', ['get','x'], 1], ['bogus-op']], {x: 1});",
    "out.warnCountAfterLazy = warnings.length;",
    "",
    "// ---- GL type semantics ----",
    "out.mixedCompare = ev(['>', '10', 2], {});            // type error -> ''",
    "out.mixedCompareAgain = ev(['>', '10', 2], {});       // warn-once",
    "out.warnCountAfterMixed = warnings.length;",
    "out.stringCompare = ev(['>', 'b', 'a'], {});",
    "out.numberCompare = ev(['>', 3, 2], {});",
    "out.gtMissing = ev(['>', ['get','m'], 5], {});        // null-safe false",
    "out.mathStringOperand = ev(['+', ['get','s'], 1], {s: '5'});   // no coercion -> ''",
    "out.mathExplicitConvert = ev(['+', ['to-number', ['get','s']], 1], {s: '5'});",
    "",
    "// ---- to-number: fallbacks and finiteness ----",
    "out.toNumberFallbackUnused = ev(['to-number', '5', 0], {});",
    "out.toNumberFallbackUsed = ev(['to-number', 'bad', 0], {});",
    "out.toNumberAllBad = ev(['to-number', 'bad'], {});",
    "out.toNumberOverflow = ev(['to-number', '1e999'], {});",
    "out.toNumberOverflowFallback = ev(['to-number', '1e999', 7], {});",
    "out.interpOverflow = ev(['interpolate', ['linear'], ['get','v'],",
    "  0, -1e308, 1, 1e308], {v: 0.5});",
    "out.nonBoolCondition = ev(['case', ['get','n'], 'a', 'b'], {n: 1});",
    "out.notNonBool = ev(['!', ['get','s']], {s: 'x'});",
    "",
    "// ---- non-finite arithmetic fails soft ----",
    "out.divByZero = ev(['/', 1, 0], {});",
    "out.plusMissing = ev(['+', ['get','missing'], 1], {});",
    "",
    "// ---- rounding away from zero ----",
    "out.roundNegHalf = ev(['round', -1.5], {});",
    "out.roundPosHalf = ev(['round', 2.5], {});",
    "out.roundPlain = ev(['round', 2.4], {});",
    "",
    "// ---- malformed known operators ----",
    "out.malformedCase = ev(['case', ['==', 1, 1], 'out'], {});",
    "out.malformedMatch = ev(['match', ['get','x'], 'a', 'b'], {x: 'a'});",
    "out.badExponentialBase = ev(",
    "  ['interpolate', ['exponential', '2'], ['get','v'], 0, 0, 4, 100], {v: 2});",
    "out.badStops = ev(['interpolate', ['linear'], ['get','v'], 10, 0, 5, 100], {v: 7});",
    "out.bezier = ev(['interpolate', ['cubic-bezier', 0.4, 0, 0.6, 1],",
    "  ['get','v'], 0, 0, 10, 100], {v: 5});",
    "out.textInterpOutput = ev(",
    "  ['interpolate', ['linear'], ['get','v'], 0, 'red', 10, 'blue'], {v: 5});",
    "",
    "// ---- ramps ----",
    "out.interpLinear = ev(['interpolate', ['linear'], ['get','v'], 0, 0, 10, 100], {v: 5});",
    "out.interpExp = ev(['interpolate', ['exponential', 2], ['get','v'], 0, 0, 4, 100], {v: 2});",
    "out.interpClampLow = ev(['interpolate', ['linear'], ['get','v'], 0, 0, 10, 100], {v: -5});",
    "out.interpClampHigh = ev(['interpolate', ['linear'], ['get','v'], 0, 0, 10, 100], {v: 50});",
    "out.stepBelow = ev(['step', ['get','v'], 'base', 10, 'ten'], {v: 9.99});",
    "out.stepAt = ev(['step', ['get','v'], 'base', 10, 'ten'], {v: 10});",
    "out.stepStringStop = ev(['step', 10, 'base', '10', 'ten'], {});",
    "out.stepBadOrder = ev(['step', 7, 'base', 10, 'ten', 5, 'five'], {});",
    "",
    "// ---- math arity ----",
    "out.minusExtraArg = ev(['-', 10, 3, 2], {});",
    "out.minNoArgs = ev(['min'], {});",
    "out.minOneArg = ev(['min', 5], {});",
    "",
    "// ---- Unicode code-point string semantics ----",
    "out.emojiLength = ev(['length', ['get','s']], {s: '\\u{1F600}'});",
    "out.emojiIndexOf = ev(['index-of', 'a', ['get','s']], {s: '\\u{1F600}a'});",
    "// transport code points, not raw emoji, so stdout is locale-independent",
    "out.emojiSliceCp = ev(['slice', ['get','s'], 0, 1], {s: '\\u{1F600}a'}).codePointAt(0);",
    "out.emojiSliceLen = Array.from(ev(['slice', ['get','s'], 0, 1], {s: '\\u{1F600}a'})).length;",
    "out.fromIndex = ev(['index-of', 'a', 'baaa', 2], {});",
    "out.inEmoji = ev(['in', '\\u{1F600}', ['get','s']], {s: 'x\\u{1F600}y'});",
    "",
    "// ---- match / coalesce / equality ----",
    "out.matchArray = ev(['match', ['get','c'], ['a','b'], 'AB', 'other'], {c: 'b'});",
    "out.matchStrict = ev(['match', ['get','n'], 1, 'one', 'fb'], {n: '1'});",
    "out.coalesceZero = ev(['coalesce', ['get','z'], 'fb'], {z: 0});",
    "out.coalesceFalse = ev(['coalesce', ['get','z'], 'fb'], {z: false});",
    "out.coalesceEmpty = ev(['coalesce', ['get','z'], 'fb'], {z: ''});",
    "out.coalesceMissing = ev(['coalesce', ['get','z'], 'fb'], {});",
    "out.eqNull = ev(['==', ['get','m'], null], {});",
    "out.eqTyped = ev(['==', ['get','n'], '1'], {n: 1});",
    "",
    "// ---- html escaping of untrusted values ----",
    "out.escMissing = ev(['mapgl-html-escape', ['get','h']], {});",
    "out.escNull = ev(['mapgl-html-escape', ['get','h']], {h: null});",
    "out.escZero = ev(['mapgl-html-escape', ['get','h']], {h: 0});",
    "out.escFalse = ev(['mapgl-html-escape', ['get','h']], {h: false});",
    "out.escEmpty = ev(['mapgl-html-escape', ['get','h']], {h: ''});",
    "out.escMarkup = ev(['mapgl-html-escape', ['get','h']], {h: '<b>&</b>'});",
    "",
    "// ---- misc operators ----",
    "out.literalArr = ev(['literal', [1, 2]], {});",
    "out.minMax = ev(['max', 1, ['min', 5, 3]], {});",
    "out.absFloorCeil = ev(['abs', ['-', ['floor', 2.7], ['ceil', 5.2]]], {});",
    "out.mod = ev(['%', 7, 3], {});",
    "out.pow = ev(['^', 2, 10], {});",
    "out.upcase = ev(['upcase', 'abc'], {});",
    "out.downcase = ev(['downcase', 'ABC'], {});",
    "",
    "// ---- legacy operators ----",
    "out.legacyConcat = ev(['concat', 'v: ', ['get','v']], {v: 7});",
    "out.legacyFormat = ev(['number-format', ['get','v'], {'max-fraction-digits': 0}], {v: 1234.6});",
    "out.badFormat = ev(['number-format', ['get','v'], {style: 'currency'}], {v: 5});",
    "",
    "// ---- malformed-form matrix: every entry must render '' with a warning ----",
    "const malformed = [",
    "  ['get'], ['get', 'a', 'b'],",
    "  ['has'],",
    "  ['concat'],",
    "  ['to-string'],",
    "  ['to-number'], ['to-number', 'nope'],",
    "  ['number-format'],",
    "  ['case', ['==', 1, 1], 'out'],   // no fallback",
    "  ['case', ['==', 1, 1]],          // too few args",
    "  ['match', ['get','x'], 'a', 'b'],// no fallback",
    "  ['coalesce'],",
    "  ['all'], ['any'],",
    "  ['!'], ['!', true, false],",
    "  ['=='], ['==', 1], ['==', 1, 2, 3],",
    "  ['>'], ['>', 1],",
    "  ['in', 'a'],",
    "  ['index-of', 'a'], ['index-of', 'a', 'abc', 1, 2],",
    "  ['length'], ['length', 'abc', 'extra'],",
    "  ['slice', 'abc'],",
    "  ['step', 2, 'base'],             // zero stop pairs",
    "  ['step', 2, 'base', 10],         // dangling stop",
    "  ['interpolate', ['linear'], 5],  // zero stop pairs",
    "  ['+'], ['+', 1],",
    "  ['-'], ['-', 10, 3, 2],",
    "  ['/'], ['/', 1], ['/', 1, 2, 3],",
    "  ['%', 1], ['^', 1],",
    "  ['abs'], ['abs', 1, 2],",
    "  ['round'], ['floor'], ['ceil'],",
    "  ['min'], ['min', 5], ['max'], ['max', 5],",
    "  ['upcase'], ['upcase', 'a', 'b'],",
    "  ['downcase'],",
    "  ['literal'],",
    "  ['mapgl-html-escape']",
    "];",
    "out.malformedResults = malformed.map((e) => ev(e, {}));",
    "",
    "// ---- unknown operator warns once ----",
    "const before = warnings.length;",
    "out.unknownOp = ev(['frobnicate', 1], {});",
    "out.unknownOpAgain = ev(['frobnicate', 1], {});",
    "out.unknownWarnCount = warnings.length - before;",
    "",
    "out.warnings = warnings;",
    "console.log(JSON.stringify(out));"
  ), script)

  raw <- system2(node, shQuote(script), stdout = TRUE, stderr = TRUE)
  results <- jsonlite::fromJSON(raw[length(raw)], simplifyVector = TRUE)

  # lazy branches never touched
  expect_equal(results$caseFirst, "one")
  expect_equal(results$lazyNumberFormat, "ok")
  expect_true(results$anyShortCircuit)
  expect_equal(results$warnCountAfterLazy, 0)

  # GL type semantics
  expect_equal(results$mixedCompare, "")
  expect_equal(results$mixedCompareAgain, "")
  expect_equal(results$warnCountAfterMixed, 1) # warn-once
  expect_true(results$stringCompare)
  expect_true(results$numberCompare)
  expect_false(results$gtMissing)
  expect_equal(results$mathStringOperand, "")
  expect_equal(results$mathExplicitConvert, 6)

  # to-number: GL fallback semantics and finite-only conversions
  expect_equal(results$toNumberFallbackUnused, 5)
  expect_equal(results$toNumberFallbackUsed, 0)
  expect_equal(results$toNumberAllBad, "")
  expect_equal(results$toNumberOverflow, "")
  expect_equal(results$toNumberOverflowFallback, 7)
  expect_equal(results$interpOverflow, "")
  expect_equal(results$nonBoolCondition, "")
  expect_equal(results$notNonBool, "")

  # non-finite arithmetic fails soft
  expect_equal(results$divByZero, "")
  expect_equal(results$plusMissing, "")

  # rounding away from zero
  expect_equal(results$roundNegHalf, -2)
  expect_equal(results$roundPosHalf, 3)
  expect_equal(results$roundPlain, 2)

  # malformed known operators fail soft
  expect_equal(results$malformedCase, "")
  expect_equal(results$malformedMatch, "")
  expect_equal(results$badExponentialBase, "")
  expect_equal(results$badStops, "")
  expect_equal(results$bezier, "")
  expect_equal(results$textInterpOutput, "")

  # ramps
  expect_equal(results$interpLinear, 50)
  expect_equal(results$interpExp, 20)
  expect_equal(results$interpClampLow, 0)
  expect_equal(results$interpClampHigh, 100)
  expect_equal(results$stepBelow, "base")
  expect_equal(results$stepAt, "ten")
  expect_equal(results$stepStringStop, "")
  expect_equal(results$stepBadOrder, "")

  # math arity is enforced
  expect_equal(results$minusExtraArg, "")
  expect_equal(results$minNoArgs, "")
  expect_equal(results$minOneArg, "")

  # Unicode code-point semantics (compared as code points, locale-independent)
  expect_equal(results$emojiLength, 1)
  expect_equal(results$emojiIndexOf, 1)
  expect_equal(results$emojiSliceCp, 128512)
  expect_equal(results$emojiSliceLen, 1)
  expect_equal(results$fromIndex, 2)
  expect_true(results$inEmoji)

  # match / coalesce / equality
  expect_equal(results$matchArray, "AB")
  expect_equal(results$matchStrict, "fb")
  expect_equal(results$coalesceZero, 0)
  expect_false(results$coalesceFalse)
  expect_equal(results$coalesceEmpty, "")
  expect_equal(results$coalesceMissing, "fb")
  expect_true(results$eqNull)
  expect_false(results$eqTyped)

  # html escaping: no-value renders as "", present values stringify + escape
  expect_equal(results$escMissing, "")
  expect_equal(results$escNull, "")
  expect_equal(results$escZero, "0")
  expect_equal(results$escFalse, "false")
  expect_equal(results$escEmpty, "")
  expect_equal(results$escMarkup, "&lt;b&gt;&amp;&lt;/b&gt;")

  # misc + legacy
  expect_equal(results$literalArr, c(1, 2))
  expect_equal(results$minMax, 3)
  expect_equal(results$absFloorCeil, 4)
  expect_equal(results$mod, 1)
  expect_equal(results$pow, 1024)
  expect_equal(results$upcase, "ABC")
  expect_equal(results$downcase, "abc")
  expect_equal(results$legacyConcat, "v: 7")
  expect_equal(results$legacyFormat, "1,235")
  expect_equal(results$badFormat, "")

  # every malformed form renders "" (with a warning; each failure is
  # tracked warn-once per operator)
  expect_true(all(results$malformedResults == ""))

  # unknown operator warns exactly once and renders ""
  expect_equal(results$unknownOp, "")
  expect_equal(results$unknownOpAgain, "")
  expect_equal(results$unknownWarnCount, 1)
  expect_true(any(grepl("frobnicate", results$warnings)))
})

test_that("the shipped expression evaluator implements the operator contract", {
  skip_on_cran()
  skip_if_not_installed("chromote")

  blank_style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list(list(
      id = "bg",
      type = "background",
      paint = list(`background-color` = "#dddddd")
    ))
  )
  m <- maplibre(style = blank_style, center = c(0, 0), zoom = 2)

  dir <- tempfile("mapgl-expr-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) skip("chromote could not start a browser")
  on.exit(b$close(), add = TRUE)

  js_value <- function(expr) {
    out <- b$Runtime$evaluate(
      paste0("JSON.stringify((function() {", expr, "})())"),
      returnByValue = TRUE
    )
    value <- out$result$value
    if (is.null(value) || identical(value, "null")) {
      return(NULL)
    }
    jsonlite::fromJSON(value, simplifyVector = TRUE)
  }
  wait_for <- function(expr, timeout = 30) {
    deadline <- Sys.time() + timeout
    repeat {
      result <- tryCatch(js_value(expr), error = function(e) NULL)
      if (isTRUE(result)) return(invisible(TRUE))
      if (Sys.time() > deadline) return(FALSE)
      Sys.sleep(0.25)
    }
  }

  b$Page$navigate(paste0("file://", html_file))
  if (!wait_for("return !!window._mapglEvaluateExpression;", timeout = 15)) {
    skip("Widget page failed to load the shared evaluator")
  }

  # Evaluate a batch of [expression, properties, expected-description] fixtures
  # in one round trip; each returns the evaluator's actual result
  results <- js_value(
    "var ev = window._mapglEvaluateExpression;
     var out = {};

     // conditionals + laziness (bogus operators in unselected branches are
     // never evaluated, so no warning and no effect)
     out.caseFirst = ev(['case', ['==', ['get','x'], 1], 'one', ['bogus-op']], {x: 1});
     out.caseFallback = ev(['case', ['==', ['get','x'], 1], 'one', 'other'], {x: 2});
     out.lazyNumberFormat = ev(
       ['case', ['==', ['get','x'], 1], 'ok',
        ['number-format', ['get','v'], {style: 'currency'}]], {x: 1});

     // match: strict typed equality + array labels + fallback
     out.matchArray = ev(['match', ['get','c'], ['a','b'], 'AB', 'other'], {c: 'b'});
     out.matchStrict = ev(['match', ['get','n'], 1, 'one', 'fb'], {n: '1'});
     out.matchHit = ev(['match', ['get','n'], 1, 'one', 'fb'], {n: 1});

     // coalesce keeps 0, false, and ''
     out.coalesceZero = ev(['coalesce', ['get','z'], 'fb'], {z: 0});
     out.coalesceFalse = ev(['coalesce', ['get','z'], 'fb'], {z: false});
     out.coalesceEmpty = ev(['coalesce', ['get','z'], 'fb'], {z: ''});
     out.coalesceMissing = ev(['coalesce', ['get','z'], 'fb'], {});

     // null-safe comparisons
     out.gtMissing = ev(['>', ['get','m'], 5], {});
     out.eqNull = ev(['==', ['get','m'], null], {});
     out.eqTyped = ev(['==', ['get','n'], '1'], {n: 1});

     // is_blank shape (as emitted by R)
     var blank = function(props) {
       return ev(['any', ['!', ['has','c']],
                  ['==', ['get','c'], null], ['==', ['get','c'], '']], props);
     };
     out.blankMissing = blank({});
     out.blankNull = blank({c: null});
     out.blankEmpty = blank({c: ''});
     out.blankZero = blank({c: 0});
     out.blankFalse = blank({c: false});
     out.blankValue = blank({c: 'x'});

     // step boundaries (input >= stop takes the stop's output)
     out.stepBelow = ev(['step', ['get','v'], 'base', 10, 'ten'], {v: 9.99});
     out.stepAt = ev(['step', ['get','v'], 'base', 10, 'ten'], {v: 10});

     // interpolate: linear midpoint, exponential factor, clamping,
     // cubic-bezier and bad stops -> ''
     out.interpLinear = ev(['interpolate', ['linear'], ['get','v'], 0, 0, 10, 100], {v: 5});
     out.interpExp = ev(['interpolate', ['exponential', 2], ['get','v'], 0, 0, 4, 100], {v: 2});
     out.interpClampLow = ev(['interpolate', ['linear'], ['get','v'], 0, 0, 10, 100], {v: -5});
     out.interpClampHigh = ev(['interpolate', ['linear'], ['get','v'], 0, 0, 10, 100], {v: 50});
     out.interpBezier = ev(['interpolate', ['cubic-bezier', 0.4, 0, 0.6, 1], ['get','v'], 0, 0, 10, 100], {v: 5});
     out.interpBadStops = ev(['interpolate', ['linear'], ['get','v'], 10, 0, 5, 100], {v: 7});

     // math, strings, lookup
     out.math = ev(['round', ['/', ['get','v'], 3]], {v: 10});
     out.upcase = ev(['upcase', ['get','s']], {s: 'abc'});
     out.inString = ev(['in', 'b', ['get','s']], {s: 'abc'});
     out.lengthOf = ev(['length', ['get','s']], {s: 'abc'});

     // escaping helper
     out.escaped = ev(['mapgl-html-escape', ['get','h']], {h: '<b>&</b>'});

     // legacy operators unchanged
     out.legacyConcat = ev(['concat', 'v: ', ['get','v']], {v: 7});
     out.legacyFormat = ev(['number-format', ['get','v'], {'max-fraction-digits': 0}], {v: 1234.6});

     // failures are soft: unknown op and invalid Intl config yield ''
     out.unknownOp = ev(['frobnicate', 1], {});
     out.unknownOpAgain = ev(['frobnicate', 1], {});
     out.badFormat = ev(['number-format', ['get','v'], {style: 'currency'}], {v: 5});

     // prototype keys are not leaked by get/has
     out.protoGet = ev(['get', 'constructor'], {}) === undefined ? 'undef' : 'leak';
     out.protoHas = ev(['has', 'constructor'], {});

     return out;"
  )

  expect_equal(results$caseFirst, "one")
  expect_equal(results$caseFallback, "other")
  expect_equal(results$lazyNumberFormat, "ok")

  expect_equal(results$matchArray, "AB")
  expect_equal(results$matchStrict, "fb")
  expect_equal(results$matchHit, "one")

  expect_equal(results$coalesceZero, 0)
  expect_false(results$coalesceFalse)
  expect_equal(results$coalesceEmpty, "")
  expect_equal(results$coalesceMissing, "fb")

  expect_false(results$gtMissing)
  expect_true(results$eqNull)
  expect_false(results$eqTyped)

  expect_true(results$blankMissing)
  expect_true(results$blankNull)
  expect_true(results$blankEmpty)
  expect_false(results$blankZero)
  expect_false(results$blankFalse)
  expect_false(results$blankValue)

  expect_equal(results$stepBelow, "base")
  expect_equal(results$stepAt, "ten")

  expect_equal(results$interpLinear, 50)
  expect_equal(results$interpExp, 20)
  expect_equal(results$interpClampLow, 0)
  expect_equal(results$interpClampHigh, 100)
  expect_equal(results$interpBezier, "")
  expect_equal(results$interpBadStops, "")

  expect_equal(results$math, 3)
  expect_equal(results$upcase, "ABC")
  expect_true(results$inString)
  expect_equal(results$lengthOf, 3)

  expect_equal(results$escaped, "&lt;b&gt;&amp;&lt;/b&gt;")

  expect_equal(results$legacyConcat, "v: 7")
  expect_equal(results$legacyFormat, "1,235")

  expect_equal(results$unknownOp, "")
  expect_equal(results$unknownOpAgain, "")
  expect_equal(results$badFormat, "")

  expect_equal(results$protoGet, "undef")
  expect_false(results$protoHas)
})

test_that("a conditional popup renders through the real click path", {
  skip_on_cran()
  skip_if_not_installed("chromote")

  blank_style <- list(
    version = 8,
    sources = structure(list(), names = character(0)),
    layers = list(list(
      id = "bg",
      type = "background",
      paint = list(`background-color` = "#dddddd")
    ))
  )

  # One polygon covering the map center; addr is missing (NA -> null)
  poly <- sf::st_as_sf(
    data.frame(owner = "COLMENERO ELSA", addr = NA_character_),
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(
        c(-5, -5), c(5, -5), c(5, 5), c(-5, 5), c(-5, -5)
      ))),
      crs = 4326
    )
  )

  m <- maplibre(style = blank_style, center = c(0, 0), zoom = 3) |>
    add_fill_layer(
      id = "parcels",
      source = poly,
      fill_color = "#3b5bdb",
      popup = concat(
        "<strong>", get_column("owner"), "</strong><br>",
        if_else_expr(
          is_blank("addr"),
          "Address not available",
          get_column("addr")
        )
      )
    )

  dir <- tempfile("mapgl-popup-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  html_file <- file.path(dir, "map.html")
  htmlwidgets::saveWidget(m, html_file, selfcontained = FALSE)

  b <- tryCatch(chromote::ChromoteSession$new(), error = function(e) NULL)
  if (is.null(b)) skip("chromote could not start a browser")
  on.exit(b$close(), add = TRUE)

  js_value <- function(expr) {
    out <- b$Runtime$evaluate(
      paste0("JSON.stringify((function() {", expr, "})())"),
      returnByValue = TRUE
    )
    value <- out$result$value
    if (is.null(value) || identical(value, "null")) {
      return(NULL)
    }
    jsonlite::fromJSON(value, simplifyVector = TRUE)
  }
  wait_for <- function(expr, timeout = 30) {
    deadline <- Sys.time() + timeout
    repeat {
      result <- tryCatch(js_value(expr), error = function(e) NULL)
      if (isTRUE(result)) return(invisible(TRUE))
      if (Sys.time() > deadline) return(FALSE)
      Sys.sleep(0.25)
    }
  }

  b$Page$navigate(paste0("file://", html_file))
  if (
    !wait_for(
      "var c = document.createElement('canvas');
       return !!(c.getContext('webgl2') || c.getContext('webgl'));",
      timeout = 10
    )
  ) {
    skip("Headless browser does not support WebGL")
  }

  ready <- wait_for(
    "var w = window.HTMLWidgets && HTMLWidgets.find('.maplibregl');
     if (!w || !w.getMap) return false;
     var map = w.getMap();
     return !!(map && map.loaded() && map.getLayer('parcels'));"
  )
  if (!ready) skip("Map failed to initialize in the headless browser")

  # Spy on the shared evaluator so the click also proves the local
  # evaluateExpression stub delegates
  js_value(
    "var orig = window._mapglEvaluateExpression;
     window._mapglSpyCalls = 0;
     window._mapglEvaluateExpression = function (e, p) {
       window._mapglSpyCalls++;
       return orig(e, p);
     };
     return true;"
  )

  # Real click at the canvas center
  center <- js_value(
    "var rect = document.querySelector('.maplibregl canvas').getBoundingClientRect();
     return {x: Math.round(rect.left + rect.width / 2),
             y: Math.round(rect.top + rect.height / 2)};"
  )
  b$Input$dispatchMouseEvent(
    type = "mousePressed",
    x = center$x,
    y = center$y,
    button = "left",
    clickCount = 1
  )
  b$Input$dispatchMouseEvent(
    type = "mouseReleased",
    x = center$x,
    y = center$y,
    button = "left",
    clickCount = 1
  )

  shown <- wait_for(
    "var el = document.querySelector('.maplibregl-popup-content');
     return !!(el && el.innerHTML.indexOf('Address not available') !== -1);"
  )
  expect_true(shown)
  expect_true(js_value(
    "return document.querySelector('.maplibregl-popup-content')
       .innerHTML.indexOf('COLMENERO ELSA') !== -1;"
  ))
  expect_true(js_value("return window._mapglSpyCalls > 0;"))
})

test_that("set_tooltip()/set_popup() accept and serialize a style", {
  messages <- list()
  session <- list(
    sendCustomMessage = function(type, message) {
      messages[[length(messages) + 1]] <<- list(type = type, message = message)
    }
  )
  proxy <- structure(
    list(id = "map", session = session),
    class = "maplibre_proxy"
  )

  set_tooltip(proxy, "c", tooltip = "{name}", style = "dark")
  msg <- messages[[1]]$message$message
  expect_equal(msg$type, "set_tooltip")
  expect_equal(msg$tooltip, "{name}")
  expect_equal(msg$tooltip_style$background_color, "rgba(35, 35, 35, 0.94)")

  # No style -> NULL spec (native appearance, unchanged behavior)
  set_popup(proxy, "c", popup = "name")
  msg2 <- messages[[2]]$message$message
  expect_equal(msg2$type, "set_popup")
  expect_null(msg2$popup_style)
})
