# Download lil-gui assets for the layer tuner
dir.create(
  "inst/htmlwidgets/lib/lil-gui",
  recursive = TRUE,
  showWarnings = FALSE
)
download.file(
  "https://cdn.jsdelivr.net/npm/lil-gui@0.19/dist/lil-gui.umd.min.js",
  destfile = "inst/htmlwidgets/lib/lil-gui/lil-gui.umd.min.js"
)
