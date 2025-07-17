/**
 * Controls management for Mapbox GL JS
 * Handles all map controls: scale, globe minimap, custom controls, geocoder, 
 * draw, fullscreen, geolocate, navigation, reset, layers control
 */

function setupControls(map, x, el) {
  // Add scale control if enabled
  if (x.scale_control) {
    const scaleControl = new mapboxgl.ScaleControl({
      maxWidth: x.scale_control.maxWidth,
      unit: x.scale_control.unit,
    });
    map.addControl(scaleControl, x.scale_control.position);
    map.controls.push(scaleControl);
  }

  // Add globe minimap if enabled
  if (x.globe_minimap && x.globe_minimap.enabled) {
    const globeMinimapOptions = {
      globeSize: x.globe_minimap.globe_size,
      landColor: x.globe_minimap.land_color,
      waterColor: x.globe_minimap.water_color,
      markerColor: x.globe_minimap.marker_color,
      markerSize: x.globe_minimap.marker_size,
    };
    const globeMinimap = new GlobeMinimap(globeMinimapOptions);
    map.addControl(globeMinimap, x.globe_minimap.position);
    map.controls.push(globeMinimap);
  }

  // Add custom controls if any are defined
  if (x.custom_controls) {
    Object.keys(x.custom_controls).forEach(function (key) {
      const controlOptions = x.custom_controls[key];
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

      map.addControl(
        customControl,
        controlOptions.position || "top-right",
      );
      map.controls.push(customControl);
    });
  }

  // Add geocoder control if enabled
  if (x.geocoder_control) {
    const geocoderOptions = {
      accessToken: mapboxgl.accessToken,
      mapboxgl: mapboxgl,
      ...x.geocoder_control,
    };

    // Set default values if not provided
    if (!geocoderOptions.placeholder)
      geocoderOptions.placeholder = "Search";
    if (typeof geocoderOptions.collapsed === "undefined")
      geocoderOptions.collapsed = false;

    const geocoder = new MapboxGeocoder(geocoderOptions);

    map.addControl(
      geocoder,
      x.geocoder_control.position || "top-right",
    );
    map.controls.push(geocoder);

    // Handle geocoder results in Shiny mode
    if (HTMLWidgets.shinyMode) {
      geocoder.on("result", function (e) {
        Shiny.setInputValue(el.id + "_geocoder", {
          result: e.result,
          time: new Date(),
        });
      });
    }
  }

  // Add fullscreen control if enabled
  if (x.fullscreen_control && x.fullscreen_control.enabled) {
    const position = x.fullscreen_control.position || "top-right";
    const fullscreen = new mapboxgl.FullscreenControl();
    map.addControl(fullscreen, position);
    map.controls.push(fullscreen);
  }

  // Add geolocate control if enabled
  if (x.geolocate_control) {
    const geolocate = new mapboxgl.GeolocateControl({
      positionOptions: x.geolocate_control.positionOptions,
      trackUserLocation: x.geolocate_control.trackUserLocation,
      showAccuracyCircle: x.geolocate_control.showAccuracyCircle,
      showUserLocation: x.geolocate_control.showUserLocation,
      showUserHeading: x.geolocate_control.showUserHeading,
      fitBoundsOptions: x.geolocate_control.fitBoundsOptions,
    });
    map.addControl(geolocate, x.geolocate_control.position);
    map.controls.push(geolocate);

    if (HTMLWidgets.shinyMode) {
      geolocate.on("geolocate", function (event) {
        console.log("Geolocate event triggered");
        console.log("Element ID:", el.id);
        console.log("Event coords:", event.coords);

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
  }

  // Add navigation control if enabled
  if (x.navigation_control) {
    const nav = new mapboxgl.NavigationControl({
      showCompass: x.navigation_control.show_compass,
      showZoom: x.navigation_control.show_zoom,
      visualizePitch: x.navigation_control.visualize_pitch,
    });
    map.addControl(nav, x.navigation_control.position);
    map.controls.push(nav);

    if (x.navigation_control.orientation === "horizontal") {
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
  }

  // Add draw control if enabled
  if (x.draw_control && x.draw_control.enabled) {
    let drawOptions = x.draw_control.options || {};

    // Generate styles if styling parameters provided
    if (x.draw_control.styling) {
      const generatedStyles = generateDrawStyles(
        x.draw_control.styling,
      );
      if (generatedStyles) {
        drawOptions.styles = generatedStyles;
      }
    }

    if (x.draw_control.freehand) {
      drawOptions = Object.assign({}, drawOptions, {
        modes: Object.assign({}, MapboxDraw.modes, {
          draw_polygon: Object.assign(
            {},
            MapboxDraw.modes.draw_freehand,
            {
              // Store the simplify_freehand option on the map object
              onSetup: function (opts) {
                const state =
                  MapboxDraw.modes.draw_freehand.onSetup.call(
                    this,
                    opts,
                  );
                this.map.simplify_freehand =
                  x.draw_control.simplify_freehand;
                return state;
              },
            },
          ),
        }),
        // defaultMode: 'draw_polygon' # Don't set the default yet
      });
    }

    const draw = new MapboxDraw(drawOptions);
    map.addControl(draw, x.draw_control.position);
    map.controls.push(draw);

    // Store draw control reference for access from widget
    el.drawControl = draw;

    // Add event listeners
    map.on("draw.create", updateDrawnFeatures);
    map.on("draw.delete", updateDrawnFeatures);
    map.on("draw.update", updateDrawnFeatures);

    // Helper function to update drawn features
    function updateDrawnFeatures() {
      if (draw) {
        var drawnFeatures = draw.getAll();
        if (HTMLWidgets.shinyMode) {
          Shiny.setInputValue(
            el.id + "_drawn_features",
            JSON.stringify(drawnFeatures),
          );
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

    // Helper function to add features from a source to draw
    function addSourceFeaturesToDraw(draw, sourceId, map) {
      const source = map.getSource(sourceId);
      if (source && source._data) {
        draw.add(source._data);
      } else {
        console.warn("Source not found or has no data:", sourceId);
      }
    }

    // Add initial features if provided
    if (x.draw_control.source) {
      addSourceFeaturesToDraw(draw, x.draw_control.source, map);
    }

    // Process any queued features
    if (x.draw_features_queue) {
      x.draw_features_queue.forEach(function (data) {
        if (data.clear_existing) {
          draw.deleteAll();
        }
        addSourceFeaturesToDraw(draw, data.source, map);
      });
    }

    // Apply orientation styling
    if (x.draw_control.orientation === "horizontal") {
      const drawBar = map
        .getContainer()
        .querySelector(".mapboxgl-ctrl-group");
      if (drawBar) {
        drawBar.style.display = "flex";
        drawBar.style.flexDirection = "row";
      }
    }

    // Add download button if requested
    if (x.draw_control.download_button) {
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
            const data = draw.getAll();

            if (data.features.length === 0) {
              alert(
                "No features to download. Please draw something first!",
              );
              return;
            }

            // Convert to string with nice formatting
            const dataStr = JSON.stringify(data, null, 2);

            // Create blob and download
            const blob = new Blob([dataStr], {
              type: "application/json",
            });
            const url = URL.createObjectURL(blob);

            const a = document.createElement("a");
            a.href = url;
            a.download = `${x.draw_control.download_filename}.geojson`;
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
  }

  // Add reset control if enabled
  if (x.reset_control) {
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

    // Initialize with empty object, will be populated after map loads
    let initialView = {};

    // Capture the initial view after the map has loaded and all view operations are complete
    map.once("load", function () {
      initialView = {
        center: map.getCenter(),
        zoom: map.getZoom(),
        pitch: map.getPitch(),
        bearing: map.getBearing(),
        animate: x.reset_control.animate,
      };

      if (x.reset_control.duration) {
        initialView.duration = x.reset_control.duration;
      }
    });

    resetControl.onclick = function () {
      // Only reset if we have captured the initial view
      if (initialView.center) {
        map.easeTo(initialView);
      }
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
      x.reset_control.position,
    );

    map.controls.push({
      onAdd: function () {
        return resetContainer;
      },
      onRemove: function () {
        resetContainer.parentNode.removeChild(resetContainer);
      },
    });
  }
}