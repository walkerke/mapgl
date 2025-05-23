% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/controls.R
\name{add_control}
\alias{add_control}
\title{Add a custom control to a map}
\usage{
add_control(map, html, position = "top-right", className = NULL, ...)
}
\arguments{
\item{map}{A map object created by the \code{mapboxgl} or \code{maplibre} functions.}

\item{html}{Character string containing the HTML content for the control.}

\item{position}{The position of the control. Can be one of "top-left", "top-right",
"bottom-left", or "bottom-right". Default is "top-right".}

\item{className}{Optional CSS class name for the control container.}

\item{...}{Additional arguments passed to the JavaScript side.}
}
\value{
The modified map object with the custom control added.
}
\description{
This function adds a custom control to a Mapbox GL or MapLibre GL map.
It allows you to create custom HTML element controls and add them to the map.
}
\examples{
\dontrun{
library(mapgl)

maplibre() |>
  add_control(
    html = "<div style='background-color: white; padding: 5px;'>
             <p>Custom HTML</p>
             <img src='path/to/image.png' alt='image'/>
            </div>",
    position = "top-left"
  )
}
}
