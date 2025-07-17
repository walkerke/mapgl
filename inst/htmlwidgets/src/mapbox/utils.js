/**
 * Utility functions for Mapbox GL JS implementation
 * These are specific to the Mapbox implementation
 */

function evaluateExpression(expression, properties) {
  if (!Array.isArray(expression)) {
    return expression;
  }

  const operator = expression[0];

  switch (operator) {
    case "get":
      return properties[expression[1]];
    case "concat":
      return expression
        .slice(1)
        .map((item) => evaluateExpression(item, properties))
        .join("");
    case "to-string":
      return String(evaluateExpression(expression[1], properties));
    case "to-number":
      return Number(evaluateExpression(expression[1], properties));
    case "number-format":
      const value = evaluateExpression(expression[1], properties);
      const options = expression[2] || {};

      // Handle locale option
      const locale = options.locale || "en-US";

      // Build Intl.NumberFormat options
      const formatOptions = {};

      // Style options
      if (options.style) formatOptions.style = options.style; // 'decimal', 'currency', 'percent', 'unit'
      if (options.currency) formatOptions.currency = options.currency;
      if (options.unit) formatOptions.unit = options.unit;

      // Digit options
      if (options.hasOwnProperty("min-fraction-digits")) {
        formatOptions.minimumFractionDigits = options["min-fraction-digits"];
      }
      if (options.hasOwnProperty("max-fraction-digits")) {
        formatOptions.maximumFractionDigits = options["max-fraction-digits"];
      }
      if (options.hasOwnProperty("min-integer-digits")) {
        formatOptions.minimumIntegerDigits = options["min-integer-digits"];
      }

      // Notation options
      if (options.notation) formatOptions.notation = options.notation; // 'standard', 'scientific', 'engineering', 'compact'
      if (options.compactDisplay)
        formatOptions.compactDisplay = options.compactDisplay; // 'short', 'long'

      // Grouping
      if (options.hasOwnProperty("useGrouping")) {
        formatOptions.useGrouping = options.useGrouping;
      }

      return new Intl.NumberFormat(locale, formatOptions).format(value);
    default:
      // For literals and other simple values
      return expression;
  }
}

function onMouseMoveTooltip(e, map, tooltipPopup, tooltipProperty) {
  map.getCanvas().style.cursor = "pointer";
  if (e.features.length > 0) {
    // Clear any existing active tooltip first to prevent stacking
    if (window._activeTooltip && window._activeTooltip !== tooltipPopup) {
      window._activeTooltip.remove();
    }

    let description;

    // Check if tooltipProperty is an expression (array) or a simple property name (string)
    if (Array.isArray(tooltipProperty)) {
      // It's an expression, evaluate it
      description = evaluateExpression(
        tooltipProperty,
        e.features[0].properties,
      );
    } else {
      // It's a property name, get the value
      description = e.features[0].properties[tooltipProperty];
    }

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

function onClickPopup(e, map, popupProperty, layerId) {
  let description;

  // Check if popupProperty is an expression (array) or a simple property name (string)
  if (Array.isArray(popupProperty)) {
    // It's an expression, evaluate it
    description = evaluateExpression(popupProperty, e.features[0].properties);
  } else {
    // It's a property name, get the value
    description = e.features[0].properties[popupProperty];
  }

  // Remove any existing popup for this layer
  if (window._mapboxPopups && window._mapboxPopups[layerId]) {
    window._mapboxPopups[layerId].remove();
  }

  // Create and show the popup
  const popup = new mapboxgl.Popup()
    .setLngLat(e.lngLat)
    .setHTML(description)
    .addTo(map);

  // Store reference to this popup
  if (!window._mapboxPopups) {
    window._mapboxPopups = {};
  }
  window._mapboxPopups[layerId] = popup;

  // Remove reference when popup is closed
  popup.on("close", function () {
    if (window._mapboxPopups[layerId] === popup) {
      delete window._mapboxPopups[layerId];
    }
  });
}

// Helper function to generate draw styles based on parameters
function generateDrawStyles(styling) {
  if (!styling) return null;

  return [
    // Point styles
    {
      id: "gl-draw-point-active",
      type: "circle",
      filter: [
        "all",
        ["==", "$type", "Point"],
        ["==", "meta", "feature"],
        ["==", "active", "true"],
      ],
      paint: {
        "circle-radius": styling.vertex_radius + 2,
        "circle-color": styling.active_color,
      },
    },
    {
      id: "gl-draw-point",
      type: "circle",
      filter: [
        "all",
        ["==", "$type", "Point"],
        ["==", "meta", "feature"],
        ["==", "active", "false"],
      ],
      paint: {
        "circle-radius": styling.vertex_radius,
        "circle-color": styling.point_color,
      },
    },
    // Line styles
    {
      id: "gl-draw-line",
      type: "line",
      filter: ["all", ["==", "$type", "LineString"]],
      layout: {
        "line-cap": "round",
        "line-join": "round",
      },
      paint: {
        "line-color": [
          "case",
          ["==", ["get", "active"], "true"],
          styling.active_color,
          styling.line_color,
        ],
        "line-width": styling.line_width,
      },
    },
    // Polygon fill
    {
      id: "gl-draw-polygon-fill",
      type: "fill",
      filter: ["all", ["==", "$type", "Polygon"]],
      paint: {
        "fill-color": [
          "case",
          ["==", ["get", "active"], "true"],
          styling.active_color,
          styling.fill_color,
        ],
        "fill-outline-color": [
          "case",
          ["==", ["get", "active"], "true"],
          styling.active_color,
          styling.fill_color,
        ],
        "fill-opacity": styling.fill_opacity,
      },
    },
    // Polygon outline
    {
      id: "gl-draw-polygon-stroke",
      type: "line",
      filter: ["all", ["==", "$type", "Polygon"]],
      layout: {
        "line-cap": "round",
        "line-join": "round",
      },
      paint: {
        "line-color": [
          "case",
          ["==", ["get", "active"], "true"],
          styling.active_color,
          styling.line_color,
        ],
        "line-width": styling.line_width,
      },
    },
    // Midpoints
    {
      id: "gl-draw-polygon-midpoint",
      type: "circle",
      filter: ["all", ["==", "$type", "Point"], ["==", "meta", "midpoint"]],
      paint: {
        "circle-radius": 3,
        "circle-color": styling.active_color,
      },
    },
    // Vertex point halos
    {
      id: "gl-draw-vertex-halo-active",
      type: "circle",
      filter: ["all", ["==", "meta", "vertex"], ["==", "$type", "Point"]],
      paint: {
        "circle-radius": [
          "case",
          ["==", ["get", "active"], "true"],
          styling.vertex_radius + 4,
          styling.vertex_radius + 2,
        ],
        "circle-color": "#FFF",
      },
    },
    // Vertex points
    {
      id: "gl-draw-vertex-active",
      type: "circle",
      filter: ["all", ["==", "meta", "vertex"], ["==", "$type", "Point"]],
      paint: {
        "circle-radius": [
          "case",
          ["==", ["get", "active"], "true"],
          styling.vertex_radius + 2,
          styling.vertex_radius,
        ],
        "circle-color": styling.active_color,
      },
    },
  ];
}