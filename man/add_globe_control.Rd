% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/controls.R
\name{add_globe_control}
\alias{add_globe_control}
\title{Add a globe control to a map}
\usage{
add_globe_control(map, position = "top-right")
}
\arguments{
\item{map}{A map object created by the \code{maplibre} function.}

\item{position}{The position of the control. Can be one of "top-left", "top-right",
"bottom-left", or "bottom-right". Default is "top-right".}
}
\value{
The modified map object with the globe control added.
}
\description{
This function adds a globe control to a MapLibre GL map that allows toggling
between "mercator" and "globe" projections with a single click.
}
\examples{
\dontrun{
library(mapgl)

maplibre() |>
    add_globe_control(position = "top-right")
}
}
