# Get Esri ArcGIS Basemap Style URL

Generates a style URL for the ArcGIS Basemap Styles Service (v2). These
styles use authoritative Esri data sources (TomTom, Garmin, USGS, etc.).
An ArcGIS access token is required.

## Usage

``` r
esri_style(
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

  The name of the style. Available styles: "navigation",
  "navigation-night", "streets", "streets-night", "streets-relief",
  "community", "outdoor", "topographic", "terrain", "imagery",
  "light-gray", "dark-gray", "oceans", "hillshade", "human-geography",
  "human-geography-dark", "charted-territory", "colored-pencil", "nova",
  "modern-antique", "midcentury", "newspaper".

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

|                      |                      |
|----------------------|----------------------|
| **Style**            | **Variants**         |
| navigation           | (none)               |
| navigation-night     | (none)               |
| streets              | (none)               |
| streets-night        | (none)               |
| streets-relief       | base                 |
| community            | (none)               |
| outdoor              | (none)               |
| topographic          | base                 |
| terrain              | base, detail         |
| imagery              | standard, labels     |
| light-gray           | base, labels         |
| dark-gray            | base, labels         |
| oceans               | base, labels         |
| hillshade            | light, dark          |
| human-geography      | base, detail, labels |
| human-geography-dark | base, detail, labels |
| charted-territory    | base                 |
| colored-pencil       | (none)               |
| nova                 | (none)               |
| modern-antique       | base                 |
| midcentury           | (none)               |
| newspaper            | (none)               |

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
maplibre(style = esri_style("streets"))

# With a variant
maplibre(style = esri_style("topographic", variant = "base"))

# With language and places
maplibre(style = esri_style("navigation", language = "fr", places = "all"))
} # }
```
