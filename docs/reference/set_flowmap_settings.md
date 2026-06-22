# Update a flowmap setting

Updates one setting of a flowmap layer.

## Usage

``` r
set_flowmap_settings(map, id, name, value)
```

## Arguments

- map:

  A map object created by
  [`mapboxgl()`](https://walker-data.com/mapgl/reference/mapboxgl.md) or
  [`maplibre()`](https://walker-data.com/mapgl/reference/maplibre.md),
  or a proxy object created by
  [`mapboxgl_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_proxy.md)
  or
  [`maplibre_proxy()`](https://walker-data.com/mapgl/reference/maplibre_proxy.md).

- id:

  The ID of the flowmap layer to update.

- name:

  The setting name to update. Supported canonical FlowMapGL setting
  names are `opacity`, `colorScheme`, `darkMode`, `fadeAmount`,
  `highlightColor`, `locationsEnabled`, `locationTotalsEnabled`,
  `locationLabelsEnabled`, `flowLinesRenderingMode`,
  `flowLineThicknessScale`, `flowLineCurviness`, `clusteringEnabled`,
  `clusteringAuto`, `clusteringLevel`, `fadeEnabled`,
  `fadeOpacityEnabled`, `adaptiveScalesEnabled`, `temporalScaleDomain`,
  `maxTopFlowsDisplayNum`, and `flowEndpointsInViewportMode`. Snake-case
  aliases such as `color_scheme`, `temporal_scale_domain`, and
  `max_top_flows_display_num` are accepted and normalized internally.
  Filter state (`selectedTimeRange`, `selectedLocations`, and
  `locationFilterMode`) must be updated with
  [`set_flowmap_filter()`](https://walker-data.com/mapgl/reference/set_flowmap_filter.md).

- value:

  The setting value.

## Value

The modified map object.

## Details

`colorScheme` accepts the same values as `flow_color_scheme` in
[`add_flowmap()`](https://walker-data.com/mapgl/reference/add_flowmap.md):
a FlowMapGL preset name, a character vector of at least two CSS colors,
or a `mapgl_continuous_scale` object from
[`interpolate_palette()`](https://walker-data.com/mapgl/reference/interpolate_palette.md).
`opacity` must be between 0 and 1. `fadeAmount` must be between 0 and
100. `maxTopFlowsDisplayNum` must be positive. `clusteringLevel` must be
numeric or `NULL`. `flowLinesRenderingMode` must be `"straight"`,
`"animated-straight"`, or `"curved"`. `temporalScaleDomain` must be
`"selected"` or `"all"`. `flowEndpointsInViewportMode` must be `"any"`
or `"both"`. Boolean settings must be scalar `TRUE` or `FALSE`.
