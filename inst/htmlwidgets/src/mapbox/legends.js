/**
 * Legends and layer controls for Mapbox GL JS
 * Handles legend display and interactive layer controls
 */

function setupLegends(map, x, el) {
  // Handle legend removal/addition
  if (!x.add) {
    const existingLegends = el.querySelectorAll(".mapboxgl-legend");
    existingLegends.forEach((legend) => legend.remove());
  }

  if (x.legend_html && x.legend_css) {
    const legendCss = document.createElement("style");
    legendCss.innerHTML = x.legend_css;
    document.head.appendChild(legendCss);

    const legend = document.createElement("div");
    legend.innerHTML = x.legend_html;
    legend.classList.add("mapboxgl-legend");
    el.appendChild(legend);
  }
}

function setupLayersControl(map, x, el) {
  // Add the layers control if provided
  if (x.layers_control) {
    const layersControl = document.createElement("div");
    layersControl.id = x.layers_control.control_id;
    layersControl.className = x.layers_control.collapsible
      ? "layers-control collapsible"
      : "layers-control";
    layersControl.style.position = "absolute";

    // Set the position correctly - fix position bug by using correct CSS positioning
    const position = x.layers_control.position || "top-left";
    if (position === "top-left") {
      layersControl.style.top =
        (x.layers_control.margin_top || 10) + "px";
      layersControl.style.left =
        (x.layers_control.margin_left || 10) + "px";
    } else if (position === "top-right") {
      layersControl.style.top =
        (x.layers_control.margin_top || 10) + "px";
      layersControl.style.right =
        (x.layers_control.margin_right || 10) + "px";
    } else if (position === "bottom-left") {
      layersControl.style.bottom =
        (x.layers_control.margin_bottom || 30) + "px";
      layersControl.style.left =
        (x.layers_control.margin_left || 10) + "px";
    } else if (position === "bottom-right") {
      layersControl.style.bottom =
        (x.layers_control.margin_bottom || 40) + "px";
      layersControl.style.right =
        (x.layers_control.margin_right || 10) + "px";
    }

    // Apply custom colors if provided
    if (x.layers_control.custom_colors) {
      const colors = x.layers_control.custom_colors;

      // Create a style element for custom colors
      const styleEl = document.createElement("style");
      let css = "";

      if (colors.background) {
        css += `#${x.layers_control.control_id} { background-color: ${colors.background}; }\n`;
      }

      if (colors.text) {
        css += `#${x.layers_control.control_id} a { color: ${colors.text}; }\n`;
      }

      if (colors.active) {
        css += `#${x.layers_control.control_id} a.active { background-color: ${colors.active}; }\n`;
        css += `#${x.layers_control.control_id} .toggle-button { background-color: ${colors.active}; }\n`;
      }

      if (colors.activeText) {
        css += `#${x.layers_control.control_id} a.active { color: ${colors.activeText}; }\n`;
        css += `#${x.layers_control.control_id} .toggle-button { color: ${colors.activeText}; }\n`;
      }

      if (colors.hover) {
        css += `#${x.layers_control.control_id} a:hover { background-color: ${colors.hover}; }\n`;
        css += `#${x.layers_control.control_id} .toggle-button:hover { background-color: ${colors.hover}; }\n`;
      }

      styleEl.textContent = css;
      document.head.appendChild(styleEl);
    }

    el.appendChild(layersControl);

    const layersList = document.createElement("div");
    layersList.className = "layers-list";
    layersControl.appendChild(layersList);

    // Fetch layers to be included in the control
    let layers =
      x.layers_control.layers ||
      map.getStyle().layers.map((layer) => layer.id);

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

    // Handle collapsible behavior
    if (x.layers_control.collapsible) {
      const toggleButton = document.createElement("div");
      toggleButton.className = "toggle-button";

      // Use stacked layers icon instead of text if requested
      if (x.layers_control.use_icon) {
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
  }
}