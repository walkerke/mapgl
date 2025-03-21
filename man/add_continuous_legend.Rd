% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/legends.R
\name{add_continuous_legend}
\alias{add_continuous_legend}
\title{Add a continuous legend}
\usage{
add_continuous_legend(
  map,
  legend_title,
  values,
  colors,
  position = "top-left",
  unique_id = NULL,
  add = FALSE,
  width = NULL,
  layer_id = NULL,
  margin_top = NULL,
  margin_right = NULL,
  margin_bottom = NULL,
  margin_left = NULL
)
}
\arguments{
\item{map}{A map object created by the \code{mapboxgl} function.}

\item{legend_title}{The title of the legend.}

\item{values}{The values being represented on the map (vector of stops).}

\item{colors}{The colors used to generate the color ramp.}

\item{position}{The position of the legend on the map (one of "top-left", "bottom-left", "top-right", "bottom-right").}

\item{unique_id}{A unique ID for the legend container. Defaults to NULL.}

\item{add}{Logical, whether to add this legend to existing legends (TRUE) or replace existing legends (FALSE). Default is FALSE.}

\item{width}{The width of the legend. Can be specified in pixels (e.g., "250px") or as "auto". Default is NULL, which uses the built-in default.}

\item{layer_id}{The ID of the layer that this legend is associated with. If provided, the legend will be shown/hidden when the layer visibility is toggled.}

\item{margin_top}{Custom top margin in pixels, allowing for fine control over legend positioning. Default is NULL (uses standard positioning).}

\item{margin_right}{Custom right margin in pixels. Default is NULL.}

\item{margin_bottom}{Custom bottom margin in pixels. Default is NULL.}

\item{margin_left}{Custom left margin in pixels. Default is NULL.}
}
\value{
The updated map object with the legend added.
}
\description{
Add a continuous legend
}
