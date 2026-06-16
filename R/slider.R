#' Add a slider control to a map
#'
#' Adds an interactive slider to a Mapbox GL or MapLibre GL map that
#' steps through a sequence of values and filters one or more layers by
#' a numeric feature property. Works source-agnostically: GeoJSON,
#' vector tile, and PMTiles layers all compose through the same filter
#' pipeline. Optional play button animates through the steps;
#' `"cumulative"` mode accumulates features through the range rather
#' than swapping them.
#'
#' Values commonly represent time (years, months, epoch seconds) but
#' need not — any monotonic numeric sequence works (magnitude
#' thresholds, percentile coverage, depth bins, etc.).
#'
#' The slider composes with other filter sources rather than replacing
#' them: a layer's initial `filter =` argument, a subsequent
#' [set_filter()] call, and an interactive [add_legend()] can all be
#' active at the same time as the slider, and the layer's resolved
#' filter is the `["all", ...]` intersection.
#'
#' @section Date and time values:
#' The slider requires numeric values. Because `sf` objects are
#' serialized to GeoJSON via `geojsonsf::sf_geojson()`, `Date` and
#' `POSIXct` columns become JSON strings, not numbers — so you must
#' pre-coerce your time column to numeric before adding the layer. Use
#' [as_time_property()] for the common cases (year, month index, epoch
#' seconds, days-since-epoch).
#'
#' @section Positioning and collisions:
#' The slider is implemented as a native control and stacks beside
#' other native controls (navigation, scale, geolocate, fullscreen) via
#' Mapbox/MapLibre's built-in positioning. Overlays such as
#' [add_legend()] and [add_layers_control()] are absolutely-positioned
#' and do not participate in that flow — placing a slider in the same
#' corner as a legend will overlap it. Choose a different corner or
#' adjust the overlay's margins.
#'
#' @param map A map object created by [mapboxgl()] or [maplibre()], or a
#'   proxy object from [mapboxgl_proxy()] / [maplibre_proxy()].
#' @param layers Character vector of layer IDs the slider should affect.
#'   Layers need not exist yet — if a matching layer is added later via
#'   proxy, the slider's current filter and/or paint expression is
#'   applied on its first paint.
#' @param property Name of the numeric feature property to filter on.
#'   Optional: if `NULL`, no filter behavior. At least one of `property`
#'   or `paint_property` must be supplied.
#' @param time_unit Optional. Only consequential when a target layer is a
#'   flowmap (`add_flowmap()`): ordinary layers filter on the numeric
#'   `property` directly, but flowmap layers need an absolute timestamp
#'   range, so in `"window"` mode the numeric value is converted to a
#'   flowmap time range using this unit. One of `"seconds"`, `"date"`, or
#'   `"year"` (the absolute units produced by [as_time_property()]).
#'   `"month"`/`"day"` are calendar indices, not instants, and cannot
#'   drive a flowmap window.
#' @param values Numeric vector of steps. Required unless `min` and
#'   `max` are supplied.
#' @param labels Optional character vector of display labels (one per
#'   value). Defaults to `as.character(values)`.
#' @param min,max,step Numeric range specification used when `values` is
#'   not supplied. `values` is generated via `seq(min, max, by = step)`.
#' @param mode One of `"sequential"` (default) — each step shows only
#'   features matching that exact value; `"cumulative"` — shows
#'   everything up through the current value; or `"window"` — shows a
#'   moving `[start, end]` range (the end is the current value). Window
#'   mode emits a range filter for ordinary layers and a
#'   `selectedTimeRange` for flowmap layers, making it the mode used to
#'   drive temporal flowmaps. Only applies when `property` is set.
#' @param window Only used when `mode = "window"`. `NULL` (default) makes
#'   a cumulative range `[min(values), T]`; a positive number makes a
#'   sliding window `[T - window, T]`, where `window` is expressed in the
#'   same units as `values` (e.g. for [as_time_property()] `unit =
#'   "date"`, `window = 7` is a 7-day window).
#' @param histogram Logical; if `TRUE`, draw a density strip behind the
#'   slider showing how many features fall at each value (a data-density
#'   backdrop, most useful with `mode = "window"` where the selected band
#'   highlights the covered bars). Loads d3 on demand. Supply the bar
#'   heights via `counts` or `histogram_data`. Default `FALSE`.
#' @param histogram_data Numeric vector of the raw property values across
#'   your features; binned in R to the nearest `values` step to produce
#'   the histogram bar heights. Use this when you have the underlying data
#'   to hand. Ignored unless `histogram = TRUE`.
#' @param counts Numeric vector of pre-computed bar heights, one per
#'   `values`. An alternative to `histogram_data` when you already have
#'   per-step counts. Ignored unless `histogram = TRUE`.
#' @param initial_value Value to start on. Defaults to the first value.
#' @param paint_property Optional Mapbox paint property the slider
#'   should animate, supplied in snake_case to match the rest of the
#'   package (e.g. `"fill_color"`, `"fill_extrusion_height"`,
#'   `"circle_radius"`). Kebab-case is also accepted for convenience
#'   when copying from Mapbox docs. Shortcut for the single-property
#'   case; when set, `paint_expressions` must also be supplied. For
#'   animating more than one paint property together (e.g. height *and*
#'   color), use `paint_properties` instead.
#' @param paint_expressions List of Mapbox expressions, one per value in
#'   `values`. On each step, the expression at the matching index is
#'   applied to each target layer via `map.setPaintProperty()`. Build
#'   expressions with [interpolate()], [match_expr()], or raw lists.
#' @param paint_properties Optional named list for animating multiple
#'   paint properties simultaneously. Shape:
#'   `list(fill_color = list(<expr_0>, <expr_1>, ...), fill_extrusion_height = list(...))`
#'   — names are snake_case (kebab-case also accepted), each value is a
#'   list of expressions the same length as `values`. Cannot be
#'   combined with `paint_property`/`paint_expressions`. Each property's
#'   pre-slider value is captured on mount and restored on removal,
#'   independently.
#' @param play_button Logical; include a play/pause button next to the
#'   slider. Default `FALSE`.
#' @param animation_duration Milliseconds to wait between steps while
#'   playing. Default `1000`.
#' @param loop Logical; when playback reaches the last value, return to
#'   the first. Default `TRUE`.
#' @param title Optional title shown above the slider.
#' @param show_value Logical; show the current label beside the slider.
#'   Default `TRUE`.
#' @param width Slider container width in pixels. Default `280`.
#' @param position One of `"top-left"`, `"top-right"`, `"bottom-left"`,
#'   `"bottom-right"`. Default `"top-left"`.
#' @param background_color,text_color,accent_color Styling overrides.
#'   Defaults match the package's other controls.
#'
#' @return The modified map or proxy object, invisibly.
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#' library(sf)
#'
#' quakes <- sf::read_sf(
#'   "https://docs.mapbox.com/mapbox-gl-js/assets/significant-earthquakes-2015.geojson"
#' )
#' quakes$month <- as.POSIXlt(quakes$time / 1000, origin = "1970-01-01")$mon
#'
#' mapboxgl(center = c(-45, 0), zoom = 0.25) |>
#'   add_circle_layer(
#'     id = "quakes",
#'     source = quakes,
#'     circle_color = "#FCA107",
#'     circle_radius = 20,
#'     circle_opacity = 0.75
#'   ) |>
#'   add_slider_control(
#'     layers = "quakes",
#'     property = "month",
#'     values = 0:11,
#'     labels = month.name,
#'     title = "Significant earthquakes in 2015",
#'     play_button = TRUE
#'   )
#'
#' # --- Paint animation: step through a choropleth's color over years
#' # Given an sf object with columns pop2020, pop2021, ..., pop2024:
#' # mapboxgl() |>
#' #   add_fill_layer(id = "tracts", source = tracts, fill_opacity = 0.85) |>
#' #   add_slider_control(
#' #     layers = "tracts",
#' #     values = 2020:2024,
#' #     paint_property = "fill_color",
#' #     paint_expressions = lapply(2020:2024, function(y) {
#' #       interpolate(
#' #         column = paste0("pop", y),
#' #         values = c(0, 5e5, 2e6),
#' #         stops  = c("#f7f4f9", "#67a9cf", "#02818a")
#' #       )
#' #     }),
#' #     play_button = TRUE
#' #   )
#' }
#'
#' @seealso [update_slider_control()], [as_time_property()]
#' @export
add_slider_control <- function(
  map,
  layers,
  property = NULL,
  time_unit = NULL,
  values = NULL,
  labels = NULL,
  min = NULL,
  max = NULL,
  step = 1,
  mode = c("sequential", "cumulative", "window"),
  window = NULL,
  histogram = FALSE,
  histogram_data = NULL,
  counts = NULL,
  initial_value = NULL,
  paint_property = NULL,
  paint_expressions = NULL,
  paint_properties = NULL,
  play_button = FALSE,
  animation_duration = 1000,
  loop = TRUE,
  title = NULL,
  show_value = TRUE,
  width = 280,
  position = "top-left",
  background_color = "#ffffffcc",
  text_color = "#404040",
  accent_color = "#4a90e2"
) {
  # ---- arg validation -------------------------------------------------
  mode <- match.arg(mode)

  if (!is.character(layers) || length(layers) == 0) {
    rlang::abort("`layers` must be a non-empty character vector of layer IDs.")
  }

  # Normalize paint property names: users supply snake_case to match
  # the rest of the package (e.g. `fill_extrusion_height`), and we
  # translate to the kebab-case Mapbox wire format (e.g.
  # `fill-extrusion-height`). Kebab-case is also accepted for users
  # copying straight from Mapbox docs — the replacement is idempotent.
  to_mapbox_name <- function(x) gsub("_", "-", x)

  # Normalize single-property form into the multi-property shape so one
  # validation and serialization path handles both. After this block,
  # `paint_spec` is either NULL (no paint behavior) or a named list
  # `list("fill-color" = list(<expr>...), "fill-extrusion-height" = ...)`
  # with each value a list of length == length(values) and keys in
  # Mapbox kebab-case.
  using_single <- !is.null(paint_property) || !is.null(paint_expressions)
  using_multi <- !is.null(paint_properties)
  if (using_single && using_multi) {
    rlang::abort(c(
      "Supply either `paint_property`+`paint_expressions` or `paint_properties`, not both.",
      i = "`paint_properties` is a named list shaped `list(fill_color = list(...), fill_extrusion_height = list(...))` and covers the multi-property case on its own."
    ))
  }
  paint_spec <- NULL
  if (using_single) {
    if (is.null(paint_property) || is.null(paint_expressions)) {
      rlang::abort(
        "`paint_property` and `paint_expressions` must be supplied together."
      )
    }
    if (
      !is.character(paint_property) ||
        length(paint_property) != 1 ||
        nchar(paint_property) == 0
    ) {
      rlang::abort("`paint_property` must be a single non-empty string.")
    }
    if (!is.list(paint_expressions)) {
      rlang::abort(
        "`paint_expressions` must be a list, one expression per value (use `list()`, not `c()`)."
      )
    }
    paint_spec <- stats::setNames(
      list(paint_expressions),
      to_mapbox_name(paint_property)
    )
  } else if (using_multi) {
    if (!is.list(paint_properties) || length(paint_properties) == 0) {
      rlang::abort(
        "`paint_properties` must be a non-empty named list (property name -> list of expressions)."
      )
    }
    prop_names <- names(paint_properties)
    if (is.null(prop_names) || any(!nzchar(prop_names))) {
      rlang::abort(
        "`paint_properties` must be a named list with non-empty names, e.g. `list(fill_extrusion_height = list(...), fill_extrusion_color = list(...))`."
      )
    }
    normalized_names <- to_mapbox_name(prop_names)
    if (any(duplicated(normalized_names))) {
      rlang::abort(
        "`paint_properties` names must be unique after snake_case -> kebab-case normalization."
      )
    }
    for (pn in prop_names) {
      if (!is.list(paint_properties[[pn]])) {
        rlang::abort(
          sprintf(
            "`paint_properties[[%s]]` must be a list of expressions (one per value).",
            dQuote(pn, FALSE)
          )
        )
      }
    }
    paint_spec <- stats::setNames(paint_properties, normalized_names)
  }

  # At least one behavior must be configured: filter (property) or paint
  # (paint_spec). Both can be active simultaneously.
  has_filter <- !is.null(property)
  has_paint <- !is.null(paint_spec)
  if (!has_filter && !has_paint) {
    rlang::abort(c(
      "Slider has no effect configured.",
      i = "Set `property` to drive a filter, or `paint_property`+`paint_expressions` (or `paint_properties`) to drive paint, or both."
    ))
  }

  if (has_filter) {
    if (
      !is.character(property) || length(property) != 1 || nchar(property) == 0
    ) {
      rlang::abort("`property` must be a single non-empty string.")
    }
  }

  # ---- window mode + time_unit ---------------------------------------
  # `window` defines a moving [start, end] range instead of a point.
  # The end is the current value T; the start is min(values) when
  # `window` is NULL (cumulative range) or T - window (sliding range).
  if (!is.null(window)) {
    if (mode != "window") {
      rlang::abort('`window` only applies when `mode = "window"`.')
    }
    if (
      !is.numeric(window) ||
        length(window) != 1 ||
        !is.finite(window) ||
        window <= 0
    ) {
      rlang::abort("`window` must be a single positive number.")
    }
  }
  if (mode == "window" && !has_filter) {
    rlang::abort('`mode = "window"` requires `property` (range filtering needs a property to filter on).')
  }

  # `time_unit` is only consequential when a target layer is a flowmap:
  # ordinary layers filter on the numeric property directly, but flowmap
  # layers need an absolute timestamp range, so the JS side converts the
  # numeric value to epoch-ms using this unit. Absolute units only
  # (year/date/seconds); month/day are indices, not instants.
  if (!is.null(time_unit)) {
    time_unit <- match.arg(
      time_unit,
      c("year", "month", "day", "date", "seconds")
    )
  }
  absolute_units <- c("year", "date", "seconds")

  # Early validation against recorded flowmap ids (init path only; for
  # proxy / late-added layers the JS guard handles it). A flowmap target
  # in window mode needs an absolute time_unit to build selectedTimeRange.
  flowmap_ids <- character(0)
  if (!is.null(map$x) && !is.null(map$x$flowmaps)) {
    flowmap_ids <- vapply(
      map$x$flowmaps,
      function(f) if (is.null(f$id)) NA_character_ else as.character(f$id),
      character(1)
    )
    flowmap_ids <- flowmap_ids[!is.na(flowmap_ids)]
  }
  if (
    mode == "window" &&
      length(intersect(layers, flowmap_ids)) > 0 &&
      (is.null(time_unit) || !time_unit %in% absolute_units)
  ) {
    rlang::abort(c(
      "A flowmap layer is targeted in window mode, but `time_unit` is not an absolute time unit.",
      i = 'Set `time_unit` to "seconds", "date", or "year" so the window can be converted to a flowmap time range.',
      x = if (is.null(time_unit)) "`time_unit` is NULL." else
        sprintf("`time_unit = \"%s\"` is a calendar index, not an instant.", time_unit)
    ))
  }

  # Build `values` from `min`/`max`/`step` if not supplied.
  if (is.null(values)) {
    if (is.null(min) || is.null(max)) {
      rlang::abort(
        "Supply either `values`, or both `min` and `max` (with optional `step`)."
      )
    }
    values <- seq(min, max, by = step)
  }

  if (inherits(values, "Date") || inherits(values, "POSIXct") || inherits(values, "POSIXlt")) {
    rlang::abort(c(
      "`values` must be numeric; got a Date/POSIXct vector.",
      i = "Use `as_time_property()` (or `as.numeric()`) to coerce first, and make sure the matching column in your data is also numeric."
    ))
  }
  if (!is.numeric(values) || length(values) == 0) {
    rlang::abort("`values` must be a non-empty numeric vector.")
  }
  if (any(!is.finite(values))) {
    rlang::abort("`values` must be finite.")
  }

  if (is.null(labels)) {
    labels <- as.character(values)
  } else {
    if (length(labels) != length(values)) {
      rlang::abort("`labels` must have the same length as `values`.")
    }
    labels <- as.character(labels)
  }

  if (is.null(initial_value)) {
    # In window mode `initial_value` is the END handle. Default it to the
    # last value so a NULL `window` spans the full [min, max] range and a
    # sized `window` sits at the most-recent end. Point modes start first.
    initial_index <- if (mode == "window") length(values) - 1L else 0L
  } else {
    matches <- which(values == initial_value)
    if (length(matches) == 0) {
      rlang::abort("`initial_value` must be one of `values`.")
    }
    # JS is 0-indexed.
    initial_index <- as.integer(matches[1]) - 1L
  }

  valid_positions <- c("top-left", "top-right", "bottom-left", "bottom-right")
  if (!position %in% valid_positions) {
    rlang::abort(
      sprintf(
        "`position` must be one of %s.",
        paste(shQuote(valid_positions), collapse = ", ")
      )
    )
  }

  # Every paint property's expression list must match `values` length
  # (checked after `values` is resolved from `min`/`max`). Applies to
  # both the single-form (normalized into paint_spec) and multi-form.
  if (!is.null(paint_spec)) {
    for (pn in names(paint_spec)) {
      if (length(paint_spec[[pn]]) != length(values)) {
        rlang::abort(
          sprintf(
            "Paint expressions for %s must have length %d (one per value); got %d.",
            dQuote(pn, FALSE),
            length(values),
            length(paint_spec[[pn]])
          )
        )
      }
    }
  }

  # ---- histogram density strip ----------------------------------------
  # An optional d3 density strip drawn behind the slider/range. Binning
  # happens here in R against the numeric `values` axis (NOT in JS against
  # dates), which is what keeps the bars aligned to the handles and avoids
  # the timezone/interval pitfalls of date binning in the browser.
  histogram <- isTRUE(histogram)
  hist_counts <- NULL
  if (histogram) {
    if (!is.null(counts)) {
      if (!is.numeric(counts) || length(counts) != length(values)) {
        rlang::abort(
          "`counts` must be a numeric vector with one value per `values`."
        )
      }
      hist_counts <- as.numeric(counts)
    } else if (!is.null(histogram_data)) {
      if (!is.numeric(histogram_data)) {
        rlang::abort("`histogram_data` must be a numeric vector.")
      }
      hd <- histogram_data[is.finite(histogram_data)]
      sv <- sort(values)
      if (length(sv) == 1) {
        hist_counts <- length(hd)
      } else {
        # Nearest-value binning: breaks at the midpoints between sorted
        # values so each datum lands on its closest step.
        mids <- (sv[-length(sv)] + sv[-1]) / 2
        bin_idx <- findInterval(hd, mids) + 1L
        tab <- tabulate(bin_idx, nbins = length(sv))
        # Map sorted-bin counts back to the original `values` order.
        hist_counts <- numeric(length(values))
        hist_counts[order(values)] <- tab
      }
    } else {
      rlang::abort(c(
        "`histogram = TRUE` needs the bar heights.",
        i = "Supply `counts` (one count per `values`) or `histogram_data` (raw numeric values to bin)."
      ))
    }
  }

  # ---- build options payload ------------------------------------------
  # Use I() on numeric vectors so jsonlite does not unbox singleton
  # numeric vectors into scalars. jsonlite defaults in htmlwidgets
  # serialize length-1 atomic vectors as scalars; `values` may be
  # length 1 in edge cases (weird but valid), and must round-trip as an
  # array.
  options <- list(
    layers = as.list(layers),
    property = property,
    values = as.list(values),
    labels = as.list(labels),
    mode = mode,
    initial_index = initial_index,
    play_button = isTRUE(play_button),
    animation_duration = as.integer(animation_duration),
    loop = isTRUE(loop),
    show_value = isTRUE(show_value),
    width = as.integer(width),
    position = position,
    background_color = background_color,
    text_color = text_color,
    accent_color = accent_color
  )
  if (!is.null(title)) options$title <- title
  if (!is.null(window)) options$window <- window
  if (!is.null(time_unit)) options$time_unit <- time_unit
  if (histogram) {
    options$histogram <- TRUE
    options$counts <- as.list(as.numeric(hist_counts))
  }
  if (!is.null(paint_spec)) {
    # Serialize as a named list of property -> list-of-expressions.
    # The JS side treats this uniformly whether the user supplied the
    # single-form or multi-form.
    options$paint_properties <- paint_spec
  }

  # ---- proxy / initial dispatch ---------------------------------------
  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    if (
      inherits(map, "mapboxgl_compare_proxy") ||
        inherits(map, "maplibre_compare_proxy")
    ) {
      rlang::abort(c(
        "`add_slider_control()` does not support compare proxies in this release.",
        i = "Attach the slider to each map individually before creating the compare widget, or open an issue to request compare support."
      ))
    }
    proxy_class <- if (inherits(map, "mapboxgl_proxy")) {
      "mapboxgl-proxy"
    } else {
      "maplibre-proxy"
    }
    map$session$sendCustomMessage(
      proxy_class,
      list(
        id = map$id,
        message = list(
          type = "add_slider_control",
          options = options
        )
      )
    )
  } else {
    if (!is.null(map$x$slider_control)) {
      rlang::warn(
        "A slider control is already configured on this map; replacing it."
      )
    }
    map$x$slider_control <- options
    # Load d3 on demand only when a histogram is requested (kept out of the
    # always-on widget dependencies). Vendored from Egor Kotov's PR #205.
    if (histogram) {
      d3_dep <- htmltools::htmlDependency(
        name = "d3",
        version = "7.9.0",
        src = c(file = system.file("htmlwidgets/lib/d3", package = "mapgl")),
        script = "d3.min.js"
      )
      map$dependencies <- c(map$dependencies, list(d3_dep))
    }
  }

  return(map)
}


#' Update a slider control from Shiny
#'
#' Proxy-only companion to [add_slider_control()]. Moves the slider
#' to a specific value, starts or stops playback, or adjusts playback
#' speed without recreating the control.
#'
#' @param proxy A proxy object from [mapboxgl_proxy()] or
#'   [maplibre_proxy()].
#' @param value Numeric; one of the values the slider was created with.
#'   The slider snaps to the closest value if an exact match is not
#'   found.
#' @param playing Logical; `TRUE` starts playback, `FALSE` stops.
#' @param animation_duration Milliseconds per step when playing.
#'
#' @return The proxy object, invisibly.
#' @export
update_slider_control <- function(
  proxy,
  value = NULL,
  playing = NULL,
  animation_duration = NULL
) {
  if (!inherits(proxy, "mapboxgl_proxy") && !inherits(proxy, "maplibre_proxy")) {
    rlang::abort(
      "`update_slider_control()` must be called on a mapboxgl_proxy or maplibre_proxy."
    )
  }
  if (
    inherits(proxy, "mapboxgl_compare_proxy") ||
      inherits(proxy, "maplibre_compare_proxy")
  ) {
    rlang::abort(
      "`update_slider_control()` does not support compare proxies in this release."
    )
  }

  options <- list()
  if (!is.null(value)) {
    if (!is.numeric(value) || length(value) != 1) {
      rlang::abort("`value` must be a single numeric value.")
    }
    options$value <- value
  }
  if (!is.null(playing)) {
    if (!is.logical(playing) || length(playing) != 1) {
      rlang::abort("`playing` must be TRUE or FALSE.")
    }
    options$playing <- playing
  }
  if (!is.null(animation_duration)) {
    options$animation_duration <- as.integer(animation_duration)
  }

  proxy_class <- if (inherits(proxy, "mapboxgl_proxy")) {
    "mapboxgl-proxy"
  } else {
    "maplibre-proxy"
  }

  proxy$session$sendCustomMessage(
    proxy_class,
    list(
      id = proxy$id,
      message = list(
        type = "update_slider_control",
        options = options
      )
    )
  )

  return(proxy)
}


#' Coerce a time column to a numeric property for filtering
#'
#' Helper for preparing a `Date` or `POSIXct` column for use with
#' [add_slider_control()]. Because `sf` objects are serialized to
#' GeoJSON as JSON strings for date/time columns, the slider needs a
#' numeric counterpart to filter on.
#'
#' @param x A `Date`, `POSIXct`, or numeric vector.
#' @param unit One of:
#'   * `"year"` — calendar year as integer (e.g. 2026).
#'   * `"month"` — zero-based month index (0 = January).
#'   * `"day"` — day of month.
#'   * `"date"` — days since `1970-01-01`.
#'   * `"seconds"` — seconds since the Unix epoch.
#'
#' @return An integer or numeric vector appropriate for attaching to an
#'   `sf` object as a new column before calling
#'   [add_slider_control()].
#'
#' @examples
#' dates <- as.Date(c("2015-01-15", "2015-06-30", "2015-12-31"))
#' as_time_property(dates, "month")
#' as_time_property(dates, "year")
#' as_time_property(dates, "date")
#'
#' @export
as_time_property <- function(
  x,
  unit = c("year", "month", "day", "date", "seconds")
) {
  unit <- match.arg(unit)

  posix <- if (inherits(x, "POSIXct") || inherits(x, "POSIXlt")) {
    as.POSIXlt(x)
  } else if (inherits(x, "Date")) {
    as.POSIXlt(x)
  } else if (is.numeric(x)) {
    # Already numeric — return as-is (user presumably knows what they
    # want) and let the switch just pass it through for seconds/date.
    if (unit %in% c("seconds", "date")) return(as.numeric(x))
    rlang::abort(
      "Numeric input is only supported with unit = \"seconds\" or \"date\"."
    )
  } else {
    rlang::abort("`x` must be a Date, POSIXct, or numeric vector.")
  }

  switch(
    unit,
    year    = as.integer(posix$year + 1900L),
    month   = as.integer(posix$mon),
    day     = as.integer(posix$mday),
    date    = as.numeric(as.Date(posix)),
    seconds = as.numeric(as.POSIXct(posix))
  )
}
