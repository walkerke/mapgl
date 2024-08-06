HTMLWidgets.widget({

  name: 'mapboxgl',

  type: 'output',

  factory: function(el, width, height) {
    let map;
    let draw;

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

        map.controls = [];


        map.on('style.load', function() {
          map.resize();

          if (HTMLWidgets.shinyMode) {

              map.on('load', function() {
                var bounds = map.getBounds();
                var center = map.getCenter();
                var zoom = map.getZoom();

                Shiny.setInputValue(el.id + '_zoom', zoom);
                Shiny.setInputValue(el.id + '_center', { lng: center.lng, lat: center.lat });
                Shiny.setInputValue(el.id + '_bbox', {
                  xmin: bounds.getWest(),
                  ymin: bounds.getSouth(),
                  xmax: bounds.getEast(),
                  ymax: bounds.getNorth()
                });
              });

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
                draggable: marker.options.draggable || false,
                ...marker.options
              };
              const mapMarker = new mapboxgl.Marker(markerOptions)
                .setLngLat([marker.lng, marker.lat])
                .addTo(map);

              if (marker.popup) {
                mapMarker.setPopup(new mapboxgl.Popup({ offset: 25 }).setText(marker.popup));
              }

              if (HTMLWidgets.shinyMode) {
                const markerId = marker.id;
                if (markerId) {
                  const lngLat = mapMarker.getLngLat();
                  Shiny.setInputValue(el.id + '_marker_' + markerId, { id: markerId, lng: lngLat.lng, lat: lngLat.lat });

                  mapMarker.on('dragend', function() {
                    const lngLat = mapMarker.getLngLat();
                    Shiny.setInputValue(el.id + '_marker_' + markerId, { id: markerId, lng: lngLat.lng, lat: lngLat.lat });
                  });
                }
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
                const geojsonData = source.data;
                map.addSource(source.id, {
                  type: 'geojson',
                  data: geojsonData,
                  generateId: true
                });
              } else if (source.type === "raster") {
                if (source.url) {
                  map.addSource(source.id, {
                    type: 'raster',
                    url: source.url,
                    tileSize: source.tileSize,
                    maxzoom: source.maxzoom
                  });
                } else if (source.tiles) {
                  map.addSource(source.id, {
                    type: 'raster',
                    tiles: source.tiles,
                    tileSize: source.tileSize,
                    maxzoom: source.maxzoom
                  });
                }
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

                if (layer.before_id) {
                  map.addLayer(layerConfig, layer.before_id);
                } else {
                  map.addLayer(layerConfig);
                }

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

          // Apply setFilter if provided
          if (x.setFilter) {
            x.setFilter.forEach(function(filter) {
              map.setFilter(filter.layer, filter.filter);
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

          // Add scale control if enabled
          if (x.scale_control) {
            const scaleControl = new mapboxgl.ScaleControl({
              maxWidth: x.scale_control.maxWidth,
              unit: x.scale_control.unit
            });
            map.addControl(scaleControl, x.scale_control.position);
            map.controls.push(scaleControl);
          }

          if (x.draw_control && x.draw_control.enabled) {
            draw = new MapboxDraw(x.draw_control.options);
            map.addControl(draw, x.draw_control.position);
            map.controls.push(draw);

            // Add event listeners
            map.on('draw.create', updateDrawnFeatures);
            map.on('draw.delete', updateDrawnFeatures);
            map.on('draw.update', updateDrawnFeatures);
          }

          function updateDrawnFeatures() {
            if (draw) {
              var drawnFeatures = draw.getAll();
              if (HTMLWidgets.shinyMode) {
                Shiny.setInputValue(el.id + '_drawn_features', JSON.stringify(drawnFeatures));
              }
              // Store drawn features in the widget's data
              if (el.querySelector) {
                var widget = HTMLWidgets.find("#" + el.id);
                if (widget) {
                  widget.drawFeatures = drawnFeatures;
                }
              }
            }
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
            // legend.classList.add("mapboxgl-legend");
            el.appendChild(legend);

          }

          // Add fullscreen control if enabled
          if (x.fullscreen_control && x.fullscreen_control.enabled) {
            const position = x.fullscreen_control.position || 'top-right';
            const fullscreen = new mapboxgl.FullscreenControl();
            map.addControl(fullscreen, position);
            map.controls.push(fullscreen);
          }

          // Add navigation control if enabled
          if (x.navigation_control) {
            const nav = new mapboxgl.NavigationControl({
              showCompass: x.navigation_control.show_compass,
              showZoom: x.navigation_control.show_zoom,
              visualizePitch: x.navigation_control.visualize_pitch
            });
            map.addControl(nav, x.navigation_control.position);
            map.controls.push(nav);
          }

          // Add the layers control if provided
          if (x.layers_control) {
            const layersControl = document.createElement('div');
            layersControl.id = x.layers_control.control_id;
            layersControl.className = x.layers_control.collapsible ? 'layers-control collapsible' : 'layers-control';
            layersControl.style.position = 'absolute';
            layersControl.style[x.layers_control.position || 'top-right'] = '10px';
            el.appendChild(layersControl);

            const layersList = document.createElement('div');
            layersList.className = 'layers-list';
            layersControl.appendChild(layersList);

            // Fetch layers to be included in the control
            let layers = x.layers_control.layers || map.getStyle().layers.map(layer => layer.id);

            // Ensure layers is always an array
            if (!Array.isArray(layers)) {
              layers = [layers];
            }

            layers.forEach((layerId, index) => {
              const link = document.createElement('a');
              link.id = layerId;
              link.href = '#';
              link.textContent = layerId;
              link.className = 'active';

              // Show or hide layer when the toggle is clicked
              link.onclick = function(e) {
                const clickedLayer = this.textContent;
                e.preventDefault();
                e.stopPropagation();

                const visibility = map.getLayoutProperty(clickedLayer, 'visibility');

                // Toggle layer visibility by changing the layout object's visibility property
                if (visibility === 'visible') {
                  map.setLayoutProperty(clickedLayer, 'visibility', 'none');
                  this.className = '';
                } else {
                  this.className = 'active';
                  map.setLayoutProperty(clickedLayer, 'visibility', 'visible');
                }
              };

              layersList.appendChild(link);
            });

            // Handle collapsible behavior
            if (x.layers_control.collapsible) {
              const toggleButton = document.createElement('div');
              toggleButton.className = 'toggle-button';
              toggleButton.textContent = 'Layers';
              toggleButton.onclick = function() {
                layersControl.classList.toggle('open');
              };
              layersControl.insertBefore(toggleButton, layersList);
            }
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

      getDrawnFeatures: function() {
        return this.drawFeatures || {type: "FeatureCollection", features: []};
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
          if (message.layer.before_id) {
            map.addLayer(message.layer, message.layer.before_id);
          } else {
            map.addLayer(message.layer);
          }

          // Add popups or tooltips if provided
          if (message.layer.popup) {
            map.on('click', message.layer.id, function(e) {
              const description = e.features[0].properties[message.layer.popup];
              new mapboxgl.Popup()
                .setLngLat(e.lngLat)
                .setHTML(description)
                .addTo(map);
            });
          }

          if (message.layer.tooltip) {
            const tooltip = new mapboxgl.Popup({
              closeButton: false,
              closeOnClick: false
            });

            map.on('mousemove', message.layer.id, function(e) {
              map.getCanvas().style.cursor = 'pointer';

              if (e.features.length > 0) {
                const description = e.features[0].properties[message.layer.tooltip];
                tooltip.setLngLat(e.lngLat).setHTML(description).addTo(map);
              } else {
                tooltip.remove();
              }
            });

            map.on('mouseleave', message.layer.id, function() {
              map.getCanvas().style.cursor = '';
              tooltip.remove();
            });
          }

          // Add hover effect if provided
          if (message.layer.hover_options) {
            const jsHoverOptions = {};
            for (const [key, value] of Object.entries(message.layer.hover_options)) {
              const jsKey = key.replace(/_/g, '-');
              jsHoverOptions[jsKey] = value;
            }

            let hoveredFeatureId = null;

            map.on('mousemove', message.layer.id, function(e) {
              if (e.features.length > 0) {
                if (hoveredFeatureId !== null) {
                  map.setFeatureState(
                    { source: typeof message.layer.source === 'string' ? message.layer.source : message.layer.id, id: hoveredFeatureId },
                    { hover: false }
                  );
                }
                hoveredFeatureId = e.features[0].id;
                map.setFeatureState(
                  { source: typeof message.layer.source === 'string' ? message.layer.source : message.layer.id, id: hoveredFeatureId },
                  { hover: true }
                );
              }
            });

            map.on('mouseleave', message.layer.id, function() {
              if (hoveredFeatureId !== null) {
                map.setFeatureState(
                  { source: typeof message.layer.source === 'string' ? message.layer.source : message.layer.id, id: hoveredFeatureId },
                  { hover: false }
                );
              }
              hoveredFeatureId = null;
            });

            Object.keys(jsHoverOptions).forEach(function(key) {
              const originalPaint = map.getPaintProperty(message.layer.id, key) || message.layer.paint[key];
              map.setPaintProperty(message.layer.id, key, [
                'case',
                ['boolean', ['feature-state', 'hover'], false],
                jsHoverOptions[key],
                originalPaint
              ]);
            });
          }


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
        const existingLegend = document.querySelector(`#${data.id} .mapboxgl-legend`);
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
        map.controls.push(nav);
      } else if (message.type === "add_draw_control") {
        draw = new MapboxDraw(message.options);
        map.addControl(draw, message.position);
        map.controls.push(draw);

        // Add event listeners
        map.on('draw.create', updateDrawnFeatures);
        map.on('draw.delete', updateDrawnFeatures);
        map.on('draw.update', updateDrawnFeatures);
      } else if (message.type === "get_drawn_features") {
        const features = draw ? draw.getAll() : null;
        Shiny.setInputValue(data.id + '_drawn_features', JSON.stringify(features));
      } else if (message.type === "clear_drawn_features") {
        if (draw) {
          draw.deleteAll();
          // Update the drawn features
          updateDrawnFeatures();
        }
      } else if (message.type === "add_markers") {
          if (!window.mapboxglMarkers) {
            window.mapboxglMarkers = [];
          }
          message.markers.forEach(function(marker) {
            const markerOptions = {
              color: marker.color,
              rotation: marker.rotation,
              draggable: marker.options.draggable || false,
              ...marker.options
            };
            const mapMarker = new mapboxgl.Marker(markerOptions)
              .setLngLat([marker.lng, marker.lat])
              .addTo(map);

            if (marker.popup) {
              mapMarker.setPopup(new mapboxgl.Popup({ offset: 25 }).setText(marker.popup));
            }

            const markerId = marker.id;
            if (markerId) {
              const lngLat = mapMarker.getLngLat();
              Shiny.setInputValue(data.id + '_marker_' + markerId, { id: markerId, lng: lngLat.lng, lat: lngLat.lat });

              mapMarker.on('dragend', function() {
                const lngLat = mapMarker.getLngLat();
                Shiny.setInputValue(data.id + '_marker_' + markerId, { id: markerId, lng: lngLat.lng, lat: lngLat.lat });
              });
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
      } else if (message.type === "add_fullscreen_control") {
        const position = message.position || 'top-right';
        const fullscreen = new mapboxgl.FullscreenControl();
        map.addControl(fullscreen, position);
        map.controls.push(fullscreen)
      } else if (message.type === "add_scale_control") {
        const scaleControl = new mapboxgl.ScaleControl({
          maxWidth: message.options.maxWidth,
          unit: message.options.unit
        });
        map.addControl(scaleControl, message.options.position);
        map.controls.push(scaleControl);
      } else if (message.type === "add_layers_control") {
        const layersControl = document.createElement('div');
        layersControl.id = message.control_id;
        layersControl.className = message.collapsible ? 'layers-control collapsible' : 'layers-control';
        layersControl.style.position = 'absolute';
        layersControl.style[message.position || 'top-right'] = '10px';

        const layersList = document.createElement('div');
        layersList.className = 'layers-list';
        layersControl.appendChild(layersList);

        let layers = message.layers || [];

        // Ensure layers is always an array
        if (!Array.isArray(layers)) {
          layers = [layers];
        }

        layers.forEach((layerId, index) => {
          const link = document.createElement('a');
          link.id = layerId;
          link.href = '#';
          link.textContent = layerId;
          link.className = 'active';

          link.onclick = function(e) {
            const clickedLayer = this.textContent;
            e.preventDefault();
            e.stopPropagation();

            const visibility = map.getLayoutProperty(clickedLayer, 'visibility');

            if (visibility === 'visible') {
              map.setLayoutProperty(clickedLayer, 'visibility', 'none');
              this.className = '';
            } else {
              this.className = 'active';
              map.setLayoutProperty(clickedLayer, 'visibility', 'visible');
            }
          };

          layersList.appendChild(link);
        });

        if (message.collapsible) {
          const toggleButton = document.createElement('div');
          toggleButton.className = 'toggle-button';
          toggleButton.textContent = 'Layers';
          toggleButton.onclick = function() {
            layersControl.classList.toggle('open');
          };
          layersControl.insertBefore(toggleButton, layersList);
        }

        const mapContainer = document.getElementById(data.id);
        if (mapContainer) {
          mapContainer.appendChild(layersControl);
        } else {
          console.error(`Cannot find map container with ID ${data.id}`);
        }
    } else if (message.type === 'clear_legend') {
        const existingLegend = document.querySelector(`#${data.id} .mapboxgl-legend`);
        if (existingLegend) {
          existingLegend.remove();
        }
      } else if (message.type === "clear_controls") {
        map.controls.forEach(control => {
          map.removeControl(control);
        });
        map.controls = [];

        const layersControl = document.querySelector(`#${data.id} .layers-control`);
        if (layersControl) {
          layersControl.remove();
        }
  }
    }
  });
}
