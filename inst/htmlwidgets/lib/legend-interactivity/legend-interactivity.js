/**
 * Legend Interactivity Module for mapgl
 * Shared functionality for both Mapbox GL and MapLibre GL
 *
 * Provides interactive legend capabilities:
 * - Categorical legends: Click to toggle category visibility
 * - Continuous legends: Dual-handle range slider for filtering
 */

/**
 * Main initialization function - called from widget code
 * @param {Object} map - The map instance (mapboxgl or maplibre)
 * @param {string} mapId - The container ID for the map
 * @param {Object} config - Configuration from R side
 */
function initializeLegendInteractivity(map, mapId, config) {
    var legendElement = document.getElementById(config.legendId);
    if (!legendElement) {
        console.warn("Legend element not found:", config.legendId);
        return;
    }

    // Ensure layer state tracking exists
    if (!window._mapglLayerState) {
        window._mapglLayerState = {};
    }
    if (!window._mapglLayerState[mapId]) {
        window._mapglLayerState[mapId] = {
            filters: {},
            paintProperties: {},
            layoutProperties: {},
            tooltips: {},
            popups: {},
            legends: {},
            interactiveFilters: {}
        };
    }

    var layerState = window._mapglLayerState[mapId];

    // Initialize interactive filter state for this layer
    if (config.layerId && !layerState.interactiveFilters[config.layerId]) {
        var originalFilter = null;
        try {
            originalFilter = map.getFilter(config.layerId);
        } catch (e) {
            // Layer may not exist yet
        }
        layerState.interactiveFilters[config.layerId] = {
            originalFilter: originalFilter,
            legendFilters: {}
        };
    }

    // Determine filter column - use provided or auto-detect
    var filterColumn = config.filterColumn;
    if (!filterColumn && config.layerId) {
        filterColumn = detectFilterColumn(map, config.layerId);
    }

    if (!filterColumn) {
        console.warn(
            "Could not determine filter column for interactive legend. " +
                "Please provide filter_column parameter."
        );
        return;
    }

    // Store config for later reference
    legendElement._interactivityConfig = {
        legendId: config.legendId,
        layerId: config.layerId,
        type: config.type,
        values: config.values,
        colors: config.colors,
        filterColumn: filterColumn,
        mapId: mapId
    };

    if (config.type === "categorical") {
        initCategoricalLegend(map, mapId, legendElement, filterColumn, config);
    } else if (config.type === "continuous") {
        initContinuousLegend(map, mapId, legendElement, filterColumn, config);
    }
}

/**
 * Detect filter column from layer's paint expression
 * @param {Object} map - The map instance
 * @param {string} layerId - The layer ID
 * @returns {string|null} The detected column name or null
 */
function detectFilterColumn(map, layerId) {
    var layer = null;
    try {
        layer = map.getLayer(layerId);
    } catch (e) {
        return null;
    }
    if (!layer) return null;

    // Check common paint properties for expressions
    var paintProps = [
        "fill-color",
        "circle-color",
        "line-color",
        "fill-opacity",
        "circle-radius",
        "line-width",
        "fill-extrusion-color"
    ];

    for (var i = 0; i < paintProps.length; i++) {
        var prop = paintProps[i];
        try {
            var paintValue = map.getPaintProperty(layerId, prop);
            if (paintValue && Array.isArray(paintValue)) {
                var column = parseExpressionForColumn(paintValue);
                if (column) return column;
            }
        } catch (e) {
            // Property may not exist for this layer type
        }
    }

    return null;
}

/**
 * Parse expression to extract column name
 * Handles: match, interpolate, step, case expressions
 * @param {Array} expr - The expression array
 * @returns {string|null} The column name or null
 */
function parseExpressionForColumn(expr) {
    if (!Array.isArray(expr) || expr.length < 2) return null;

    var type = expr[0];

    // match: ["match", ["get", "column"], ...]
    if (type === "match" && Array.isArray(expr[1])) {
        if (expr[1][0] === "get" && typeof expr[1][1] === "string") {
            return expr[1][1];
        }
    }

    // interpolate: ["interpolate", ["linear"], ["get", "column"], ...]
    if (type === "interpolate" && expr.length >= 3) {
        var getExpr = expr[2];
        if (Array.isArray(getExpr) && getExpr[0] === "get") {
            return getExpr[1];
        }
    }

    // step: ["step", ["get", "column"], base, ...]
    if (type === "step" && Array.isArray(expr[1])) {
        if (expr[1][0] === "get" && typeof expr[1][1] === "string") {
            return expr[1][1];
        }
    }

    // case with na_color wrapper: ["case", ["==", ["get", "column"], null], na_color, inner_expr]
    if (type === "case" && expr.length >= 4) {
        // Check inner expression (last non-default element)
        for (var i = 3; i < expr.length; i++) {
            if (Array.isArray(expr[i])) {
                var result = parseExpressionForColumn(expr[i]);
                if (result) return result;
            }
        }
    }

    return null;
}

/**
 * Initialize categorical legend interactivity
 */
function initCategoricalLegend(map, mapId, legendElement, filterColumn, config) {
    var items = legendElement.querySelectorAll(".legend-item");

    // Use filterValues for actual filtering, values for display
    var filterValues = config.filterValues || config.values;
    var displayValues = config.values;
    var breaks = config.breaks; // For range-based filtering (from classifications)

    // Track enabled state by index (to map display values to filter values)
    var numCategories = displayValues.length;
    var enabledIndices = new Set();
    for (var i = 0; i < numCategories; i++) {
        enabledIndices.add(i);
    }

    var layerState = window._mapglLayerState[mapId];
    var interactiveState = layerState.interactiveFilters[config.layerId];

    // Store category state
    interactiveState.enabledIndices = enabledIndices;
    interactiveState.filterValues = filterValues;
    interactiveState.breaks = breaks;
    interactiveState.filterColumn = filterColumn;

    // Store original colors for each item
    var originalColors = {};

    // Add click handlers to each item
    items.forEach(function (item, idx) {
        var displayValue = item.getAttribute("data-value") || String(displayValues[idx]);
        item.setAttribute("data-value", displayValue);
        item.setAttribute("data-index", idx);
        item.setAttribute("data-enabled", "true");

        // Store original color - try multiple selectors for different patch types
        var colorSpan = item.querySelector(".legend-color") ||
                        item.querySelector(".legend-shape-svg") ||
                        item.querySelector(".legend-shape-custom");
        if (colorSpan) {
            originalColors[idx] = colorSpan.style.backgroundColor ||
                                  colorSpan.getAttribute("fill") ||
                                  config.colors[idx];
        } else {
            // Fallback to config colors
            originalColors[idx] = config.colors[idx];
        }

        item.addEventListener("click", function (e) {
            e.preventDefault();
            e.stopPropagation();

            var currentlyEnabled = item.getAttribute("data-enabled") === "true";
            var newState = !currentlyEnabled;

            item.setAttribute("data-enabled", String(newState));

            if (newState) {
                enabledIndices.add(idx);
                // Restore original color
                if (colorSpan) {
                    colorSpan.style.backgroundColor = originalColors[idx];
                }
            } else {
                enabledIndices.delete(idx);
                // Grey out
                if (colorSpan) {
                    colorSpan.style.backgroundColor = "#cccccc";
                }
            }

            // Apply filter - use breaks for range-based, filterValues for categorical
            if (breaks && breaks.length > 0) {
                applyRangeBasedCategoricalFilter(
                    map,
                    mapId,
                    config.layerId,
                    filterColumn,
                    enabledIndices,
                    breaks,
                    interactiveState.originalFilter
                );
            } else {
                applyCategoricalFilter(
                    map,
                    mapId,
                    config.layerId,
                    filterColumn,
                    enabledIndices,
                    filterValues,
                    interactiveState.originalFilter
                );
            }

            // Update reset button visibility
            updateResetButton(legendElement, enabledIndices.size < numCategories);

            // Send to Shiny if applicable
            if (typeof HTMLWidgets !== "undefined" && HTMLWidgets.shinyMode) {
                // Get enabled filter values for Shiny
                var enabledFilterValues = [];
                enabledIndices.forEach(function(i) {
                    enabledFilterValues.push(filterValues[i]);
                });
                Shiny.setInputValue(mapId + "_legend_filter", {
                    legendId: config.legendId,
                    layerId: config.layerId,
                    type: "categorical",
                    column: filterColumn,
                    enabledValues: enabledFilterValues,
                    timestamp: Date.now()
                });
            }
        });
    });

    // Add reset button
    addResetButton(legendElement, function () {
        items.forEach(function (item, i) {
            item.setAttribute("data-enabled", "true");
            var colorSpan = item.querySelector(".legend-color") ||
                            item.querySelector(".legend-shape-svg") ||
                            item.querySelector(".legend-shape-custom");
            if (colorSpan && originalColors[i] !== undefined) {
                colorSpan.style.backgroundColor = originalColors[i];
            }
        });
        enabledIndices.clear();
        for (var i = 0; i < numCategories; i++) {
            enabledIndices.add(i);
        }

        // Reset filter to original
        if (interactiveState.originalFilter) {
            map.setFilter(config.layerId, interactiveState.originalFilter);
        } else {
            map.setFilter(config.layerId, null);
        }
        layerState.filters[config.layerId] = interactiveState.originalFilter;

        updateResetButton(legendElement, false);

        // Send to Shiny
        if (typeof HTMLWidgets !== "undefined" && HTMLWidgets.shinyMode) {
            Shiny.setInputValue(mapId + "_legend_filter", {
                legendId: config.legendId,
                layerId: config.layerId,
                type: "categorical",
                column: filterColumn,
                enabledValues: filterValues.slice(),
                timestamp: Date.now()
            });
        }
    });
}

/**
 * Initialize continuous legend interactivity with dual-handle slider
 */
function initContinuousLegend(map, mapId, legendElement, filterColumn, config) {
    var values = config.values.map(Number);
    var minValue = Math.min.apply(null, values);
    var maxValue = Math.max.apply(null, values);

    var layerState = window._mapglLayerState[mapId];
    var interactiveState = layerState.interactiveFilters[config.layerId];

    // Store range state
    interactiveState.rangeMin = minValue;
    interactiveState.rangeMax = maxValue;
    interactiveState.originalMin = minValue;
    interactiveState.originalMax = maxValue;
    interactiveState.filterColumn = filterColumn;

    // Create slider container
    var sliderContainer = document.createElement("div");
    sliderContainer.className = "legend-slider-container";

    var sliderId = config.legendId + "-slider";

    // Create two range inputs for dual-handle slider
    var sliderHtml =
        '<div class="legend-range-track" id="' + sliderId + '-track"></div>' +
        '<input type="range" class="legend-range-slider legend-range-min" id="' + sliderId + '-min"' +
        ' min="' + minValue + '" max="' + maxValue + '" value="' + minValue + '" step="any">' +
        '<input type="range" class="legend-range-slider legend-range-max" id="' + sliderId + '-max"' +
        ' min="' + minValue + '" max="' + maxValue + '" value="' + maxValue + '" step="any">' +
        '<div class="legend-range-current" id="' + sliderId + '-current">' +
        formatValue(minValue) + " - " + formatValue(maxValue) +
        "</div>";

    sliderContainer.innerHTML = sliderHtml;

    // Insert after the gradient bar
    var gradientBar = legendElement.querySelector(".legend-gradient");
    if (gradientBar) {
        gradientBar.parentNode.insertBefore(sliderContainer, gradientBar.nextSibling);
    } else {
        legendElement.appendChild(sliderContainer);
    }

    // Hide the original labels (replaced by slider display)
    var originalLabels = legendElement.querySelector(".legend-labels");
    if (originalLabels) {
        originalLabels.style.display = "none";
    }

    // Get slider elements
    var minSlider = document.getElementById(sliderId + "-min");
    var maxSlider = document.getElementById(sliderId + "-max");
    var track = document.getElementById(sliderId + "-track");
    var currentDisplay = document.getElementById(sliderId + "-current");

    // Update track position
    function updateTrack() {
        var minVal = parseFloat(minSlider.value);
        var maxVal = parseFloat(maxSlider.value);
        var range = maxValue - minValue;
        var minPercent = ((minVal - minValue) / range) * 100;
        var maxPercent = ((maxVal - minValue) / range) * 100;

        track.style.left = minPercent + "%";
        track.style.width = maxPercent - minPercent + "%";

        currentDisplay.textContent = formatValue(minVal) + " - " + formatValue(maxVal);
    }

    // Debounced filter application
    var filterTimeout;
    function applyFilterDebounced() {
        clearTimeout(filterTimeout);
        filterTimeout = setTimeout(function () {
            var minVal = parseFloat(minSlider.value);
            var maxVal = parseFloat(maxSlider.value);

            interactiveState.rangeMin = minVal;
            interactiveState.rangeMax = maxVal;

            applyRangeFilter(
                map,
                mapId,
                config.layerId,
                filterColumn,
                minVal,
                maxVal,
                interactiveState.originalFilter
            );

            // Update reset button visibility
            var hasFilter =
                minVal > minValue + 0.001 || maxVal < maxValue - 0.001;
            updateResetButton(legendElement, hasFilter);

            // Send to Shiny if applicable
            if (typeof HTMLWidgets !== "undefined" && HTMLWidgets.shinyMode) {
                Shiny.setInputValue(mapId + "_legend_filter", {
                    legendId: config.legendId,
                    layerId: config.layerId,
                    type: "continuous",
                    column: filterColumn,
                    range: [minVal, maxVal],
                    timestamp: Date.now()
                });
            }
        }, 50);
    }

    // Event listeners for sliders
    minSlider.addEventListener("input", function () {
        if (parseFloat(minSlider.value) > parseFloat(maxSlider.value)) {
            minSlider.value = maxSlider.value;
        }
        updateTrack();
        applyFilterDebounced();
    });

    maxSlider.addEventListener("input", function () {
        if (parseFloat(maxSlider.value) < parseFloat(minSlider.value)) {
            maxSlider.value = minSlider.value;
        }
        updateTrack();
        applyFilterDebounced();
    });

    // Initial track position
    updateTrack();

    // Add reset button
    addResetButton(legendElement, function () {
        minSlider.value = minValue;
        maxSlider.value = maxValue;
        updateTrack();

        interactiveState.rangeMin = minValue;
        interactiveState.rangeMax = maxValue;

        // Reset filter to original
        if (interactiveState.originalFilter) {
            map.setFilter(config.layerId, interactiveState.originalFilter);
        } else {
            map.setFilter(config.layerId, null);
        }
        layerState.filters[config.layerId] = interactiveState.originalFilter;

        updateResetButton(legendElement, false);

        // Send to Shiny
        if (typeof HTMLWidgets !== "undefined" && HTMLWidgets.shinyMode) {
            Shiny.setInputValue(mapId + "_legend_filter", {
                legendId: config.legendId,
                layerId: config.layerId,
                type: "continuous",
                column: filterColumn,
                range: [minValue, maxValue],
                timestamp: Date.now()
            });
        }
    });
}

/**
 * Apply categorical filter to layer
 * @param enabledIndices - Set of enabled indices
 * @param filterValues - Array of actual data values to filter on
 */
function applyCategoricalFilter(
    map,
    mapId,
    layerId,
    column,
    enabledIndices,
    filterValues,
    originalFilter
) {
    var layerState = window._mapglLayerState[mapId];

    var interactiveFilter;
    if (enabledIndices.size === 0) {
        // No categories enabled - hide all features
        interactiveFilter = ["==", ["get", column], "__IMPOSSIBLE_VALUE__"];
    } else {
        // Build array of enabled filter values
        var enabledValues = [];
        enabledIndices.forEach(function(i) {
            if (filterValues[i] !== undefined) {
                enabledValues.push(String(filterValues[i]));
            }
        });

        // Create "match" filter for enabled categories
        // Format: ["match", ["get", column], [values], true, false]
        interactiveFilter = [
            "match",
            ["get", column],
            enabledValues,
            true,
            false
        ];
    }

    // Combine with original filter if exists
    var finalFilter = combineFilters(originalFilter, interactiveFilter);

    map.setFilter(layerId, finalFilter);
    layerState.filters[layerId] = finalFilter;
}

/**
 * Apply range-based categorical filter (for binned/quantile classifications)
 * @param enabledIndices - Set of enabled bin indices
 * @param breaks - Array of break values [min, break1, break2, ..., max]
 */
function applyRangeBasedCategoricalFilter(
    map,
    mapId,
    layerId,
    column,
    enabledIndices,
    breaks,
    originalFilter
) {
    var layerState = window._mapglLayerState[mapId];

    var interactiveFilter;
    if (enabledIndices.size === 0) {
        // No categories enabled - hide all features
        interactiveFilter = ["==", ["get", column], "__IMPOSSIBLE_VALUE__"];
    } else {
        // Build "any" filter with range conditions for each enabled bin
        var rangeConditions = [];
        enabledIndices.forEach(function(i) {
            if (i < breaks.length - 1) {
                var minVal = breaks[i];
                var maxVal = breaks[i + 1];
                // Each bin: value >= min AND value < max (except last bin uses <=)
                var isLastBin = (i === breaks.length - 2);
                var binCondition = [
                    "all",
                    [">=", ["get", column], minVal],
                    isLastBin ? ["<=", ["get", column], maxVal] : ["<", ["get", column], maxVal]
                ];
                rangeConditions.push(binCondition);
            }
        });

        if (rangeConditions.length === 1) {
            interactiveFilter = rangeConditions[0];
        } else {
            interactiveFilter = ["any"].concat(rangeConditions);
        }
    }

    // Combine with original filter if exists
    var finalFilter = combineFilters(originalFilter, interactiveFilter);

    map.setFilter(layerId, finalFilter);
    layerState.filters[layerId] = finalFilter;
}

/**
 * Apply range filter to layer
 */
function applyRangeFilter(
    map,
    mapId,
    layerId,
    column,
    min,
    max,
    originalFilter
) {
    var layerState = window._mapglLayerState[mapId];

    var interactiveFilter = [
        "all",
        [">=", ["get", column], min],
        ["<=", ["get", column], max]
    ];

    // Combine with original filter if exists
    var finalFilter = combineFilters(originalFilter, interactiveFilter);

    map.setFilter(layerId, finalFilter);
    layerState.filters[layerId] = finalFilter;
}

/**
 * Combine existing filter with interactive filter
 */
function combineFilters(existingFilter, interactiveFilter) {
    if (!existingFilter) {
        return interactiveFilter;
    }
    // Wrap both in "all"
    return ["all", existingFilter, interactiveFilter];
}

/**
 * Add reset button to legend
 */
function addResetButton(legendElement, resetCallback) {
    if (legendElement.querySelector(".legend-reset-btn")) return;

    var resetBtn = document.createElement("button");
    resetBtn.className = "legend-reset-btn";
    resetBtn.textContent = "Reset Filter";
    resetBtn.addEventListener("click", function (e) {
        e.preventDefault();
        e.stopPropagation();
        resetCallback();
    });
    legendElement.appendChild(resetBtn);
}

/**
 * Update reset button visibility
 */
function updateResetButton(legendElement, show) {
    var resetBtn = legendElement.querySelector(".legend-reset-btn");
    if (resetBtn) {
        resetBtn.classList.toggle("visible", show);
    }
}

/**
 * Format numeric value for display
 */
function formatValue(value) {
    if (value === null || value === undefined || isNaN(value)) {
        return String(value);
    }
    var absValue = Math.abs(value);
    if (absValue >= 1000000) {
        return (value / 1000000).toFixed(1) + "M";
    } else if (absValue >= 1000) {
        return (value / 1000).toFixed(1) + "K";
    } else if (Number.isInteger(value)) {
        return value.toString();
    } else {
        return value.toFixed(2);
    }
}
