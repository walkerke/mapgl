% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/legends.R
\name{clear_legend}
\alias{clear_legend}
\title{Clear legend(s) from a map in a proxy session}
\usage{
clear_legend(map, legend_ids = NULL)
}
\arguments{
\item{map}{A map object created by the \code{mapboxgl_proxy} or \code{maplibre_proxy} function.}

\item{legend_ids}{Optional. A character vector of legend IDs to clear. If not provided, all legends will be cleared.}
}
\value{
The updated map object with the specified legend(s) cleared.
}
\description{
Clear legend(s) from a map in a proxy session
}
