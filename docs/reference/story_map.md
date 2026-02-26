# Create a scrollytelling story map

Create a scrollytelling story map

## Usage

``` r
story_map(
  map_id,
  sections,
  map_type = c("mapboxgl", "maplibre", "leaflet"),
  root_margin = "-20% 0px -20% 0px",
  threshold = 0,
  styles = NULL,
  bg_color = "rgba(255,255,255,0.9)",
  text_color = "#34495e",
  font_family = NULL
)
```

## Arguments

- map_id:

  The ID of your mapboxgl, maplibre, or leaflet output defined in the
  server, e.g. `"map"`

- sections:

  A named list of story_section objects. Names will correspond to map
  events defined within the server using
  [`on_section()`](https://walker-data.com/mapgl/reference/on_section.md).

- map_type:

  One of `"mapboxgl"`, `"maplibre"`, or `"leaflet"`. This will use
  either
  [`mapboxglOutput()`](https://walker-data.com/mapgl/reference/mapboxglOutput.md),
  [`maplibreOutput()`](https://walker-data.com/mapgl/reference/maplibreOutput.md),
  or `leafletOutput()` respectively, and must correspond to the
  appropriate `render*()` function used in the server.

- root_margin:

  The margin around the viewport for triggering sections by the
  intersection observer. Should be specified as a string, e.g.
  `"-20% 0px -20% 0px"`.

- threshold:

  A number that indicates the visibility ratio for a story ' panel to be
  used to trigger a section; should be a number between 0 and 1.
  Defaults to 0, meaning that the section is triggered as soon as the
  first pixel is visible.

- styles:

  Optional custom CSS styles. Should be specified as a character string
  within `shiny::tags$style()`.

- bg_color:

  Default background color for all sections

- text_color:

  Default text color for all sections

- font_family:

  Default font family for all sections
