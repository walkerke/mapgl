# Initialize a Maplibre GL Map

Initialize a Maplibre GL Map

## Usage

``` r
maplibre(
  style = carto_style("voyager"),
  center = c(0, 0),
  zoom = 0,
  bearing = 0,
  pitch = 0,
  projection = "globe",
  bounds = NULL,
  width = "100%",
  height = NULL,
  ...
)
```

## Arguments

- style:

  The style JSON to use.

- center:

  A numeric vector of length 2 specifying the initial center of the map.

- zoom:

  The initial zoom level of the map.

- bearing:

  The initial bearing (rotation) of the map, in degrees.

- pitch:

  The initial pitch (tilt) of the map, in degrees.

- projection:

  The map projection to use (e.g., "mercator", "globe").

- bounds:

  The bounding box to fit the map to. Accepts one of the following:

  - `sf` object;

  - output of
    [`st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html);

  - unnamed numeric vector of the form `c(xmin, ymin, xmax, ymax)`.

- width:

  The width of the output htmlwidget.

- height:

  The height of the output htmlwidget.

- ...:

  Additional named parameters to be passed to the MapLibre GL JS Map.
  See the MapLibre GL JS documentation for a full list of options:
  <https://maplibre.org/maplibre-gl-js/docs/API/type-aliases/MapOptions/>.
  Common options include:

  - `minZoom` / `maxZoom`: Minimum and maximum zoom levels (0-24).

  - `maxBounds`: Restrict panning to a bounding box, specified as
    `list(c(sw_lng, sw_lat), c(ne_lng, ne_lat))`.

  - `dragRotate`: If `FALSE`, disables rotation via mouse drag (default
    `TRUE`).

  - `touchZoomRotate`: If `FALSE`, disables pinch-to-rotate on touch
    (default `TRUE`).

  - `scrollZoom`: If `FALSE`, disables scroll wheel zoom (default
    `TRUE`).

## Value

An HTML widget for a MapLibre GL map.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic map
maplibre()

# Constrained map with zoom limits and disabled rotation
maplibre(
  bounds = my_sf_object,
  minZoom = 5,
  maxZoom = 12,
  dragRotate = FALSE,
  touchZoomRotate = FALSE
)
} # }
```
