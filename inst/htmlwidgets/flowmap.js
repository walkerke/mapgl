window.MapGLFlowmapPlugin = (function () {
  const FLOWMAP_ATTRIBUTION_SELECTOR =
    ".mapboxgl-ctrl-attrib-inner, .maplibregl-ctrl-attrib-inner";
  const FLOWMAP_ATTRIBUTION_LINK_SELECTOR =
    'a[data-mapgl-flowmap-attribution="true"]';
  const FLOWMAP_ATTRIBUTION_SEPARATOR_SELECTOR =
    '[data-mapgl-flowmap-attribution-separator="true"]';
  const DEFAULT_LOCATION_TOOLTIP =
    "<strong>{name}</strong><br>Incoming trips: {totals.incomingCount}<br>Outgoing trips: {totals.outgoingCount}<br>Internal or round trips: {totals.internalCount}";
  const DEFAULT_FLOW_TOOLTIP = "<strong>{origin.id} -> {dest.id}</strong><br>{count}";

  function dataframeToRows(data, HTMLWidgets) {
    if (!data || Array.isArray(data) || typeof data !== "object") {
      return data;
    }

    if (HTMLWidgets && typeof HTMLWidgets.dataframeToD3 === "function") {
      return HTMLWidgets.dataframeToD3(data);
    }

    return data;
  }

  function attributionNodeHasContent(node) {
    if (!node) {
      return false;
    }

    if (
      node.nodeType === 1 &&
      (node.matches(FLOWMAP_ATTRIBUTION_LINK_SELECTOR) ||
        node.matches(FLOWMAP_ATTRIBUTION_SEPARATOR_SELECTOR))
    ) {
      return false;
    }

    return node.textContent && node.textContent.trim() !== "";
  }

  function hasNativeAttributionContent(attributionInner) {
    for (var i = 0; i < attributionInner.childNodes.length; i++) {
      if (attributionNodeHasContent(attributionInner.childNodes[i])) {
        return true;
      }
    }

    return false;
  }

  function makeFlowmapAttributionLink() {
    const link = document.createElement("a");
    link.href = "https://flowmap.gl/";
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    link.setAttribute("data-mapgl-flowmap-attribution", "true");
    link.textContent = "Flowmap.gl";
    return link;
  }

  function normalizeFlowmapAttributionLink(link) {
    link.href = "https://flowmap.gl/";
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    link.setAttribute("data-mapgl-flowmap-attribution", "true");
    link.textContent = "Flowmap.gl";
  }

  function ensureFlowmapAttribution(map) {
    if (!map || typeof map.getContainer !== "function") {
      return;
    }

    const container = map.getContainer();
    if (!container || typeof container.querySelector !== "function") {
      return;
    }

    const attributionInner = container.querySelector(
      FLOWMAP_ATTRIBUTION_SELECTOR
    );
    if (!attributionInner) {
      return;
    }

    const existingLinks = attributionInner.querySelectorAll(
      FLOWMAP_ATTRIBUTION_LINK_SELECTOR
    );
    var link = existingLinks[0] || makeFlowmapAttributionLink();

    normalizeFlowmapAttributionLink(link);

    for (var i = 1; i < existingLinks.length; i++) {
      existingLinks[i].remove();
    }

    const separators = attributionInner.querySelectorAll(
      FLOWMAP_ATTRIBUTION_SEPARATOR_SELECTOR
    );
    for (var j = 0; j < separators.length; j++) {
      separators[j].remove();
    }

    if (attributionInner.firstChild !== link) {
      attributionInner.insertBefore(link, attributionInner.firstChild);
    }

    if (hasNativeAttributionContent(attributionInner)) {
      const separator = document.createElement("span");
      separator.setAttribute(
        "data-mapgl-flowmap-attribution-separator",
        "true"
      );
      separator.textContent = " | ";
      attributionInner.insertBefore(separator, link.nextSibling);
    }
  }

  function installFlowmapAttributionRefresh(map) {
    if (!map || map._mapglFlowmapAttributionRefreshInstalled) {
      return;
    }

    var timer = null;
    const refresh = function () {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(function () {
        timer = null;
        ensureFlowmapAttribution(map);
      }, 50);
    };

    map._mapglFlowmapAttributionRefreshInstalled = true;
    map._mapglFlowmapAttributionRefresh = refresh;

    map.on("styledata", refresh);
    map.on("sourcedata", refresh);
    map.on("idle", refresh);
    map.once("remove", function () {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
      map.off("styledata", refresh);
      map.off("sourcedata", refresh);
      map.off("idle", refresh);
      map._mapglFlowmapAttributionRefreshInstalled = false;
      map._mapglFlowmapAttributionRefresh = null;
    });

    ensureFlowmapAttribution(map);
  }

  function getTooltipStore(map) {
    if (!map._mapglFlowmapTooltips) {
      map._mapglFlowmapTooltips = {};
    }
    return map._mapglFlowmapTooltips;
  }

  function hideFlowmapTooltip(map, id) {
    const store = getTooltipStore(map);
    const tooltip = store[id];
    if (!tooltip) {
      return;
    }
    if (tooltip.popup) {
      tooltip.popup.remove();
    }
    if (tooltip.element) {
      tooltip.element.style.display = "none";
    }
  }

  function hideAllFlowmapTooltips(map) {
    const store = getTooltipStore(map);
    Object.keys(store).forEach(function (id) {
      hideFlowmapTooltip(map, id);
    });
  }

  function hideOtherFlowmapTooltips(map, activeId) {
    const store = getTooltipStore(map);
    Object.keys(store).forEach(function (id) {
      if (id !== activeId) {
        hideFlowmapTooltip(map, id);
      }
    });
  }

  function getPopupConstructor() {
    if (typeof mapboxgl !== "undefined" && mapboxgl.Popup) {
      return mapboxgl.Popup;
    }
    if (typeof maplibregl !== "undefined" && maplibregl.Popup) {
      return maplibregl.Popup;
    }
    return null;
  }

  function escapeHTML(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function getPathValue(object, path) {
    if (!object || !path) {
      return undefined;
    }

    return path.split(".").reduce(function (value, key) {
      if (value == null) {
        return undefined;
      }
      return value[key];
    }, object);
  }

  function renderTooltipTemplate(template, object) {
    return template.replace(/\{([^}]+)\}/g, function (match, path) {
      const value = getPathValue(object, path.trim());
      return escapeHTML(value == null ? "" : value);
    });
  }

  function getTooltipTemplate(tooltip, objectType) {
    const template = tooltip[objectType];
    if (template === false || template == null) {
      return null;
    }
    if (template === true) {
      return objectType === "location"
        ? DEFAULT_LOCATION_TOOLTIP
        : DEFAULT_FLOW_TOOLTIP;
    }
    return template;
  }

  function getTooltipHTML(config, info) {
    const tooltip = config.tooltip || {};
    const object = info && info.object;
    if (!object || !object.type) {
      return null;
    }

    const template = getTooltipTemplate(tooltip, object.type);
    if (!template) {
      return null;
    }

    return renderTooltipTemplate(template, object);
  }

  function getTooltipLngLat(map, info) {
    if (info && info.lngLat) {
      return info.lngLat;
    }
    if (info && Array.isArray(info.coordinate)) {
      return info.coordinate;
    }

    const object = info && info.object;
    if (!object) {
      return null;
    }

    if (object.type === "location" && object.location) {
      const location = object.location;
      if (location.lon != null && location.lat != null) {
        return [location.lon, location.lat];
      }
    }

    if (object.type === "flow" && object.origin && object.dest) {
      const origin = object.origin;
      const dest = object.dest;
      if (
        origin.lon != null &&
        origin.lat != null &&
        dest.lon != null &&
        dest.lat != null
      ) {
        return [(origin.lon + dest.lon) / 2, (origin.lat + dest.lat) / 2];
      }
    }

    return null;
  }

  function getTooltipPoint(map, info) {
    if (info && Number.isFinite(info.x) && Number.isFinite(info.y)) {
      return { x: info.x, y: info.y };
    }

    const lngLat = getTooltipLngLat(map, info);
    if (lngLat && map && typeof map.project === "function") {
      return map.project(lngLat);
    }

    return null;
  }

  function mergeClassName(base, extra) {
    return extra ? base + " " + extra : base;
  }

  function showPopupTooltip(map, config, info, html) {
    const Popup = getPopupConstructor();
    if (!Popup) {
      showElementTooltip(map, config, info, html);
      return;
    }

    const tooltip = config.tooltip || {};
    const options = Object.assign(
      {
        closeButton: false,
        closeOnClick: false,
        maxWidth: "400px",
      },
      tooltip.options || {}
    );
    const baseClass = [
      "mapgl-flowmap-tooltip",
      "mapgl-flowmap-tooltip--" + (tooltip.theme || "light"),
    ].join(" ");
    options.className = mergeClassName(baseClass, options.className);

    const lngLat = getTooltipLngLat(map, info);
    if (!lngLat) {
      hideFlowmapTooltip(map, config.id);
      return;
    }

    const store = getTooltipStore(map);
    if (!store[config.id]) {
      store[config.id] = {};
    }
    if (!store[config.id].popup) {
      store[config.id].popup = new Popup(options);
    }

    store[config.id].popup.setLngLat(lngLat).setHTML(html).addTo(map);
  }

  function getElementOffset(options) {
    const offset = options && options.offset;
    if (Array.isArray(offset) && offset.length >= 2) {
      return [Number(offset[0]) || 0, Number(offset[1]) || 0];
    }
    if (typeof offset === "number") {
      return [offset, offset];
    }
    return [10, 10];
  }

  function showElementTooltip(map, config, info, html) {
    const tooltip = config.tooltip || {};
    const point = getTooltipPoint(map, info);
    if (!point || !map || typeof map.getContainer !== "function") {
      return;
    }

    const store = getTooltipStore(map);
    if (!store[config.id]) {
      store[config.id] = {};
    }

    if (!store[config.id].element) {
      const element = document.createElement("div");
      element.className = [
        "flowmap-tooltip",
        "mapgl-flowmap-example-tooltip",
        "mapgl-flowmap-example-tooltip--" + (tooltip.theme || "dark"),
      ].join(" ");
      map.getContainer().appendChild(element);
      store[config.id].element = element;
    }

    const element = store[config.id].element;
    const offset = getElementOffset(tooltip.options || {});
    element.innerHTML = html;
    element.style.left = point.x + offset[0] + "px";
    element.style.top = point.y + offset[1] + "px";
    element.style.display = "block";
  }

  function showFlowmapTooltip(map, config, info) {
    const html = getTooltipHTML(config, info);
    if (!html) {
      hideFlowmapTooltip(map, config.id);
      return;
    }

    hideOtherFlowmapTooltips(map, config.id);

    if (config.tooltip && config.tooltip.style === "flowmap") {
      showElementTooltip(map, config, info, html);
    } else {
      showPopupTooltip(map, config, info, html);
    }
  }

  function ensureOverlay(map, interleaved, elId, settings) {
    if (typeof FlowmapGL === "undefined") {
      console.error("FlowmapGL is not loaded. Cannot add flowmap layers.");
      return null;
    }

    if (interleaved) {
      // Interleaved mode (MapboxOverlay) for layer ordering (beforeId/slot)
      if (
        map._mapglFlowmapOverlay &&
        map._mapglFlowmapOverlayInterleaved === true
      ) {
        return map._mapglFlowmapOverlay;
      }

      // Cleanup standalone Deck if any
      if (map._deckgl) {
        try {
          map._deckgl.finalize();
        } catch (e) {}
        map._deckgl = null;
      }
      if (map._deckContainer) {
        try {
          map._deckContainer.remove();
        } catch (e) {}
        map._deckContainer = null;
      }

      if (map._mapglFlowmapOverlay) {
        try {
          map.removeControl(map._mapglFlowmapOverlay);
        } catch (e) {}
      }

      const overlay = new FlowmapGL.MapboxOverlay({
        interleaved: true,
        layers: [],
      });

      map.addControl(overlay);
      map._mapglFlowmapOverlay = overlay;
      map._mapglFlowmapOverlayInterleaved = true;

      map.once("remove", function () {
        map._mapglFlowmapOverlay = null;
        map._mapglFlowmapLayers = [];
      });

      return overlay;
    } else {
      // Standalone mode: Create standalone Deck container to bypass nested control stacking context.
      // This is crucial because CSS mix-blend-mode will not blend with sibling map canvas elements
      // if nested deep inside Mapbox/MapLibre's .mapboxgl-control-container hierarchy.
      if (
        map._deckgl &&
        map._mapglFlowmapOverlayInterleaved === false
      ) {
        // Update blending styles on the existing canvas during widget updates
        // NOTE: blend must go on the canvas, not the container, to avoid
        // stacking-context isolation that prevents cross-element blending.
        const deckCanvas = map._deckCanvas;
        if (deckCanvas) {
          if (settings && settings.flowBlend) {
            if (typeof settings.flowBlend === "string") {
              deckCanvas.style.mixBlendMode = settings.flowBlend;
            } else {
              deckCanvas.style.mixBlendMode = settings.darkMode ? "screen" : "multiply";
            }
          } else {
            deckCanvas.style.mixBlendMode = "";
          }
        }
        return map._deckgl;
      }

      // Cleanup MapboxOverlay if any
      if (map._mapglFlowmapOverlay) {
        try {
          map.removeControl(map._mapglFlowmapOverlay);
        } catch (e) {}
        map._mapglFlowmapOverlay = null;
      }
      if (map._deckgl) {
        try {
          map._deckgl.finalize();
        } catch (e) {}
        map._deckgl = null;
      }
      if (map._deckContainer) {
        try {
          map._deckContainer.remove();
        } catch (e) {}
        map._deckContainer = null;
      }

      const container = map.getContainer();

      // Create overlay container div directly under map container (sibling of canvas container)
      const deckContainer = document.createElement("div");
      deckContainer.id = "deck-container-" + elId;
      deckContainer.style.cssText = "position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;";
      container.appendChild(deckContainer);

      // Create standalone canvas
      const deckCanvas = document.createElement("canvas");
      deckCanvas.id = "deck-canvas-" + elId;
      deckCanvas.style.cssText = "width:100%;height:100%;";
      deckContainer.appendChild(deckCanvas);

      map._deckContainer = deckContainer;
      map._deckCanvas = deckCanvas;

      const center = map.getCenter();
      const initialViewState = {
        longitude: center.lng,
        latitude: center.lat,
        zoom: map.getZoom(),
        pitch: map.getPitch(),
        bearing: map.getBearing()
      };

      const deckInstance = new FlowmapGL.Deck({
        canvas: deckCanvas,
        controller: false, // map controls the camera
        _useDevicePixels: true,
        initialViewState: initialViewState,
        layers: [],
        getTooltip: null,
        pickingRadius: 5
      });

      // Synchronize standalone Deck viewport state with map moves
      const syncViewState = () => {
        const center = map.getCenter();
        deckInstance.setProps({
          viewState: {
            longitude: center.lng,
            latitude: center.lat,
            zoom: map.getZoom(),
            pitch: map.getPitch(),
            bearing: map.getBearing()
          }
        });
      };

      map.on("move", syncViewState);
      map.on("moveend", syncViewState);
      syncViewState();

      // Forward mouse events from Mapbox to standalone Deck for picking / hover tooltips
      const onMapMouseMove = (e) => {
        if (!deckInstance || !map._mapglFlowmapLayers || map._mapglFlowmapLayers.length === 0) return;
        const { x, y } = e.point;
        try {
          const info = deckInstance.pickObject({ x, y, radius: 2 });
          map.getCanvas().style.cursor = info ? "pointer" : '';

          if (info && info.layer && (info.layer.onHover || (info.layer.props && info.layer.props.onHover))) {
            info.x = x;
            info.y = y;
            info.lngLat = e.lngLat;
            if (e.lngLat) {
              info.coordinate = [e.lngLat.lng, e.lngLat.lat];
            }
            const event = { srcEvent: e.originalEvent || e };
            if (typeof info.layer.onHover === "function") {
              info.layer.onHover(info, event);
            } else {
              info.layer.props.onHover(info, event);
            }
          } else {
            hideAllFlowmapTooltips(map);
          }
        } catch (err) {
          // Ignore deck.gl assertion failures during rapid scrubbing
          // console.warn('Deck.gl picking error:', err);
        }
      };

      if (!map._hasDeckMoveListener) {
        map.on("mousemove", onMapMouseMove);
        map.on("mouseout", function () {
          hideAllFlowmapTooltips(map);
        });
        map._hasDeckMoveListener = true;
      }

      map._deckgl = deckInstance;
      map._mapglFlowmapOverlayInterleaved = false;

      // Apply CSS Blending directly to the canvas element.
      // IMPORTANT: The container must NOT have a z-index (other than auto)
      // because that creates a stacking context which isolates the canvas
      // and prevents mix-blend-mode from blending with the underlying map.
      if (settings && settings.flowBlend) {
        if (typeof settings.flowBlend === "string") {
          deckCanvas.style.mixBlendMode = settings.flowBlend;
        } else {
          deckCanvas.style.mixBlendMode = settings.darkMode ? "screen" : "multiply";
        }
      } else {
        deckCanvas.style.mixBlendMode = "";
      }

      map.once("remove", function () {
        if (map._deckgl) {
          try {
            map._deckgl.finalize();
          } catch (e) {}
          map._deckgl = null;
        }
        if (map._deckContainer) {
          try {
            map._deckContainer.remove();
          } catch (e) {}
          map._deckContainer = null;
        }
        map._mapglFlowmapLayers = [];
        hideAllFlowmapTooltips(map);
      });

      return deckInstance;
    }
  }

  function makeLayer(config, HTMLWidgets, map) {
    const locations = dataframeToRows(config.data.locations, HTMLWidgets);
    const flows = dataframeToRows(config.data.flows, HTMLWidgets);
    const settings = config.settings || {};

    const layerProps = {
      id: config.id,
      data: {
        locations: locations,
        flows: flows,
      },
      beforeId: config.beforeId || undefined,
      slot: config.slot || undefined,
      pickable: true,
      visible: config.visibility !== "none",
      opacity: settings.opacity == null ? 1 : settings.opacity,
      colorScheme: settings.colorScheme,
      darkMode: settings.darkMode,
      fadeAmount: settings.fadeAmount,
      highlightColor: settings.highlightColor,
      locationsEnabled: settings.locationsEnabled,
      locationTotalsEnabled: settings.locationTotalsEnabled,
      locationLabelsEnabled: settings.locationLabelsEnabled,
      flowLinesRenderingMode: settings.flowLinesRenderingMode,
      flowLineThicknessScale: settings.flowLineThicknessScale == null ? 1 : settings.flowLineThicknessScale,
      flowLineCurviness: settings.flowLineCurviness == null ? 1 : settings.flowLineCurviness,
      clusteringEnabled: settings.clusteringEnabled,
      clusteringAuto: settings.clusteringAuto,
      clusteringLevel: settings.clusteringLevel === null ? undefined : settings.clusteringLevel,
      fadeEnabled: settings.fadeEnabled,
      fadeOpacityEnabled: settings.fadeOpacityEnabled,
      adaptiveScalesEnabled: settings.adaptiveScalesEnabled,
      temporalScaleDomain: settings.temporalScaleDomain || "selected",
      maxTopFlowsDisplayNum: settings.maxTopFlowsDisplayNum,
      flowEndpointsInViewportMode: settings.flowEndpointsInViewportMode,
      getLocationId: function (location) {
        return location.id;
      },
      getLocationLat: function (location) {
        return location.lat;
      },
      getLocationLon: function (location) {
        return location.lon;
      },
      getLocationName: function (location) {
        return location.name || location.id;
      },
      getFlowOriginId: function (flow) {
        return flow.origin;
      },
      getFlowDestId: function (flow) {
        return flow.dest;
      },
      getFlowMagnitude: function (flow) {
        return flow.count;
      },
    };

    if (settings.timeColumn) {
      layerProps.getFlowTime = function (flow) {
        return flow.time ? new Date(flow.time) : undefined;
      };
    }

    if (settings.selectedTimeRange) {
      layerProps.filter = {
        ...layerProps.filter,
        selectedTimeRange: [
          new Date(settings.selectedTimeRange[0]),
          new Date(settings.selectedTimeRange[1])
        ]
      };
    }

    if (settings.selectedTimeRanges) {
      layerProps.filter = {
        ...layerProps.filter,
        selectedTimeRange: null,
        selectedTimeRanges: normalizeTimeRanges(settings.selectedTimeRanges)
      };
    }

    if (settings.selectedLocations) {
      layerProps.filter = {
        ...layerProps.filter,
        selectedLocations: settings.selectedLocations
      };
    }

    if (settings.locationFilterMode) {
      layerProps.filter = {
        ...layerProps.filter,
        locationFilterMode: settings.locationFilterMode
      };
    }

    if (config.tooltip && config.tooltip.enabled) {
      layerProps.onHover = function (info) {
        showFlowmapTooltip(map, config, info);
      };
    }

    return makeFlowmapLayer(layerProps);
  }

  function makeFlowmapLayer(layerProps) {
    const layer = new FlowmapGL.FlowmapLayer(layerProps);
    layer._mapglOnHover = layerProps.onHover;
    layer._mapglOnClick = layerProps.onClick;
    return layer;
  }

  function cloneFlowmapLayer(layer, props) {
    const cloneProps = Object.assign({}, props);

    if (Object.prototype.hasOwnProperty.call(layer, "_mapglOnHover")) {
      cloneProps.onHover = layer._mapglOnHover;
    }
    if (Object.prototype.hasOwnProperty.call(layer, "_mapglOnClick")) {
      cloneProps.onClick = layer._mapglOnClick;
    }

    const cloned = layer.clone(cloneProps);
    cloned._mapglOnHover = layer._mapglOnHover;
    cloned._mapglOnClick = layer._mapglOnClick;
    return cloned;
  }

  function init(map, x, el, HTMLWidgets) {
    if (!x.flowmaps || x.flowmaps.length === 0) {
      return;
    }

    if (typeof FlowmapGL === "undefined" || !FlowmapGL.FlowmapLayer) {
      console.error("FlowmapGL is not loaded. Cannot add flowmap layers.");
      return;
    }

    installFlowmapAttributionRefresh(map);

    const interleaved = x.flowmaps.some(function (flowmap) {
      return Boolean(flowmap.beforeId || flowmap.slot);
    });

    var firstFlowmap = x.flowmaps[0];
    var settings = firstFlowmap.settings || {};

    const overlay = ensureOverlay(map, interleaved, el.id, settings);
    if (!overlay) {
      return;
    }

    const flowmapLayers = x.flowmaps.map(function (config) {
      return makeLayer(config, HTMLWidgets, map);
    });

    map._mapglFlowmapLayers = flowmapLayers;
    overlay.setProps({ layers: flowmapLayers });
  }

  function hasLayer(map, id) {
    return Boolean(
      map &&
        map._mapglFlowmapLayers &&
        map._mapglFlowmapLayers.some(function (layer) {
          return layer.id === id;
        }),
    );
  }

  function getVisibility(map, id) {
    if (!hasLayer(map, id)) {
      return undefined;
    }

    const layer = map._mapglFlowmapLayers.find(function (candidate) {
      return candidate.id === id;
    });

    return layer && layer.props.visible === false ? "none" : "visible";
  }

  function setVisibility(map, id, visibility) {
    var overlay = map._mapglFlowmapOverlay || map._deckgl;
    if (!hasLayer(map, id) || !overlay) {
      return false;
    }

    const visible = visibility !== "none";
    map._mapglFlowmapLayers = map._mapglFlowmapLayers.map(function (layer) {
      if (layer.id !== id) {
        return layer;
      }
      if (!visible) {
        hideFlowmapTooltip(map, id);
      }
      return cloneFlowmapLayer(layer, { visible: visible });
    });
    overlay.setProps({ layers: map._mapglFlowmapLayers });
    return true;
  }

  function setFilter(map, id, filter) {
    var overlay = map._mapglFlowmapOverlay || map._deckgl;
    if (!hasLayer(map, id) || !overlay) {
      return false;
    }

    const newFilter = { ...filter };

    if (newFilter.selectedTimeRange) {
      newFilter.selectedTimeRange = [
        new Date(newFilter.selectedTimeRange[0]),
        new Date(newFilter.selectedTimeRange[1])
      ];
    }

    if (newFilter.selectedTimeRanges) {
      newFilter.selectedTimeRanges = normalizeTimeRanges(newFilter.selectedTimeRanges);
    }

    map._mapglFlowmapLayers = map._mapglFlowmapLayers.map(function (layer) {
      if (layer.id !== id) {
        return layer;
      }
      return cloneFlowmapLayer(layer, {
        filter: Object.assign({}, layer.props.filter, newFilter)
      });
    });
    overlay.setProps({ layers: map._mapglFlowmapLayers });
    return true;
  }

  function normalizeTimeRanges(ranges) {
    if (!Array.isArray(ranges)) {
      return null;
    }

    return ranges
      .filter(function (range) {
        return Array.isArray(range) && range.length === 2;
      })
      .map(function (range) {
        return [new Date(range[0]), new Date(range[1])];
      });
  }

  function setSettings(map, id, settings) {
    var overlay = map._mapglFlowmapOverlay || map._deckgl;
    if (!hasLayer(map, id) || !overlay) {
      return false;
    }

    map._mapglFlowmapLayers = map._mapglFlowmapLayers.map(function (layer) {
      if (layer.id !== id) {
        return layer;
      }
      return cloneFlowmapLayer(layer, settings);
    });
    overlay.setProps({ layers: map._mapglFlowmapLayers });
    return true;
  }

  return {
    init: init,
    hasLayer: hasLayer,
    getVisibility: getVisibility,
    setVisibility: setVisibility,
    setFilter: setFilter,
    setSettings: setSettings,
  };
})();
