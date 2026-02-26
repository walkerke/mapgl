# Get Esri Open Basemap Style URL

Generates a style URL for the ArcGIS Open Basemap Styles. These styles
use open data from Overture Maps and OpenStreetMap. An ArcGIS access
token is required.

## Usage

``` r
esri_open_style(
  style_name,
  variant = NULL,
  token = NULL,
  language = NULL,
  worldview = NULL,
  places = NULL
)
```

## Arguments

- style_name:

  The name of the style. Available styles: "osm-style",
  "osm-style-relief", "navigation", "navigation-dark", "streets",
  "streets-relief", "streets-night", "hybrid", "light-gray",
  "dark-gray", "blueprint".

- variant:

  An optional variant for the style. Not all styles support variants.
  Use the style table in Details to see which variants are available.

- token:

  An ArcGIS access token (character) or an `httr2_token` object as
  returned by
  [`arcgisutils::auth_user()`](https://rdrr.io/pkg/arcgisutils/man/auth.html)
  and similar functions. If not provided, the function will attempt to
  use the `ARCGIS_API_KEY` environment variable.

- language:

  An optional language code for map labels (e.g., "fr", "zh-CN").

- worldview:

  An optional worldview for boundary representation.

- places:

  An optional POI visibility setting: "all", "attributed", or "none".

## Value

A style URL string for use with
[`maplibre`](https://walker-data.com/mapgl/reference/maplibre.md).

## Details

The following styles and variant options are available:

|                  |              |
|------------------|--------------|
| **Style**        | **Variants** |
| osm-style        | (none)       |
| osm-style-relief | base         |
| navigation       | (none)       |
| navigation-dark  | (none)       |
| streets          | (none)       |
| streets-relief   | base         |
| streets-night    | (none)       |
| hybrid           | detail       |
| light-gray       | base, labels |
| dark-gray        | base, labels |
| blueprint        | (none)       |

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
maplibre(style = esri_open_style("streets"))

# With a variant
maplibre(style = esri_open_style("light-gray", variant = "labels"))

# Dark navigation style
maplibre(style = esri_open_style("navigation-dark"))
} # }
```
