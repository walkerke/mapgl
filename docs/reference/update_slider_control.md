# Update a slider control from Shiny

Proxy-only companion to
[`add_slider_control()`](https://walker-data.com/mapgl/reference/add_slider_control.md).
Moves the slider to a specific value, starts or stops playback, or
adjusts playback speed without recreating the control.

## Usage

``` r
update_slider_control(
  proxy,
  value = NULL,
  playing = NULL,
  animation_duration = NULL
)
```

## Arguments

- proxy:

  A proxy object from
  [`mapboxgl_proxy()`](https://walker-data.com/mapgl/reference/mapboxgl_proxy.md)
  or
  [`maplibre_proxy()`](https://walker-data.com/mapgl/reference/maplibre_proxy.md).

- value:

  Numeric; one of the values the slider was created with. The slider
  snaps to the closest value if an exact match is not found.

- playing:

  Logical; `TRUE` starts playback, `FALSE` stops.

- animation_duration:

  Milliseconds per step when playing.

## Value

The proxy object, invisibly.
