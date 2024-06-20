HTMLWidgets.widget({

  name: 'mapboxgl',

  type: 'output',

  factory: function(el, width, height) {
    let map;

    // Add default CSS for full screen
    const css = `
      body, html {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
      }
      #${el.id} {
        position: absolute;
        top: 0;
        bottom: 0;
        left: 0;
        right: 0;
        width: 100%;
        height: 100%;
      }
    `;
    const style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = css;
    document.getElementsByTagName('head')[0].appendChild(style);

    return {
      renderValue: function(x) {
        if (typeof mapboxgl === 'undefined') {
          console.error("Mapbox GL JS is not loaded.");
          return;
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
          ...x.additional_params
        });

        map.on('style.load', function() {
          map.resize();

          if (HTMLWidgets.shinyMode) {
            map.on('moveend', function(e) {
              var map = e.target;
              var bounds = map.getBounds();
              var center = map.getCenter();
              var zoom = map.getZoom();

              Shiny.onInputChange(el.id + '_zoom', zoom);
              Shiny.onInputChange(el.id + '_center', { lng: center.lng, lat: center.lat });
              Shiny.onInputChange(el.id + '_bbox', {
                xmin: bounds.getWest(),
                ymin: bounds.getSouth(),
                xmax: bounds.getEast(),
                ymax: bounds.getNorth()
              });
            });
          }

          // Set config properties if provided
          if (x.config_properties) {
            x.config_properties.forEach(function(config) {
              map.setConfigProperty(config.importId, config.configName, config.value);
            });
          }

          if (x.markers) {
            if (!window.mapboxglMarkers) {
              window.mapboxglMarkers = [];
            }
            x.markers.forEach(function(marker) {
              const markerOptions = {
                color: marker.color,
                rotation: marker.rotation,
                ...marker.options
              };
              const mapMarker = new mapboxgl.Marker(markerOptions)
                .setLngLat([marker.lng, marker.lat])
                .addTo(map);

              if (marker.popup) {
                mapMarker.setPopup(new mapboxgl.Popup({ offset: 25 }).setText(marker.popup));
              }

              window.mapboxglMarkers.push(mapMarker);
            });
          }


          // Add sources if provided
          if (x.sources) {
            x.sources.forEach(function(source) {
              if (source.type === "vector") {
                map.addSource(source.id, {
                  type: 'vector',
                  url: source.url
                });
              } else if (source.type === "geojson") {
                const geojsonData = source.geojson;
                map.addSource(source.id, {
                  type: 'geojson',
                  data: geojsonData,
                  generateId: true
                });
              } else if (source.type === "raster") {
                map.addSource(source.id, {
                  type: 'raster',
                  url: source.url,
                  tileSize: source.tileSize,
                  maxzoom: source.maxzoom
                });
              } else if (source.type === "raster-dem") {
                map.addSource(source.id, {
                  type: 'raster-dem',
                  url: source.url,
                  tileSize: source.tileSize,
                  maxzoom: source.maxzoom
                });
              } else if (source.type === "image") {
                map.addSource(source.id, {
                  type: 'image',
                  url: source.url,
                  coordinates: source.coordinates
                });
              } else if (source.type === "video") {
                map.addSource(source.id, {
                  type: 'video',
                  urls: source.urls,
                  coordinates: source.coordinates
                });
              }
            });
          }

          // Add layers if provided
          if (x.layers) {
            x.layers.forEach(function(layer) {
              try {
                const layerConfig = {
                  id: layer.id,
                  type: layer.type,
                  source: layer.source,
                  layout: layer.layout || {},
                  paint: layer.paint || {}
                };

                // Check if source is an object and set generateId if source type is 'geojson'
                if (typeof layer.source === 'object' && layer.source.type === 'geojson') {
                  layerConfig.source.generateId = true;
                } else if (typeof layer.source === 'string') {
                  // Handle string source if needed
                  layerConfig.source = layer.source;
                }

                if (layer.source_layer) {
                  layerConfig['source-layer'] = layer.source_layer;
                }

                if (layer.slot) {
                  layerConfig['slot'] = layer.slot;
                }

                if (layer.minzoom) {
                  layerConfig['minzoom'] = layer.minzoom;
                }

                if (layer.maxzoom) {
                  layerConfig['maxzoom'] = layer.maxzoom;
                }

                map.addLayer(layerConfig);

                // Add popups or tooltips if provided
                if (layer.popup) {
                  map.on('click', layer.id, function(e) {
                    const description = e.features[0].properties[layer.popup];

                    new mapboxgl.Popup()
                      .setLngLat(e.lngLat)
                      .setHTML(description)
                      .addTo(map);
                  });
                }

                if (layer.tooltip) {
                  const tooltip = new mapboxgl.Popup({
                    closeButton: false,
                    closeOnClick: false
                  });

                  map.on('mousemove', layer.id, function(e) {
                    map.getCanvas().style.cursor = 'pointer';

                    if (e.features.length > 0) {
                      const description = e.features[0].properties[layer.tooltip];
                      tooltip.setLngLat(e.lngLat).setHTML(description).addTo(map);
                    } else {
                      tooltip.remove();
                    }
                  });

                  map.on('mouseleave', layer.id, function() {
                    map.getCanvas().style.cursor = '';
                    tooltip.remove();
                  });

                }

                // Add hover effect if provided
                if (layer.hover_options) {
                  const jsHoverOptions = {};
                  for (const [key, value] of Object.entries(layer.hover_options)) {
                    const jsKey = key.replace(/_/g, '-');
                    jsHoverOptions[jsKey] = value;
                  }

                  let hoveredFeatureId = null;

                  map.on('mousemove', layer.id, function(e) {
                    if (e.features.length > 0) {
                      if (hoveredFeatureId !== null) {
                        map.setFeatureState(
                          { source: typeof layer.source === 'string' ? layer.source : layer.id, id: hoveredFeatureId },
                          { hover: false }
                        );
                      }
                      hoveredFeatureId = e.features[0].id;
                      map.setFeatureState(
                        { source: typeof layer.source === 'string' ? layer.source : layer.id, id: hoveredFeatureId },
                        { hover: true }
                      );
                    }
                  });

                  map.on('mouseleave', layer.id, function() {
                    if (hoveredFeatureId !== null) {
                      map.setFeatureState(
                        { source: typeof layer.source === 'string' ? layer.source : layer.id, id: hoveredFeatureId },
                        { hover: false }
                      );
                    }
                    hoveredFeatureId = null;
                  });

                  Object.keys(jsHoverOptions).forEach(function(key) {
                    const originalPaint = map.getPaintProperty(layer.id, key) || layer.paint[key];
                    map.setPaintProperty(layer.id, key, [
                      'case',
                      ['boolean', ['feature-state', 'hover'], false],
                      jsHoverOptions[key],
                      originalPaint
                    ]);
                  });
                }

              } catch (e) {
                console.error("Failed to add layer: ", layer, e);
              }
            });
          }

          // Set terrain if provided
          if (x.terrain) {
            map.setTerrain({
              source: x.terrain.source,
              exaggeration: x.terrain.exaggeration
            });
          }

          // Set fog
          if (x.fog) {
            map.setFog(x.fog);
          }

          if (x.fitBounds) {
            map.fitBounds(x.fitBounds.bounds, x.fitBounds.options);
          }
          if (x.flyTo) {
            map.flyTo(x.flyTo);
          }
          if (x.easeTo) {
            map.easeTo(x.easeTo);
          }
          if (x.setCenter) {
            map.setCenter(x.setCenter);
          }
          if (x.setZoom) {
            map.setZoom(x.setZoom);
          }
          if (x.jumpTo) {
            map.jumpTo(x.jumpTo);
          }

          const existingLegend = document.getElementById('mapboxgl-legend');
          if (existingLegend) {
            existingLegend.remove();
          }

          if (x.legend_html && x.legend_css) {
            const legendCss = document.createElement('style');
            legendCss.innerHTML = x.legend_css;
            document.head.appendChild(legendCss);

            const legend = document.createElement('div');
            legend.innerHTML = x.legend_html;
            legend.classList.add("mapboxgl-legend");
            el.appendChild(legend);
          }

          if (x.fullscreen_control) {
            map.addControl(new mapboxgl.FullscreenControl());
          }

          // Add navigation control if enabled
          if (x.navigation_control) {
            const nav = new mapboxgl.NavigationControl({
              showCompass: x.navigation_control.show_compass,
              showZoom: x.navigation_control.show_zoom,
              visualizePitch: x.navigation_control.visualize_pitch
            });
            map.addControl(nav, x.navigation_control.position);
          }

          // Add click event listener in shinyMode
          if (HTMLWidgets.shinyMode) {
            map.on('click', function(e) {
            const features = map.queryRenderedFeatures(e.point);

            if (features.length > 0) {
              const feature = features[0];
              Shiny.onInputChange(el.id + '_feature_click', {
                id: feature.id,
                properties: feature.properties,
                layer: feature.layer.id,
                lng: e.lngLat.lng,
                lat: e.lngLat.lat,
                time: new Date()
              });
            } else {
              Shiny.onInputChange(el.id + '_feature_click', null);
            }

            // Event listener for the map
            Shiny.onInputChange(el.id + '_click', {
              lng: e.lngLat.lng,
              lat: e.lngLat.lat,
              time: new Date()
            });
          });
        }

          el.map = map;
        });

        el.map = map;
      },

      getMap: function() {
        return map;  // Return the map instance
      },

      resize: function(width, height) {
        if (map) {
          map.resize();
        }
      }
    };
  }
});

if (HTMLWidgets.shinyMode) {
  Shiny.addCustomMessageHandler('mapboxgl-proxy', function(data) {
    var map = HTMLWidgets.find("#" + data.id).getMap();
    if (map) {
      var message = data.message;
      if (message.type === "set_filter") {
        map.setFilter(message.layer, message.filter);
      } else if (message.type === "add_source") {
        map.addSource(message.source)
      } else if (message.type === "add_layer") {
        try {
          map.addLayer(message.layer);
        } catch (e) {
          console.error("Failed to add layer via proxy: ", message.layer, e);
        }
      } else if (message.type === "remove_layer") {
        if (map.getLayer(message.layer)) {
          map.removeLayer(message.layer);
        }
        if (map.getSource(message.layer)) {
          map.removeSource(message.layer);
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
      } else if (message.type === "set_paint_property") {
        map.setPaintProperty(message.layer, message.name, message.value);
      } else if (message.type === "add_legend") {
        const existingLegend = document.getElementById('mapboxgl-legend');
        if (existingLegend) {
          existingLegend.remove();
        }

        const legendCss = document.createElement('style');
        legendCss.innerHTML = message.legend_css;
        document.head.appendChild(legendCss);

        const legend = document.createElement('div');
        legend.innerHTML = message.html;
        legend.classList.add("mapboxgl-legend");
        document.getElementById(data.id).appendChild(legend);
      } else if (message.type === "set_config_property") {
        map.setConfigProperty(message.importId, message.configName, message.value);
      } else if (message.type === "set_style") {
      map.setStyle(message.style, { diff: message.diff });

      if (message.config) {
        Object.keys(message.config).forEach(function(key) {
          map.setConfigProperty('basemap', key, message.config[key]);
        });
      }
    } else if (message.type === "add_navigation_control") {
        const nav = new mapboxgl.NavigationControl({
          showCompass: message.options.show_compass,
          showZoom: message.options.show_zoom,
          visualizePitch: message.options.visualize_pitch
        });
        map.addControl(nav, message.position);
      } else if (message.type === "add_markers") {
        if (!window.mapboxglMarkers) {
          window.mapboxglMarkers = [];
        }
        message.markers.forEach(function(marker) {
          const markerOptions = {
            color: marker.color,
            rotation: marker.rotation,
            ...marker.options
          };
          const mapMarker = new mapboxgl.Marker(markerOptions)
            .setLngLat([marker.lng, marker.lat])
            .addTo(map);

          if (marker.popup) {
            mapMarker.setPopup(new mapboxgl.Popup({ offset: 25 }).setText(marker.popup));
          }

          window.mapboxglMarkers.push(mapMarker);
        });
      } else if (message.type === "clear_markers") {
          if (window.mapboxglMarkers) {
            window.mapboxglMarkers.forEach(function(marker) {
              marker.remove();
            });
            window.mapboxglMarkers = [];
          }
      } else if (message.type === "query_rendered_features") {
        // Query rendered features
        function queryFeatures(geometry, layers, filter) {
          var queryOptions = {};
          if (layers) queryOptions.layers = layers;
          if (filter) queryOptions.filter = filter;

          var features = geometry ? map.queryRenderedFeatures(geometry, queryOptions) : map.queryRenderedFeatures(queryOptions);

          var uniqueFeatures = {};
          features.forEach(function(feature) {
            var id = feature.id; // Identify features by ID
            if (!uniqueFeatures[id]) {
              uniqueFeatures[id] = feature.properties;
            }
          });

          var layerFeatureProperties = {};
          Object.keys(uniqueFeatures).forEach(function(id) {
            var feature = uniqueFeatures[id];
            var layer = feature.layer.id; // Ensure 'layer_id' is set in the properties
            if (!layerFeatureProperties[layer]) {
              layerFeatureProperties[layer] = [];
            }
            layerFeatureProperties[layer].push(feature);
          });

          Shiny.setInputValue(data.id + '_feature_query', layerFeatureProperties);
        }

        queryFeatures(message.geometry, message.layers, message.filter);

      }
    }

  });
}
