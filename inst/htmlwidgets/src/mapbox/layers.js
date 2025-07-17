/**
 * Layer management for Mapbox GL JS
 * Handles layer creation, popups, tooltips, hover effects, and layer interactions
 */

function setupLayers(map, x) {
  // Add layers if provided
  if (x.layers) {
    x.layers.forEach(function (layer) {
      try {
        const layerConfig = {
          id: layer.id,
          type: layer.type,
          source: layer.source,
          layout: layer.layout || {},
          paint: layer.paint || {},
        };

        // Check if source is an object and set generateId if source type is 'geojson'
        if (
          typeof layer.source === "object" &&
          layer.source.type === "geojson"
        ) {
          layerConfig.source.generateId = true;
        } else if (typeof layer.source === "string") {
          // Handle string source if needed
          layerConfig.source = layer.source;
        }

        if (layer.source_layer) {
          layerConfig["source-layer"] = layer.source_layer;
        }

        if (layer.slot) {
          layerConfig["slot"] = layer.slot;
        }

        if (layer.minzoom) {
          layerConfig["minzoom"] = layer.minzoom;
        }
        if (layer.maxzoom) {
          layerConfig["maxzoom"] = layer.maxzoom;
        }

        if (layer.filter) {
          layerConfig["filter"] = layer.filter;
        }

        if (layer.before_id) {
          map.addLayer(layerConfig, layer.before_id);
        } else {
          map.addLayer(layerConfig);
        }

        // Add popups or tooltips if provided
        if (layer.popup) {
          // Initialize popup tracking if it doesn't exist
          if (!window._mapboxPopups) {
            window._mapboxPopups = {};
          }

          // Create click handler for this layer
          const clickHandler = function (e) {
            onClickPopup(e, map, layer.popup, layer.id);
          };

          // Store these handler references so we can remove them later if needed
          if (!window._mapboxClickHandlers) {
            window._mapboxClickHandlers = {};
          }
          window._mapboxClickHandlers[layer.id] = clickHandler;

          // Add the click handler
          map.on("click", layer.id, clickHandler);

          // Change cursor to pointer when hovering over the layer
          map.on("mouseenter", layer.id, function () {
            map.getCanvas().style.cursor = "pointer";
          });

          // Change cursor back to default when leaving the layer
          map.on("mouseleave", layer.id, function () {
            map.getCanvas().style.cursor = "";
          });
        }

        if (layer.tooltip) {
          const tooltip = new mapboxgl.Popup({
            closeButton: false,
            closeOnClick: false,
          });

          // Create a reference to the mousemove handler function.
          // We need to pass 'e', 'map', 'tooltip', and 'layer.tooltip' to onMouseMoveTooltip.
          const mouseMoveHandler = function (e) {
            onMouseMoveTooltip(e, map, tooltip, layer.tooltip);
          };

          // Create a reference to the mouseleave handler function.
          // We need to pass 'map' and 'tooltip' to onMouseLeaveTooltip.
          const mouseLeaveHandler = function () {
            onMouseLeaveTooltip(map, tooltip);
          };

          // Attach the named handler references, not anonymous functions.
          map.on("mousemove", layer.id, mouseMoveHandler);
          map.on("mouseleave", layer.id, mouseLeaveHandler);

          // Store these handler references so you can remove them later if needed
          if (!window._mapboxHandlers) {
            window._mapboxHandlers = {};
          }
          window._mapboxHandlers[layer.id] = {
            mousemove: mouseMoveHandler,
            mouseleave: mouseLeaveHandler,
          };
        }

        // Add hover effect if provided
        if (layer.hover_options) {
          const jsHoverOptions = {};
          for (const [key, value] of Object.entries(
            layer.hover_options,
          )) {
            const jsKey = key.replace(/_/g, "-");
            jsHoverOptions[jsKey] = value;
          }

          let hoveredFeatureId = null;

          map.on("mousemove", layer.id, function (e) {
            if (e.features.length > 0) {
              if (hoveredFeatureId !== null) {
                const featureState = {
                  source:
                    typeof layer.source === "string"
                      ? layer.source
                      : layer.id,
                  id: hoveredFeatureId,
                };
                if (layer.source_layer) {
                  featureState.sourceLayer = layer.source_layer;
                }
                map.setFeatureState(featureState, { hover: false });
              }
              hoveredFeatureId = e.features[0].id;
              const featureState = {
                source:
                  typeof layer.source === "string"
                    ? layer.source
                    : layer.id,
                id: hoveredFeatureId,
              };
              if (layer.source_layer) {
                featureState.sourceLayer = layer.source_layer;
              }
              map.setFeatureState(featureState, {
                hover: true,
              });
            }
          });

          map.on("mouseleave", layer.id, function () {
            if (hoveredFeatureId !== null) {
              const featureState = {
                source:
                  typeof layer.source === "string"
                    ? layer.source
                    : layer.id,
                id: hoveredFeatureId,
              };
              if (layer.source_layer) {
                featureState.sourceLayer = layer.source_layer;
              }
              map.setFeatureState(featureState, {
                hover: false,
              });
            }
            hoveredFeatureId = null;
          });

          Object.keys(jsHoverOptions).forEach(function (key) {
            const originalPaint =
              map.getPaintProperty(layer.id, key) || layer.paint[key];
            map.setPaintProperty(layer.id, key, [
              "case",
              ["boolean", ["feature-state", "hover"], false],
              jsHoverOptions[key],
              originalPaint,
            ]);
          });
        }
      } catch (e) {
        console.error("Failed to add layer: ", layer, e);
      }
    });
  }
}

function setupLayerFilters(map, x) {
  // Apply setFilter if provided
  if (x.setFilter) {
    x.setFilter.forEach(function (filter) {
      map.setFilter(filter.layer, filter.filter);
    });
  }
}