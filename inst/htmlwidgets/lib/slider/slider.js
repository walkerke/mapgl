/**
 * Time Slider Control for mapgl (Mapbox GL JS and MapLibre GL JS).
 *
 * Implements the IControl interface so it participates in the native
 * control positioning system (stacks beside navigation, scale, etc).
 *
 * Composes with the shared per-layer filter registry installed by
 * mapboxgl.js / maplibregl.js:
 *   - window._mapglEnsureLayerState(map)
 *   - window._mapglComposeFilter(map, layerId)
 * Writes the slider's filter to filterStack[layer].slider; base / user /
 * legend slots from other sources continue to compose on every tick.
 *
 * Public surface:
 *   new SliderControl(options)
 *     .onAdd(map), .onRemove()
 *     .targetsLayer(layerId)   -- bool; for proxy add_layer wiring
 *     .currentFilter()         -- returns the current slider expression
 *     .update({ value, playing, animation_duration })  -- proxy updater
 */
(function () {
    "use strict";

    // Inline SVG icons. currentColor lets CSS theme them.
    var ICON_PLAY =
        '<svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true">' +
        '<path fill="currentColor" d="M4 2.5v11l10-5.5z"/></svg>';
    var ICON_PAUSE =
        '<svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true">' +
        '<path fill="currentColor" d="M4 2h3v12H4zM9 2h3v12H9z"/></svg>';

    function buildFilter(mode, property, value) {
        if (mode === "cumulative") {
            return ["<=", ["get", property], value];
        }
        // default: sequential / equality
        return ["==", ["get", property], value];
    }

    function SliderControl(options) {
        this.options = options || {};
        this._layers = (options.layers || []).slice();
        this._property = options.property;
        this._values = (options.values || []).slice();
        this._labels = (options.labels && options.labels.length === this._values.length)
            ? options.labels.slice()
            : this._values.map(function (v) { return String(v); });
        this._mode = (options.mode === "cumulative" || options.mode === "window")
            ? options.mode
            : "sequential";
        // Window mode only: size of the moving [start, end] range. null =>
        // cumulative range [min, T]; number => sliding range [T - window, T].
        this._window = (options.window != null) ? options.window : null;
        // Absolute time unit used to convert numeric values to a flowmap
        // selectedTimeRange (window mode + flowmap target only).
        this._timeUnit = options.time_unit || null;
        this._index = this._clampIndex(options.initial_index || 0);
        // Window mode tracks an explicit [start, end] range over the value
        // grid. _endIndex is the playhead/end and mirrors _index so paint and
        // the value label reuse the same machinery; _startIndex is derived
        // from `window` (initial width in value units), or 0 for a [min, end]
        // range when `window` is NULL.
        this._endIndex = this._index;
        this._startIndex = this._computeStartIndex(this._endIndex);
        // Optional density histogram (d3, loaded on demand). `counts` is one
        // bar height per value, binned in R against the value axis.
        this._histogram = !!options.histogram;
        this._counts = (options.counts || []).map(Number);
        this._playButton = !!options.play_button;
        this._animationDuration = Math.max(50, options.animation_duration || 1000);
        this._loop = options.loop !== false;
        this._title = options.title || null;
        this._showValue = options.show_value !== false;
        this._width = options.width || 280;
        this._background = options.background_color || "#ffffffcc";
        this._textColor = options.text_color || "#404040";
        this._accent = options.accent_color || "#4a90e2";
        this._playing = false;
        this._timer = null;
        // Shiny input name: either explicitly provided or derived from the
        // map container id in onAdd as `<id>_slider`.
        this._shinyInputName = options.shiny_input_name || null;
        // Paint-property animation (optional). The R side normalizes both
        // the single-form (paint_property + paint_expressions) and the
        // multi-form (paint_properties) into a single dict shape:
        //   paint_properties: { "fill-color": [expr0, expr1, ...], ... }
        // For backwards compat with any payload still in the single form,
        // we also accept paint_property + paint_expressions here.
        this._paintProperties = {};
        if (options.paint_properties && typeof options.paint_properties === "object") {
            for (var pn in options.paint_properties) {
                if (Object.prototype.hasOwnProperty.call(options.paint_properties, pn)) {
                    this._paintProperties[pn] = (options.paint_properties[pn] || []).slice();
                }
            }
        } else if (options.paint_property && options.paint_expressions) {
            this._paintProperties[options.paint_property] =
                (options.paint_expressions || []).slice();
        }
        // Per-layer, per-property baseline captured on first apply.
        // Shape: { layer_id: { property_name: <original value> } }
        this._paintBaseline = {};
    }

    SliderControl.prototype._clampIndex = function (i) {
        if (!this._values.length) return 0;
        if (i < 0) return 0;
        if (i >= this._values.length) return this._values.length - 1;
        return i;
    };

    // Initial start index for window mode: smallest index whose value is
    // >= (values[endIdx] - window). NULL window => 0 (range spans [min, T]).
    // Works for non-uniform value grids.
    SliderControl.prototype._computeStartIndex = function (endIdx) {
        if (this._window == null) return 0;
        var endVal = this._values[endIdx];
        var lo = endVal - this._window;
        for (var i = 0; i < this._values.length; i++) {
            if (this._values[i] >= lo) return Math.min(i, endIdx);
        }
        return endIdx;
    };

    SliderControl.prototype.targetsLayer = function (layerId) {
        return this._layers.indexOf(layerId) !== -1;
    };

    // Current window bounds as [startValue, endValue] (window mode only),
    // read from the explicit start/end handle positions.
    SliderControl.prototype._windowBounds = function () {
        return [this._values[this._startIndex], this._values[this._endIndex]];
    };

    // Convert a numeric slider value to epoch milliseconds for a flowmap
    // selectedTimeRange, using the R-supplied time_unit. Returns null for
    // non-absolute units (month/day) or a missing unit, signalling the
    // caller to skip the flowmap target rather than emit a bad range.
    SliderControl.prototype._toTime = function (v) {
        if (v == null || isNaN(v)) return null;
        switch (this._timeUnit) {
            case "seconds": return v * 1000;
            case "date": return v * 86400000;
            case "year": return Date.UTC(v, 0, 1);
            default: return null;
        }
    };

    SliderControl.prototype.currentFilter = function () {
        if (!this._values.length || !this._property) return null;
        if (this._mode === "window") {
            // Inclusive both ends: values are instants, so [start, end]
            // keeps a single-step range non-empty (a half-open `< end`
            // would empty a zero-width selection and cause off-by-one).
            var b = this._windowBounds();
            return [
                "all",
                [">=", ["get", this._property], b[0]],
                ["<=", ["get", this._property], b[1]]
            ];
        }
        return buildFilter(this._mode, this._property, this._values[this._index]);
    };

    // Return { property: expression } for the current step, or null if
    // paint isn't configured.
    SliderControl.prototype._currentPaintOverrides = function () {
        var props = Object.keys(this._paintProperties);
        if (!props.length) return null;
        var out = {};
        for (var i = 0; i < props.length; i++) {
            var list = this._paintProperties[props[i]];
            if (list && list.length) out[props[i]] = list[this._index];
        }
        return out;
    };

    // Capture baseline(s) and apply current paint expression(s) for a
    // single layer. Safe to call multiple times for the same layer (the
    // per-property baseline is captured only on first sighting). Called
    // from the late-added-layer hook in the binding files and indirectly
    // from the main apply path via the same per-layer branch.
    SliderControl.prototype.captureAndApplyPaintForLayer = function (layerId) {
        if (!this._map) return;
        var props = Object.keys(this._paintProperties);
        if (!props.length) return;
        if (!this._map.getLayer || !this._map.getLayer(layerId)) return;
        if (!this._paintBaseline[layerId]) this._paintBaseline[layerId] = {};
        for (var i = 0; i < props.length; i++) {
            var prop = props[i];
            var list = this._paintProperties[prop];
            if (!list || !list.length) continue;
            if (!Object.prototype.hasOwnProperty.call(this._paintBaseline[layerId], prop)) {
                // undefined = no explicit value; setPaintProperty(..., undefined)
                // restores the style default on removal.
                this._paintBaseline[layerId][prop] = this._map.getPaintProperty(layerId, prop);
            }
            this._map.setPaintProperty(layerId, prop, list[this._index]);
        }
    };

    SliderControl.prototype.onAdd = function (map) {
        this._map = map;
        // Enforce one-slider-per-map: quietly replace any prior instance.
        if (map._mapglSliderControl && map._mapglSliderControl !== this) {
            try { map.removeControl(map._mapglSliderControl); } catch (e) { /* noop */ }
        }
        map._mapglSliderControl = this;
        // Derive the Shiny input name from the map container id if not
        // supplied explicitly.
        if (!this._shinyInputName) {
            var _cid = (map.getContainer && map.getContainer().id) || null;
            if (_cid) this._shinyInputName = _cid + "_slider";
        }

        var self = this;

        // Build DOM.
        // The outer node uses .mapboxgl-ctrl so native positioning applies;
        // the inner wrapper is what we style. Inline width/colors come from
        // options so we don't need a style injection step for each instance.
        var root = document.createElement("div");
        root.className = "mapboxgl-ctrl maplibregl-ctrl mapgl-slider";
        root.style.width = this._width + "px";
        root.style.background = this._background;
        root.style.color = this._textColor;

        // CSS custom property powers the accent color in the range thumb.
        root.style.setProperty("--mapgl-slider-accent", this._accent);

        var body = document.createElement("div");
        body.className = "mapgl-slider-body";

        if (this._title) {
            var titleEl = document.createElement("div");
            titleEl.className = "mapgl-slider-title";
            titleEl.textContent = this._title;
            body.appendChild(titleEl);
        }

        var header = document.createElement("div");
        header.className = "mapgl-slider-header";

        var valueEl = document.createElement("div");
        valueEl.className = "mapgl-slider-value";
        if (!this._showValue) valueEl.style.display = "none";
        valueEl.textContent = this._labels[this._index] || "";
        header.appendChild(valueEl);
        this._valueEl = valueEl;

        body.appendChild(header);

        // Density strip sits between the label and the slider row, sharing
        // the body width so bars align above the handles/band below.
        if (this._histogram && this._counts.length) {
            body.appendChild(this._buildHistogram());
        }

        var row = document.createElement("div");
        row.className = "mapgl-slider-row";

        if (this._playButton) {
            var playBtn = document.createElement("button");
            playBtn.type = "button";
            playBtn.className = "mapgl-slider-play";
            playBtn.setAttribute("aria-label", "Play");
            playBtn.innerHTML = ICON_PLAY;
            playBtn.addEventListener("click", function () {
                self._togglePlay();
            });
            row.appendChild(playBtn);
            this._playBtn = playBtn;
        }

        // Window mode renders a two-handle range; all other modes render a
        // single thumb.
        if (this._mode === "window") {
            row.appendChild(this._buildRangeInput());
        } else {
            row.appendChild(this._buildSingleInput());
        }

        body.appendChild(row);
        root.appendChild(body);
        this._root = root;

        // Seed filter registry slots for each target layer and apply.
        // Initial mount uses the synchronous path so the first paint
        // already has the filter applied (no flash of unfiltered data).
        this._applyFilterNow();

        // Fire initial Shiny input value if applicable.
        this._fireShinyInput();

        // Draw the density strip once d3 has loaded and the control has a
        // measurable width (it mounts at 0px until the control framework
        // inserts it into the corner).
        if (this._histogram && this._counts.length) {
            this._ensureHistogram();
        }

        // Keep the slider filter applied even if the style reloads.
        this._onStyleData = function () {
            // Style reloads re-run the replay in state.filters, which
            // includes our composed expression. But filterStack persists
            // on window so composeAndApplyFilter remains correct; just
            // re-trigger to be safe in case any layer got re-created with
            // only its `base` filter. Immediate rather than coalesced so
            // we never leave a stale filter visible.
            self._applyFilterNow();
        };
        map.on("styledata", this._onStyleData);

        return root;
    };

    // ---- Histogram density strip (adapted from Egor Kotov's PR #205) ----
    // The bar + accent rendering and CSS classes (.mapgl-bar) come from his
    // time-control; the data source (R-binned `counts` on the value axis)
    // and the index-aligned x-scale are the mapgl-specific rewiring, and the
    // range selection is the slider's own two-handle control rather than his
    // d3 brush.
    SliderControl.prototype._buildHistogram = function () {
        var host = document.createElement("div");
        host.className = "mapgl-slider-histogram";
        this._histEl = host;
        return host;
    };

    // Poll until d3 is present and the strip has a real width, then draw.
    SliderControl.prototype._ensureHistogram = function () {
        var self = this;
        var tries = 0;
        function attempt() {
            if (!self._histEl) return;
            var ready = typeof window.d3 !== "undefined" &&
                self._histEl.clientWidth > 20;
            if (ready) {
                self._renderHistogramBars();
                return;
            }
            if (tries++ > 120) { // ~6s
                if (typeof console !== "undefined" && console.warn) {
                    console.warn(
                        "[mapgl] slider histogram needs d3; it did not load — " +
                        "showing the slider without the density strip. " +
                        "(Declare histogram = TRUE at initial render so d3 is bundled.)"
                    );
                }
                return;
            }
            setTimeout(attempt, 50);
        }
        attempt();
    };

    SliderControl.prototype._renderHistogramBars = function () {
        var d3 = window.d3;
        if (!d3 || !this._histEl || !this._counts.length) return;
        var width = this._histEl.clientWidth || this._width;
        var height = 46;
        var n = this._counts.length;
        var maxIdx = Math.max(1, n - 1);
        var maxC = d3.max(this._counts) || 1;
        var y = d3.scaleLinear().domain([0, maxC]).range([height - 1, 4]);
        var barW = Math.max(1, (width / n) * 0.7);
        var self = this;

        var svg = d3.select(this._histEl).select("svg");
        if (svg.empty()) svg = d3.select(this._histEl).append("svg");
        svg.attr("width", width).attr("height", height);
        svg.selectAll("*").remove();

        svg
            .selectAll(".mapgl-bar")
            .data(this._counts)
            .enter()
            .append("rect")
            .attr("class", "mapgl-bar")
            // Spread bars across the full width so the first and last sit
            // flush with the edges (no half-bars), while the extreme bars
            // still line up with the index 0 / maxIdx ends of the band below.
            .attr("x", function (d, i) { return (i / maxIdx) * (width - barW); })
            .attr("y", function (d) { return y(d); })
            .attr("width", barW)
            .attr("height", function (d) { return Math.max(0, height - y(d)); })
            .attr("rx", 1)
            .attr("fill", self._accent);

        this._renderedHist = true;
        this._updateHistogramHighlight();
    };

    // Index range of "active" bars for the current selection/value.
    SliderControl.prototype._histActiveRange = function () {
        if (this._mode === "window") return [this._startIndex, this._endIndex];
        if (this._mode === "cumulative") return [0, this._index];
        return [this._index, this._index];
    };

    // Bars inside the active range are full opacity; the rest are dimmed,
    // so the density strip reads as a "brush over the histogram".
    SliderControl.prototype._updateHistogramHighlight = function () {
        if (!this._renderedHist || typeof window.d3 === "undefined") return;
        var r = this._histActiveRange();
        var lo = r[0], hi = r[1];
        window.d3
            .select(this._histEl)
            .selectAll(".mapgl-bar")
            .attr("opacity", function (d, i) {
                return i >= lo && i <= hi ? 1 : 0.28;
            });
    };

    // Single-thumb input for sequential/cumulative modes.
    SliderControl.prototype._buildSingleInput = function () {
        var self = this;
        var input = document.createElement("input");
        input.type = "range";
        input.className = "mapgl-slider-input";
        input.min = "0";
        input.max = String(Math.max(0, this._values.length - 1));
        input.step = "1";
        input.value = String(this._index);
        // Pause when the user scrubs.
        input.addEventListener("input", function (e) {
            self._setIndex(parseInt(e.target.value, 10), { pause: true, fromUser: true });
        });
        this._input = input;
        return input;
    };

    // Two-handle range input for window mode: a shared track, a filled band
    // between the handles, and two overlaid native range inputs (the
    // pointer-events trick in the CSS keeps both thumbs grabbable).
    SliderControl.prototype._buildRangeInput = function () {
        var self = this;
        var maxIdx = Math.max(0, this._values.length - 1);

        var wrap = document.createElement("div");
        wrap.className = "mapgl-slider-range";

        var track = document.createElement("div");
        track.className = "mapgl-slider-range-track";
        wrap.appendChild(track);

        var fill = document.createElement("div");
        fill.className = "mapgl-slider-range-fill";
        wrap.appendChild(fill);
        this._rangeFill = fill;
        this._rangeWrap = wrap;
        // The band itself is grabbable: dragging it pans the whole window at
        // fixed width (mirrors the interactive legend's draggable middle).
        this._attachBandDrag(fill, wrap);

        var startInput = document.createElement("input");
        startInput.type = "range";
        startInput.className = "mapgl-slider-range-start";
        startInput.min = "0";
        startInput.max = String(maxIdx);
        startInput.step = "1";
        startInput.value = String(this._startIndex);
        startInput.addEventListener("input", function (e) {
            self._setStart(parseInt(e.target.value, 10), { pause: true });
        });

        var endInput = document.createElement("input");
        endInput.type = "range";
        endInput.className = "mapgl-slider-range-end";
        endInput.min = "0";
        endInput.max = String(maxIdx);
        endInput.step = "1";
        endInput.value = String(this._endIndex);
        endInput.addEventListener("input", function (e) {
            self._setEnd(parseInt(e.target.value, 10), { pause: true });
        });

        wrap.appendChild(startInput);
        wrap.appendChild(endInput);
        this._startInput = startInput;
        this._endInput = endInput;

        this._renderRangeFill();
        this._updateWindowLabel();
        return wrap;
    };

    // Position the filled band between the two handles (percent of track).
    SliderControl.prototype._renderRangeFill = function () {
        if (!this._rangeFill) return;
        var maxIdx = Math.max(1, this._values.length - 1);
        var a = (this._startIndex / maxIdx) * 100;
        var b = (this._endIndex / maxIdx) * 100;
        this._rangeFill.style.left = a + "%";
        this._rangeFill.style.width = Math.max(0, b - a) + "%";
        this._updateHistogramHighlight();
    };

    // Window value label shows the range, collapsing to one label when the
    // band is zero-width.
    SliderControl.prototype._updateWindowLabel = function () {
        if (!this._valueEl) return;
        var a = this._labels[this._startIndex] || "";
        var b = this._labels[this._endIndex] || "";
        this._valueEl.textContent = a === b ? a : a + " – " + b;
    };

    // Set both handles at once (used by band drag, play slide, and the
    // proxy updater). Centralizes the input/fill/label sync + apply.
    SliderControl.prototype._setBand = function (s, e, opts) {
        opts = opts || {};
        s = this._clampIndex(s);
        e = this._clampIndex(e);
        if (s > e) { var t = s; s = e; e = t; }
        var changed = s !== this._startIndex || e !== this._endIndex;
        this._startIndex = s;
        this._endIndex = e;
        this._index = e;
        if (this._startInput) this._startInput.value = String(s);
        if (this._endInput) this._endInput.value = String(e);
        this._renderRangeFill();
        this._updateWindowLabel();
        if (changed || opts.force) {
            this._applyFilterToLayers();
            this._fireShinyInput();
        }
    };

    // Drag the filled band to pan the window left/right at a fixed width.
    SliderControl.prototype._attachBandDrag = function (fill, wrap) {
        var self = this;
        var dragging = false;
        var startX = 0;
        var startStartIdx = 0;
        var width = 0;
        function maxIdx() {
            return Math.max(1, self._values.length - 1);
        }
        function onMove(e) {
            if (!dragging) return;
            var rectW = wrap.getBoundingClientRect().width || 1;
            var deltaIdx = Math.round(((e.clientX - startX) / rectW) * maxIdx());
            var ns = startStartIdx + deltaIdx;
            if (ns < 0) ns = 0;
            if (ns + width > maxIdx()) ns = maxIdx() - width;
            self._setBand(ns, ns + width);
        }
        function onUp() {
            dragging = false;
            fill.classList.remove("is-dragging");
            document.removeEventListener("pointermove", onMove);
            document.removeEventListener("pointerup", onUp);
        }
        fill.addEventListener("pointerdown", function (e) {
            dragging = true;
            startX = e.clientX;
            startStartIdx = self._startIndex;
            width = self._endIndex - self._startIndex;
            self._stopLoop();
            fill.classList.add("is-dragging");
            document.addEventListener("pointermove", onMove);
            document.addEventListener("pointerup", onUp);
            e.preventDefault();
        });
    };

    SliderControl.prototype._setStart = function (idx, opts) {
        opts = opts || {};
        idx = this._clampIndex(idx);
        if (idx > this._endIndex) idx = this._endIndex; // start cannot pass end
        var changed = idx !== this._startIndex;
        this._startIndex = idx;
        if (this._startInput) this._startInput.value = String(idx);
        this._renderRangeFill();
        this._updateWindowLabel();
        if (opts.pause) this._stopLoop();
        if (changed || opts.force) {
            this._applyFilterToLayers();
            this._fireShinyInput();
        }
    };

    SliderControl.prototype._setEnd = function (idx, opts) {
        opts = opts || {};
        idx = this._clampIndex(idx);
        if (idx < this._startIndex) idx = this._startIndex; // end cannot pass start
        var changed = idx !== this._endIndex;
        this._endIndex = idx;
        this._index = idx; // keep _index synced to the end for paint/label reuse
        if (this._endInput) this._endInput.value = String(idx);
        this._renderRangeFill();
        this._updateWindowLabel();
        if (opts.pause) this._stopLoop();
        if (changed || opts.force) {
            this._applyFilterToLayers();
            this._fireShinyInput();
        }
    };

    // Slide the band so its end sits at idx, preserving width (clamped at the
    // left edge). Used by the proxy updater and could back a "go to" jump.
    SliderControl.prototype._setWindowEnd = function (idx, opts) {
        opts = opts || {};
        var maxIdx = this._values.length - 1;
        var width = this._endIndex - this._startIndex;
        idx = this._clampIndex(idx);
        var startIdx = idx - width;
        if (startIdx < 0) {
            startIdx = 0;
            idx = Math.min(width, maxIdx);
        }
        if (opts.pause) this._stopLoop();
        this._setBand(startIdx, idx, { force: true });
    };

    // Advance the window one step to the right, preserving width; wrap or
    // stop at the end depending on `loop`. Called by the play loop.
    SliderControl.prototype._advanceWindow = function () {
        var maxIdx = this._values.length - 1;
        var width = this._endIndex - this._startIndex;
        if (this._endIndex >= maxIdx) {
            if (!this._loop) {
                this._stopLoop();
                return;
            }
            this._setBand(0, Math.min(width, maxIdx), { force: true });
        } else {
            this._setBand(this._startIndex + 1, this._endIndex + 1, { force: true });
        }
    };

    SliderControl.prototype.onRemove = function () {
        this._stopLoop();
        if (this._map) {
            if (this._onStyleData) {
                try { this._map.off("styledata", this._onStyleData); } catch (e) { /* noop */ }
            }
            // Release slider slot for every targeted layer.
            var state = (typeof window._mapglEnsureLayerState === "function")
                ? window._mapglEnsureLayerState(this._map)
                : null;
            if (state) {
                for (var i = 0; i < this._layers.length; i++) {
                    var lid = this._layers[i];
                    if (state.filterStack[lid]) {
                        state.filterStack[lid].slider = null;
                    }
                    if (typeof window._mapglComposeFilter === "function") {
                        window._mapglComposeFilter(this._map, lid);
                    }
                }
            }
            // Restore every captured paint baseline, across all layers
            // and all configured paint properties. Passing undefined to
            // setPaintProperty restores the style default, which matches
            // the original "no explicit value" state.
            for (var baseLid in this._paintBaseline) {
                if (
                    !Object.prototype.hasOwnProperty.call(
                        this._paintBaseline,
                        baseLid
                    )
                ) continue;
                if (!this._map.getLayer || !this._map.getLayer(baseLid)) continue;
                var layerBaselines = this._paintBaseline[baseLid];
                for (var bProp in layerBaselines) {
                    if (
                        Object.prototype.hasOwnProperty.call(layerBaselines, bProp)
                    ) {
                        this._map.setPaintProperty(
                            baseLid,
                            bProp,
                            layerBaselines[bProp]
                        );
                    }
                }
            }
            if (this._map._mapglSliderControl === this) {
                delete this._map._mapglSliderControl;
            }
        }
        if (this._root && this._root.parentNode) {
            this._root.parentNode.removeChild(this._root);
        }
        this._map = null;
    };

    // Coalesce filter applies to one-per-animation-frame. On dense
    // vector tile / PMTiles layers, map.setFilter triggers a repaint
    // that can queue up faster than the renderer paints; without this,
    // fast dragging leaves the map trailing the slider. rAF coalescing
    // collapses multiple drag ticks into a single setFilter per paint
    // tick, reading the most recent index when the frame actually fires.
    SliderControl.prototype._applyFilterToLayers = function () {
        if (!this._map || !this._values.length) return;
        if (this._rafPending) return;
        var self = this;
        this._rafPending = true;
        var raf =
            (typeof window !== "undefined" && window.requestAnimationFrame) ||
            function (fn) { return setTimeout(fn, 16); };
        raf(function () {
            self._rafPending = false;
            self._applyFilterNow();
        });
    };

    // Synchronous application path. Called from the rAF callback and on
    // onAdd / styledata / onRemove where we want immediate effect.
    // Applies filter (if `property` is configured) and/or paint (if
    // paint properties are configured). Either, both, or neither may run
    // per tick depending on how the slider was configured.
    SliderControl.prototype._applyFilterNow = function () {
        if (!this._map || !this._values.length) return;
        var hasFilter = this._property != null;
        var paintProps = Object.keys(this._paintProperties);
        var hasPaint = paintProps.length > 0;
        var filter = this.currentFilter();
        var state = (typeof window._mapglEnsureLayerState === "function")
            ? window._mapglEnsureLayerState(this._map)
            : null;
        for (var i = 0; i < this._layers.length; i++) {
            var lid = this._layers[i];

            // ---- filter branch ----
            if (hasFilter) {
                // Flowmap layers consume an absolute time range via their
                // own plugin, not a Mapbox filter expression. Feature-detect
                // the plugin (absent until the flowmap feature is loaded) and
                // route window-mode ranges to selectedTimeRange.
                var isFlowmap =
                    typeof window.MapGLFlowmapPlugin !== "undefined" &&
                    window.MapGLFlowmapPlugin.hasLayer &&
                    window.MapGLFlowmapPlugin.hasLayer(this._map, lid);
                if (isFlowmap && this._mode === "window") {
                    var _b = this._windowBounds();
                    var loT = this._toTime(_b[0]);
                    var hiT = this._toTime(_b[1]);
                    if (loT == null || hiT == null) {
                        if (typeof console !== "undefined" && console.warn) {
                            console.warn(
                                "[mapgl] slider window on flowmap layer '" +
                                lid +
                                "' needs an absolute time_unit ('seconds','date','year'); skipping."
                            );
                        }
                    } else {
                        window.MapGLFlowmapPlugin.setFilter(this._map, lid, {
                            selectedTimeRange: [loT, hiT]
                        });
                    }
                } else if (state) {
                    state.filterStack[lid] = state.filterStack[lid] || {};
                    state.filterStack[lid].slider = filter;
                    if (typeof window._mapglComposeFilter === "function") {
                        window._mapglComposeFilter(this._map, lid);
                    } else if (this._map.getLayer && this._map.getLayer(lid)) {
                        // Legacy fallback: no composition with other sources.
                        this._map.setFilter(lid, filter);
                    }
                }
            }

            // ---- paint branch ----
            // Loop every configured paint property; capture baseline per
            // (layer, property) on first sighting, then apply current expr.
            if (hasPaint && this._map.getLayer && this._map.getLayer(lid)) {
                if (!this._paintBaseline[lid]) this._paintBaseline[lid] = {};
                for (var p = 0; p < paintProps.length; p++) {
                    var prop = paintProps[p];
                    var list = this._paintProperties[prop];
                    if (!list || !list.length) continue;
                    if (
                        !Object.prototype.hasOwnProperty.call(
                            this._paintBaseline[lid],
                            prop
                        )
                    ) {
                        this._paintBaseline[lid][prop] =
                            this._map.getPaintProperty(lid, prop);
                    }
                    this._map.setPaintProperty(lid, prop, list[this._index]);
                }
            }
        }
    };

    SliderControl.prototype._setIndex = function (index, opts) {
        opts = opts || {};
        var clamped = this._clampIndex(index);
        var changed = clamped !== this._index;
        this._index = clamped;
        if (this._input) this._input.value = String(clamped);
        if (this._valueEl) this._valueEl.textContent = this._labels[clamped] || "";
        this._updateHistogramHighlight();
        if (opts.pause) this._stopLoop();
        if (changed || opts.force) {
            this._applyFilterToLayers();
            this._fireShinyInput();
        }
    };

    SliderControl.prototype._fireShinyInput = function () {
        if (!this._shinyInputName) return;
        if (typeof Shiny === "undefined" || !Shiny.setInputValue) return;
        var payload;
        if (this._mode === "window") {
            payload = {
                start: this._values[this._startIndex],
                end: this._values[this._endIndex],
                start_index: this._startIndex,
                end_index: this._endIndex,
                start_label: this._labels[this._startIndex],
                end_label: this._labels[this._endIndex],
                playing: this._playing
            };
        } else {
            payload = {
                value: this._values[this._index],
                index: this._index,
                label: this._labels[this._index],
                playing: this._playing
            };
        }
        Shiny.setInputValue(this._shinyInputName, payload, { priority: "event" });
    };

    SliderControl.prototype._togglePlay = function () {
        if (this._playing) this._stopLoop(); else this._startLoop();
    };

    SliderControl.prototype._startLoop = function () {
        if (this._playing || this._values.length < 2) return;
        this._playing = true;
        this._setPlayIcon(true);
        var self = this;
        var step = function () {
            if (!self._playing) return;
            if (self._mode === "window") {
                // Slide the whole band forward, preserving width.
                self._advanceWindow();
            } else {
                var next = self._index + 1;
                if (next >= self._values.length) {
                    if (!self._loop) { self._stopLoop(); return; }
                    next = 0;
                }
                self._setIndex(next, { force: true });
            }
            self._timer = setTimeout(step, self._animationDuration);
        };
        this._timer = setTimeout(step, this._animationDuration);
        this._fireShinyInput();
    };

    SliderControl.prototype._stopLoop = function () {
        if (this._timer) { clearTimeout(this._timer); this._timer = null; }
        if (!this._playing) return;
        this._playing = false;
        this._setPlayIcon(false);
        this._fireShinyInput();
    };

    SliderControl.prototype._setPlayIcon = function (playing) {
        if (!this._playBtn) return;
        this._playBtn.innerHTML = playing ? ICON_PAUSE : ICON_PLAY;
        this._playBtn.setAttribute("aria-label", playing ? "Pause" : "Play");
    };

    // Proxy-driven updates from R's update_slider_control().
    SliderControl.prototype.update = function (msg) {
        if (msg == null) return;
        if (msg.animation_duration != null) {
            this._animationDuration = Math.max(50, msg.animation_duration);
        }
        if (msg.value != null) {
            // Find the matching index for this value. Use strict equality;
            // values are expected to be numeric.
            var idx = -1;
            for (var i = 0; i < this._values.length; i++) {
                if (this._values[i] === msg.value) { idx = i; break; }
            }
            // Fallback: if exact match fails (e.g., float imprecision), pick
            // the nearest numeric value.
            if (idx === -1) {
                var bestDelta = Infinity;
                for (var j = 0; j < this._values.length; j++) {
                    var d = Math.abs(Number(this._values[j]) - Number(msg.value));
                    if (d < bestDelta) { bestDelta = d; idx = j; }
                }
            }
            if (idx >= 0) {
                if (this._mode === "window") {
                    this._setWindowEnd(idx, { force: true });
                } else {
                    this._setIndex(idx, { force: true });
                }
            }
        }
        if (msg.playing === true && !this._playing) this._startLoop();
        if (msg.playing === false && this._playing) this._stopLoop();
    };

    // Expose globally for the binding files to instantiate.
    window.MapglSliderControl = SliderControl;
})();
