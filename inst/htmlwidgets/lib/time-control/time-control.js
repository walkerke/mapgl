(function () {
  /**
   * TimeControl: temporal scrubbing histogram with optional drag and collapse.
   * Drives one or several layers (flowmap or ordinary Mapbox/MapLibre).
   */
  class TimeControl {
    constructor(options = {}) {
      this.options = Object.assign(
        {
          id: "mapgl-time-control",
          bins: [],
          interval: "hour",
          speed: 500,
          loop: true,
          initialRange: null,
          targetLayerIds: null,
          featureTimeProperty: "time",
          featureTimeFormat: "iso",
          accentColor: "#00bcd4",
          darkMode: true,
          position: "bottom-left",
          draggable: false,
          collapsible: false,
          collapsed: false,
          title: null,
        },
        options,
      );

      this._isPlaying = false;
      this._listeners = {};
      this._currentRange = null;
      this._ranges = [];
      this._isCollapsed = !!this.options.collapsed;
      this._canCollapse = !!(this.options.collapsible || this.options.draggable);
    }

    onAdd(map) {
      this._map = map;
      const opts = this.options;

      this._container = document.createElement("div");
      this._container.className =
        "mapgl-time-control-container maplibregl-ctrl mapboxgl-ctrl";

      if (opts.darkMode) this._container.classList.add("dark-mode");
      if (opts.draggable) this._container.classList.add("is-draggable");
      if (this._canCollapse) this._container.classList.add("is-collapsible");

      this._header = document.createElement("div");
      this._header.className = "mapgl-time-header";

      this._collapseBtn = document.createElement("button");
      this._collapseBtn.className = "mapgl-time-icon-btn";
      this._collapseBtn.type = "button";
      this._collapseBtn.innerHTML = this._clockIcon();
      this._collapseBtn.setAttribute(
        "aria-label",
        this._isCollapsed ? "Expand time control" : "Collapse time control",
      );
      if (this._canCollapse) {
        this._collapseBtn.onclick = (e) => {
          if (this._dragged) {
            this._dragged = false;
            return;
          }
          this.toggleCollapse();
        };
      } else {
        this._collapseBtn.tabIndex = -1;
        this._collapseBtn.setAttribute("aria-hidden", "true");
      }

      this._playBtn = document.createElement("button");
      this._playBtn.type = "button";
      this._playBtn.className = "mapgl-time-play-btn";
      this._playBtn.innerHTML = this._getPlayIcon();
      this._playBtn.onclick = () => this.toggle();

      const titleEl = document.createElement("span");
      titleEl.className = "mapgl-time-title";
      titleEl.textContent = opts.title || "";

      this._label = document.createElement("div");
      this._label.className = "mapgl-current-range-label";

      this._header.appendChild(this._collapseBtn);
      this._header.appendChild(this._playBtn);
      this._header.appendChild(titleEl);
      this._header.appendChild(this._label);
      this._container.appendChild(this._header);

      // Body (holds chart wrapper)
      this._body = document.createElement("div");
      this._body.className = "mapgl-time-body";

      const wrapper = document.createElement("div");
      wrapper.className = "mapgl-timeline-wrapper";

      this._svgNode = document.createElementNS(
        "http://www.w3.org/2000/svg",
        "svg",
      );
      wrapper.appendChild(this._svgNode);

      const hint = document.createElement("div");
      hint.className = "mapgl-time-hint";
      hint.textContent = "Shift + drag = select multiple | Double click = select all";
      wrapper.appendChild(hint);

      this._body.appendChild(wrapper);
      this._container.appendChild(this._body);

      // Draggable: detach from corner and position absolutely on map container
      if (opts.draggable || opts.position === "bottom-center") {
        if (opts.position === "bottom-center") {
          this._container.classList.add("mapgl-pos-bottom-center");
        }
        if (opts.draggable) {
          this._container.classList.add("mapgl-floating");
          // Default initial placement: bottom-left of map container
          this._container.style.position = "absolute";
          this._container.style.left = "12px";
          this._container.style.bottom = "12px";
          this._container.style.right = "auto";
          this._container.style.top = "auto";
          this._setupDrag();
        }
        map.getContainer().appendChild(this._container);
      }

      if (this._isCollapsed) {
        this._container.classList.add("is-collapsed");
      }

      this._retryCount = 0;
      this._checkReadyAndInit();

      return this._container;
    }

    _clockIcon() {
      return '<span class="mapgl-time-icon-glyph" aria-hidden="true">&#9719;</span>';
    }

    toggleCollapse() {
      if (!this._canCollapse) return;
      this._isCollapsed = !this._isCollapsed;
      this._container.classList.toggle("is-collapsed", this._isCollapsed);
      if (this._collapseBtn) {
        this._collapseBtn.setAttribute(
          "aria-label",
          this._isCollapsed ? "Expand time control" : "Collapse time control",
        );
      }
    }

    _setupDrag() {
      const handle = this._header || this._container;
      handle.style.cursor = "move";
      let startX, startY, originLeft, originTop, moved;
      const onDown = (e) => {
        const button = e.target.closest("button");
        if (button && button !== this._collapseBtn) return;

        if (!button) {
          e.preventDefault();
        }

        this._dragged = false;
        const rect = this._container.getBoundingClientRect();
        const parentRect = this._map.getContainer().getBoundingClientRect();
        originLeft = rect.left - parentRect.left;
        originTop = rect.top - parentRect.top;
        startX = e.clientX;
        startY = e.clientY;
        moved = false;
        document.addEventListener("mousemove", onMove);
        document.addEventListener("mouseup", onUp);
      };
      const onMove = (e) => {
        const dx = e.clientX - startX;
        const dy = e.clientY - startY;
        if (!moved && Math.abs(dx) + Math.abs(dy) < 3) return;

        e.preventDefault();
        e.stopPropagation();

        if (!moved) {
          moved = true;
          this._dragged = true;
          this._container.style.bottom = "auto";
          this._container.style.right = "auto";
          this._container.style.left = originLeft + "px";
          this._container.style.top = originTop + "px";
        }
        this._container.style.left = originLeft + dx + "px";
        this._container.style.top = originTop + dy + "px";
      };
      const onUp = () => {
        document.removeEventListener("mousemove", onMove);
        document.removeEventListener("mouseup", onUp);
      };
      handle.addEventListener("mousedown", onDown);
    }

    _checkReadyAndInit() {
      const width = this._svgNode.parentElement.clientWidth;
      if (window.d3 && width > 50) {
        this._initChart();
      } else if (this._retryCount < 100) {
        this._retryCount++;
        setTimeout(() => this._checkReadyAndInit(), 50);
      } else {
        if (!window.d3) console.error("D3.js missing for time-control.");
        if (width <= 50) console.error("TimeControl container has 0 width.");
      }
    }

    onRemove() {
      this.pause();
      if (this._container && this._container.parentNode) {
        this._container.parentNode.removeChild(this._container);
      }
      this._map = undefined;
    }

    _initChart() {
      const d3 = window.d3;
      const width = this._svgNode.parentElement.clientWidth;
      const height = 140;
      const margin = { top: 28, right: 10, bottom: 44, left: 46 };
      const innerWidth = width - margin.left - margin.right;
      const innerHeight = height - margin.top - margin.bottom;
      if (innerWidth <= 0) return;

      const svg = d3
        .select(this._svgNode)
        .attr("width", width)
        .attr("height", height);

      // Clear any existing elements inside the SVG to prevent duplicate overlapping charts
      svg.selectAll("*").remove();

      const g = svg
        .append("g")
        .attr("transform", `translate(${margin.left},${margin.top})`);

      let binsData = this.options.bins;
      if (binsData && !Array.isArray(binsData) && typeof binsData === "object") {
        const keys = Object.keys(binsData);
        const rowCount = binsData[keys[0]].length;
        binsData = Array.from({ length: rowCount }, (_, i) => {
          const row = {};
          keys.forEach((k) => (row[k] = binsData[k][i]));
          return row;
        });
      }
      const bins = binsData.map((d) => ({
        time: new Date(d.time),
        count: +d.count,
      }));

      const intervalMs = this._getIntervalMs();
      const domainEnd = new Date(
        bins[bins.length - 1].time.getTime() + intervalMs,
      );
      const x = d3
        .scaleTime()
        .domain([bins[0].time, domainEnd])
        .range([0, innerWidth]);
      const y = d3
        .scaleLinear()
        .domain([0, d3.max(bins, (d) => d.count) || 1])
        .range([innerHeight, 0]);

      const barWidth = innerWidth / bins.length;
      g.selectAll(".mapgl-bar")
        .data(bins)
        .enter()
        .append("rect")
        .attr("class", "mapgl-bar")
        .attr("x", (d) => x(d.time) + 1)
        .attr("y", (d) => y(d.count))
        .attr("width", Math.max(0.5, barWidth - 2))
        .attr("height", (d) => Math.max(0, innerHeight - y(d.count)))
        .attr("rx", 1.5)
        .attr("fill", this.options.accentColor);

      const timeFormat =
        this.options.interval === "day"
          ? d3.timeFormat("%b %d")
          : d3.timeFormat("%H:%M");

      // X-Axis
      g.append("g")
        .attr("class", "mapgl-axis")
        .attr("transform", `translate(0,${innerHeight})`)
        .call(d3.axisBottom(x).ticks(6).tickFormat(timeFormat));

      // Y-Axis
      const yMax = d3.max(bins, (d) => d.count) || 1;
      const yTicks = Array.from(new Set([0, Math.round(yMax / 2), yMax])).sort((a, b) => a - b);
      g.append("g")
        .attr("class", "mapgl-axis mapgl-y-axis")
        .call(
          d3.axisLeft(y)
            .tickValues(yTicks)
            .tickFormat(d3.format(","))
        );

      this._xScale = x;
      this._innerWidth = innerWidth;
      this._innerHeight = innerHeight;

      this._brush = d3
        .brushX()
        .extent([
          [0, 0],
          [innerWidth, innerHeight],
        ])
        .on("brush end", (event) => this._handleBrush(event));
      this._brushGroup = g
        .append("g")
        .attr("class", "mapgl-brush")
        .call(this._brush);

      svg.on("dblclick", (event) => {
        event.preventDefault();
        event.stopPropagation();
        this._brushGroup.call(this._brush.move, [0, innerWidth]);
      });

      this._rangeOverlay = g
        .append("g")
        .attr("class", "mapgl-selected-ranges");

      let initialSelection;
      if (this.options.initialRange) {
        initialSelection = [
          x(new Date(this.options.initialRange[0])),
          x(new Date(this.options.initialRange[1])),
        ];
      } else {
        const start = bins[0].time;
        const binsToSelect = Math.max(1, Math.round(bins.length * 0.2));
        const end = new Date(
          start.getTime() + binsToSelect * intervalMs,
        );
        initialSelection = [x(start), x(end)];
      }
      this._brushGroup.call(this._brush.move, initialSelection);
      this._renderRanges();
    }

    _handleBrush(event) {
      if (event.type === "start") {
        const append =
          event &&
          event.sourceEvent &&
          event.sourceEvent.shiftKey &&
          this._ranges.length > 0;
        
        if (!append) {
          this._ranges = [];
          this._renderRanges();
        }
      }

      if (!event.selection) {
        if (this._activeLabel) this._activeLabel.style("display", "none");
        return;
      }

      const range = this._selectionToRange(event.selection);
      const ranges = this._rangesForBrush(range, event);

      this._currentRange = range;
      this._updateLabel(ranges);
      this._emit("change", ranges);
      this._applyFilter(ranges);

      // Show active label hovering above the active brush rectangle
      if (!this._activeLabel) {
        this._activeLabel = this._brushGroup
          .append("text")
          .attr("class", "mapgl-range-label")
          .attr("text-anchor", "middle");
      }

      const [s0, s1] = event.selection;
      this._activeLabel
        .attr("x", s0 + (s1 - s0) / 2)
        .attr("y", -10)
        .text(this._formatRange(range))
        .style("display", null);

      if (event.type === "end" && !this._isPlaying) {
        this._ranges = ranges;
        this._renderRanges();
        if (this._activeLabel) this._activeLabel.style("display", "none");
        this._brushGroup.call(this._brush.move, null);
      } else if (event.type === "end") {
        this._ranges = ranges;
        this._renderRanges();
      }
    }

    _selectionToRange(selection) {
      return selection.map((value) => this._xScale.invert(value));
    }

    _rangesForBrush(range, event) {
      const append =
        event &&
        event.sourceEvent &&
        event.sourceEvent.shiftKey &&
        this._ranges.length > 0;

      return this._normalizeRanges(
        append ? this._ranges.concat([range]) : [range],
      );
    }

    _normalizeRanges(ranges) {
      if (
        Array.isArray(ranges) &&
        ranges.length === 2 &&
        !Array.isArray(ranges[0])
      ) {
        ranges = [ranges];
      }

      const normalized = ranges
        .filter((range) => Array.isArray(range) && range.length === 2)
        .map((range) => {
          const start = new Date(range[0]);
          const end = new Date(range[1]);
          return start <= end ? [start, end] : [end, start];
        })
        .filter((range) => range[0].getTime() !== range[1].getTime())
        .sort((a, b) => a[0] - b[0]);

      return normalized.reduce((merged, range) => {
        const previous = merged[merged.length - 1];
        if (previous && range[0] <= previous[1]) {
          if (range[1] > previous[1]) previous[1] = range[1];
        } else {
          merged.push(range);
        }
        return merged;
      }, []);
    }

    _renderRanges() {
      if (!this._rangeOverlay || !this._xScale) return;

      // 1. Render selection rectangles
      const rects = this._rangeOverlay
        .selectAll(".mapgl-selected-range")
        .data(this._ranges);

      rects
        .enter()
        .append("rect")
        .attr("class", "mapgl-selected-range")
        .merge(rects)
        .attr("x", (d) => this._xScale(d[0]))
        .attr("y", 0)
        .attr("width", (d) =>
          Math.max(1, this._xScale(d[1]) - this._xScale(d[0])),
        )
        .attr("height", this._innerHeight);

      rects.exit().remove();

      // 2. Render left resize handles (west)
      const handlesW = this._rangeOverlay
        .selectAll(".mapgl-range-handle-w")
        .data(this._ranges);

      handlesW
        .enter()
        .append("rect")
        .attr("class", "mapgl-range-handle mapgl-range-handle-w")
        .merge(handlesW)
        .attr("x", (d) => this._xScale(d[0]) - 3)
        .attr("y", 0)
        .attr("width", 6)
        .attr("height", this._innerHeight);

      handlesW.exit().remove();

      // 3. Render right resize handles (east)
      const handlesE = this._rangeOverlay
        .selectAll(".mapgl-range-handle-e")
        .data(this._ranges);

      handlesE
        .enter()
        .append("rect")
        .attr("class", "mapgl-range-handle mapgl-range-handle-e")
        .merge(handlesE)
        .attr("x", (d) => this._xScale(d[1]) - 3)
        .attr("y", 0)
        .attr("width", 6)
        .attr("height", this._innerHeight);

      handlesE.exit().remove();

      // 4. Compute vertical positions (above/below) dynamically based on overlaps
      const positions = [];
      let lastAboveRight = -Infinity;
      const padding = 12; // safety margin between labels

      for (let i = 0; i < this._ranges.length; i++) {
        const d = this._ranges[i];
        const text = this._formatRange(d);
        const textWidth = text.length * 6; // approximate text width
        const cx = this._xScale(d[0]) + (this._xScale(d[1]) - this._xScale(d[0])) / 2;
        const left = cx - textWidth / 2;
        const right = cx + textWidth / 2;

        if (left < lastAboveRight + padding) {
          positions.push("below");
        } else {
          positions.push("above");
          lastAboveRight = right;
        }
      }

      // 5. Render text labels hovering above/below
      const labels = this._rangeOverlay
        .selectAll(".mapgl-range-label")
        .data(this._ranges);

      labels
        .enter()
        .append("text")
        .attr("class", "mapgl-range-label")
        .attr("text-anchor", "middle")
        .merge(labels)
        .attr("x", (d) => {
          const x0 = this._xScale(d[0]);
          const x1 = this._xScale(d[1]);
          return x0 + (x1 - x0) / 2;
        })
        .attr("y", (d, i) => {
          const pos = positions[i] || "above";
          return pos === "above" ? -10 : this._innerHeight + 32;
        })
        .text((d) => this._formatRange(d));

      labels.exit().remove();

      this._setupRangeDrag();
    }

    _formatRange(range) {
      const d3 = window.d3;
      if (!d3) return "";
      const fmt = d3.timeFormat("%H:%M");
      const dateFmt = d3.timeFormat("%b %d");
      const fullFmt = d3.timeFormat("%Y-%m-%d %H:%M");
      if (this.options.interval === "day") {
        return `${dateFmt(range[0])} — ${dateFmt(range[1])}`;
      } else if (range[0].toDateString() === range[1].toDateString()) {
        // When it's only one day, omit the date before time to save space!
        return `${fmt(range[0])} — ${fmt(range[1])}`;
      } else {
        return `${fullFmt(range[0])} — ${fullFmt(range[1])}`;
      }
    }

    _setupRangeDrag() {
      const d3 = window.d3;
      if (!d3 || !this._rangeOverlay) return;

      const rects = this._rangeOverlay.selectAll(".mapgl-selected-range");
      const handlesW = this._rangeOverlay.selectAll(".mapgl-range-handle-w");
      const handlesE = this._rangeOverlay.selectAll(".mapgl-range-handle-e");

      // 1. Drag main selection to move
      const dragRect = d3.drag()
        .on("start", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          event.subject.originalRange = [new Date(d[0]), new Date(d[1])];
          event.subject.startX = event.x;
        })
        .on("drag", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          const dx = event.x - event.subject.startX;

          // Convert dx (pixels) to time offset (ms) using scale
          const startX = this._xScale(event.subject.originalRange[0]) + dx;

          // Constrain within scale limits [0, innerWidth]
          const minX = 0;
          const maxX = this._innerWidth;
          const widthPx = this._xScale(event.subject.originalRange[1]) - this._xScale(event.subject.originalRange[0]);

          let newStartX = startX;
          if (newStartX < minX) {
            newStartX = minX;
          } else if (newStartX + widthPx > maxX) {
            newStartX = maxX - widthPx;
          }

          const newStart = this._xScale.invert(newStartX);
          const newEnd = this._xScale.invert(newStartX + widthPx);

          // Mutate the range bounds in place so references remain valid
          d[0] = newStart;
          d[1] = newEnd;

          // Re-render immediately during drag to update positions and text
          this._renderRanges();
          this._updateLabel(this._ranges);
          this._applyFilter(this._ranges);
          this._emit("change", this._ranges);
        })
        .on("end", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          // Normalize (and merge overlapping ranges) on mouseup/end
          this._ranges = this._normalizeRanges(this._ranges);
          this._renderRanges();
          this._updateLabel(this._ranges);
          this._applyFilter(this._ranges);
          this._emit("change", this._ranges);
        });

      rects.call(dragRect);

      // 2. Drag left handle to resize start boundary
      const dragLeft = d3.drag()
        .on("start", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          event.subject.originalEnd = new Date(d[1]);
        })
        .on("drag", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          let newX = event.x;
          // Constrain: must be between 0 and the right boundary (leaving min 5px width)
          const minX = 0;
          const maxX = this._xScale(event.subject.originalEnd) - 5;
          if (newX < minX) newX = minX;
          if (newX > maxX) newX = maxX;

          const newStart = this._xScale.invert(newX);

          d[0] = newStart;
          d[1] = event.subject.originalEnd;

          this._renderRanges();
          this._updateLabel(this._ranges);
          this._applyFilter(this._ranges);
          this._emit("change", this._ranges);
        })
        .on("end", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          this._ranges = this._normalizeRanges(this._ranges);
          this._renderRanges();
          this._updateLabel(this._ranges);
          this._applyFilter(this._ranges);
          this._emit("change", this._ranges);
        });

      handlesW.call(dragLeft);

      // 3. Drag right handle to resize end boundary
      const dragRight = d3.drag()
        .on("start", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          event.subject.originalStart = new Date(d[0]);
        })
        .on("drag", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          let newX = event.x;
          // Constrain: must be between left boundary (leaving min 5px width) and full width
          const minX = this._xScale(event.subject.originalStart) + 5;
          const maxX = this._innerWidth;
          if (newX < minX) newX = minX;
          if (newX > maxX) newX = maxX;

          const newEnd = this._xScale.invert(newX);

          d[0] = event.subject.originalStart;
          d[1] = newEnd;

          this._renderRanges();
          this._updateLabel(this._ranges);
          this._applyFilter(this._ranges);
          this._emit("change", this._ranges);
        })
        .on("end", (event, d) => {
          if (event.sourceEvent) {
            event.sourceEvent.preventDefault();
            event.sourceEvent.stopPropagation();
          }
          this._ranges = this._normalizeRanges(this._ranges);
          this._renderRanges();
          this._updateLabel(this._ranges);
          this._applyFilter(this._ranges);
          this._emit("change", this._ranges);
        });

      handlesE.call(dragRight);
    }

    _getIntervalMs() {
      switch (this.options.interval) {
        case "hour": return 3600000;
        case "day": return 86400000;
        default: return 3600000;
      }
    }

    _applyFilter(ranges) {
      if (!this._map) return;
      const ids = this._resolveTargetIds();
      ids.forEach((id) => this._applyToLayer(id, ranges));
    }

    _resolveTargetIds() {
      const explicit = this.options.targetLayerIds;
      if (Array.isArray(explicit) && explicit.length > 0) {
        return explicit.filter((s) => typeof s === "string");
      }
      // Default: all flowmap layers
      const map = this._map;
      if (map && map._mapglFlowmapLayers) {
        return map._mapglFlowmapLayers.map((l) => l.id);
      }
      return [];
    }

    _applyToLayer(id, ranges) {
      const map = this._map;
      const normalizedRanges = this._normalizeRanges(ranges);
      if (normalizedRanges.length === 0) return;

      // Flowmap layer?
      if (
        window.MapGLFlowmapPlugin &&
        typeof window.MapGLFlowmapPlugin.hasLayer === "function" &&
        window.MapGLFlowmapPlugin.hasLayer(map, id)
      ) {
        const selectedTimeRanges = normalizedRanges.map((range) => [
          range[0].toISOString(),
          range[1].toISOString(),
        ]);
        const filter =
          selectedTimeRanges.length === 1
            ? {
                selectedTimeRange: selectedTimeRanges[0],
                selectedTimeRanges: null,
              }
            : {
                selectedTimeRange: null,
                selectedTimeRanges: selectedTimeRanges,
              };
        window.MapGLFlowmapPlugin.setFilter(map, id, filter);
        return;
      }

      // Native map layer
      if (typeof map.getLayer !== "function" || !map.getLayer(id)) return;
      const clauses = normalizedRanges.map((range) =>
        this._nativeRangeFilter(range),
      );
      const filter = clauses.length === 1 ? clauses[0] : ["any", ...clauses];
      try {
        map.setFilter(id, filter);
      } catch (e) {
        console.warn("time-control: failed to setFilter on", id, e);
      }
    }

    _nativeRangeFilter(range) {
      const prop = this.options.featureTimeProperty;
      const fmt = this.options.featureTimeFormat;
      let lo, hi;
      if (fmt === "epoch_ms") {
        lo = range[0].getTime();
        hi = range[1].getTime();
      } else if (fmt === "epoch_s") {
        lo = Math.floor(range[0].getTime() / 1000);
        hi = Math.floor(range[1].getTime() / 1000);
      } else {
        lo = range[0].toISOString();
        hi = range[1].toISOString();
      }
      const numericGet =
        fmt === "epoch_ms" || fmt === "epoch_s"
          ? ["to-number", ["get", prop]]
          : ["get", prop];
      return [
        "all",
        [">=", numericGet, lo],
        ["<", numericGet, hi],
      ];
    }

    _updateLabel(ranges) {
      const d3 = window.d3;
      if (!d3) return;
      const normalizedRanges = this._normalizeRanges(ranges);
      if (normalizedRanges.length === 0) return;

      if (normalizedRanges.length > 1) {
        this._label.innerText = `${normalizedRanges.length} selected ranges`;
        return;
      }

      const range = normalizedRanges[0];
      const fmt = d3.timeFormat("%H:%M");
      const dateFmt = d3.timeFormat("%b %d");
      const fullFmt = d3.timeFormat("%Y-%m-%d %H:%M");
      if (this.options.interval === "day") {
        this._label.innerText = `${dateFmt(range[0])} — ${dateFmt(range[1])}`;
      } else if (range[0].toDateString() === range[1].toDateString()) {
        this._label.innerText = `${dateFmt(range[0])} ${fmt(range[0])} — ${fmt(range[1])}`;
      } else {
        this._label.innerText = `${fullFmt(range[0])} — ${fullFmt(range[1])}`;
      }
    }

    toggle() { if (this._isPlaying) this.pause(); else this.play(); }
    play() {
      if (this._isPlaying) return;
      this._isPlaying = true;
      this._playBtn.innerHTML = this._getPauseIcon();
      const d3 = window.d3;
      if (d3) {
        const selection = d3.brushSelection(this._brushGroup.node());
        if (!selection && this._ranges && this._ranges.length > 0) {
          const r = this._ranges[0];
          this._brushGroup.call(this._brush.move, [this._xScale(r[0]), this._xScale(r[1])]);
        }
      }
      this._animate();
      this._emit("play");
    }
    pause() {
      if (!this._isPlaying) return;
      this._isPlaying = false;
      this._playBtn.innerHTML = this._getPlayIcon();
      if (this._animationFrame) cancelAnimationFrame(this._animationFrame);
      this._brushGroup.call(this._brush.move, null);
      this._emit("pause");
    }
    _animate() {
      if (!this._isPlaying) return;
      const d3 = window.d3;
      if (!d3) return;
      const selection = d3.brushSelection(this._brushGroup.node());
      if (!selection) return;
      const width = selection[1] - selection[0];
      let nextStart = selection[0] + 1.5;
      if (nextStart + width > this._innerWidth) {
        if (this.options.loop) nextStart = 0;
        else { this.pause(); return; }
      }
      this._brushGroup.call(this._brush.move, [nextStart, nextStart + width]);
      this._animationFrame = requestAnimationFrame(() => this._animate());
    }
    _getPlayIcon() { return `<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>`; }
    _getPauseIcon() { return `<svg viewBox="0 0 24 24"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>`; }
    on(event, cb) { (this._listeners[event] ||= []).push(cb); }
    _emit(event, data) { (this._listeners[event] || []).forEach((cb) => cb(data)); }
  }

  function addControl(map, config) {
    const tc = new TimeControl(config);
    const floating = config.draggable || config.position === "bottom-center";
    if (floating) {
      tc.onAdd(map);
    } else {
      map.addControl(tc, config.position);
    }
    if (!map.controls) map.controls = [];
    map.controls.push({ type: "timeControl", control: tc });
    if (config.autoplay) setTimeout(() => tc.play(), 2000);
    return tc;
  }

  window.MapGLTimeControlPlugin = {
    init: function (map, x) {
      if (x.time_controls && x.time_controls.length > 0) {
        x.time_controls.forEach((config) => addControl(map, config));
      }
    },
    handleMessage: function (map, message) {
      if (message.type === "add_time_control") {
        addControl(map, message);
        return true;
      }
      return false;
    },
  };
  window.MapGLTimeControl = TimeControl;
})();
