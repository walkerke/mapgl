# mapgl 0.2.1

* Improved styling and positioning behavior of the layers control. Users can now customize the appearance of the layers control, and the layers control is collapsed by default with cleaner appearance.
Added ability to link legends to specific layers with the new `layer_id` parameter in `add_legend()`. When a layer is toggled in the layers control, its associated legend will automatically show or hide.
* Added support for custom legend positioning with new margin parameters (`margin_top`, `margin_right`, `margin_bottom`, `margin_left`) that allow fine-grained control over legend placement.
* Fixed layers control toggle button state to correctly reflect the initial visibility of layers, resolving the issue with layers set to `visibility = "none"` showing as active in the control.
* Support for the `compare()` plugin in Shiny applications, with new rendering and proxy functions for comparison apps in Mapbox and MapLibre.
* New `mode` parameter in `compare()` allowing users to choose between `"swipe"` mode with a comparison slider, and `"sync"` mode which displays synchronized maps side-by-side. 
* Updates throughout the codebase to allow features to be used in comparison maps via Shiny proxy sessions.

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
