.mapgl_draw_sync <- new.env(parent = emptyenv())
.mapgl_draw_sync$server <- NULL
.mapgl_draw_sync$port <- NULL
.mapgl_draw_sync$cache <- new.env(parent = emptyenv())

reg.finalizer(.mapgl_draw_sync, function(e) {
  .mapgl_draw_sync_stop(e)
}, onexit = TRUE)

.mapgl_new_id <- function() {
  hex <- sample(c(0:9, letters[1:6]), 32, replace = TRUE)
  paste0(
    paste0(hex[1:8], collapse = ""),
    "-",
    paste0(hex[9:12], collapse = ""),
    "-",
    paste0(hex[13:16], collapse = ""),
    "-",
    paste0(hex[17:20], collapse = ""),
    "-",
    paste0(hex[21:32], collapse = "")
  )
}

.mapgl_empty_drawn_features <- function() {
  sf::st_sf(
    id = integer(),
    geometry = sf::st_sfc(crs = 4326)
  )
}

.mapgl_draw_sync_headers <- function() {
  list(
    "Access-Control-Allow-Origin" = "*",
    "Access-Control-Allow-Methods" = "POST, OPTIONS",
    "Access-Control-Allow-Headers" = "content-type"
  )
}

.mapgl_draw_sync_app <- function(cache) {
  list(
    call = function(req) {
      headers <- .mapgl_draw_sync_headers()

      if (identical(req$REQUEST_METHOD, "OPTIONS")) {
        return(list(status = 200L, headers = headers, body = ""))
      }

      path <- req$PATH_INFO %||% ""
      if (!identical(req$REQUEST_METHOD, "POST") ||
        !grepl("^/features/[^/]+$", path)) {
        return(list(status = 404L, headers = headers, body = ""))
      }

      mapgl_id <- utils::URLdecode(sub("^/features/", "", path))
      body <- rawToChar(req$rook.input$read())
      cache[[mapgl_id]] <- body

      list(status = 200L, headers = headers, body = "ok")
    }
  )
}

.mapgl_draw_sync_start <- function() {
  if (!is.null(.mapgl_draw_sync$server)) {
    return(invisible(.mapgl_draw_sync))
  }

  last_error <- NULL
  for (i in seq_len(10)) {
    port <- httpuv::randomPort()
    server <- tryCatch(
      httpuv::startServer(
        "127.0.0.1",
        port,
        .mapgl_draw_sync_app(.mapgl_draw_sync$cache)
      ),
      error = function(e) {
        last_error <<- e
        NULL
      }
    )

    if (!is.null(server)) {
      .mapgl_draw_sync$server <- server
      .mapgl_draw_sync$port <- port
      return(invisible(.mapgl_draw_sync))
    }
  }

  rlang::abort(
    c(
      "Could not start the mapgl draw sync server.",
      x = conditionMessage(last_error)
    )
  )
}

.mapgl_draw_sync_stop <- function(e = .mapgl_draw_sync) {
  if (!is.null(e$server)) {
    try(httpuv::stopServer(e$server), silent = TRUE)
    e$server <- NULL
    e$port <- NULL
  }
  invisible(NULL)
}

.mapgl_draw_sync_url <- function(mapgl_id) {
  .mapgl_draw_sync_start()
  sprintf(
    "http://127.0.0.1:%s/features/%s",
    .mapgl_draw_sync$port,
    utils::URLencode(mapgl_id, reserved = TRUE)
  )
}

.mapgl_draw_sync_service <- function(timeout_ms = 50) {
  if (is.null(.mapgl_draw_sync$server)) {
    return(invisible(FALSE))
  }

  deadline <- Sys.time() + (timeout_ms / 1000)
  repeat {
    try(httpuv::service(10), silent = TRUE)
    if (Sys.time() >= deadline) {
      break
    }
  }

  invisible(TRUE)
}

.mapgl_draw_sync_get <- function(mapgl_id) {
  .mapgl_draw_sync_service(250)
  .mapgl_draw_sync$cache[[mapgl_id]]
}

.mapgl_coerce_drawn_features <- function(features) {
  if (is.null(features) || identical(features, "null")) {
    return(.mapgl_empty_drawn_features())
  }

  if (is.character(features)) {
    features_json <- paste(features, collapse = "\n")
    if (!nzchar(features_json)) {
      return(.mapgl_empty_drawn_features())
    }
  } else {
    features_json <- jsonlite::toJSON(
      features,
      auto_unbox = TRUE,
      null = "null",
      na = "null"
    )
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(features_json, simplifyVector = FALSE),
    error = function(e) NULL
  )

  if (is.null(parsed) ||
    !identical(parsed$type, "FeatureCollection") ||
    length(parsed$features %||% list()) == 0) {
    return(.mapgl_empty_drawn_features())
  }

  sf_obj <- geojsonsf::geojson_sf(features_json)
  sf_obj <- sf::st_make_valid(sf_obj)
  sf::st_crs(sf_obj) <- 4326
  if (!"id" %in% names(sf_obj)) {
    sf_obj$id <- seq_len(nrow(sf_obj))
  }
  sf_obj <- sf_obj[c(setdiff(names(sf_obj), attr(sf_obj, "sf_column")), attr(sf_obj, "sf_column"))]
  sf_obj
}

.mapgl_shiny_input_value <- function(session, input_id) {
  tryCatch(
    session$input[[input_id]],
    error = function(e) shiny::isolate(session$input[[input_id]])
  )
}

.onUnload <- function(libpath) {
  .mapgl_draw_sync_stop()
}
