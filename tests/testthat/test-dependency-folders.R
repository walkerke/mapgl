test_that("each widget dependency ships only its own folder", {
  # A dependency's whole src folder is copied when a map is saved, so a src of "htmlwidgets" would copy the
  # package's entire widget directory, and two dependencies sharing a folder would copy it twice.
  for (widget_name in c("mapboxgl", "maplibregl", "mapboxgl_compare", "maplibregl_compare")) {
    deps <- htmlwidgets::getDependency(widget_name, "mapgl")
    local <- Filter(function(d) !is.null(d$src$file), deps)
    srcs <- vapply(local, function(d) d$src$file, character(1))
    names(srcs) <- vapply(local, function(d) d$name, character(1))
    # the widget's own binding is added by htmlwidgets with only its listed file copied
    others <- srcs[!grepl("-binding$", names(srcs))]
    expect_false(any(others == "htmlwidgets"), info = widget_name)
    expect_false(anyDuplicated(others) > 0, info = paste(widget_name, paste(others[duplicated(others)], collapse = ", ")))
  }
})
