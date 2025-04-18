% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/layers.R
\name{add_line_layer}
\alias{add_line_layer}
\title{Add a line layer to a map}
\usage{
add_line_layer(
  map,
  id,
  source,
  source_layer = NULL,
  line_blur = NULL,
  line_cap = NULL,
  line_color = NULL,
  line_dasharray = NULL,
  line_emissive_strength = NULL,
  line_gap_width = NULL,
  line_gradient = NULL,
  line_join = NULL,
  line_miter_limit = NULL,
  line_occlusion_opacity = NULL,
  line_offset = NULL,
  line_opacity = NULL,
  line_pattern = NULL,
  line_round_limit = NULL,
  line_sort_key = NULL,
  line_translate = NULL,
  line_translate_anchor = "map",
  line_trim_color = NULL,
  line_trim_fade_range = NULL,
  line_trim_offset = NULL,
  line_width = NULL,
  line_z_offset = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
)
}
\arguments{
\item{map}{A map object created by the \code{mapboxgl} or \code{maplibre} functions.}

\item{id}{A unique ID for the layer.}

\item{source}{The ID of the source, alternatively an sf object (which will be
converted to a GeoJSON source) or a named list that specifies \code{type} and
\code{url} for a remote source.}

\item{source_layer}{The source layer (for vector sources).}

\item{line_blur}{Amount to blur the line, in pixels.}

\item{line_cap}{The display of line endings. One of "butt", "round", "square".}

\item{line_color}{The color with which the line will be drawn.}

\item{line_dasharray}{Specifies the lengths of the alternating dashes and
gaps that form the dash pattern.}

\item{line_emissive_strength}{Controls the intensity of light emitted on the
source features.}

\item{line_gap_width}{Draws a line casing outside of a line's actual path.
Value indicates the width of the inner gap.}

\item{line_gradient}{A gradient used to color a line feature at various
distances along its length.}

\item{line_join}{The display of lines when joining.}

\item{line_miter_limit}{Used to automatically convert miter joins to bevel
joins for sharp angles.}

\item{line_occlusion_opacity}{Opacity multiplier of the line part that is
occluded by 3D objects.}

\item{line_offset}{The line's offset.}

\item{line_opacity}{The opacity at which the line will be drawn.}

\item{line_pattern}{Name of image in sprite to use for drawing image lines.}

\item{line_round_limit}{Used to automatically convert round joins to miter
joins for shallow angles.}

\item{line_sort_key}{Sorts features in ascending order based on this value.}

\item{line_translate}{The geometry's offset. Values are \code{c(x, y)} where
negatives indicate left and up, respectively.}

\item{line_translate_anchor}{Controls the frame of reference for \code{line-translate}.}

\item{line_trim_color}{The color to be used for rendering the trimmed line section.}

\item{line_trim_fade_range}{The fade range for the trim-start and trim-end points.}

\item{line_trim_offset}{The line part between \code{c(trim_start, trim_end)} will be
painted using \code{line_trim_color}.}

\item{line_width}{Stroke thickness.}

\item{line_z_offset}{Vertical offset from ground, in meters.}

\item{visibility}{Whether this layer is displayed.}

\item{slot}{An optional slot for layer order.}

\item{min_zoom}{The minimum zoom level for the layer.}

\item{max_zoom}{The maximum zoom level for the layer.}

\item{popup}{A column name containing information to display in a popup on click.
Columns containing HTML will be parsed.}

\item{tooltip}{A column name containing information to display in a tooltip on hover.
Columns containing HTML will be parsed.}

\item{hover_options}{A named list of options for highlighting features in the
layer on hover.}

\item{before_id}{The name of the layer that this layer appears "before",
allowing you to insert layers below other layers in your basemap (e.g. labels)}

\item{filter}{An optional filter expression to subset features in the layer.}
}
\value{
The modified map object with the new line layer added.
}
\description{
Add a line layer to a map
}
\examples{
\dontrun{
library(mapgl)
library(tigris)

loving_roads <- roads("TX", "Loving")

maplibre(style = maptiler_style("backdrop")) |>
    fit_bounds(loving_roads) |>
    add_line_layer(
        id = "tracks",
        source = loving_roads,
        line_color = "navy",
        line_opacity = 0.7
    )
}
}
