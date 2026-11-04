#' Add a 3D model to a Mapbox GL map
#'
#' Registers a glTF or GLB model with the map so that [add_model_layer()] can
#' draw it. Mapbox GL JS only; MapLibre has no model layer.
#'
#' @param map A map object created by [mapboxgl()], or a proxy created by
#'   [mapboxgl_proxy()].
#' @param id A string; the model ID that `model_id` in [add_model_layer()]
#'   refers to.
#' @param url The URL of a `.glb` or `.gltf` file, or the path to a local
#'   `.glb` file, which is embedded in the map as a data URI. A local `.gltf`
#'   file that refers to external buffers or textures can't be embedded;
#'   convert it to `.glb` first.
#'
#' @return The modified map object.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mapgl)
#'
#' turbines <- sf::st_as_sf(
#'   data.frame(lon = c(-100.40, -100.41), lat = c(32.30, 32.31)),
#'   coords = c("lon", "lat"), crs = 4326
#' )
#'
#' mapboxgl(center = c(-100.405, 32.305), zoom = 15, pitch = 70) |>
#'   add_model("turbine", "turbine.glb") |>
#'   add_model_layer("turbines", turbines, model_id = "turbine")
#' }
add_model <- function(map, id, url) {
  if (inherits(map, c("maplibregl", "maplibre_proxy"))) {
    rlang::abort("3D models are only supported by Mapbox GL JS; use `mapboxgl()`.")
  }

  if (file.exists(url)) {
    ext <- tolower(tools::file_ext(url))
    if (ext != "glb") {
      rlang::abort(c(
        "Local models must be `.glb` files.",
        i = "Pass a URL for a `.gltf` file, or convert it to `.glb`."
      ))
    }
    url <- base64enc::dataURI(file = url, mime = "model/gltf-binary")
  }

  model_info <- list(id = id, url = url)

  if (inherits(map, "mapboxgl_compare_proxy")) {
    map$session$sendCustomMessage("mapboxgl-compare-proxy", list(
      id = map$id,
      message = list(
        type = "add_model",
        modelId = id,
        url = url,
        map = map$map_side
      )
    ))
  } else if (inherits(map, "mapboxgl_proxy")) {
    map$session$sendCustomMessage("mapboxgl-proxy", list(
      id = map$id,
      message = list(type = "add_model", modelId = id, url = url)
    ))
  } else if (inherits(map, "mapboxgl")) {
    map$x$models <- c(map$x$models, list(model_info))
  } else {
    rlang::abort("`add_model()` must be used with a `mapboxgl()` map or a `mapboxgl_proxy()`.")
  }

  return(map)
}

#' Add a 3D model layer to a Mapbox GL map
#'
#' Draws one instance of a 3D model, registered with [add_model()], at each
#' point feature of a source. Mapbox GL JS only.
#'
#' Scale, rotation and translation accept data-driven expressions, so each
#' instance can be sized and oriented from feature attributes. Mapbox can't
#' build an array from feature values with `["array", ...]`, but an
#' `interpolate` expression with array outputs can. For a uniform scale taken
#' from a column `s`:
#' `model_scale = list("interpolate", list("linear"), get_column("s"), 0, list("literal", list(0, 0, 0)), 10, list("literal", list(10, 10, 10)))`.
#' Mapbox does not support zoom-dependent expressions on these properties for
#' GeoJSON or vector tile sources.
#'
#' Mapbox reads glTF models as y-up and converts them to the map's z-up frame,
#' with the model's -z axis pointing north. Feature queries and popups don't
#' reliably register clicks on model geometry; for clickable models, add a
#' transparent [add_fill_extrusion_layer()] or a circle layer at the same
#' locations and attach the popup there.
#'
#' Models are drawn in metres: a model whose glTF units are metres appears at
#' real-world size when `model_scale` is `c(1, 1, 1)`. Instances sit on the
#' terrain when terrain is set with [set_terrain()].
#'
#' @inheritParams add_fill_extrusion_layer
#' @param source An sf object of points, or the ID of a GeoJSON or vector
#'   source.
#' @param model_id The ID of a model registered with [add_model()], or an
#'   expression that returns one per feature.
#' @param model_scale A numeric vector of length 3, `c(x, y, z)`, scaling the
#'   model along each axis, or an expression.
#' @param model_rotation A numeric vector of length 3, `c(x, y, z)`, giving
#'   rotation around each axis in degrees, or an expression.
#' @param model_translation A numeric vector of length 3, `c(x, y, z)`, giving
#'   an offset in metres, or an expression.
#' @param model_color The color to mix into the model's materials.
#' @param model_color_mix_intensity How much of `model_color` to mix in, from 0
#'   (none) to 1.
#' @param model_opacity The opacity of the model, from 0 to 1.
#' @param model_emissive_strength Emissive strength, used with 3D lights such as
#'   those in the Mapbox Standard style.
#' @param model_cast_shadows,model_receive_shadows Logical; whether the model
#'   casts and receives shadows.
#' @param model_ambient_occlusion_intensity Ambient occlusion intensity, from 0
#'   to 1.
#' @param model_type `"common-3d"` (the default) or `"location-indicator"`.
#' @param model_elevation_reference `"ground"` (the default) to place models on
#'   the terrain, or `"sea"` to measure translation from sea level.
#'
#' @return The modified map object.
#' @export
add_model_layer <- function(
  map,
  id,
  source,
  model_id,
  source_layer = NULL,
  model_scale = NULL,
  model_rotation = NULL,
  model_translation = NULL,
  model_color = NULL,
  model_color_mix_intensity = NULL,
  model_opacity = NULL,
  model_emissive_strength = NULL,
  model_cast_shadows = NULL,
  model_receive_shadows = NULL,
  model_ambient_occlusion_intensity = NULL,
  model_type = NULL,
  model_elevation_reference = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
) {
  if (inherits(map, c("maplibregl", "maplibre_proxy"))) {
    rlang::abort("Model layers are only supported by Mapbox GL JS; use `mapboxgl()`.")
  }

  as_xyz <- function(x, arg) {
    if (is.null(x) || is.list(x)) return(x)
    if (!is.numeric(x) || length(x) != 3) {
      rlang::abort(sprintf("`%s` must be a numeric vector of length 3 or an expression.", arg))
    }
    as.list(x)
  }

  paint <- list(
    "model-scale" = as_xyz(model_scale, "model_scale"),
    "model-rotation" = as_xyz(model_rotation, "model_rotation"),
    "model-translation" = as_xyz(model_translation, "model_translation"),
    "model-color" = model_color,
    "model-color-mix-intensity" = model_color_mix_intensity,
    "model-opacity" = model_opacity,
    "model-emissive-strength" = model_emissive_strength,
    "model-cast-shadows" = model_cast_shadows,
    "model-receive-shadows" = model_receive_shadows,
    "model-ambient-occlusion-intensity" = model_ambient_occlusion_intensity,
    "model-type" = model_type,
    "model-elevation-reference" = model_elevation_reference
  )
  paint <- paint[!vapply(paint, is.null, logical(1))]

  layout <- list("model-id" = model_id)
  if (!is.null(visibility)) layout[["visibility"]] <- visibility

  add_layer(
    map,
    id,
    "model",
    source,
    source_layer,
    paint,
    layout,
    slot,
    min_zoom,
    max_zoom,
    popup,
    tooltip,
    hover_options,
    before_id,
    filter,
    tooltip_style = tooltip_style,
    popup_style = popup_style
  )
}
