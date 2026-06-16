# Download D3.js assets for the Time Control
dir.create("inst/htmlwidgets/lib/d3", recursive = TRUE, showWarnings = FALSE)
download.file(
  "https://cdn.jsdelivr.net/npm/d3@7.9.0/dist/d3.min.js",
  destfile = "inst/htmlwidgets/lib/d3/d3.min.js"
)
