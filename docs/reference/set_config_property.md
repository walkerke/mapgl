# Set a configuration property for a Mapbox GL map

Set a configuration property for a Mapbox GL map

## Usage

``` r
set_config_property(map, import_id, config_name, value)
```

## Arguments

- map:

  A map object created by the `mapboxgl` function or a proxy object
  defined with
  [`mapboxgl_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_proxy.md).

- import_id:

  The name of the imported style to set the config for (e.g.,
  'basemap').

- config_name:

  The name of the configuration property from the style.

- value:

  The value to set for the configuration property.

## Value

The updated map object with the configuration property set.
