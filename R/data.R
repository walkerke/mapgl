#' BIXI Montréal Bike Share Stations (2019)
#'
#' A dataset containing the names and coordinates of BIXI bicycle sharing
#' stations in Montréal, Quebec, Canada.
#'
#' @format A data frame with 618 rows and 4 variables:
#' \describe{
#'   \item{id}{Unique station ID (character, e.g., `"4000"`, `"MTL-ECO5.1-01"`)}
#'   \item{name}{Station name (character, e.g., `"Jeanne-d'Arc / Ontario"`)}
#'   \item{lat}{Latitude coordinate (numeric)}
#'   \item{lon}{Longitude coordinate (numeric)}
#' }
#' @source BIXI Montréal Open Data (\url{https://bixi.com/fr/donnees-ouvertes}).
#'   Prepared for \url{https://github.com/FlowmapBlue/FlowmapBlue} by Ilya Boyandin (\url{https://twitter.com/ilyabo}).
#' @seealso \code{\link{bixi_flows}}
#' @examples
#' # Convert to sf object to view on a map
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   bixi_sf <- sf::st_as_sf(bixi_locations, coords = c("lon", "lat"), crs = 4326)
#'   print(head(bixi_sf))
#' }
"bixi_locations"

#' BIXI Montréal Hourly Bike Sharing Flows (July 1-7, 2019)
#'
#' A dataset containing hourly aggregated bike sharing trips between BIXI
#' stations in Montréal during the week of July 1 to July 7, 2019.
#'
#' To minimize the package footprint, the dataset has been truncated to a
#' **minimum of three trips** (retaining only flows where \code{count > 2}),
#' which reduces the rows from 213,227 to 6,092, and compresses the final size
#' to just **~22 KB**.
#'
#' @format A data frame with 6,092 rows and 4 variables:
#' \describe{
#'   \item{time}{Hourly timestamp (POSIXct, UTC)}
#'   \item{origin}{Origin station ID (factor, matching \code{bixi_locations$id})}
#'   \item{dest}{Destination station ID (factor, matching \code{bixi_locations$id})}
#'   \item{count}{Aggregated number of bike sharing trips in that hour (integer)}
#' }
#' @source BIXI Montréal Open Data (\url{https://bixi.com/fr/donnees-ouvertes}).
#'   Prepared for \url{https://github.com/FlowmapBlue/FlowmapBlue} by Ilya Boyandin (\url{https://twitter.com/ilyabo}).
#'   Original interactive visualization on Flowmap.blue:
#'   \url{https://www.flowmap.blue/1qTVOzkPB7U1ySI4g4uPtVBzzEDCI8n1WXAmQeZL15fE}
#' @seealso \code{\link{bixi_locations}}
#' @examples
#' # Check first few records
#' print(head(bixi_flows))
"bixi_flows"
