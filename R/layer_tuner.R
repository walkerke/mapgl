# Helper to check if a call expression contains any of our map constructors
call_contains_constructor <- function(call) {
    if (!is.call(call)) return(FALSE)
    fun <- tryCatch(deparse(call[[1]]), error = function(e) "")
    if (fun %in% c("maplibre", "mapboxgl", "maplibre_compare", "mapboxgl_compare")) {
        return(TRUE)
    }
    for (arg in as.list(call)[-1]) {
        if (call_contains_constructor(arg)) {
            return(TRUE)
        }
    }
    return(FALSE)
}

# Recursively parse the call stack expression into a list of R calls and their original deparsed arguments
parse_pipeline_calls <- function(call) {
    if (!is.call(call)) return(list())
    fun <- tryCatch(deparse(call[[1]]), error = function(e) "")
    if (fun == "") return(list())

    # Stop parsing and treat constructors as terminal/base calls
    if (fun %in% c("maplibre", "mapboxgl", "maplibre_compare", "mapboxgl_compare")) {
        args_list <- list()
        args <- tail(as.list(call), -1)
        arg_names <- names(call)[-1]
        for (i in seq_along(args)) {
            name <- if (!is.null(arg_names) && arg_names[i] != "") arg_names[i] else ""
            val <- paste(deparse(args[[i]]), collapse = "\n")
            args_list[[length(args_list) + 1]] <- list(name = name, value = val)
        }
        return(list(list(fun = fun, args = args_list)))
    }

    if (length(call) > 1) {
        first_arg <- call[[2]]
        parent_calls <- parse_pipeline_calls(first_arg)

        args_list <- list()
        args <- tail(as.list(call), -2)
        arg_names <- names(call)[-c(1, 2)]
        for (i in seq_along(args)) {
            name <- if (!is.null(arg_names) && arg_names[i] != "") arg_names[i] else ""
            val <- paste(deparse(args[[i]]), collapse = "\n")
            args_list[[length(args_list) + 1]] <- list(name = name, value = val)
        }

        # Check for pipes
        if (fun %in% c("|>", "%>%")) {
            rhs <- call[[3]]
            if (is.call(rhs)) {
                rhs_fun <- deparse(rhs[[1]])
                rhs_args <- tail(as.list(rhs), -1)
                rhs_arg_names <- names(rhs)[-1]
                rhs_args_list <- list()
                for (i in seq_along(rhs_args)) {
                    name <- if (!is.null(rhs_arg_names) && rhs_arg_names[i] != "") rhs_arg_names[i] else ""
                    val <- paste(deparse(rhs_args[[i]]), collapse = "\n")
                    rhs_args_list[[length(rhs_args_list) + 1]] <- list(name = name, value = val)
                }
                return(c(parent_calls, list(list(fun = rhs_fun, args = rhs_args_list))))
            }
        } else {
            return(c(parent_calls, list(list(fun = fun, args = args_list))))
        }
    }
    return(list(list(fun = fun, args = list())))
}

#' Add a Layer Tuner to a map
#'
#' This function adds an interactive live customization widget (using lil-gui) to the map.
#' It allows users to customize paint and layout properties of map layers in real-time.
#'
#' @param map A `mapboxgl` or `maplibre` object.
#' @param layers A character vector of layer IDs to include in the tuner, or `"all"` (default)
#'   to include all compatible layers.
#' @param show_all_args A logical value. If `TRUE`, the exported R code will include all
#'   whitelisted arguments for each layer (using current map values or defaults) even if they
#'   were not explicitly customized in your original R code or during tuning. Default is `FALSE`.
#' @param title Optional title for the tuner panel. Defaults to the built-in
#'   layer tuner title.
#' @param position Initial position of the tuner panel. One of `"top-left"`,
#'   `"top-right"`, `"bottom-left"`, or `"bottom-right"`. Defaults to
#'   `"top-left"`.
#' @param width Initial tuner panel width. Numeric values are interpreted as
#'   pixels; character values are passed through as CSS lengths. Defaults to
#'   `245`.
#' @param height Optional initial tuner panel height. Numeric values are
#'   interpreted as pixels; character values are passed through as CSS lengths.
#'   Defaults to `NULL`, which lets the panel size itself automatically.
#' @param collapsed Logical value indicating whether the tuner panel should be
#'   collapsed initially. Defaults to `FALSE`.
#'
#' @return The modified map object with the layer tuner added.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' mapboxgl() |>
#'   add_flowmap(
#'     id = "flows",
#'     locations = locations,
#'     flows = flows
#'   ) |>
#'   add_layer_tuner(position = "top-right", width = 320)
#' }
add_layer_tuner <- function(
    map,
    layers = "all",
    show_all_args = FALSE,
    title = NULL,
    position = "top-left",
    width = 245,
    height = NULL,
    collapsed = FALSE) {
    position_choices <- c("top-left", "top-right", "bottom-left", "bottom-right")
    if (
        !is.character(position) ||
            length(position) != 1 ||
            is.na(position) ||
            !position %in% position_choices
    ) {
        rlang::abort(paste0(
            "`position` must be one of ",
            paste0("`", position_choices, "`", collapse = ", "),
            "."
        ))
    }
    title <- layer_tuner_optional_string(title, "title")
    width <- layer_tuner_css_length(width, "width")
    height <- layer_tuner_css_length(height, "height", allow_null = TRUE)

    if (!is.logical(collapsed) || length(collapsed) != 1 || is.na(collapsed)) {
        rlang::abort("`collapsed` must be `TRUE` or `FALSE`.")
    }

    # Dynamically query flowmap color schemes so the widget is perfectly auto-populated
    flowmap_schemes <- tryCatch({
        flowmap_color_schemes()
    }, error = function(e) {
        c("Teal", "Blues", "Burg", "BurgYl", "RedOr", "Oranges", "YlOrBr", "YlOrRd", "OrRd", "Reds", "RdPu", "Purples", "Purp", "PurpOr", "Muted", "TealGrn", "Gold", "Peach", "PinkYl", "Mint", "BlkYl", "BlkOrange", "Violet", "TealBlues", "YellowGreen", "OrangePink", "TealGold", "GoldRed", "Sunset", "SunsetDark", "Bny", "BurgPink", "TealMint", "TealSilver", "Onyx")
    })

    # Capture original R pipeline calls dynamically from the R session!
    original_calls <- NULL
    tryCatch({
        calls <- sys.calls()
        pipeline_call <- NULL
        for (c in calls) {
            if (call_contains_constructor(c)) {
                pipeline_call <- c
                break
            }
        }
        if (!is.null(pipeline_call)) {
            original_calls <- parse_pipeline_calls(pipeline_call)
            # Filter out add_layer_tuner call from the reconstructed code to avoid nesting it infinitely
            original_calls <- Filter(function(x) x$fun != "add_layer_tuner", original_calls)
        }
    }, error = function(e) {
        # Silent fallback
    })

  map_type <- if (
    inherits(map, "mapboxgl") ||
      inherits(map, "mapboxgl_compare") ||
      inherits(map, "mapboxgl_compare_proxy")
  ) {
    "mapboxgl"
  } else {
    "maplibre"
  }

  layer_tuner <- list(
    enabled = TRUE,
    layers = layers,
    flowmap_color_schemes = flowmap_schemes,
    map_type = map_type,
    original_calls = original_calls,
    show_all_args = show_all_args,
        title = title,
        position = position,
        width = width,
    height = height,
    collapsed = collapsed
  )
  map$x$layer_tuner <- layer_tuner

  if (inherits(map, "mapboxgl_compare") || inherits(map, "maplibregl_compare")) {
    map$x$map1$layer_tuner <- layer_tuner
    map$x$map2$layer_tuner <- layer_tuner
  }

    lil_gui_dep <- htmltools::htmlDependency(
        name = "lil-gui",
        version = "0.19.0",
        src = c(file = system.file("htmlwidgets/lib/lil-gui", package = "mapgl")),
        script = "lil-gui.umd.min.js"
    )

    layer_tuner_dep <- htmltools::htmlDependency(
        name = "layer-tuner",
        version = "1.0.0",
        src = c(file = system.file("htmlwidgets/lib/layer-tuner", package = "mapgl")),
        script = "layer-tuner.js"
    )

    map$dependencies <- c(map$dependencies, list(lil_gui_dep, layer_tuner_dep))

    if (inherits(map, "mapboxgl_proxy") || inherits(map, "maplibre_proxy")) {
        if (
            inherits(map, "mapboxgl_compare_proxy") ||
                inherits(map, "maplibre_compare_proxy")
        ) {
            proxy_class <- if (inherits(map, "mapboxgl_compare_proxy"))
                "mapboxgl-compare-proxy" else "maplibre-compare-proxy"
            map$session$sendCustomMessage(
                proxy_class,
                list(
                    id = map$id,
                    message = list(
                        type = "add_layer_tuner",
                        layers = layers,
                        layer_tuner = map$x$layer_tuner,
                        map = map$map_side
                    )
                )
            )
        } else {
            proxy_class <- if (inherits(map, "mapboxgl_proxy"))
                "mapboxgl-proxy" else "maplibre-proxy"
            map$session$sendCustomMessage(
                proxy_class,
                list(
                    id = map$id,
                    message = list(
                        type = "add_layer_tuner",
                        layers = layers,
                        layer_tuner = map$x$layer_tuner
                    )
                )
            )
        }
    }

    map
}

layer_tuner_optional_string <- function(value, arg) {
    if (is.null(value)) return(NULL)
    if (
        !is.character(value) ||
            length(value) != 1 ||
            is.na(value) ||
            !nzchar(value)
    ) {
        rlang::abort(paste0("`", arg, "` must be a non-empty string or `NULL`."))
    }
    value
}

layer_tuner_css_length <- function(value, arg, allow_null = FALSE) {
    if (is.null(value)) {
        if (allow_null) return(NULL)
        rlang::abort(paste0("`", arg, "` must be a positive number or CSS length."))
    }

    if (is.numeric(value)) {
        if (
            length(value) != 1 ||
                is.na(value) ||
                !is.finite(value) ||
                value <= 0
        ) {
            rlang::abort(paste0("`", arg, "` must be a positive number or CSS length."))
        }
        return(paste0(value, "px"))
    }

    if (
        !is.character(value) ||
            length(value) != 1 ||
            is.na(value) ||
            !nzchar(trimws(value))
    ) {
        rlang::abort(paste0("`", arg, "` must be a positive number or CSS length."))
    }

    value
}
