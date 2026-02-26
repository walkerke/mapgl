# Add markers to a Mapbox GL or Maplibre GL map

Add markers to a Mapbox GL or Maplibre GL map

## Usage

``` r
add_markers(
  map,
  data,
  color = "red",
  rotation = 0,
  popup = NULL,
  marker_id = NULL,
  draggable = FALSE,
  ...
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- data:

  A length-2 numeric vector of coordinates, a list of length-2 numeric
  vectors, or an `sf` POINT object.

- color:

  The color of the marker (default is "red").

- rotation:

  The rotation of the marker (default is 0).

- popup:

  A column name for popups (if data is an `sf` object) or a string for a
  single popup (if data is a numeric vector or list of vectors).

- marker_id:

  A unique ID for the marker. For lists, names will be inherited from
  the list names. For `sf` objects, this should be a column name.

- draggable:

  A boolean indicating if the marker should be draggable (default is
  FALSE).

- ...:

  Additional options passed to the marker.

## Value

The modified map object with the markers added.

## Examples

``` r
if (FALSE) { # \dontrun{
library(mapgl)
library(sf)

# Create a map object
map <- mapboxgl(
  style = mapbox_style("streets"),
  center = c(-74.006, 40.7128),
  zoom = 10
)

# Add a single draggable marker with an ID
map <- add_markers(
  map,
  c(-74.006, 40.7128),
  color = "blue",
  rotation = 45,
  popup = "A marker",
  draggable = TRUE,
  marker_id = "marker1"
)

# Add multiple markers from a named list of coordinates
coords_list <- list(marker2 = c(-74.006, 40.7128),
                    marker3 = c(-73.935242, 40.730610))
map <- add_markers(
  map,
  coords_list,
  color = "green",
  popup = "Multiple markers",
  draggable = TRUE
)

# Create an sf POINT object
points_sf <- st_as_sf(data.frame(
  id = c("marker4", "marker5"),
  lon = c(-74.006, -73.935242),
  lat = c(40.7128, 40.730610)
), coords = c("lon", "lat"), crs = 4326)
points_sf$popup <- c("Point 1", "Point 2")

# Add multiple markers from an sf object with IDs from a column
map <- add_markers(
  map,
  points_sf,
  color = "red",
  popup = "popup",
  draggable = TRUE,
  marker_id = "id"
)
} # }
```
