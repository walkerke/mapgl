% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/style_helpers.R
\name{interpolate_palette}
\alias{interpolate_palette}
\title{Create an interpolation expression with automatic palette and break calculation}
\usage{
interpolate_palette(
  column,
  data_values,
  method = "equal",
  n = 5,
  palette = viridisLite::viridis,
  na_color = "grey"
)
}
\arguments{
\item{column}{The name of the column to use for the interpolation.}

\item{data_values}{A numeric vector of the actual data values used to calculate breaks.}

\item{method}{The method for calculating breaks. Options are "equal" (equal intervals),
"quantile" (quantile breaks), or "jenks" (Jenks natural breaks). Defaults to "equal".}

\item{n}{The number of break points to create. Defaults to 5.}

\item{palette}{A function that takes n and returns a character vector of colors.
Defaults to viridisLite::viridis.}

\item{na_color}{The color to use for missing values. Defaults to "grey".}
}
\value{
A list of class "mapgl_continuous_scale" containing the interpolation expression and metadata.
}
\description{
This function creates an interpolation expression by automatically calculating
break points using different methods and applying a color palette. It handles
the values/stops matching automatically and supports the same classification
methods as the step functions.
}
\examples{
\dontrun{
# Create continuous color scale
data_values <- c(10, 25, 30, 45, 60, 75, 90)
scale <- interpolate_palette("value", data_values, method = "equal", n = 5)

# Use in a layer
add_fill_layer(map, fill_color = scale$expression)

# Extract legend information  
labels <- get_legend_labels(scale, format = "currency")
colors <- scale$colors
}
}
