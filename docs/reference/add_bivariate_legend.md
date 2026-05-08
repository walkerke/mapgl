# Add a bivariate legend

Add a bivariate legend

## Usage

``` r
add_bivariate_legend(
  map,
  scale,
  legend_title = NULL,
  x_title = NULL,
  y_title = NULL,
  position = "top-left",
  width = NULL,
  style = NULL,
  add = FALSE,
  unique_id = NULL,
  layer_id = NULL,
  target = "compare",
  draggable = FALSE,
  collapsible = FALSE,
  collapsed = FALSE
)
```

## Arguments

- map:

  A map object created by
  [`mapboxgl()`](https://walker-data.com/mapgl/reference/mapboxgl.md) or
  [`maplibre()`](https://walker-data.com/mapgl/reference/maplibre.md), a
  compare object, or a proxy object.

- scale:

  A `mapgl_bivariate_scale` object from
  [`bivariate_scale()`](https://walker-data.com/mapgl/reference/bivariate_scale.md).

- legend_title:

  Optional legend title.

- x_title:

  Label for the horizontal axis. Defaults to the x column name.

- y_title:

  Label for the vertical axis. Defaults to the y column name.

- position:

  The legend position.

- width:

  Legend width.

- style:

  Optional styling options from
  [`legend_style()`](https://walker-data.com/mapgl/reference/legend_style.md)
  or a list.

- add:

  Logical, whether to add to existing legends.

- unique_id:

  Optional unique legend ID.

- layer_id:

  Optional associated layer ID for layer-control show/hide.

- target:

  For compare objects, one of `"compare"`, `"before"`, or `"after"`.

- draggable:

  Logical, whether the legend can be dragged.

- collapsible:

  Logical, whether the legend can collapse.

- collapsed:

  Logical, whether the legend starts collapsed.

## Value

The updated map object.
