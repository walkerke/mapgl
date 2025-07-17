/**
 * Marker management for Mapbox GL JS
 * Handles marker creation, popups, and Shiny integration
 */

function setupMarkers(map, x, el) {
  if (x.markers) {
    if (!window.mapboxglMarkers) {
      window.mapboxglMarkers = [];
    }
    x.markers.forEach(function (marker) {
      const markerOptions = {
        color: marker.color,
        rotation: marker.rotation,
        draggable: marker.options.draggable || false,
        ...marker.options,
      };
      const mapMarker = new mapboxgl.Marker(markerOptions)
        .setLngLat([marker.lng, marker.lat])
        .addTo(map);

      if (marker.popup) {
        mapMarker.setPopup(
          new mapboxgl.Popup({ offset: 25 }).setHTML(marker.popup),
        );
      }

      if (HTMLWidgets.shinyMode) {
        const markerId = marker.id;
        if (markerId) {
          const lngLat = mapMarker.getLngLat();
          Shiny.setInputValue(el.id + "_marker_" + markerId, {
            id: markerId,
            lng: lngLat.lng,
            lat: lngLat.lat,
          });

          mapMarker.on("dragend", function () {
            const lngLat = mapMarker.getLngLat();
            Shiny.setInputValue(el.id + "_marker_" + markerId, {
              id: markerId,
              lng: lngLat.lng,
              lat: lngLat.lat,
            });
          });
        }
      }

      window.mapboxglMarkers.push(mapMarker);
    });
  }
}