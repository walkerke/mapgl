# mapgl 0.2.0

* A new "story map" feature allows users to build interactive story maps.  [View the story mapping vignette](https://walker-data.com/mapgl/articles/story-maps.html) for more information.
* Various bug fixes and performance improvements; [visit the package GitHub page for more details](https://github.com/walkerke/mapgl).

# mapgl 0.1.4

* `add_image()` allows you to add your own image to the map's sprite for use as an icon / symbol layer
* `add_geolocate_control()` adds a Geolocate control to the map
* `add_globe_minimap()` adds a mini globe overview map that tracks how your map moves around the globe
* Support for multiple legends with the argument `add = TRUE`
* A `move_layer()` function that gives you more fine-grained control over layer ordering in a Shiny session
* Various bug fixes and performance improvements.


# mapgl 0.1.3

* Geocoding support for Mapbox and MapLibre maps added with `add_geocoder_control()`
* Freehand draw support in the draw toolbar with `add_draw_control(freehand = TRUE)`
* A "reset view" control available with `add_reset_control()`
* Circle clustering is streamlined with the `cluster_options()` function, to be used with the `cluster_options` argument in `add_circle_layer()` and `add_symbol_layer()`
* Various bug fixes and performance improvements.

# mapgl 0.1.0

* Initial release.
