#' Configure tooltip or popup options
#'
#' Internal helper to create a configuration object for tooltips or popups.
#' Use [tooltip_options()] or [popup_options()] for public usage.
#'
#' @param template Template string or a named list with `location` and/or `flow` keys.
#' @param theme Visual theme: `"auto"`, `"light"`, or `"dark"`.
#' @param behavior Interaction behavior: `"hover"`, or `"click"`.
#' @param render_mode Internal rendering mode: `"floating"` or `"anchored"`.
#' @param ... Additional properties passed to the Mapbox/MapLibre popup.
#' @noRd
tooltip_popup_options <- function(
  template = NULL,
  theme = c("auto", "light", "dark"),
  behavior = c("hover", "click"),
  render_mode = c("floating", "anchored"),
  ...
) {
  theme <- match.arg(theme)
  behavior <- match.arg(behavior)
  render_mode <- match.arg(render_mode)
  popup_props <- list(...)

  if (length(popup_props) > 0 && (is.null(names(popup_props)) || any(!nzchar(names(popup_props))))) {
    rlang::abort("Additional popup properties must be named.")
  }

  structure(
    list(
      template = template,
      theme = theme,
      behavior = behavior,
      popup_props = popup_props,
      render_mode = render_mode
    ),
    class = "mapgl_tooltip_popup_options"
  )
}

#' Configure tooltip options
#'
#' @param template Template string or a named list with `location` and/or `flow` keys.
#' @param theme Visual theme: `"auto"`, `"light"`, or `"dark"`.
#' @param ... Additional properties passed to the Mapbox/MapLibre popup, such as `className`, `css`, `maxWidth`, etc.
#' @export
tooltip_options <- function(template = NULL, theme = "auto", ...) {
  tooltip_popup_options(template, theme, behavior = "hover", ...)
}

#' Configure popup options
#'
#' @param template Template string or a named list with `location` and/or `flow` keys.
#' @param theme Visual theme: `"auto"`, `"light"`, or `"dark"`.
#' @param ... Additional properties passed to the Mapbox/MapLibre popup, such as `className`, `css`, `maxWidth`, etc.
#' @export
popup_options <- function(template = NULL, theme = "auto", ...) {
  tooltip_popup_options(template, theme, behavior = "click", ...)
}
