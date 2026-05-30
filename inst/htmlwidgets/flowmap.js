window.MapGLFlowmapPlugin = (function () {
  function dataframeToRows(data, HTMLWidgets) {
    if (!data || Array.isArray(data) || typeof data !== "object") {
      return data;
    }

    if (HTMLWidgets && typeof HTMLWidgets.dataframeToD3 === "function") {
      return HTMLWidgets.dataframeToD3(data);
    }

    return data;
  }

  function ensureOverlay(map, interleaved) {
    if (typeof FlowmapGL === "undefined" || !FlowmapGL.MapboxOverlay) {
      console.error("FlowmapGL is not loaded. Cannot add flowmap layers.");
      return null;
    }

    if (
      map._mapglFlowmapOverlay &&
      map._mapglFlowmapOverlayInterleaved === interleaved
    ) {
      return map._mapglFlowmapOverlay;
    }

    if (map._mapglFlowmapOverlay) {
      try {
        map.removeControl(map._mapglFlowmapOverlay);
      } catch (e) {
        // The map may already be cleaning up.
      }
    }

    const overlay = new FlowmapGL.MapboxOverlay({
      interleaved: interleaved,
      layers: [],
    });

    map.addControl(overlay);
    map._mapglFlowmapOverlay = overlay;
    map._mapglFlowmapOverlayInterleaved = interleaved;

    map.once("remove", function () {
      map._mapglFlowmapOverlay = null;
      map._mapglFlowmapLayers = [];
    });

    return overlay;
  }

  function makeLayer(config, HTMLWidgets) {
    const locations = dataframeToRows(config.data.locations, HTMLWidgets);
    const flows = dataframeToRows(config.data.flows, HTMLWidgets);
    const settings = config.settings || {};

    return new FlowmapGL.FlowmapLayer({
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
    });
  }

  function init(map, x, el, HTMLWidgets) {
    if (!x.flowmaps || x.flowmaps.length === 0) {
      return;
    }

    if (typeof FlowmapGL === "undefined" || !FlowmapGL.FlowmapLayer) {
      console.error("FlowmapGL is not loaded. Cannot add flowmap layers.");
      return;
    }

    const interleaved = x.flowmaps.some(function (flowmap) {
      return Boolean(flowmap.beforeId || flowmap.slot);
    });
    const overlay = ensureOverlay(map, interleaved);
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
    if (!hasLayer(map, id) || !map._mapglFlowmapOverlay) {
      return false;
    }

    const visible = visibility !== "none";
    map._mapglFlowmapLayers = map._mapglFlowmapLayers.map(function (layer) {
      if (layer.id !== id) {
        return layer;
      }
      return layer.clone({ visible: visible });
    });
    map._mapglFlowmapOverlay.setProps({ layers: map._mapglFlowmapLayers });
    return true;
  }

  return {
    init: init,
    hasLayer: hasLayer,
    getVisibility: getVisibility,
    setVisibility: setVisibility,
  };
})();
