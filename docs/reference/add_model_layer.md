# Add a 3D model layer to a Mapbox GL map

Draws one instance of a 3D model, registered with
[`add_model()`](https://walker-data.com/mapgl/reference/add_model.md),
at each point feature of a source. Mapbox GL JS only.

## Usage

``` r
add_model_layer(
  map,
  id,
  source,
  model_id,
  source_layer = NULL,
  model_scale = NULL,
  model_rotation = NULL,
  model_translation = NULL,
  model_color = NULL,
  model_color_mix_intensity = NULL,
  model_opacity = NULL,
  model_emissive_strength = NULL,
  model_cast_shadows = NULL,
  model_receive_shadows = NULL,
  model_ambient_occlusion_intensity = NULL,
  model_type = NULL,
  model_elevation_reference = NULL,
  visibility = "visible",
  slot = NULL,
  min_zoom = NULL,
  max_zoom = NULL,
  popup = NULL,
  tooltip = NULL,
  tooltip_style = NULL,
  popup_style = NULL,
  hover_options = NULL,
  before_id = NULL,
  filter = NULL
)
```

## Arguments

- map:

  A map object created by the `mapboxgl` or `maplibre` functions.

- id:

  A unique ID for the layer.

- source:

  An sf object of points, or the ID of a GeoJSON or vector source.

- model_id:

  The ID of a model registered with
  [`add_model()`](https://walker-data.com/mapgl/reference/add_model.md),
  or an expression that returns one per feature.

- source_layer:

  The source layer (for vector sources).

- model_scale:

  A numeric vector of length 3, `c(x, y, z)`, scaling the model along
  each axis, or an expression.

- model_rotation:

  A numeric vector of length 3, `c(x, y, z)`, giving rotation around
  each axis in degrees, or an expression.

- model_translation:

  A numeric vector of length 3, `c(x, y, z)`, giving an offset in
  metres, or an expression.

- model_color:

  The color to mix into the model's materials.

- model_color_mix_intensity:

  How much of `model_color` to mix in, from 0 (none) to 1.

- model_opacity:

  The opacity of the model, from 0 to 1.

- model_emissive_strength:

  Emissive strength, used with 3D lights such as those in the Mapbox
  Standard style.

- model_cast_shadows, model_receive_shadows:

  Logical; whether the model casts and receives shadows.

- model_ambient_occlusion_intensity:

  Ambient occlusion intensity, from 0 to 1.

- model_type:

  `"common-3d"` (the default) or `"location-indicator"`.

- model_elevation_reference:

  `"ground"` (the default) to place models on the terrain, or `"sea"` to
  measure translation from sea level.

- visibility:

  Whether this layer is displayed.

- slot:

  An optional slot for layer order.

- min_zoom:

  The minimum zoom level for the layer.

- max_zoom:

  The maximum zoom level for the layer.

- popup:

  Popup content shown on click: a column name, a `{brace}` template
  (e.g. `"{name}: {value}"`), or a
  [`concat()`](https://walker-data.com/mapgl/reference/concat.md)/[`number_format()`](https://walker-data.com/mapgl/reference/number_format.md)
  expression. Columns containing HTML are parsed.

- tooltip:

  Tooltip content shown on hover; same forms as `popup`.

- tooltip_style, popup_style:

  Optional appearance for the tooltip/popup: a preset string (`"light"`
  or `"dark"`) or a
  [`tooltip_style()`](https://walker-data.com/mapgl/reference/tooltip_style.md)
  object. When omitted, the native (unstyled) appearance is kept.

- hover_options:

  A named list of options for highlighting features in the layer on
  hover.

- before_id:

  The name of the layer that this layer appears "before", allowing you
  to insert layers below other layers in your basemap (e.g. labels).

- filter:

  An optional filter expression to subset features in the layer.

## Value

The modified map object.

## Details

Scale, rotation and translation accept data-driven and zoom-based
expressions, so each instance can be sized and oriented from feature
attributes. Expressions can't combine separate columns into an array,
but an `interpolate` expression with array outputs can turn one column
into a `c(x, y, z)` value. For a uniform scale taken from a column `s`:
`model_scale = list("interpolate", list("linear"), get_column("s"), 0, list("literal", list(0, 0, 0)), 10, list("literal", list(10, 10, 10)))`.

Mapbox reads glTF models as y-up and converts them to the map's z-up
frame, with the model's -z axis pointing north. Feature queries and
popups don't reliably register clicks on model geometry; for clickable
models, add a transparent
[`add_fill_extrusion_layer()`](https://walker-data.com/mapgl/reference/add_fill_extrusion_layer.md)
or a circle layer at the same locations and attach the popup there.

Models are drawn in metres: a model whose glTF units are metres appears
at real-world size when `model_scale` is `c(1, 1, 1)`. Instances sit on
the terrain when terrain is set with
[`set_terrain()`](https://walker-data.com/mapgl/reference/set_terrain.md).
