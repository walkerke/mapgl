#' Add a time control with a histogram
#'
#' Adds an interactive time scrubber with a histogram to the map. The control
#' filters temporal data by dragging a range across a bar chart. It can drive
#' one or several layers at once — both flowmap layers and ordinary
#' Mapbox/MapLibre layers (circle, fill, line, symbol, etc.) whose source
#' features carry a time property.
#'
#' For ordinary layers, the control sets a Mapbox filter expression of the
#' form `[">=", ["get", feature_time_property], start] && ["<", ..., end]`.
#' The property is assumed to be an ISO 8601 timestamp string by default; pass
#' `feature_time_format = "epoch_ms"` (or `"epoch_s"`) if your source data
#' encodes time as numeric epoch milliseconds (or seconds).
#'
#' For flowmap layers the control updates the `selectedTimeRange` of the
#' flowmap filter via the flowmap.gl plugin.
#'
#' @param map A map object created by [mapboxgl()] or [maplibre()].
#' @param data A data frame containing the temporal data used to build the
#'   histogram (bin counts and extent).
#' @param time_column The name of the column in `data` containing timestamps
#'   (POSIXct or Date).
#' @param layer_id Target layer ID(s) to filter. Either a character vector of
#'   layer IDs (flowmap and/or ordinary layers), or `NULL` to filter every
#'   flowmap layer in the map. To filter ordinary (non-flowmap) layers, list
#'   them explicitly.
#' @param feature_time_property For ordinary (non-flowmap) target layers, the
#'   name of the feature property holding the timestamp. Defaults to
#'   `time_column`.
#' @param feature_time_format How the timestamp is stored on ordinary target
#'   layers' source features: `"iso"` (ISO 8601 string, default),
#'   `"epoch_ms"`, or `"epoch_s"`.
#' @param time_interval The aggregation interval for the histogram: `"hour"`
#'   or `"day"`.
#' @param position The position of the control: `"top-right"`, `"top-left"`,
#'   `"bottom-right"`, `"bottom-left"`, or `"bottom-center"`.
#' @param initial_range Optional vector of two dates for the initial selection.
#' @param loop Logical; whether to loop the playback.
#' @param speed Playback speed in milliseconds per step (default 500).
#' @param autoplay Logical; if `TRUE`, start playing the scrubber animation
#'   immediately after the control mounts. Defaults to `FALSE`.
#' @param accent_color Color for the bars and selection handles.
#' @param dark_mode Logical; whether to use a dark theme for the widget.
#' @param draggable Logical; if `TRUE` the widget is detached from the map
#'   corner container and can be repositioned by dragging its header.
#' @param collapsible Logical; if `TRUE` the histogram body can be collapsed
#'   to a compact bar.
#' @param collapsed Logical; whether to start in the collapsed state. Implies
#'   `collapsible = TRUE`.
#' @param title Optional short title shown in the header (useful when the
#'   control is draggable or collapsible).
#'
#' @return The modified map object.
#' @export
add_time_control <- function(
  map,
  data,
  time_column,
  layer_id = NULL,
  feature_time_property = NULL,
  feature_time_format = c("iso", "epoch_ms", "epoch_s"),
  time_interval = c("hour", "day"),
  position = "bottom-left",
  initial_range = NULL,
  loop = TRUE,
  speed = 500,
  autoplay = FALSE,
  accent_color = "#00bcd4",
  dark_mode = TRUE,
  draggable = FALSE,
  collapsible = FALSE,
  collapsed = FALSE,
  title = NULL
) {
  time_interval <- match.arg(time_interval)
  feature_time_format <- match.arg(feature_time_format)

  if (!time_column %in% names(data)) {
    rlang::abort(paste0("Time column '", time_column, "' not found in data."))
  }

  times <- data[[time_column]]
  if (!inherits(times, "POSIXct") && !inherits(times, "Date")) {
    rlang::abort("Time column must be POSIXct or Date.")
  }

  if (!is.null(layer_id)) {
    if (!is.character(layer_id) || length(layer_id) < 1) {
      rlang::abort("`layer_id` must be a character vector of one or more layer IDs, or NULL for all flowmap layers.")
    }
  }

  if (is.null(feature_time_property)) {
    feature_time_property <- time_column
  }

  if (isTRUE(collapsed)) {
    collapsible <- TRUE
  }

  tzone <- attr(times, "tzone")
  if (is.null(tzone) || tzone == "") tzone <- "UTC"

  if (time_interval == "hour") {
    start_time <- as.POSIXct(format(min(times), "%Y-%m-%d %H:00:00", tz = tzone), tz = tzone)
    end_time <- as.POSIXct(format(max(times) + 3600, "%Y-%m-%d %H:00:00", tz = tzone), tz = tzone)
    breaks <- seq(from = start_time, to = end_time, by = "hour")
    binned <- cut(times, breaks = breaks, include.lowest = TRUE)
  } else {
    breaks <- seq(
      from = as.Date(min(times)),
      to = as.Date(max(times) + 1),
      by = "day"
    )
    binned <- cut(times, breaks = breaks, include.lowest = TRUE)
  }

  bin_counts <- table(binned)

  bins_df <- data.frame(
    time = breaks[-length(breaks)],
    count = as.numeric(bin_counts),
    stringsAsFactors = FALSE
  )

  if (time_interval == "hour") {
    bins_df$time <- format(as.POSIXct(bins_df$time, tz = tzone), "%Y-%m-%dT%H:%M:%SZ")
  } else {
    bins_df$time <- format(as.Date(bins_df$time), "%Y-%m-%d")
  }

  initial_range_iso <- NULL
  if (!is.null(initial_range)) {
    if (length(initial_range) != 2) {
      rlang::abort("`initial_range` must be a length-2 vector of dates/timestamps.")
    }
    if (inherits(initial_range, "POSIXct")) {
      initial_range_iso <- format(initial_range, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    } else if (inherits(initial_range, "Date")) {
      initial_range_iso <- format(initial_range, "%Y-%m-%d")
    } else {
      initial_range_iso <- as.character(initial_range)
    }
  }

  control_config <- list(
    targetLayerIds = if (is.null(layer_id)) NULL else as.list(layer_id),
    featureTimeProperty = feature_time_property,
    featureTimeFormat = feature_time_format,
    bins = bins_df,
    interval = time_interval,
    position = position,
    initialRange = initial_range_iso,
    loop = loop,
    speed = speed,
    autoplay = autoplay,
    accentColor = accent_color,
    darkMode = dark_mode,
    draggable = draggable,
    collapsible = collapsible,
    collapsed = collapsed,
    title = title
  )

  if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
    do.call(
      mapgl_invoke_method,
      c(list(map, "add_time_control"), control_config)
    )
  } else {
    if (is.null(map$x$time_controls)) {
      map$x$time_controls <- list()
    }
    map$x$time_controls <- c(map$x$time_controls, list(control_config))
  }

  return(map)
}
