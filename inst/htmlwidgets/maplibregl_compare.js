HTMLWidgets.widget({
    name: "maplibregl_compare",

    type: "output",

    factory: function (el, width, height) {
        return {
            renderValue: function (x) {
                if (typeof maplibregl === "undefined") {
                    console.error("Maplibre GL JS is not loaded.");
                    return;
                }
                if (typeof maplibregl.Compare === "undefined") {
                    console.error("Maplibre GL Compare plugin is not loaded.");
                    return;
                }

                el.innerHTML = `
          <div id="${x.elementId}-before" class="map" style="width: 100%; height: 100%; position: absolute;"></div>
          <div id="${x.elementId}-after" class="map" style="width: 100%; height: 100%; position: absolute;"></div>
        `;

                var beforeMap = new maplibregl.Map({
                    container: `${x.elementId}-before`,
                    style: x.map1.style,
                    center: x.map1.center,
                    zoom: x.map1.zoom,
                    bearing: x.map1.bearing,
                    pitch: x.map1.pitch,
                    accessToken: x.map1.access_token,
                    ...x.map1.additional_params,
                });

                var afterMap = new maplibregl.Map({
                    container: `${x.elementId}-after`,
                    style: x.map2.style,
                    center: x.map2.center,
                    zoom: x.map2.zoom,
                    bearing: x.map2.bearing,
                    pitch: x.map2.pitch,
                    accessToken: x.map2.access_token,
                    ...x.map2.additional_params,
                });

                new maplibregl.Compare(beforeMap, afterMap, `#${x.elementId}`, {
                    mousemove: x.mousemove,
                    orientation: x.orientation,
                });

                // Ensure both maps resize correctly
                beforeMap.on("load", function () {
                    beforeMap.resize();
                    applyMapModifications(beforeMap, x.map1);
                });

                afterMap.on("load", function () {
                    afterMap.resize();
                    applyMapModifications(afterMap, x.map2);
                });

                function applyMapModifications(map, mapData) {
                    // Set config properties if provided
                    if (mapData.config_properties) {
                        mapData.config_properties.forEach(function (config) {
                            map.setConfigProperty(
                                config.importId,
                                config.configName,
                                config.value,
                            );
                        });
                    }

                    if (mapData.markers) {
                        if (!window.maplibreglMarkers) {
                            window.maplibreglMarkers = [];
                        }
                        mapData.markers.forEach(function (marker) {
                            const markerOptions = {
                                color: marker.color,
                                rotation: marker.rotation,
                                draggable: marker.options.draggable || false,
                                ...marker.options,
                            };
                            const mapMarker = new maplibregl.Marker(
                                markerOptions,
                            )
                                .setLngLat([marker.lng, marker.lat])
                                .addTo(map);

                            if (marker.popup) {
                                mapMarker.setPopup(
                                    new maplibregl.Popup({
                                        offset: 25,
                                    }).setText(marker.popup),
                                );
                            }

                            const markerId = marker.id;
                            if (markerId) {
                                const lngLat = mapMarker.getLngLat();
                                Shiny.setInputValue(
                                    el.id + "_marker_" + markerId,
                                    {
                                        id: markerId,
                                        lng: lngLat.lng,
                                        lat: lngLat.lat,
                                    },
                                );

                                mapMarker.on("dragend", function () {
                                    const lngLat = mapMarker.getLngLat();
                                    Shiny.setInputValue(
                                        el.id + "_marker_" + markerId,
                                        {
                                            id: markerId,
                                            lng: lngLat.lng,
                                            lat: lngLat.lat,
                                        },
                                    );
                                });
                            }

                            window.maplibreglMarkers.push(mapMarker);
                        });
                    }

                    // Add sources if provided
                    if (mapData.sources) {
                        mapData.sources.forEach(function (source) {
                            if (source.type === "vector") {
                                map.addSource(source.id, {
                                    type: "vector",
                                    url: source.url,
                                });
                            } else if (source.type === "geojson") {
                                const geojsonData = source.geojson;
                                map.addSource(source.id, {
                                    type: "geojson",
                                    data: geojsonData,
                                    generateId: true,
                                });
                            } else if (source.type === "raster") {
                                if (source.url) {
                                    map.addSource(source.id, {
                                        type: "raster",
                                        url: source.url,
                                        tileSize: source.tileSize,
                                        maxzoom: source.maxzoom,
                                    });
                                } else if (source.tiles) {
                                    map.addSource(source.id, {
                                        type: "raster",
                                        tiles: source.tiles,
                                        tileSize: source.tileSize,
                                        maxzoom: source.maxzoom,
                                    });
                                }
                            } else if (source.type === "raster-dem") {
                                map.addSource(source.id, {
                                    type: "raster-dem",
                                    url: source.url,
                                    tileSize: source.tileSize,
                                    maxzoom: source.maxzoom,
                                });
                            } else if (source.type === "image") {
                                map.addSource(source.id, {
                                    type: "image",
                                    url: source.url,
                                    coordinates: source.coordinates,
                                });
                            } else if (source.type === "video") {
                                map.addSource(source.id, {
                                    type: "video",
                                    urls: source.urls,
                                    coordinates: source.coordinates,
                                });
                            }
                        });
                    }

                    // Add layers if provided
                    if (mapData.layers) {
                        mapData.layers.forEach(function (layer) {
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
                                    layerConfig["source-layer"] =
                                        layer.source_layer;
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

                                if (layer.before_id) {
                                    map.addLayer(layerConfig, layer.before_id);
                                } else {
                                    map.addLayer(layerConfig);
                                }

                                // Add popups or tooltips if provided
                                //                if (layer.popup) {
                                //                  map.on('click', layer.id, function(e) {
                                //                    const description = e.features[0].properties[layer.popup];
                                //
                                //                    new maplibregl.Popup()
                                //                      .setLngLat(e.lngLat)
                                //                      .setHTML(description)
                                //                      .addTo(map);
                                //                  });
                                //                }
                                //
                                //                if (layer.tooltip) {
                                //                  const tooltip = new maplibregl.Popup({
                                //                    closeButton: false,
                                //                    closeOnClick: false
                                //                  });
                                //
                                //                  map.on('mousemove', layer.id, function(e) {
                                //                    map.getCanvas().style.cursor = 'pointer';
                                //
                                //                    if (e.features.length > 0) {
                                //                      const description = e.features[0].properties[layer.tooltip];
                                //                      tooltip.setLngLat(e.lngLat).setHTML(description).addTo(map);
                                //                    } else {
                                //                      tooltip.remove();
                                //                    }
                                //                  });
                                //
                                //                  map.on('mouseleave', layer.id, function() {
                                //                    map.getCanvas().style.cursor = '';
                                //                    tooltip.remove();
                                //                  });
                                //
                                //                }

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
                                                map.setFeatureState(
                                                    {
                                                        source:
                                                            typeof layer.source ===
                                                            "string"
                                                                ? layer.source
                                                                : layer.id,
                                                        id: hoveredFeatureId,
                                                    },
                                                    { hover: false },
                                                );
                                            }
                                            hoveredFeatureId = e.features[0].id;
                                            map.setFeatureState(
                                                {
                                                    source:
                                                        typeof layer.source ===
                                                        "string"
                                                            ? layer.source
                                                            : layer.id,
                                                    id: hoveredFeatureId,
                                                },
                                                { hover: true },
                                            );
                                        }
                                    });

                                    map.on("mouseleave", layer.id, function () {
                                        if (hoveredFeatureId !== null) {
                                            map.setFeatureState(
                                                {
                                                    source:
                                                        typeof layer.source ===
                                                        "string"
                                                            ? layer.source
                                                            : layer.id,
                                                    id: hoveredFeatureId,
                                                },
                                                { hover: false },
                                            );
                                        }
                                        hoveredFeatureId = null;
                                    });

                                    Object.keys(jsHoverOptions).forEach(
                                        function (key) {
                                            const originalPaint =
                                                map.getPaintProperty(
                                                    layer.id,
                                                    key,
                                                ) || layer.paint[key];
                                            map.setPaintProperty(
                                                layer.id,
                                                key,
                                                [
                                                    "case",
                                                    [
                                                        "boolean",
                                                        [
                                                            "feature-state",
                                                            "hover",
                                                        ],
                                                        false,
                                                    ],
                                                    jsHoverOptions[key],
                                                    originalPaint,
                                                ],
                                            );
                                        },
                                    );
                                }
                            } catch (e) {
                                console.error(
                                    "Failed to add layer: ",
                                    layer,
                                    e,
                                );
                            }
                        });
                    }

                    // Set terrain if provided
                    if (mapData.terrain) {
                        map.setTerrain({
                            source: mapData.terrain.source,
                            exaggeration: mapData.terrain.exaggeration,
                        });
                    }

                    // Set fog
                    if (mapData.fog) {
                        map.setFog(mapData.fog);
                    }

                    if (mapData.fitBounds) {
                        map.fitBounds(
                            mapData.fitBounds.bounds,
                            mapData.fitBounds.options,
                        );
                    }
                    if (mapData.flyTo) {
                        map.flyTo(mapData.flyTo);
                    }
                    if (mapData.easeTo) {
                        map.easeTo(mapData.easeTo);
                    }
                    if (mapData.setCenter) {
                        map.setCenter(mapData.setCenter);
                    }
                    if (mapData.setZoom) {
                        map.setZoom(mapData.setZoom);
                    }
                    if (mapData.jumpTo) {
                        map.jumpTo(mapData.jumpTo);
                    }

                    const existingLegend =
                        document.getElementById("mapboxgl-legend");
                    if (existingLegend) {
                        existingLegend.remove();
                    }

                    if (mapData.legend_html && mapData.legend_css) {
                        const legendCss = document.createElement("style");
                        legendCss.innerHTML = mapData.legend_css;
                        document.head.appendChild(legendCss);

                        const legend = document.createElement("div");
                        legend.innerHTML = mapData.legend_html;
                        // legend.classList.add("mapboxgl-legend");
                        el.appendChild(legend);
                    }

                    // Add fullscreen control if enabled
                    if (
                        mapData.fullscreen_control &&
                        mapData.fullscreen_control.enabled
                    ) {
                        const position =
                            mapData.fullscreen_control.position || "top-right";
                        map.addControl(
                            new maplibregl.FullscreenControl(),
                            position,
                        );
                    }

                    // Add navigation control if enabled
                    if (mapData.navigation_control) {
                        const nav = new maplibregl.NavigationControl({
                            showCompass:
                                mapData.navigation_control.show_compass,
                            showZoom: mapData.navigation_control.show_zoom,
                            visualizePitch:
                                mapData.navigation_control.visualize_pitch,
                        });
                        map.addControl(
                            nav,
                            mapData.navigation_control.position,
                        );
                    }

                    // Add the layers control if provided
                    if (mapData.layers_control) {
                        const layersControl = document.createElement("div");
                        layersControl.id = mapData.layers_control.control_id;
                        layersControl.className = mapData.layers_control
                            .collapsible
                            ? "layers-control collapsible"
                            : "layers-control";
                        layersControl.style.position = "absolute";
                        layersControl.style[
                            mapData.layers_control.position || "top-right"
                        ] = "10px";
                        el.appendChild(layersControl);

                        const layersList = document.createElement("div");
                        layersList.className = "layers-list";
                        layersControl.appendChild(layersList);

                        // Fetch layers to be included in the control
                        let layers =
                            mapData.layers_control.layers ||
                            map.getStyle().layers.map((layer) => layer.id);

                        layers.forEach((layerId, index) => {
                            const link = document.createElement("a");
                            link.id = layerId;
                            link.href = "#";
                            link.textContent = layerId;
                            link.className = "active";

                            // Show or hide layer when the toggle is clicked
                            link.onclick = function (e) {
                                const clickedLayer = this.textContent;
                                e.preventDefault();
                                e.stopPropagation();

                                const visibility = map.getLayoutProperty(
                                    clickedLayer,
                                    "visibility",
                                );

                                // Toggle layer visibility by changing the layout object's visibility property
                                if (visibility === "visible") {
                                    map.setLayoutProperty(
                                        clickedLayer,
                                        "visibility",
                                        "none",
                                    );
                                    this.className = "";
                                } else {
                                    this.className = "active";
                                    map.setLayoutProperty(
                                        clickedLayer,
                                        "visibility",
                                        "visible",
                                    );
                                }
                            };

                            layersList.appendChild(link);
                        });

                        // Handle collapsible behavior
                        if (mapData.layers_control.collapsible) {
                            const toggleButton = document.createElement("div");
                            toggleButton.className = "toggle-button";
                            toggleButton.textContent = "Layers";
                            toggleButton.onclick = function () {
                                layersControl.classList.toggle("open");
                            };
                            layersControl.insertBefore(
                                toggleButton,
                                layersList,
                            );
                        }
                    }
                }
            },

            resize: function (width, height) {
                // Code to handle resizing if necessary
            },
        };
    },
});
