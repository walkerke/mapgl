/**
 * Shiny proxy handlers for Mapbox GL JS
 * Handles all message types sent from R to update the map in reactive contexts
 */

/**
 * Setup Shiny proxy message handlers
 */
function setupShinyProxy() {
  if (HTMLWidgets.shinyMode) {
    Shiny.addCustomMessageHandler("mapboxgl-proxy", function (data) {
      var widget = HTMLWidgets.find("#" + data.id);
      if (!widget) return;
      var map = widget.getMap();
      if (map) {
        var message = data.message;

        // Initialize layer state tracking if not already present
        if (!window._mapglLayerState) {
          window._mapglLayerState = {};
        }
        const mapId = map.getContainer().id;
        if (!window._mapglLayerState[mapId]) {
          window._mapglLayerState[mapId] = {
            filters: {}, // layerId -> filter expression
            paintProperties: {}, // layerId -> {propertyName -> value}
            layoutProperties: {}, // layerId -> {propertyName -> value}
            tooltips: {}, // layerId -> tooltip property
            popups: {}, // layerId -> popup property
            legends: {}, // legendId -> {html: string, css: string}
          };
        }
        const layerState = window._mapglLayerState[mapId];

        // Helper function to update drawn features
        function updateDrawnFeatures() {
          var drawControl = widget.drawControl || widget.getDraw();
          if (drawControl) {
            var drawnFeatures = drawControl.getAll();
            if (HTMLWidgets.shinyMode) {
              Shiny.setInputValue(
                data.id + "_drawn_features",
                JSON.stringify(drawnFeatures),
              );
            }
            // Store drawn features in the widget's data
            if (widget) {
              widget.drawFeatures = drawnFeatures;
            }
          }
        }

        // Helper function to add features from a source to draw
        function addSourceFeaturesToDraw(draw, sourceId, map) {
          const source = map.getSource(sourceId);
          if (source && source._data) {
            draw.add(source._data);
          } else {
            console.warn("Source not found or has no data:", sourceId);
          }
        }

        if (message.type === "set_filter") {
          map.setFilter(message.layer, message.filter);
          // Track filter state for layer restoration
          layerState.filters[message.layer] = message.filter;
        } else if (message.type === "add_source") {
          if (message.source.type === "vector") {
            const sourceConfig = {
              type: "vector",
              url: message.source.url,
            };
            // Add promoteId if provided
            if (message.source.promoteId) {
              sourceConfig.promoteId = message.source.promoteId;
            }
            // Add any other properties from the source object
            Object.keys(message.source).forEach(function (key) {
              if (
                key !== "id" &&
                key !== "type" &&
                key !== "url" &&
                key !== "promoteId"
              ) {
                sourceConfig[key] = message.source[key];
              }
            });
            map.addSource(message.source.id, sourceConfig);
          } else if (message.source.type === "geojson") {
            const sourceConfig = {
              type: "geojson",
              data: message.source.data,
              generateId: message.source.generateId,
            };
            // Add any other properties from the source object
            Object.keys(message.source).forEach(function (key) {
              if (
                key !== "id" &&
                key !== "type" &&
                key !== "data" &&
                key !== "generateId"
              ) {
                sourceConfig[key] = message.source[key];
              }
            });
            map.addSource(message.source.id, sourceConfig);
          } else if (message.source.type === "raster") {
            const sourceConfig = {
              type: "raster",
              tileSize: message.source.tileSize,
            };
            if (message.source.url) {
              sourceConfig.url = message.source.url;
            } else if (message.source.tiles) {
              sourceConfig.tiles = message.source.tiles;
            }
            if (message.source.maxzoom) {
              sourceConfig.maxzoom = message.source.maxzoom;
            }
            // Add any other properties from the source object
            Object.keys(message.source).forEach(function (key) {
              if (
                key !== "id" &&
                key !== "type" &&
                key !== "url" &&
                key !== "tiles" &&
                key !== "tileSize" &&
                key !== "maxzoom"
              ) {
                sourceConfig[key] = message.source[key];
              }
            });
            map.addSource(message.source.id, sourceConfig);
          } else if (message.source.type === "raster-dem") {
            const sourceConfig = {
              type: "raster-dem",
              url: message.source.url,
              tileSize: message.source.tileSize,
            };
            if (message.source.maxzoom) {
              sourceConfig.maxzoom = message.source.maxzoom;
            }
            // Add any other properties from the source object
            Object.keys(message.source).forEach(function (key) {
              if (
                key !== "id" &&
                key !== "type" &&
                key !== "url" &&
                key !== "tileSize" &&
                key !== "maxzoom"
              ) {
                sourceConfig[key] = message.source[key];
              }
            });
            map.addSource(message.source.id, sourceConfig);
          } else if (message.source.type === "image") {
            const sourceConfig = {
              type: "image",
              url: message.source.url,
              coordinates: message.source.coordinates,
            };
            // Add any other properties from the source object
            Object.keys(message.source).forEach(function (key) {
              if (
                key !== "id" &&
                key !== "type" &&
                key !== "url" &&
                key !== "coordinates"
              ) {
                sourceConfig[key] = message.source[key];
              }
            });
            map.addSource(message.source.id, sourceConfig);
          } else if (message.source.type === "video") {
            const sourceConfig = {
              type: "video",
              urls: message.source.urls,
              coordinates: message.source.coordinates,
            };
            // Add any other properties from the source object
            Object.keys(message.source).forEach(function (key) {
              if (
                key !== "id" &&
                key !== "type" &&
                key !== "urls" &&
                key !== "coordinates"
              ) {
                sourceConfig[key] = message.source[key];
              }
            });
            map.addSource(message.source.id, sourceConfig);
          } else {
            // Handle custom source types (like pmtile-source)
            const sourceConfig = { type: message.source.type };

            // Copy all properties except id
            Object.keys(message.source).forEach(function (key) {
              if (key !== "id") {
                sourceConfig[key] = message.source[key];
              }
            });

            map.addSource(message.source.id, sourceConfig);
          }
        } else if (message.type === "add_layer") {
          try {
            if (message.layer.before_id) {
              map.addLayer(message.layer, message.layer.before_id);
            } else {
              map.addLayer(message.layer);
            }

            // Add popups or tooltips if provided
            if (message.layer.popup) {
              // Initialize popup tracking if it doesn't exist
              if (!window._mapboxPopups) {
                window._mapboxPopups = {};
              }

              // Create click handler for this layer
              const clickHandler = function (e) {
                onClickPopup(e, map, message.layer.popup, message.layer.id);
              };

              // Store these handler references so we can remove them later if needed
              if (!window._mapboxClickHandlers) {
                window._mapboxClickHandlers = {};
              }
              window._mapboxClickHandlers[message.layer.id] = clickHandler;

              // Add the click handler
              map.on("click", message.layer.id, clickHandler);

              // Change cursor to pointer when hovering over the layer
              map.on("mouseenter", message.layer.id, function () {
                map.getCanvas().style.cursor = "pointer";
              });

              // Change cursor back to default when leaving the layer
              map.on("mouseleave", message.layer.id, function () {
                map.getCanvas().style.cursor = "";
              });
            }

            if (message.layer.tooltip) {
              const tooltip = new mapboxgl.Popup({
                closeButton: false,
                closeOnClick: false,
              });

              // Define named handler functions:
              const mouseMoveHandler = function (e) {
                onMouseMoveTooltip(e, map, tooltip, message.layer.tooltip);
              };

              const mouseLeaveHandler = function () {
                onMouseLeaveTooltip(map, tooltip);
              };

              // Attach handlers by reference:
              map.on("mousemove", message.layer.id, mouseMoveHandler);
              map.on("mouseleave", message.layer.id, mouseLeaveHandler);

              // Store these handler references for later removal:
              if (!window._mapboxHandlers) {
                window._mapboxHandlers = {};
              }
              window._mapboxHandlers[message.layer.id] = {
                mousemove: mouseMoveHandler,
                mouseleave: mouseLeaveHandler,
              };
            }

            // Add hover effect if provided
            if (message.layer.hover_options) {
              const jsHoverOptions = {};
              for (const [key, value] of Object.entries(
                message.layer.hover_options,
              )) {
                const jsKey = key.replace(/_/g, "-");
                jsHoverOptions[jsKey] = value;
              }

              let hoveredFeatureId = null;

              map.on("mousemove", message.layer.id, function (e) {
                if (e.features.length > 0) {
                  if (hoveredFeatureId !== null) {
                    const featureState = {
                      source:
                        typeof message.layer.source === "string"
                          ? message.layer.source
                          : message.layer.id,
                      id: hoveredFeatureId,
                    };
                    if (message.layer.source_layer) {
                      featureState.sourceLayer = message.layer.source_layer;
                    }
                    map.setFeatureState(featureState, {
                      hover: false,
                    });
                  }
                  hoveredFeatureId = e.features[0].id;
                  const featureState = {
                    source:
                      typeof message.layer.source === "string"
                        ? message.layer.source
                        : message.layer.id,
                    id: hoveredFeatureId,
                  };
                  if (message.layer.source_layer) {
                    featureState.sourceLayer = message.layer.source_layer;
                  }
                  map.setFeatureState(featureState, {
                    hover: true,
                  });
                }
              });

              map.on("mouseleave", message.layer.id, function () {
                if (hoveredFeatureId !== null) {
                  const featureState = {
                    source:
                      typeof message.layer.source === "string"
                        ? message.layer.source
                        : message.layer.id,
                    id: hoveredFeatureId,
                  };
                  if (message.layer.source_layer) {
                    featureState.sourceLayer = message.layer.source_layer;
                  }
                  map.setFeatureState(featureState, {
                    hover: false,
                  });
                }
                hoveredFeatureId = null;
              });

              Object.keys(jsHoverOptions).forEach(function (key) {
                const originalPaint =
                  map.getPaintProperty(message.layer.id, key) ||
                  message.layer.paint[key];
                map.setPaintProperty(message.layer.id, key, [
                  "case",
                  ["boolean", ["feature-state", "hover"], false],
                  jsHoverOptions[key],
                  originalPaint,
                ]);
              });
            }
          } catch (e) {
            console.error("Failed to add layer via proxy: ", message.layer, e);
          }
        } else if (message.type === "remove_layer") {
          // If there's an active tooltip, remove it first
          if (window._activeTooltip) {
            window._activeTooltip.remove();
            delete window._activeTooltip;
          }

          // If there's an active popup for this layer, remove it
          if (window._mapboxPopups && window._mapboxPopups[message.layer]) {
            window._mapboxPopups[message.layer].remove();
            delete window._mapboxPopups[message.layer];
          }

          if (map.getLayer(message.layer)) {
            // Remove tooltip handlers
            if (window._mapboxHandlers && window._mapboxHandlers[message.layer]) {
              const handlers = window._mapboxHandlers[message.layer];
              if (handlers.mousemove) {
                map.off("mousemove", message.layer, handlers.mousemove);
              }
              if (handlers.mouseleave) {
                map.off("mouseleave", message.layer, handlers.mouseleave);
              }
              // Clean up the reference
              delete window._mapboxHandlers[message.layer];
            }

            // Remove click handlers for popups
            if (
              window._mapboxClickHandlers &&
              window._mapboxClickHandlers[message.layer]
            ) {
              map.off(
                "click",
                message.layer,
                window._mapboxClickHandlers[message.layer],
              );
              delete window._mapboxClickHandlers[message.layer];
            }

            // Remove the layer
            map.removeLayer(message.layer);
          }
          if (map.getSource(message.layer)) {
            map.removeSource(message.layer);
          }

          // Clean up tracked layer state
          const mapId = map.getContainer().id;
          if (window._mapglLayerState && window._mapglLayerState[mapId]) {
            const layerState = window._mapglLayerState[mapId];
            delete layerState.filters[message.layer];
            delete layerState.paintProperties[message.layer];
            delete layerState.layoutProperties[message.layer];
            delete layerState.tooltips[message.layer];
            delete layerState.popups[message.layer];
            // Note: legends are not tied to specific layers, so we don't clear them here
          }
        } else if (message.type === "fit_bounds") {
          map.fitBounds(message.bounds, message.options);
        } else if (message.type === "fly_to") {
          map.flyTo(message.options);
        } else if (message.type === "ease_to") {
          map.easeTo(message.options);
        } else if (message.type === "set_center") {
          map.setCenter(message.center);
        } else if (message.type === "set_zoom") {
          map.setZoom(message.zoom);
        } else if (message.type === "jump_to") {
          map.jumpTo(message.options);
        } else if (message.type === "set_layout_property") {
          map.setLayoutProperty(message.layer, message.name, message.value);
          // Track layout property state for layer restoration
          if (!layerState.layoutProperties[message.layer]) {
            layerState.layoutProperties[message.layer] = {};
          }
          layerState.layoutProperties[message.layer][message.name] =
            message.value;
        } else if (message.type === "set_paint_property") {
          const layerId = message.layer;
          const propertyName = message.name;
          const newValue = message.value;

          // Check if the layer has hover options
          const layerStyle = map
            .getStyle()
            .layers.find((layer) => layer.id === layerId);
          const currentPaintProperty = map.getPaintProperty(
            layerId,
            propertyName,
          );

          if (
            currentPaintProperty &&
            Array.isArray(currentPaintProperty) &&
            currentPaintProperty[0] === "case"
          ) {
            // This property has hover options, so we need to preserve them
            const hoverValue = currentPaintProperty[2];
            const newPaintProperty = [
              "case",
              ["boolean", ["feature-state", "hover"], false],
              hoverValue,
              newValue,
            ];
            map.setPaintProperty(layerId, propertyName, newPaintProperty);
          } else {
            // No hover options, just set the new value directly
            map.setPaintProperty(layerId, propertyName, newValue);
          }
          // Track paint property state for layer restoration
          if (!layerState.paintProperties[layerId]) {
            layerState.paintProperties[layerId] = {};
          }
          layerState.paintProperties[layerId][propertyName] = newValue;
        } else if (message.type === "query_rendered_features") {
          // Query rendered features
          let queryOptions = {};
          if (message.layers) {
            // Ensure layers is always an array
            queryOptions.layers = Array.isArray(message.layers)
              ? message.layers
              : [message.layers];
          }
          if (message.filter) queryOptions.filter = message.filter;

          let features;
          if (message.geometry) {
            features = map.queryRenderedFeatures(message.geometry, queryOptions);
          } else {
            // No geometry specified - query entire viewport
            features = map.queryRenderedFeatures(queryOptions);
          }

          // Deduplicate features by id or by properties if no id
          const uniqueFeatures = new Map();
          features.forEach(function (feature) {
            let key;
            if (feature.id !== undefined && feature.id !== null) {
              key = feature.id;
            } else {
              // Create a key from properties if no id available
              key = JSON.stringify(feature.properties);
            }

            if (!uniqueFeatures.has(key)) {
              uniqueFeatures.set(key, feature);
            }
          });

          // Convert to GeoJSON FeatureCollection
          const deduplicatedFeatures = Array.from(uniqueFeatures.values());
          const featureCollection = {
            type: "FeatureCollection",
            features: deduplicatedFeatures,
          };

          Shiny.setInputValue(
            data.id + "_queried_features",
            JSON.stringify(featureCollection),
          );
        } else if (message.type === "add_legend") {
          // Extract legend ID from HTML to track it
          const legendIdMatch = message.html.match(/id="([^"]+)"/);
          const legendId = legendIdMatch ? legendIdMatch[1] : null;

          if (!message.add) {
            const existingLegends = document.querySelectorAll(
              `#${data.id} .mapboxgl-legend`,
            );
            existingLegends.forEach((legend) => legend.remove());

            // Clean up any existing legend styles that might have been added
            const legendStyles = document.querySelectorAll(
              "style[data-mapgl-legend-css]",
            );
            legendStyles.forEach((style) => style.remove());

            // Clear legend state when replacing all legends
            layerState.legends = {};
          }

          // Track legend state
          if (legendId) {
            layerState.legends[legendId] = {
              html: message.html,
              css: message.legend_css,
            };
          }

          const legendCss = document.createElement("style");
          legendCss.innerHTML = message.legend_css;
          legendCss.setAttribute("data-mapgl-legend-css", data.id); // Mark this style for later cleanup
          document.head.appendChild(legendCss);

          const legend = document.createElement("div");
          legend.innerHTML = message.html;
          legend.classList.add("mapboxgl-legend");
          document.getElementById(data.id).appendChild(legend);
        } else if (message.type === "set_config_property") {
          map.setConfigProperty(
            message.importId,
            message.configName,
            message.value,
          );
        } else if (message.type === "set_style") {
          // Default preserve_layers to true if not specified
          const preserveLayers = message.preserve_layers !== false;

          // If we should preserve layers and sources
          if (preserveLayers) {
            // Store the current style before changing it
            const currentStyle = map.getStyle();
            const userSourceIds = [];
            const userLayers = [];

            // Identify user-added sources (those not in the original style)
            // We'll assume any source that's not "composite", "mapbox", or starts with "mapbox-" is user-added
            for (const sourceId in currentStyle.sources) {
              if (
                sourceId !== "composite" &&
                sourceId !== "mapbox" &&
                !sourceId.startsWith("mapbox-")
              ) {
                userSourceIds.push(sourceId);
                const source = currentStyle.sources[sourceId];
                // Store layer-specific handler references
                if (window._mapboxHandlers) {
                  const handlers = window._mapboxHandlers;
                  for (const layerId in handlers) {
                    // Find layers associated with this source
                    const layer = currentStyle.layers.find(
                      (l) => l.id === layerId,
                    );
                    if (layer && layer.source === sourceId) {
                      layer._handlers = handlers[layerId];
                    }
                  }
                }
              }
            }

            // Identify layers using user-added sources
            currentStyle.layers.forEach(function (layer) {
              if (userSourceIds.includes(layer.source)) {
                userLayers.push(layer);
              }
            });

            // Set up event listener to re-add sources and layers after style loads
            const onStyleLoad = function () {
              // Re-add user sources
              userSourceIds.forEach(function (sourceId) {
                if (!map.getSource(sourceId)) {
                  const source = currentStyle.sources[sourceId];
                  map.addSource(sourceId, source);
                }
              });

              // Re-add user layers
              userLayers.forEach(function (layer) {
                if (!map.getLayer(layer.id)) {
                  map.addLayer(layer);

                  // Re-add event handlers for tooltips and hover effects
                  if (layer._handlers) {
                    const handlers = layer._handlers;

                    if (handlers.mousemove) {
                      map.on("mousemove", layer.id, handlers.mousemove);
                    }

                    if (handlers.mouseleave) {
                      map.on("mouseleave", layer.id, handlers.mouseleave);
                    }
                  }

                  // Recreate hover states if needed
                  if (layer.paint) {
                    for (const key in layer.paint) {
                      const value = layer.paint[key];
                      if (
                        Array.isArray(value) &&
                        value[0] === "case" &&
                        Array.isArray(value[1]) &&
                        value[1][0] === "boolean" &&
                        value[1][1][0] === "feature-state" &&
                        value[1][1][1] === "hover"
                      ) {
                        // This is a hover-enabled paint property
                        map.setPaintProperty(layer.id, key, value);
                      }
                    }
                  }
                }
              });

              // Clear any active tooltips before restoration to prevent stacking
              if (window._activeTooltip) {
                window._activeTooltip.remove();
                delete window._activeTooltip;
              }

              // Restore tracked layer modifications
              const mapId = map.getContainer().id;
              const savedLayerState =
                window._mapglLayerState && window._mapglLayerState[mapId];
              if (savedLayerState) {
                // Restore filters
                for (const layerId in savedLayerState.filters) {
                  if (map.getLayer(layerId)) {
                    map.setFilter(layerId, savedLayerState.filters[layerId]);
                  }
                }

                // Restore paint properties
                for (const layerId in savedLayerState.paintProperties) {
                  if (map.getLayer(layerId)) {
                    const properties = savedLayerState.paintProperties[layerId];
                    for (const propertyName in properties) {
                      const savedValue = properties[propertyName];

                      // Check if layer has hover effects that need to be preserved
                      const currentValue = map.getPaintProperty(
                        layerId,
                        propertyName,
                      );
                      if (
                        currentValue &&
                        Array.isArray(currentValue) &&
                        currentValue[0] === "case"
                      ) {
                        // Preserve hover effects while updating base value
                        const hoverValue = currentValue[2];
                        const newPaintProperty = [
                          "case",
                          ["boolean", ["feature-state", "hover"], false],
                          hoverValue,
                          savedValue,
                        ];
                        map.setPaintProperty(
                          layerId,
                          propertyName,
                          newPaintProperty,
                        );
                      } else {
                        map.setPaintProperty(layerId, propertyName, savedValue);
                      }
                    }
                  }
                }

                // Restore layout properties
                for (const layerId in savedLayerState.layoutProperties) {
                  if (map.getLayer(layerId)) {
                    const properties = savedLayerState.layoutProperties[layerId];
                    for (const propertyName in properties) {
                      map.setLayoutProperty(
                        layerId,
                        propertyName,
                        properties[propertyName],
                      );
                    }
                  }
                }

                // Restore tooltips
                for (const layerId in savedLayerState.tooltips) {
                  if (map.getLayer(layerId)) {
                    const tooltipProperty = savedLayerState.tooltips[layerId];

                    // Remove existing tooltip handlers first
                    if (
                      window._mapboxHandlers &&
                      window._mapboxHandlers[layerId]
                    ) {
                      if (window._mapboxHandlers[layerId].mousemove) {
                        map.off(
                          "mousemove",
                          layerId,
                          window._mapboxHandlers[layerId].mousemove,
                        );
                      }
                      if (window._mapboxHandlers[layerId].mouseleave) {
                        map.off(
                          "mouseleave",
                          layerId,
                          window._mapboxHandlers[layerId].mouseleave,
                        );
                      }
                    }

                    // Create new tooltip
                    const tooltip = new mapboxgl.Popup({
                      closeButton: false,
                      closeOnClick: false,
                    });

                    const mouseMoveHandler = function (e) {
                      onMouseMoveTooltip(e, map, tooltip, tooltipProperty);
                    };

                    const mouseLeaveHandler = function () {
                      onMouseLeaveTooltip(map, tooltip);
                    };

                    map.on("mousemove", layerId, mouseMoveHandler);
                    map.on("mouseleave", layerId, mouseLeaveHandler);

                    // Store handler references
                    if (!window._mapboxHandlers) {
                      window._mapboxHandlers = {};
                    }
                    window._mapboxHandlers[layerId] = {
                      mousemove: mouseMoveHandler,
                      mouseleave: mouseLeaveHandler,
                    };
                  }
                }

                // Restore popups
                for (const layerId in savedLayerState.popups) {
                  if (map.getLayer(layerId)) {
                    const popupProperty = savedLayerState.popups[layerId];

                    // Remove existing popup handlers first
                    if (
                      window._mapboxHandlers &&
                      window._mapboxHandlers[layerId] &&
                      window._mapboxHandlers[layerId].click
                    ) {
                      map.off(
                        "click",
                        layerId,
                        window._mapboxHandlers[layerId].click,
                      );
                    }

                    // Create new popup handler
                    const clickHandler = function (e) {
                      onClickPopup(e, map, popupProperty, layerId);
                    };

                    map.on("click", layerId, clickHandler);

                    // Store handler reference
                    if (!window._mapboxHandlers) {
                      window._mapboxHandlers = {};
                    }
                    if (!window._mapboxHandlers[layerId]) {
                      window._mapboxHandlers[layerId] = {};
                    }
                    window._mapboxHandlers[layerId].click = clickHandler;
                  }
                }

                // Restore legends
                if (Object.keys(savedLayerState.legends).length > 0) {
                  // Clear any existing legends first to prevent stacking
                  const existingLegends = document.querySelectorAll(
                    `#${mapId} .mapboxgl-legend`,
                  );
                  existingLegends.forEach((legend) => legend.remove());

                  // Clear existing legend styles
                  const legendStyles = document.querySelectorAll(
                    `style[data-mapgl-legend-css="${mapId}"]`,
                  );
                  legendStyles.forEach((style) => style.remove());

                  // Restore each legend
                  for (const legendId in savedLayerState.legends) {
                    const legendData = savedLayerState.legends[legendId];

                    // Add legend CSS
                    const legendCss = document.createElement("style");
                    legendCss.innerHTML = legendData.css;
                    legendCss.setAttribute("data-mapgl-legend-css", mapId);
                    document.head.appendChild(legendCss);

                    // Add legend HTML
                    const legend = document.createElement("div");
                    legend.innerHTML = legendData.html;
                    legend.classList.add("mapboxgl-legend");
                    const mapContainer = document.getElementById(mapId);
                    if (mapContainer) {
                      mapContainer.appendChild(legend);
                    }
                  }
                }
              }

              // Remove this listener to avoid adding the same layers multiple times
              map.off("style.load", onStyleLoad);
            };

            map.on("style.load", onStyleLoad);
          }

          // Change the style
          map.setStyle(message.style, {
            config: message.config,
            diff: message.diff,
          });
        } else if (message.type === "add_navigation_control") {
          const nav = new mapboxgl.NavigationControl({
            showCompass: message.options.show_compass,
            showZoom: message.options.show_zoom,
            visualizePitch: message.options.visualize_pitch,
          });
          map.addControl(nav, message.position);
          map.controls.push(nav);

          if (message.orientation === "horizontal") {
            const navBar = map
              .getContainer()
              .querySelector(
                ".mapboxgl-ctrl.mapboxgl-ctrl-group:not(.mapbox-gl-draw_ctrl-draw-btn)",
              );
            if (navBar) {
              navBar.style.display = "flex";
              navBar.style.flexDirection = "row";
            }
          }
        } else if (message.type === "add_reset_control") {
          const resetControl = document.createElement("button");
          resetControl.className = "mapboxgl-ctrl-icon mapboxgl-ctrl-reset";
          resetControl.type = "button";
          resetControl.setAttribute("aria-label", "Reset");
          resetControl.innerHTML = "⟲";
          resetControl.style.fontSize = "30px";
          resetControl.style.fontWeight = "bold";
          resetControl.style.backgroundColor = "white";
          resetControl.style.border = "none";
          resetControl.style.cursor = "pointer";
          resetControl.style.padding = "0";
          resetControl.style.width = "30px";
          resetControl.style.height = "30px";
          resetControl.style.display = "flex";
          resetControl.style.justifyContent = "center";
          resetControl.style.alignItems = "center";
          resetControl.style.transition = "background-color 0.2s";
          resetControl.addEventListener("mouseover", function () {
            this.style.backgroundColor = "#f0f0f0";
          });
          resetControl.addEventListener("mouseout", function () {
            this.style.backgroundColor = "white";
          });

          const resetContainer = document.createElement("div");
          resetContainer.className = "mapboxgl-ctrl mapboxgl-ctrl-group";
          resetContainer.appendChild(resetControl);

          const initialView = {
            center: map.getCenter(),
            zoom: map.getZoom(),
            pitch: map.getPitch(),
            bearing: map.getBearing(),
            animate: message.animate,
          };

          if (message.duration) {
            initialView.duration = message.duration;
          }

          resetControl.onclick = function () {
            map.easeTo(initialView);
          };

          map.addControl(
            {
              onAdd: function () {
                return resetContainer;
              },
              onRemove: function () {
                resetContainer.parentNode.removeChild(resetContainer);
              },
            },
            message.position,
          );

          map.controls.push({
            onAdd: function () {
              return resetContainer;
            },
            onRemove: function () {
              resetContainer.parentNode.removeChild(resetContainer);
            },
          });
        } else if (message.type === "add_draw_control") {
          let drawOptions = message.options || {};

          // Generate styles if styling parameters provided
          if (message.styling) {
            const generatedStyles = generateDrawStyles(message.styling);
            if (generatedStyles) {
              drawOptions.styles = generatedStyles;
            }
          }

          if (message.freehand) {
            drawOptions = Object.assign({}, drawOptions, {
              modes: Object.assign({}, MapboxDraw.modes, {
                draw_polygon: MapboxDraw.modes.draw_freehand,
              }),
              // defaultMode: 'draw_polygon' # Don't set the default yet
            });
          }

          // Create the draw control
          var drawControl = new MapboxDraw(drawOptions);
          map.addControl(drawControl, message.position);
          map.controls.push(drawControl);

          // Store the draw control on the widget for later access
          widget.drawControl = drawControl;

          // Add event listeners
          map.on("draw.create", updateDrawnFeatures);
          map.on("draw.delete", updateDrawnFeatures);
          map.on("draw.update", updateDrawnFeatures);

          // Add initial features if provided
          if (message.source) {
            addSourceFeaturesToDraw(drawControl, message.source, map);
          }

          if (message.orientation === "horizontal") {
            const drawBar = map
              .getContainer()
              .querySelector(".mapboxgl-ctrl-group");
            if (drawBar) {
              drawBar.style.display = "flex";
              drawBar.style.flexDirection = "row";
            }
          }

          // Add download button if requested
          if (message.download_button) {
            // Add CSS for download button if not already added
            if (!document.querySelector("#mapgl-draw-download-styles")) {
              const style = document.createElement("style");
              style.id = "mapgl-draw-download-styles";
              style.textContent = `
                .mapbox-gl-draw_download {
                  background: transparent;
                  border: none;
                  cursor: pointer;
                  display: block;
                  height: 30px;
                  width: 30px;
                  padding: 0;
                  outline: none;
                }
                .mapbox-gl-draw_download:hover {
                  background-color: rgba(0, 0, 0, 0.05);
                }
                .mapbox-gl-draw_download svg {
                  width: 20px;
                  height: 20px;
                  margin: 5px;
                  fill: #333;
                }
              `;
              document.head.appendChild(style);
            }

            // Small delay to ensure Draw control is fully rendered
            setTimeout(() => {
              // Find the Draw control button group
              const drawButtons = map
                .getContainer()
                .querySelector(
                  ".mapboxgl-ctrl-group:has(.mapbox-gl-draw_polygon)",
                );

              if (drawButtons) {
                // Create download button
                const downloadBtn = document.createElement("button");
                downloadBtn.className = "mapbox-gl-draw_download";
                downloadBtn.title = "Download drawn features as GeoJSON";

                // Add SVG download icon
                downloadBtn.innerHTML = `
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                    <path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/>
                  </svg>
                `;

                downloadBtn.addEventListener("click", () => {
                  // Get all drawn features
                  const data = drawControl.getAll();

                  if (data.features.length === 0) {
                    alert(
                      "No features to download. Please draw something first!",
                    );
                    return;
                  }

                  // Convert to string with nice formatting
                  const dataStr = JSON.stringify(data, null, 2);

                  // Create blob and download
                  const blob = new Blob([dataStr], { type: "application/json" });
                  const url = URL.createObjectURL(blob);

                  const a = document.createElement("a");
                  a.href = url;
                  a.download = `${message.download_filename || "drawn-features"}.geojson`;
                  document.body.appendChild(a);
                  a.click();
                  document.body.removeChild(a);
                  URL.revokeObjectURL(url);
                });

                // Append to the Draw control button group
                drawButtons.appendChild(downloadBtn);
              }
            }, 100);
          }
        } else if (message.type === "get_drawn_features") {
          var drawControl = widget.drawControl || widget.getDraw();
          if (drawControl) {
            const features = drawControl.getAll();
            Shiny.setInputValue(
              data.id + "_drawn_features",
              JSON.stringify(features),
            );
          } else {
            Shiny.setInputValue(
              data.id + "_drawn_features",
              JSON.stringify(null),
            );
          }
        } else if (message.type === "clear_drawn_features") {
          var drawControl = widget.drawControl || widget.getDraw();
          if (drawControl) {
            drawControl.deleteAll();
            // Update the drawn features
            updateDrawnFeatures();
          }
        } else if (message.type === "add_features_to_draw") {
          var drawControl = widget.drawControl || widget.getDraw();
          if (drawControl) {
            if (message.data.clear_existing) {
              drawControl.deleteAll();
            }
            addSourceFeaturesToDraw(drawControl, message.data.source, map);
            // Update the drawn features
            updateDrawnFeatures();
          } else {
            console.warn("Draw control not initialized");
          }
        } else if (message.type === "add_markers") {
          if (!window.mapboxglMarkers) {
            window.mapboxglMarkers = [];
          }
          message.markers.forEach(function (marker) {
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

            const markerId = marker.id;
            if (markerId) {
              const lngLat = mapMarker.getLngLat();
              Shiny.setInputValue(data.id + "_marker_" + markerId, {
                id: markerId,
                lng: lngLat.lng,
                lat: lngLat.lat,
              });

              mapMarker.on("dragend", function () {
                const lngLat = mapMarker.getLngLat();
                Shiny.setInputValue(data.id + "_marker_" + markerId, {
                  id: markerId,
                  lng: lngLat.lng,
                  lat: lngLat.lat,
                });
              });
            }

            window.mapboxglMarkers.push(mapMarker);
          });
        } else if (message.type === "clear_markers") {
          if (window.mapboxglMarkers) {
            window.mapboxglMarkers.forEach(function (marker) {
              marker.remove();
            });
            window.mapboxglMarkers = [];
          }
        } else if (message.type === "add_fullscreen_control") {
          const position = message.position || "top-right";
          const fullscreen = new mapboxgl.FullscreenControl();
          map.addControl(fullscreen, position);
          map.controls.push(fullscreen);
        } else if (message.type === "add_scale_control") {
          const scaleControl = new mapboxgl.ScaleControl({
            maxWidth: message.options.maxWidth,
            unit: message.options.unit,
          });
          map.addControl(scaleControl, message.options.position);
          map.controls.push(scaleControl);
        } else if (message.type === "add_geolocate_control") {
          const geolocate = new mapboxgl.GeolocateControl({
            positionOptions: message.options.positionOptions,
            trackUserLocation: message.options.trackUserLocation,
            showAccuracyCircle: message.options.showAccuracyCircle,
            showUserLocation: message.options.showUserLocation,
            showUserHeading: message.options.showUserHeading,
            fitBoundsOptions: message.options.fitBoundsOptions,
          });
          map.addControl(geolocate, message.options.position);
          map.controls.push(geolocate);

          if (HTMLWidgets.shinyMode) {
            geolocate.on("geolocate", function (event) {
              Shiny.setInputValue(el.id + "_geolocate", {
                coords: event.coords,
                time: new Date(),
              });
            });

            geolocate.on("trackuserlocationstart", function () {
              Shiny.setInputValue(el.id + "_geolocate_tracking", {
                status: "start",
                time: new Date(),
              });
            });

            geolocate.on("trackuserlocationend", function () {
              Shiny.setInputValue(el.id + "_geolocate_tracking", {
                status: "end",
                time: new Date(),
              });
            });

            geolocate.on("error", function (error) {
              if (error.error.code === 1) {
                Shiny.setInputValue(el.id + "_geolocate_error", {
                  message: "Location permission denied",
                  time: new Date(),
                });
              }
            });
          }
        } else if (message.type === "add_geocoder_control") {
          const geocoderOptions = {
            accessToken: mapboxgl.accessToken,
            mapboxgl: mapboxgl,
            ...message.options,
          };

          // Set default values if not provided
          if (!geocoderOptions.placeholder)
            geocoderOptions.placeholder = "Search";
          if (typeof geocoderOptions.collapsed === "undefined")
            geocoderOptions.collapsed = false;

          const geocoder = new MapboxGeocoder(geocoderOptions);

          map.addControl(geocoder, message.position || "top-right");
          map.controls.push(geocoder);

          // Handle geocoder results in Shiny mode
          geocoder.on("result", function (e) {
            Shiny.setInputValue(data.id + "_geocoder", {
              result: e.result,
              time: new Date(),
            });
          });
        } else if (message.type === "add_layers_control") {
          const layersControl = document.createElement("div");
          layersControl.id = message.control_id;
          layersControl.className = message.collapsible
            ? "layers-control collapsible"
            : "layers-control";
          layersControl.style.position = "absolute";

          // Set the position correctly
          const position = message.position || "top-left";
          if (position === "top-left") {
            layersControl.style.top = (message.margin_top || 10) + "px";
            layersControl.style.left = (message.margin_left || 10) + "px";
          } else if (position === "top-right") {
            layersControl.style.top = (message.margin_top || 10) + "px";
            layersControl.style.right = (message.margin_right || 10) + "px";
          } else if (position === "bottom-left") {
            layersControl.style.bottom = (message.margin_bottom || 30) + "px";
            layersControl.style.left = (message.margin_left || 10) + "px";
          } else if (position === "bottom-right") {
            layersControl.style.bottom = (message.margin_bottom || 40) + "px";
            layersControl.style.right = (message.margin_right || 10) + "px";
          }

          // Apply custom colors if provided
          if (message.custom_colors) {
            const colors = message.custom_colors;

            // Create a style element for custom colors
            const styleEl = document.createElement("style");
            let css = "";

            if (colors.background) {
              css += `#${message.control_id} { background-color: ${colors.background}; }\n`;
            }

            if (colors.text) {
              css += `#${message.control_id} a { color: ${colors.text}; }\n`;
            }

            if (colors.active) {
              css += `#${message.control_id} a.active { background-color: ${colors.active}; }\n`;
              css += `#${message.control_id} .toggle-button { background-color: ${colors.active}; }\n`;
            }

            if (colors.activeText) {
              css += `#${message.control_id} a.active { color: ${colors.activeText}; }\n`;
              css += `#${message.control_id} .toggle-button { color: ${colors.activeText}; }\n`;
            }

            if (colors.hover) {
              css += `#${message.control_id} a:hover { background-color: ${colors.hover}; }\n`;
              css += `#${message.control_id} .toggle-button:hover { background-color: ${colors.hover}; }\n`;
            }

            styleEl.textContent = css;
            document.head.appendChild(styleEl);
          }

          const layersList = document.createElement("div");
          layersList.className = "layers-list";
          layersControl.appendChild(layersList);

          let layers = message.layers || [];

          // Ensure layers is always an array
          if (!Array.isArray(layers)) {
            layers = [layers];
          }

          layers.forEach((layerId, index) => {
            const link = document.createElement("a");
            link.id = layerId;
            link.href = "#";
            link.textContent = layerId;

            // Check if the layer visibility is set to "none" initially
            const initialVisibility = map.getLayoutProperty(
              layerId,
              "visibility",
            );
            link.className = initialVisibility === "none" ? "" : "active";

            // Also hide any associated legends if the layer is initially hidden
            if (initialVisibility === "none") {
              const associatedLegends = document.querySelectorAll(
                `.mapboxgl-legend[data-layer-id="${layerId}"]`,
              );
              associatedLegends.forEach((legend) => {
                legend.style.display = "none";
              });
            }

            link.onclick = function (e) {
              const clickedLayer = this.textContent;
              e.preventDefault();
              e.stopPropagation();

              const visibility = map.getLayoutProperty(
                clickedLayer,
                "visibility",
              );

              if (visibility === "visible") {
                map.setLayoutProperty(clickedLayer, "visibility", "none");
                this.className = "";

                // Hide associated legends
                const associatedLegends = document.querySelectorAll(
                  `.mapboxgl-legend[data-layer-id="${clickedLayer}"]`,
                );
                associatedLegends.forEach((legend) => {
                  legend.style.display = "none";
                });
              } else {
                this.className = "active";
                map.setLayoutProperty(clickedLayer, "visibility", "visible");

                // Show associated legends
                const associatedLegends = document.querySelectorAll(
                  `.mapboxgl-legend[data-layer-id="${clickedLayer}"]`,
                );
                associatedLegends.forEach((legend) => {
                  legend.style.display = "";
                });
              }
            };

            layersList.appendChild(link);
          });

          if (message.collapsible) {
            const toggleButton = document.createElement("div");
            toggleButton.className = "toggle-button";

            // Use stacked layers icon instead of text if requested
            if (message.use_icon) {
              // Add icon-only class to the control for compact styling
              layersControl.classList.add("icon-only");

              // More GIS-like layers stack icon
              toggleButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
                          <polyline points="2 17 12 22 22 17"></polyline>
                          <polyline points="2 12 12 17 22 12"></polyline>
                      </svg>`;
              toggleButton.style.display = "flex";
              toggleButton.style.alignItems = "center";
              toggleButton.style.justifyContent = "center";
            } else {
              toggleButton.textContent = "Layers";
            }

            toggleButton.onclick = function () {
              layersControl.classList.toggle("open");
            };
            layersControl.insertBefore(toggleButton, layersList);
          }

          const mapContainer = document.getElementById(data.id);
          if (mapContainer) {
            mapContainer.appendChild(layersControl);
          } else {
            console.error(`Cannot find map container with ID ${data.id}`);
          }
        } else if (message.type === "clear_legend") {
          if (message.ids && Array.isArray(message.ids)) {
            message.ids.forEach((id) => {
              const legend = document.querySelector(
                `#${data.id} div[id="${id}"]`,
              );
              if (legend) {
                legend.remove();
              }
              // Remove from legend state
              delete layerState.legends[id];
            });
          } else if (message.ids) {
            const legend = document.querySelector(
              `#${data.id} div[id="${message.ids}"]`,
            );
            if (legend) {
              legend.remove();
            }
            // Remove from legend state
            delete layerState.legends[message.ids];
          } else {
            // Remove all legend elements
            const existingLegends = document.querySelectorAll(
              `#${data.id} .mapboxgl-legend`,
            );
            existingLegends.forEach((legend) => {
              legend.remove();
            });

            // Clean up any legend styles associated with this map
            const legendStyles = document.querySelectorAll(
              `style[data-mapgl-legend-css="${data.id}"]`,
            );
            legendStyles.forEach((style) => {
              style.remove();
            });

            // Clear all legend state
            layerState.legends = {};
          }
        } else if (message.type === "add_custom_control") {
          const controlOptions = message.options;
          const customControlContainer = document.createElement("div");

          if (controlOptions.className) {
            customControlContainer.className = controlOptions.className;
          } else {
            customControlContainer.className =
              "mapboxgl-ctrl mapboxgl-ctrl-group";
          }

          customControlContainer.innerHTML = controlOptions.html;

          const customControl = {
            onAdd: function () {
              return customControlContainer;
            },
            onRemove: function () {
              if (customControlContainer.parentNode) {
                customControlContainer.parentNode.removeChild(
                  customControlContainer,
                );
              }
            },
          };

          map.addControl(customControl, controlOptions.position || "top-right");
          map.controls.push(customControl);
        } else if (message.type === "clear_controls") {
          map.controls.forEach((control) => {
            map.removeControl(control);
          });
          map.controls = [];

          const layersControl = document.querySelector(
            `#${data.id} .layers-control`,
          );
          if (layersControl) {
            layersControl.remove();
          }

          // Remove globe minimap if it exists
          const globeMinimap = document.querySelector(
            ".mapboxgl-ctrl-globe-minimap",
          );
          if (globeMinimap) {
            globeMinimap.remove();
          }
        } else if (message.type === "move_layer") {
          if (map.getLayer(message.layer)) {
            if (message.before) {
              map.moveLayer(message.layer, message.before);
            } else {
              map.moveLayer(message.layer);
            }
          } else {
            console.error("Layer not found:", message.layer);
          }
        } else if (message.type === "add_image") {
          if (Array.isArray(message.images)) {
            message.images.forEach(function (imageInfo) {
              map.loadImage(imageInfo.url, function (error, image) {
                if (error) {
                  console.error("Error loading image:", error);
                  return;
                }
                if (!map.hasImage(imageInfo.id)) {
                  map.addImage(imageInfo.id, image, imageInfo.options);
                }
              });
            });
          } else if (message.url) {
            map.loadImage(message.url, function (error, image) {
              if (error) {
                console.error("Error loading image:", error);
                return;
              }
              if (!map.hasImage(message.imageId)) {
                map.addImage(message.imageId, image, message.options);
              }
            });
          } else {
            console.error("Invalid image data:", message);
          }
        } else if (message.type === "set_tooltip") {
          const layerId = message.layer;
          const newTooltipProperty = message.tooltip;

          // Track tooltip state
          layerState.tooltips[layerId] = newTooltipProperty;

          // If there's an active tooltip open, remove it first
          if (window._activeTooltip) {
            window._activeTooltip.remove();
            delete window._activeTooltip;
          }

          // Remove old handlers if any
          if (window._mapboxHandlers && window._mapboxHandlers[layerId]) {
            const handlers = window._mapboxHandlers[layerId];
            if (handlers.mousemove) {
              map.off("mousemove", layerId, handlers.mousemove);
            }
            if (handlers.mouseleave) {
              map.off("mouseleave", layerId, handlers.mouseleave);
            }
            delete window._mapboxHandlers[layerId];
          }

          // Create a new tooltip popup
          const tooltip = new mapboxgl.Popup({
            closeButton: false,
            closeOnClick: false,
          });

          // Define new handlers referencing the updated tooltip property
          const mouseMoveHandler = function (e) {
            onMouseMoveTooltip(e, map, tooltip, newTooltipProperty);
          };
          const mouseLeaveHandler = function () {
            onMouseLeaveTooltip(map, tooltip);
          };

          // Add the new event handlers
          map.on("mousemove", layerId, mouseMoveHandler);
          map.on("mouseleave", layerId, mouseLeaveHandler);

          // Store these handlers so we can remove/update them in the future
          if (!window._mapboxHandlers) {
            window._mapboxHandlers = {};
          }
          window._mapboxHandlers[layerId] = {
            mousemove: mouseMoveHandler,
            mouseleave: mouseLeaveHandler,
          };
        } else if (message.type === "set_popup") {
          const layerId = message.layer;
          const newPopupProperty = message.popup;

          // Track popup state
          layerState.popups[layerId] = newPopupProperty;

          // Remove any existing popup for this layer
          if (window._mapboxPopups && window._mapboxPopups[layerId]) {
            window._mapboxPopups[layerId].remove();
            delete window._mapboxPopups[layerId];
          }

          // Remove old click handler if any
          if (
            window._mapboxClickHandlers &&
            window._mapboxClickHandlers[layerId]
          ) {
            map.off("click", layerId, window._mapboxClickHandlers[layerId]);
            delete window._mapboxClickHandlers[layerId];
          }

          // Remove old hover handlers for cursor change
          map.off("mouseenter", layerId);
          map.off("mouseleave", layerId);

          // Create new click handler
          const clickHandler = function (e) {
            onClickPopup(e, map, newPopupProperty, layerId);
          };

          // Add the new event handler
          map.on("click", layerId, clickHandler);

          // Change cursor to pointer when hovering over the layer
          map.on("mouseenter", layerId, function () {
            map.getCanvas().style.cursor = "pointer";
          });

          // Change cursor back to default when leaving the layer
          map.on("mouseleave", layerId, function () {
            map.getCanvas().style.cursor = "";
          });

          // Store handler reference
          if (!window._mapboxClickHandlers) {
            window._mapboxClickHandlers = {};
          }
          window._mapboxClickHandlers[layerId] = clickHandler;
        } else if (message.type === "set_source") {
          const layerId = message.layer;
          const newData = message.source;
          const layerObject = map.getLayer(layerId);

          if (!layerObject) {
            console.error("Layer not found: ", layerId);
            return;
          }

          const sourceId = layerObject.source;
          const sourceObject = map.getSource(sourceId);

          if (!sourceObject) {
            console.error("Source not found: ", sourceId);
            return;
          }

          // Update the geojson data
          sourceObject.setData(newData);
        } else if (message.type === "set_rain") {
          if (message.remove) {
            map.setRain(null);
          } else if (message.rain) {
            map.setRain(message.rain);
          }
        } else if (message.type === "set_snow") {
          if (message.remove) {
            map.setSnow(null);
          } else if (message.snow) {
            map.setSnow(message.snow);
          }
        } else if (message.type === "set_projection") {
          const projection = message.projection;
          map.setProjection(projection);
        } else if (message.type === "add_globe_minimap") {
          const globeMinimapOptions = {
            globeSize: message.options.globe_size || 100,
            landColor: message.options.land_color || "#404040",
            waterColor: message.options.water_color || "#090909",
            markerColor: message.options.marker_color || "#1da1f2",
            markerSize: message.options.marker_size || 2,
          };
          const globeMinimap = new GlobeMinimap(globeMinimapOptions);
          map.addControl(globeMinimap, message.position || "bottom-left");
          map.controls.push(globeMinimap);
        }
      }
    });
  }
}