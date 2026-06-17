#' Style a tooltip or popup
#'
#' Builds a styling specification for map tooltips and popups, mirroring
#' [legend_style()]. Pass the result -- or simply a preset name like `"dark"`
#' -- to the `tooltip_style` / `popup_style` argument of a layer function or
#' [add_flowmap()]. Start from an optional light/dark `preset` and override any
#' individual properties on top of it. With no styling argument supplied,
#' tooltips keep their default (unstyled) appearance.
#'
#' @param preset Optional base theme: `"light"`, `"dark"`, or `"auto"` (resolve
#'   to light or dark from the flowmap dark mode; ordinary layers treat
#'   `"auto"` as light). Individual arguments below override the preset.
#' @param background_color CSS color for the tooltip/popup background.
#' @param background_opacity Numeric in `[0, 1]` for the background opacity.
#' @param text_color CSS color for the text.
#' @param border_color CSS color for the border.
#' @param border_width Border width in pixels.
#' @param border_radius Corner radius in pixels.
#' @param font_family CSS `font-family` string.
#' @param font_size Font size in pixels.
#' @param font_weight CSS `font-weight`.
#' @param padding Internal padding in pixels.
#' @param max_width Maximum width as a CSS size (e.g. `"320px"`).
#' @param shadow Logical; whether to draw a drop shadow.
#' @param shadow_color CSS color of the drop shadow.
#' @param shadow_size Blur radius of the drop shadow in pixels.
#' @param position For flowmap tooltips/popups, `"floating"` (cursor-following)
#'   or `"anchored"` (pinned to the feature). Ignored by ordinary layers.
#' @param offset For floating flowmap tooltips, a numeric pixel offset or a
#'   length-2 numeric `c(x, y)`.
#'
#' @return A list of class `mapgl_tooltip_style`.
#' @export
#'
#' @examples
#' \dontrun{
#' # A dark preset, tweaked
#' tooltip_style("dark", border_radius = 8, font_size = 13)
#'
#' # Fully custom
#' tooltip_style(
#'   background_color = "rgba(20,30,48,0.95)",
#'   text_color = "#e6edf3",
#'   border_radius = 6
#' )
#' }
tooltip_style <- function(
  preset = NULL,
  background_color = NULL,
  background_opacity = NULL,
  text_color = NULL,
  border_color = NULL,
  border_width = NULL,
  border_radius = NULL,
  font_family = NULL,
  font_size = NULL,
  font_weight = NULL,
  padding = NULL,
  max_width = NULL,
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  position = NULL,
  offset = NULL
) {
  if (!is.null(preset)) {
    preset <- match.arg(preset, c("light", "dark", "auto"))
  }
  if (!is.null(position)) {
    position <- match.arg(position, c("floating", "anchored"))
  }

  style <- list(
    preset = preset,
    background_color = background_color,
    background_opacity = background_opacity,
    text_color = text_color,
    border_color = border_color,
    border_width = border_width,
    border_radius = border_radius,
    font_family = font_family,
    font_size = font_size,
    font_weight = font_weight,
    padding = padding,
    max_width = max_width,
    shadow = shadow,
    shadow_color = shadow_color,
    shadow_size = shadow_size,
    position = position,
    offset = offset
  )

  style <- style[!vapply(style, is.null, logical(1))]
  class(style) <- "mapgl_tooltip_style"
  style
}

#' @rdname tooltip_style
#' @export
popup_style <- function(
  preset = NULL,
  background_color = NULL,
  background_opacity = NULL,
  text_color = NULL,
  border_color = NULL,
  border_width = NULL,
  border_radius = NULL,
  font_family = NULL,
  font_size = NULL,
  font_weight = NULL,
  padding = NULL,
  max_width = NULL,
  shadow = NULL,
  shadow_color = NULL,
  shadow_size = NULL,
  position = NULL,
  offset = NULL
) {
  tooltip_style(
    preset = preset,
    background_color = background_color,
    background_opacity = background_opacity,
    text_color = text_color,
    border_color = border_color,
    border_width = border_width,
    border_radius = border_radius,
    font_family = font_family,
    font_size = font_size,
    font_weight = font_weight,
    padding = padding,
    max_width = max_width,
    shadow = shadow,
    shadow_color = shadow_color,
    shadow_size = shadow_size,
    position = position,
    offset = offset
  )
}

# Built-in light/dark presets (Egor Kotov's flowmap.css values, generalized).
mapgl_tooltip_style_preset <- function(name) {
  switch(
    name,
    light = list(
      background_color = "rgba(255, 255, 255, 0.96)",
      text_color = "#222222",
      border_color = "rgba(0, 0, 0, 0.12)",
      border_width = 1,
      border_radius = 4,
      shadow = TRUE,
      shadow_color = "rgba(0, 0, 0, 0.16)",
      shadow_size = 8,
      padding = 8
    ),
    dark = list(
      background_color = "rgba(35, 35, 35, 0.94)",
      text_color = "#ffffff",
      border_color = "rgba(255, 255, 255, 0.12)",
      border_width = 1,
      border_radius = 4,
      shadow = TRUE,
      shadow_color = "rgba(0, 0, 0, 0.4)",
      shadow_size = 8,
      padding = 8
    ),
    NULL
  )
}

# Resolve a tooltip/popup style argument (NULL, a preset string, or a
# tooltip_style()/popup_style() object) into a plain serialized spec for JS.
# `dark_mode` resolves an "auto" preset (flowmap passes its resolved dark mode;
# ordinary layers default to light).
mapgl_normalize_tooltip_style <- function(x, dark_mode = FALSE, arg = "tooltip_style") {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.character(x) && length(x) == 1 && !is.na(x)) {
    x <- tooltip_style(preset = x)
  }
  if (!inherits(x, "mapgl_tooltip_style")) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be a preset string (\"light\", \"dark\", or \"auto\") or a ",
      "`tooltip_style()`/`popup_style()` object."
    ))
  }

  preset <- x$preset
  base <- list()
  if (!is.null(preset)) {
    if (identical(preset, "auto")) {
      preset <- if (isTRUE(dark_mode)) "dark" else "light"
    }
    base <- mapgl_tooltip_style_preset(preset)
    if (is.null(base)) {
      rlang::abort(sprintf("Unknown tooltip style preset \"%s\".", preset))
    }
  }

  overrides <- x[setdiff(names(x), "preset")]
  spec <- utils::modifyList(base, overrides)
  if (length(spec) == 0) {
    return(NULL)
  }
  spec
}

