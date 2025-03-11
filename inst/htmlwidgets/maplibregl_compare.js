HTMLWidgets.widget({
    name: "maplibregl_compare",

    type: "output",

    factory: function (el, width, height) {
        // Store maps and compare object to allow access during Shiny updates
        let beforeMap, afterMap, compareControl;
        
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
                
                // Add PMTiles support
                if (typeof pmtiles !== "undefined") {
                    let protocol = new pmtiles.Protocol({ metadata: true });
                    maplibregl.addProtocol("pmtiles", protocol.tile);
                }

                // Create container divs for the maps
                const beforeContainerId = `${el.id}-before`;
                const afterContainerId = `${el.id}-after`;
                
                // Different HTML structure based on mode
                if (x.mode === "sync") {
                    // Side-by-side sync mode
                    const containerStyle = x.orientation === "horizontal" 
                        ? `display: flex; flex-direction: column; width: 100%; height: 100%;` 
                        : `display: flex; flex-direction: row; width: 100%; height: 100%;`;
                    
                    const mapStyle = x.orientation === "horizontal"
                        ? `width: 100%; height: 50%; position: relative;`
                        : `width: 50%; height: 100%; position: relative;`;
                    
                    el.innerHTML = `
                      <div style="${containerStyle}">
                        <div id="${beforeContainerId}" class="map" style="${mapStyle}"></div>
                        <div id="${afterContainerId}" class="map" style="${mapStyle}"></div>
                      </div>
                    `;
                } else {
                    // Default swipe mode
                    el.innerHTML = `
                      <div id="${beforeContainerId}" class="map" style="width: 100%; height: 100%; position: absolute;"></div>
                      <div id="${afterContainerId}" class="map" style="width: 100%; height: 100%; position: absolute;"></div>
                    `;
                }

                beforeMap = new maplibregl.Map({
                    container: beforeContainerId,
                    style: x.map1.style,
                    center: x.map1.center,
                    zoom: x.map1.zoom,
                    bearing: x.map1.bearing,
                    pitch: x.map1.pitch,
                    accessToken: x.map1.access_token,
                    ...x.map1.additional_params,
                });

                afterMap = new maplibregl.Map({
                    container: afterContainerId,
                    style: x.map2.style,
                    center: x.map2.center,
                    zoom: x.map2.zoom,
                    bearing: x.map2.bearing,
                    pitch: x.map2.pitch,
                    accessToken: x.map2.access_token,
                    ...x.map2.additional_params,
                });

                if (x.mode === "swipe") {
                    // Only create the swiper in swipe mode
                    compareControl = new maplibregl.Compare(beforeMap, afterMap, `#${el.id}`, {
                        mousemove: x.mousemove,
                        orientation: x.orientation,
                    });
                } else {
                    // For sync mode, we directly leverage the sync-move module's approach

                    // Function to synchronize maps as seen in the mapbox-gl-sync-move module
                    const syncMaps = () => {
                        // Array of maps to sync
                        const maps = [beforeMap, afterMap];
                        // Array of move event handlers
                        const moveHandlers = [];
                        
                        // Setup the sync between maps
                        maps.forEach((map, index) => {
                            // Create a handler for each map that syncs all other maps
                            moveHandlers[index] = (e) => {
                                // Disable all move events temporarily
                                maps.forEach((m, i) => {
                                    m.off('move', moveHandlers[i]);
                                });
                                
                                // Get the state from the map that triggered the event
                                const center = map.getCenter();
                                const zoom = map.getZoom();
                                const bearing = map.getBearing();
                                const pitch = map.getPitch();
                                
                                // Apply this state to all other maps
                                maps.filter((m, i) => i !== index).forEach(m => {
                                    m.jumpTo({
                                        center: center,
                                        zoom: zoom,
                                        bearing: bearing,
                                        pitch: pitch
                                    });
                                });
                                
                                // Re-enable move events
                                maps.forEach((m, i) => {
                                    m.on('move', moveHandlers[i]);
                                });
                            };
                            
                            // Add the move handler to each map
                            map.on('move', moveHandlers[index]);
                        });
                    };
                    
                    // Initialize the sync
                    syncMaps();
                }

                // Ensure both maps resize correctly
                beforeMap.on("load", function () {
                    beforeMap.resize();
                    applyMapModifications(beforeMap, x.map1);
                    
                    // Setup Shiny event handlers for the before map
                    if (HTMLWidgets.shinyMode) {
                        setupShinyEvents(beforeMap, el.id, "before");
                    }
                });

                afterMap.on("load", function () {
                    afterMap.resize();
                    applyMapModifications(afterMap, x.map2);
                    
                    // Setup Shiny event handlers for the after map
                    if (HTMLWidgets.shinyMode) {
                        setupShinyEvents(afterMap, el.id, "after");
                    }
                });
                
                // Handle Shiny messages
                if (HTMLWidgets.shinyMode) {
                    Shiny.addCustomMessageHandler("maplibre-compare-proxy", function(message) {
                        if(message.id !== el.id)
                            return;
                            
                        processShinyMessage(message.message);
                    });
                }
                
                function processShinyMessage(message) {
                    const map = message.map === "before" ? beforeMap : afterMap;
                    
                    switch(message.type) {
                        case "set_style":
                            map.setStyle(message.style);
                            break;
                        case "add_source":
                            // Add or update a source
                            if (map.getSource(message.source_id)) {
                                map.removeSource(message.source_id);
                            }
                            map.addSource(message.source_id, message.source);
                            break;
                        case "add_layer":
                            if (map.getLayer(message.layer.id)) {
                                map.removeLayer(message.layer.id);
                            }
                            map.addLayer(message.layer);
                            break;
                        case "remove_layer":
                            if (map.getLayer(message.layer_id)) {
                                map.removeLayer(message.layer_id);
                            }
                            break;
                        case "set_view":
                            map.jumpTo({
                                center: message.center,
                                zoom: message.zoom,
                                bearing: message.bearing,
                                pitch: message.pitch
                            });
                            break;
                        case "fly_to":
                            map.flyTo(message.options);
                            break;
                        case "set_filter":
                            map.setFilter(message.layer, message.filter);
                            break;
                        case "set_paint_property":
                            map.setPaintProperty(message.layer, message.name, message.value);
                            break;
                        case "set_layout_property":
                            map.setLayoutProperty(message.layer, message.name, message.value);
                            break;
                        case "set_pitch":
                            map.setPitch(message.pitch);
                            break;
                        case "set_bearing":
                            map.setBearing(message.bearing);
                            break;
                        case "set_zoom":
                            map.setZoom(message.zoom);
                            break;
                        case "set_center":
                            map.setCenter(message.center);
                            break;
                        case "set_projection":
                            // Only if maplibre supports projection
                            if (typeof map.setProjection === 'function') {
                                map.setProjection(message.projection);
                            }
                            break;
                        case "set_source":
                            var layer = map.getLayer(message.layer);
                            if (layer) {
                                var source = layer.source;
                                map.getSource(source).setData(JSON.parse(message.source));
                            }
                            break;
                        case "set_tooltip":
                            // Implement tooltip functionality 
                            if (map.getLayer(message.layer)) {
                                // Remove any existing tooltip handlers
                                map.off('mousemove', message.layer);
                                map.off('mouseleave', message.layer);
                                
                                const tooltip = new maplibregl.Popup({
                                    closeButton: false,
                                    closeOnClick: false
                                });
                                
                                map.on('mousemove', message.layer, function(e) {
                                    map.getCanvas().style.cursor = 'pointer';
                                    if (e.features.length > 0) {
                                        const description = e.features[0].properties[message.tooltip];
                                        tooltip
                                            .setLngLat(e.lngLat)
                                            .setHTML(description)
                                            .addTo(map);
                                    }
                                });
                                
                                map.on('mouseleave', message.layer, function() {
                                    map.getCanvas().style.cursor = '';
                                    tooltip.remove();
                                });
                            }
                            break;
                        case "clear_markers":
                            if (window.maplibreglMarkers) {
                                window.maplibreglMarkers.forEach(function(marker) {
                                    marker.remove();
                                });
                                window.maplibreglMarkers = [];
                            }
                            break;
                        case "move_layer":
                            if (map.getLayer(message.layer)) {
                                if (message.before) {
                                    map.moveLayer(message.layer, message.before);
                                } else {
                                    map.moveLayer(message.layer);
                                }
                            }
                            break;
                        case "set_opacity":
                            // Set opacity for all fill layers
                            const style = map.getStyle();
                            if (style && style.layers) {
                                style.layers.forEach(function(layer) {
                                    if (layer.type === 'fill' && map.getLayer(layer.id)) {
                                        map.setPaintProperty(layer.id, 'fill-opacity', message.opacity);
                                    }
                                });
                            }
                            break;
                    }
                }
                
                function setupShinyEvents(map, parentId, mapType) {
                    // Set view state on move end
                    map.on("moveend", function() {
                        const center = map.getCenter();
                        const zoom = map.getZoom();
                        const bearing = map.getBearing();
                        const pitch = map.getPitch();
                        
                        if (window.Shiny) {
                            Shiny.setInputValue(parentId + "_" + mapType + "_view", {
                                center: [center.lng, center.lat],
                                zoom: zoom,
                                bearing: bearing,
                                pitch: pitch
                            });
                        }
                    });
                    
                    // Send clicked point coordinates to Shiny
                    map.on("click", function(e) {
                        if (window.Shiny) {
                            Shiny.setInputValue(parentId + "_" + mapType + "_click", {
                                lng: e.lngLat.lng,
                                lat: e.lngLat.lat,
                                time: Date.now()
                            });
                        }
                    });
                }
                
                function applyMapModifications(map, mapData) {
                    // Define the tooltip handler functions to match the ones in maplibregl.js
                    function onMouseMoveTooltip(e, map, tooltipPopup, tooltipProperty) {
                        map.getCanvas().style.cursor = "pointer";
                        if (e.features.length > 0) {
                            const description = e.features[0].properties[tooltipProperty];
                            tooltipPopup.setLngLat(e.lngLat).setHTML(description).addTo(map);
                    
                            // Store reference to currently active tooltip
                            window._activeTooltip = tooltipPopup;
                        } else {
                            tooltipPopup.remove();
                            // If this was the active tooltip, clear the reference
                            if (window._activeTooltip === tooltipPopup) {
                                delete window._activeTooltip;
                            }
                        }
                    }
                    
                    function onMouseLeaveTooltip(map, tooltipPopup) {
                        map.getCanvas().style.cursor = "";
                        tooltipPopup.remove();
                        if (window._activeTooltip === tooltipPopup) {
                            delete window._activeTooltip;
                        }
                    }

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
                    
                    // Process H3J sources if provided
                    if (mapData.h3j_sources) {
                        mapData.h3j_sources.forEach(async function (source) {
                            await map.addH3JSource(source.id, {
                                data: source.url,
                            });
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
                                if (layer.popup) {
                                    map.on("click", layer.id, function (e) {
                                        const description =
                                            e.features[0].properties[layer.popup];

                                        new maplibregl.Popup()
                                            .setLngLat(e.lngLat)
                                            .setHTML(description)
                                            .addTo(map);
                                    });

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
                                    const tooltip = new maplibregl.Popup({
                                        closeButton: false,
                                        closeOnClick: false,
                                    });

                                    // Create a reference to the mousemove handler function
                                    const mouseMoveHandler = function (e) {
                                        onMouseMoveTooltip(
                                            e,
                                            map,
                                            tooltip,
                                            layer.tooltip,
                                        );
                                    };

                                    // Create a reference to the mouseleave handler function
                                    const mouseLeaveHandler = function () {
                                        onMouseLeaveTooltip(map, tooltip);
                                    };

                                    // Attach the named handler references
                                    map.on("mousemove", layer.id, mouseMoveHandler);
                                    map.on(
                                        "mouseleave",
                                        layer.id,
                                        mouseLeaveHandler,
                                    );

                                    // Store these handler references
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
                    
                    // Add custom images if provided
                    if (mapData.images && Array.isArray(mapData.images)) {
                        mapData.images.forEach(async function (imageInfo) {
                            try {
                                const image = await map.loadImage(
                                    imageInfo.url,
                                );
                                if (!map.hasImage(imageInfo.id)) {
                                    map.addImage(
                                        imageInfo.id,
                                        image.data,
                                        imageInfo.options,
                                    );
                                }
                            } catch (error) {
                                console.error("Error loading image:", error);
                            }
                        });
                    } else if (mapData.images) {
                        console.error("mapData.images is not an array:", mapData.images);
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
                    
                    // Add geolocate control if enabled
                    if (mapData.geolocate_control) {
                        const geolocate = new maplibregl.GeolocateControl({
                            positionOptions:
                                mapData.geolocate_control.positionOptions,
                            trackUserLocation:
                                mapData.geolocate_control.trackUserLocation,
                            showAccuracyCircle:
                                mapData.geolocate_control.showAccuracyCircle,
                            showUserLocation:
                                mapData.geolocate_control.showUserLocation,
                            showUserHeading:
                                mapData.geolocate_control.showUserHeading,
                            fitBoundsOptions:
                                mapData.geolocate_control.fitBoundsOptions,
                        });
                        map.addControl(geolocate, mapData.geolocate_control.position);

                        if (HTMLWidgets.shinyMode) {
                            geolocate.on("geolocate", function (event) {
                                Shiny.setInputValue(el.id + "_geolocate", {
                                    coords: event.coords,
                                    time: new Date(),
                                });
                            });

                            geolocate.on("trackuserlocationstart", function () {
                                Shiny.setInputValue(
                                    el.id + "_geolocate_tracking",
                                    {
                                        status: "start",
                                        time: new Date(),
                                    },
                                );
                            });

                            geolocate.on("trackuserlocationend", function () {
                                Shiny.setInputValue(
                                    el.id + "_geolocate_tracking",
                                    {
                                        status: "end",
                                        time: new Date(),
                                    },
                                );
                            });

                            geolocate.on("error", function (error) {
                                if (error.error.code === 1) {
                                    Shiny.setInputValue(
                                        el.id + "_geolocate_error",
                                        {
                                            message:
                                                "Location permission denied",
                                            time: new Date(),
                                        },
                                    );
                                }
                            });
                        }
                    }
                    
                    // Add geocoder control if enabled
                    if (mapData.geocoder_control) {
                        const geocoderApi = {
                            forwardGeocode: async (config) => {
                                const features = [];
                                try {
                                    const request = `https://nominatim.openstreetmap.org/search?q=${
                                        config.query
                                    }&format=geojson&polygon_geojson=1&addressdetails=1`;
                                    const response = await fetch(request);
                                    const geojson = await response.json();
                                    for (const feature of geojson.features) {
                                        const center = [
                                            feature.bbox[0] +
                                                (feature.bbox[2] -
                                                    feature.bbox[0]) /
                                                    2,
                                            feature.bbox[1] +
                                                (feature.bbox[3] -
                                                    feature.bbox[1]) /
                                                    2,
                                        ];
                                        const point = {
                                            type: "Feature",
                                            geometry: {
                                                type: "Point",
                                                coordinates: center,
                                            },
                                            place_name:
                                                feature.properties.display_name,
                                            properties: feature.properties,
                                            text: feature.properties
                                                .display_name,
                                            place_type: ["place"],
                                            center,
                                        };
                                        features.push(point);
                                    }
                                } catch (e) {
                                    console.error(
                                        `Failed to forwardGeocode with error: ${e}`,
                                    );
                                }

                                return {
                                    features,
                                };
                            },
                        };
                        const geocoderOptions = {
                            maplibregl: maplibregl,
                            ...mapData.geocoder_control,
                        };

                        // Set default values if not provided
                        if (!geocoderOptions.placeholder)
                            geocoderOptions.placeholder = "Search";
                        if (typeof geocoderOptions.collapsed === "undefined")
                            geocoderOptions.collapsed = false;

                        const geocoder = new MaplibreGeocoder(
                            geocoderApi,
                            geocoderOptions,
                        );

                        map.addControl(
                            geocoder,
                            mapData.geocoder_control.position || "top-right",
                        );
                        
                        // Handle geocoder results in Shiny mode
                        if (HTMLWidgets.shinyMode) {
                            geocoder.on("results", function (e) {
                                Shiny.setInputValue(el.id + "_geocoder", {
                                    result: e,
                                    time: new Date(),
                                });
                            });
                        }
                    }

                    // Add reset control if enabled
                    if (mapData.reset_control) {
                        const resetControl = document.createElement("button");
                        resetControl.className =
                            "maplibregl-ctrl-icon maplibregl-ctrl-reset";
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
                        resetContainer.className =
                            "maplibregl-ctrl maplibregl-ctrl-group";
                        resetContainer.appendChild(resetControl);

                        const initialView = {
                            center: mapData.center,
                            zoom: mapData.zoom,
                            pitch: mapData.pitch,
                            bearing: mapData.bearing,
                            animate: mapData.reset_control.animate,
                        };

                        if (mapData.reset_control.duration) {
                            initialView.duration = mapData.reset_control.duration;
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
                                    resetContainer.parentNode.removeChild(
                                        resetContainer,
                                    );
                                },
                            },
                            mapData.reset_control.position,
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
