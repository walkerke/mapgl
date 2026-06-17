test_that("as_time_property coerces each unit", {
  d <- as.Date(c("2020-01-15", "2022-06-30", "2024-12-31"))
  expect_equal(as_time_property(d, "year"), c(2020L, 2022L, 2024L))
  expect_equal(as_time_property(d, "month"), c(0L, 5L, 11L)) # zero-based
  expect_equal(as_time_property(d, "day"), c(15L, 30L, 31L))
  expect_equal(as_time_property(d, "date"), as.numeric(d))
})

test_that("as_time_property handles POSIXct, tz, and numeric passthrough", {
  # Non-UTC POSIXct: seconds must equal the true epoch seconds (no tz shift)
  ct <- as.POSIXct("2020-03-15 12:00:00", tz = "America/Chicago")
  expect_equal(as_time_property(ct, "seconds"), as.numeric(ct))
  expect_equal(as_time_property(ct, "year"), 2020L)

  # Numeric input only allowed for absolute units
  expect_equal(as_time_property(c(1, 2, 3), "seconds"), c(1, 2, 3))
  expect_equal(as_time_property(c(1, 2, 3), "date"), c(1, 2, 3))
  expect_error(as_time_property(c(1, 2), "year"), "seconds.*date|date.*seconds")
  expect_error(as_time_property(list(1), "year"), "Date, POSIXct, or numeric")
})

test_that("slider_style() builds, resolves, and serializes", {
  s <- slider_style("dark", accent_color = "#ffcc00", thumb_size = 18)
  expect_s3_class(s, "mapgl_slider_style")
  expect_equal(s$preset, "dark")
  expect_equal(s$accent_color, "#ffcc00")

  resolved <- mapgl_normalize_slider_style(s)
  expect_equal(resolved$background_color, "rgba(24, 30, 38, 0.92)")
  expect_equal(resolved$text_color, "#f3f4f6")
  expect_equal(resolved$accent_color, "#ffcc00")
  expect_equal(resolved$thumb_size, 18)

  custom <- mapgl_normalize_slider_style(
    slider_style(background_color = "navy", text_color = "white")
  )
  expect_equal(custom$background_color, "navy")
  expect_equal(custom$text_color, "white")
  expect_null(mapgl_normalize_slider_style(NULL))
  expect_error(mapgl_normalize_slider_style(42), "preset string")
  expect_error(slider_style("sepia"), "should be one of")

  w <- maplibre() |>
    add_slider_control(
      layers = "l",
      property = "t",
      values = 1:3,
      slider_style = s
    )
  expect_equal(w$x$slider_control$slider_style$background_color, "rgba(24, 30, 38, 0.92)")
  expect_equal(w$x$slider_control$slider_style$accent_color, "#ffcc00")
  expect_equal(w$x$slider_control$slider_style$thumb_size, 18)
})

test_that("omitting slider_style keeps legacy styling payload unchanged", {
  w <- maplibre() |>
    add_slider_control(
      layers = "l",
      property = "t",
      values = 1:3,
      width = 320,
      background_color = "#f8fafc",
      text_color = "#111827",
      accent_color = "#2563eb"
    )

  expect_null(w$x$slider_control$slider_style)
  expect_equal(w$x$slider_control$width, 320L)
  expect_equal(w$x$slider_control$background_color, "#f8fafc")
  expect_equal(w$x$slider_control$text_color, "#111827")
  expect_equal(w$x$slider_control$accent_color, "#2563eb")
})

test_that("slider auto-formats time labels from time_unit when labels are NULL", {
  # seconds -> formatted datetime (UTC), the inverse of as_time_property()
  secs <- as_time_property(
    as.POSIXct(c("2019-07-01 00:00", "2019-07-01 01:00"), tz = "UTC"),
    "seconds"
  )
  m <- maplibre() |>
    add_slider_control(
      layers = "x",
      property = "t",
      values = secs,
      time_unit = "seconds",
      mode = "window",
      window = 3600
    )
  expect_equal(
    unlist(m$x$slider$labels),
    c("2019-07-01 00:00", "2019-07-01 01:00")
  )

  # date -> ISO date
  dts <- as_time_property(as.Date(c("2020-01-01", "2020-06-15")), "date")
  m2 <- maplibre() |>
    add_slider_control(
      layers = "x",
      property = "d",
      values = dts,
      time_unit = "date",
      mode = "window",
      window = 30
    )
  expect_equal(unlist(m2$x$slider$labels), c("2020-01-01", "2020-06-15"))

  # No time_unit -> raw numeric labels (unchanged behavior)
  m3 <- maplibre() |>
    add_slider_control(layers = "x", property = "year", values = 2015:2017)
  expect_equal(unlist(m3$x$slider$labels), c("2015", "2016", "2017"))

  # Explicit labels always win over auto-formatting
  m4 <- maplibre() |>
    add_slider_control(
      layers = "x",
      property = "t",
      values = secs,
      time_unit = "seconds",
      labels = c("midnight", "1am"),
      mode = "window",
      window = 3600
    )
  expect_equal(unlist(m4$x$slider$labels), c("midnight", "1am"))
})

test_that("add_slider_control validates core args", {
  m <- maplibre()
  expect_error(
    add_slider_control(m, layers = character(0), property = "x", values = 1:3),
    "non-empty character"
  )
  # no effect configured (neither property nor paint)
  expect_error(
    add_slider_control(m, layers = "l", values = 1:3),
    "no effect configured"
  )
  # Date values rejected
  expect_error(
    add_slider_control(m, layers = "l", property = "t",
      values = as.Date(c("2020-01-01", "2021-01-01"))),
    "must be numeric"
  )
  # values from min/max
  w <- add_slider_control(m, layers = "l", property = "t", min = 0, max = 4, step = 2)
  expect_equal(unlist(w$x$slider_control$values), c(0, 2, 4))
  # initial_value must be a member
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3, initial_value = 9),
    "must be one of"
  )
  # position enum
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3, position = "middle"),
    "position"
  )
})

test_that("window mode validates correctly", {
  m <- maplibre()
  # window requires window mode
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3, window = 2),
    "only applies"
  )
  # window must be positive
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3,
      mode = "window", window = -1),
    "positive"
  )
  # window mode requires property
  expect_error(
    add_slider_control(m, layers = "l", values = 1:3, mode = "window",
      paint_property = "circle_color",
      paint_expressions = as.list(rep("red", 3))),
    "requires .property"
  )
  # serialization: window + time_unit carried; defaults end at last value
  w <- add_slider_control(m, layers = "l", property = "t", values = 2015:2024,
    mode = "window", window = 3, time_unit = "year")
  expect_equal(w$x$slider_control$mode, "window")
  expect_equal(w$x$slider_control$window, 3)
  expect_equal(w$x$slider_control$presentation, "compact")
  # auto window_behavior -> fixed when a window duration is supplied
  expect_equal(w$x$slider_control$window_behavior, "fixed")
  expect_equal(w$x$slider_control$time_unit, "year")
  expect_equal(w$x$slider_control$initial_index, 9L) # last value

  # window_behavior can be forced to a resizable two-edge range
  r <- add_slider_control(m, layers = "l", property = "t", values = 2015:2024,
    mode = "window", window = 3, window_behavior = "resizable")
  expect_equal(r$x$slider_control$window_behavior, "resizable")

  # fixed behavior needs window mode + a window duration
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3,
      window_behavior = "fixed"),
    "only applies"
  )
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3,
      mode = "window", window_behavior = "fixed"),
    "requires a positive"
  )
})

test_that("presentation = 'timeline' implies the histogram and needs data", {
  m <- maplibre()
  t <- add_slider_control(m, layers = "l", property = "t", values = 1:10,
    mode = "window", window = 3, presentation = "timeline",
    counts = rep(1, 10))
  expect_equal(t$x$slider_control$presentation, "timeline")
  expect_true(t$x$slider_control$histogram)
  expect_equal(length(t$x$slider_control$counts), 10)

  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:10,
      mode = "window", window = 3, presentation = "timeline"),
    "needs the bar data"
  )
})

test_that("draggable serializes and defaults to FALSE", {
  m <- maplibre()
  d <- add_slider_control(m, layers = "l", property = "t", values = 1:3,
    draggable = TRUE)
  expect_true(d$x$slider_control$draggable)
  # default is docked (FALSE)
  s <- add_slider_control(m, layers = "l", property = "t", values = 1:3)
  expect_false(s$x$slider_control$draggable)
})

test_that("flowmap target in window mode needs an absolute time_unit", {
  m <- maplibre()
  # Simulate a flowmap having been added (the validation reads map$x$flowmaps).
  m$x$flowmaps <- list(list(id = "flows"))
  expect_error(
    add_slider_control(m, layers = "flows", property = "t", values = 1:3,
      mode = "window", time_unit = "month"),
    "absolute time unit"
  )
  expect_error(
    add_slider_control(m, layers = "flows", property = "t", values = 1:3,
      mode = "window"), # time_unit NULL
    "absolute time unit"
  )
  # absolute unit is accepted
  w <- add_slider_control(m, layers = "flows", property = "t", values = 1:3,
    mode = "window", time_unit = "date")
  expect_equal(w$x$slider_control$time_unit, "date")
})

test_that("histogram validates and bins in R", {
  m <- maplibre()
  # needs data
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3, histogram = TRUE),
    "needs the bar heights"
  )
  # counts length must match values
  expect_error(
    add_slider_control(m, layers = "l", property = "t", values = 1:3,
      histogram = TRUE, counts = c(1, 2)),
    "one value per"
  )
  # histogram_data binned to nearest value
  hd <- c(2015, 2015, 2015, 2017, 2017, 2020)
  w <- add_slider_control(m, layers = "l", property = "year", values = 2015:2020,
    histogram = TRUE, histogram_data = hd)
  expect_equal(
    unlist(w$x$slider_control$counts),
    c(3, 0, 2, 0, 0, 1) # 2015:x3, 2017:x2, 2020:x1
  )
  expect_true(isTRUE(w$x$slider_control$histogram))
})

test_that("paint args normalize to kebab-case property names", {
  m <- maplibre()
  w <- add_slider_control(m, layers = "l", values = 1:3,
    paint_property = "fill_extrusion_height",
    paint_expressions = as.list(c(10, 20, 30)))
  expect_true("fill-extrusion-height" %in% names(w$x$slider_control$paint_properties))
  # single + multi forms are mutually exclusive
  expect_error(
    add_slider_control(m, layers = "l", values = 1:3,
      paint_property = "fill_color", paint_expressions = as.list(rep("red", 3)),
      paint_properties = list(fill_color = as.list(rep("red", 3)))),
    "not both"
  )
})

test_that("d3 dependency is attached only when histogram is requested", {
  m <- maplibre()
  has_d3 <- function(w) any(vapply(w$dependencies,
    function(d) identical(d$name, "d3"), logical(1)))
  w_no <- add_slider_control(m, layers = "l", property = "t", values = 1:3)
  expect_false(has_d3(w_no))
  w_yes <- add_slider_control(m, layers = "l", property = "t", values = 1:3,
    histogram = TRUE, counts = c(1, 2, 3))
  expect_true(has_d3(w_yes))
})

test_that("add_slider_control dispatches over a proxy and rejects compare proxies", {
  session <- shiny::MockShinySession$new()
  px <- maplibre_proxy("map", session = session)
  out <- add_slider_control(px, layers = "l", property = "t", values = 1:3)
  expect_s3_class(out, "maplibre_proxy")

  cpx <- maplibre_compare_proxy("cmp", session = session, map_side = "before")
  expect_error(
    add_slider_control(cpx, layers = "l", property = "t", values = 1:3),
    "does not support compare proxies"
  )
})

test_that("update_slider_control validates and dispatches", {
  session <- shiny::MockShinySession$new()
  px <- maplibre_proxy("map", session = session)
  expect_s3_class(
    update_slider_control(px, value = 2, playing = TRUE),
    "maplibre_proxy"
  )
  expect_error(update_slider_control(px, value = c(1, 2)), "single numeric")
  expect_error(update_slider_control(px, playing = "yes"), "TRUE or FALSE")
  # non-proxy rejected
  expect_error(
    update_slider_control(maplibre(), value = 1),
    "mapboxgl_proxy or maplibre_proxy"
  )
})
