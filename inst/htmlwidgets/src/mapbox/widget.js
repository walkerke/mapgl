/**
 * HTMLWidgets factory for Mapbox GL JS
 * Main widget definition and initialization logic
 */

HTMLWidgets.widget({
  name: "mapboxgl",

  type: "output",

  factory: function (el, width, height) {
    let map;
    let draw;

    return {
      renderValue: function (x) {
        if (typeof mapboxgl === "undefined") {
          console.error("Mapbox GL JS is not loaded.");
          return;
        }

        // Register PMTiles source type if available
        if (
          typeof MapboxPmTilesSource !== "undefined" &&
          typeof pmtiles !== "undefined"
        ) {
          try {
            mapboxgl.Style.setSourceType(
              PMTILES_SOURCE_TYPE,
              MapboxPmTilesSource,
            );
            console.log("PMTiles support enabled for Mapbox GL JS");
          } catch (e) {
            console.warn("Failed to register PMTiles source type:", e);
          }
        }

        mapboxgl.accessToken = x.access_token;

        map = new mapboxgl.Map({
          container: el.id,
          style: x.style,
          center: x.center,
          zoom: x.zoom,
          bearing: x.bearing,
          pitch: x.pitch,
          projection: x.projection,
          parallels: x.parallels,
          ...x.additional_params,
        });

        map.controls = [];

        map.on("style.load", function () {
          map.resize();

          if (HTMLWidgets.shinyMode) {
            map.on("load", function () {
              var bounds = map.getBounds();
              var center = map.getCenter();
              var zoom = map.getZoom();

              Shiny.setInputValue(el.id + "_zoom", zoom);
              Shiny.setInputValue(el.id + "_center", {
                lng: center.lng,
                lat: center.lat,
              });
              Shiny.setInputValue(el.id + "_bbox", {
                xmin: bounds.getWest(),
                ymin: bounds.getSouth(),
                xmax: bounds.getEast(),
                ymax: bounds.getNorth(),
              });
            });

            map.on("moveend", function (e) {
              var map = e.target;
              var bounds = map.getBounds();
              var center = map.getCenter();
              var zoom = map.getZoom();

              Shiny.onInputChange(el.id + "_zoom", zoom);
              Shiny.onInputChange(el.id + "_center", {
                lng: center.lng,
                lat: center.lat,
              });
              Shiny.onInputChange(el.id + "_bbox", {
                xmin: bounds.getWest(),
                ymin: bounds.getSouth(),
                xmax: bounds.getEast(),
                ymax: bounds.getNorth(),
              });
            });
          }

          // Set config properties if provided
          if (x.config_properties) {
            x.config_properties.forEach(function (config) {
              map.setConfigProperty(
                config.importId,
                config.configName,
                config.value,
              );
            });
          }

          // Setup markers if provided
          setupMarkers(map, x, el);

          // Setup sources if provided  
          setupSources(map, x);

          // Setup layers if provided
          setupLayers(map, x);
          setupLayerFilters(map, x);

          // Setup effects and navigation
          setupEffectsAndNavigation(map, x);

          // Setup controls
          setupControls(map, x, el);

          // Setup legends and layer controls
          setupLegends(map, x, el);
          setupLayersControl(map, x, el);

          // Setup cluster handling
          setupClusterHandling(map);

          // Setup Shiny event handlers
          setupShinyEventHandlers(map, x, el);

          el.map = map;
        });

        el.map = map;
      },

      getMap: function () {
        return map;
      },

      getDraw: function () {
        return draw;
      },

      getDrawnFeatures: function () {
        return (
          this.drawFeatures || {
            type: "FeatureCollection",
            features: [],
          }
        );
      },

      resize: function (width, height) {
        if (map) {
          map.resize();
        }
      },
    };
  },
});

/**
 * Setup cluster handling for map layers
 */
function setupClusterHandling(map) {
  // If clusters are present, add event handling
  map.getStyle().layers.forEach((layer) => {
    if (layer.id.includes("-clusters")) {
      map.on("click", layer.id, (e) => {
        const features = map.queryRenderedFeatures(e.point, {
          layers: [layer.id],
        });
        const clusterId = features[0].properties.cluster_id;
        map
          .getSource(layer.source)
          .getClusterExpansionZoom(clusterId, (err, zoom) => {
            if (err) return;

            map.easeTo({
              center: features[0].geometry.coordinates,
              zoom: zoom,
            });
          });
      });

      map.on("mouseenter", layer.id, () => {
        map.getCanvas().style.cursor = "pointer";
      });
      map.on("mouseleave", layer.id, () => {
        map.getCanvas().style.cursor = "";
      });
    }
  });
}

/**
 * Setup Shiny event handlers for map interactions
 */
function setupShinyEventHandlers(map, x, el) {
  // Add click event listener in shinyMode
  if (HTMLWidgets.shinyMode) {
    map.on("click", function (e) {
      const features = map.queryRenderedFeatures(e.point);

      if (features.length > 0) {
        const feature = features[0];
        Shiny.onInputChange(el.id + "_feature_click", {
          id: feature.id,
          properties: feature.properties,
          layer: feature.layer.id,
          lng: e.lngLat.lng,
          lat: e.lngLat.lat,
          time: new Date(),
        });
      } else {
        Shiny.onInputChange(el.id + "_feature_click", null);
      }

      // Event listener for the map
      Shiny.onInputChange(el.id + "_click", {
        lng: e.lngLat.lng,
        lat: e.lngLat.lat,
        time: new Date(),
      });
    });

    // add hover listener for shinyMode if enabled
    if (x.hover_events && x.hover_events.enabled) {
      map.on("mousemove", function (e) {
        // Feature hover events
        if (x.hover_events.features) {
          const options = x.hover_events.layer_id
            ? {
                layers: Array.isArray(x.hover_events.layer_id)
                  ? x.hover_events.layer_id
                  : x.hover_events.layer_id
                      .split(",")
                      .map((id) => id.trim()),
              }
            : undefined;
          const features = map.queryRenderedFeatures(e.point, options);

          if (features.length > 0) {
            const feature = features[0];
            Shiny.onInputChange(el.id + "_feature_hover", {
              id: feature.id,
              properties: feature.properties,
              layer: feature.layer.id,
              lng: e.lngLat.lng,
              lat: e.lngLat.lat,
              time: new Date(),
            });
          } else {
            Shiny.onInputChange(el.id + "_feature_hover", null);
          }
        }

        // Coordinate hover events
        if (x.hover_events.coordinates) {
          Shiny.onInputChange(el.id + "_hover", {
            lng: e.lngLat.lng,
            lat: e.lngLat.lat,
            time: new Date(),
          });
        }
      });
    }
  }
}

// Setup Shiny proxy handlers
setupShinyProxy();