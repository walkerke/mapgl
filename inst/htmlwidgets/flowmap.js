window.MapGLFlowmapPlugin = (function () {
  const FLOWMAP_ATTRIBUTION_SELECTOR =
    ".mapboxgl-ctrl-attrib-inner, .maplibregl-ctrl-attrib-inner";
  const FLOWMAP_ATTRIBUTION_LINK_SELECTOR =
    'a[data-mapgl-flowmap-attribution="true"]';
  const FLOWMAP_ATTRIBUTION_SEPARATOR_SELECTOR =
    '[data-mapgl-flowmap-attribution-separator="true"]';

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

          // Hide any existing tooltips
          var oldTooltips = document.querySelectorAll(".flowmap-tooltip");
          for (var i = 0; i < oldTooltips.length; i++) {
            oldTooltips[i].style.display = "none";
          }

          if (info && info.layer && info.layer.props.onHover) {
            info.layer.props.onHover(info);
          }
        } catch (err) {
          // Ignore deck.gl assertion failures during rapid scrubbing
          // console.warn('Deck.gl picking error:', err);
        }
      };

      if (!map._hasDeckMoveListener) {
        map.on("mousemove", onMapMouseMove);
        map.on("mouseout", function () {
          var oldTooltips = document.querySelectorAll(".flowmap-tooltip");
          for (var i = 0; i < oldTooltips.length; i++) {
            oldTooltips[i].style.display = "none";
          }
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
      });

      return deckInstance;
    }
  }

  function makeLayer(config, HTMLWidgets) {
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

    return new FlowmapGL.FlowmapLayer(layerProps);
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
      return makeLayer(config, HTMLWidgets);
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
      return layer.clone({ visible: visible });
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

    map._mapglFlowmapLayers = map._mapglFlowmapLayers.map(function (layer) {
      if (layer.id !== id) {
        return layer;
      }
      return layer.clone({ filter: Object.assign({}, layer.props.filter, newFilter) });
    });
    overlay.setProps({ layers: map._mapglFlowmapLayers });
    return true;
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
      return layer.clone(settings);
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
