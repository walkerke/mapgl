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
      this._isCollapsed = !!this.options.collapsed;
    }

    onAdd(map) {
      this._map = map;
      const opts = this.options;

      this._container = document.createElement("div");
      this._container.className =
        "mapgl-time-control-container maplibregl-ctrl mapboxgl-ctrl";

      if (opts.darkMode) this._container.classList.add("dark-mode");
      if (opts.draggable) this._container.classList.add("is-draggable");
      if (opts.collapsible) this._container.classList.add("is-collapsible");

      // Header (only present when draggable, collapsible, or titled)
      const showHeader = opts.draggable || opts.collapsible || !!opts.title;
      if (showHeader) {
        this._header = document.createElement("div");
        this._header.className = "mapgl-time-header";

        this._dragHandle = document.createElement("span");
        this._dragHandle.className = "mapgl-time-drag";
        this._dragHandle.innerHTML = opts.draggable
          ? '<svg viewBox="0 0 24 24" width="14" height="14"><circle cx="9" cy="6" r="1.5"/><circle cx="15" cy="6" r="1.5"/><circle cx="9" cy="12" r="1.5"/><circle cx="15" cy="12" r="1.5"/><circle cx="9" cy="18" r="1.5"/><circle cx="15" cy="18" r="1.5"/></svg>'
          : "";

        const titleEl = document.createElement("span");
        titleEl.className = "mapgl-time-title";
        titleEl.textContent = opts.title || "";

        this._collapseBtn = document.createElement("button");
        this._collapseBtn.className = "mapgl-time-collapse-btn";
        this._collapseBtn.type = "button";
        this._collapseBtn.innerHTML = this._caretIcon();
        this._collapseBtn.onclick = () => this.toggleCollapse();
        if (!opts.collapsible) this._collapseBtn.style.display = "none";

        this._header.appendChild(this._dragHandle);
        this._header.appendChild(titleEl);
        this._header.appendChild(this._collapseBtn);
        this._container.appendChild(this._header);
      }

      // Body (holds play button + chart)
      this._body = document.createElement("div");
      this._body.className = "mapgl-time-body";

      this._playBtn = document.createElement("button");
      this._playBtn.type = "button";
      this._playBtn.className = "mapgl-time-play-btn";
      this._playBtn.innerHTML = this._getPlayIcon();
      this._playBtn.onclick = () => this.toggle();

      const wrapper = document.createElement("div");
      wrapper.className = "mapgl-timeline-wrapper";

      this._label = document.createElement("div");
      this._label.className = "mapgl-current-range-label";
      wrapper.appendChild(this._label);

      this._svgNode = document.createElementNS(
        "http://www.w3.org/2000/svg",
        "svg",
      );
      wrapper.appendChild(this._svgNode);

      this._body.appendChild(this._playBtn);
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

    _caretIcon() {
      return this._isCollapsed
        ? '<svg viewBox="0 0 24 24" width="14" height="14"><path d="M7 10l5 5 5-5z"/></svg>'
        : '<svg viewBox="0 0 24 24" width="14" height="14"><path d="M7 14l5-5 5 5z"/></svg>';
    }

    toggleCollapse() {
      this._isCollapsed = !this._isCollapsed;
      this._container.classList.toggle("is-collapsed", this._isCollapsed);
      if (this._collapseBtn) this._collapseBtn.innerHTML = this._caretIcon();
    }

    _setupDrag() {
      const handle = this._header || this._container;
      handle.style.cursor = "move";
      let startX, startY, originLeft, originTop;
      const onDown = (e) => {
        // Only start drag from header / drag handle area, not buttons inside header
        if (e.target.closest("button")) return;
        e.preventDefault();
        const rect = this._container.getBoundingClientRect();
        const parentRect = this._map.getContainer().getBoundingClientRect();
        originLeft = rect.left - parentRect.left;
        originTop = rect.top - parentRect.top;
        startX = e.clientX;
        startY = e.clientY;
        this._container.style.bottom = "auto";
        this._container.style.right = "auto";
        this._container.style.left = originLeft + "px";
        this._container.style.top = originTop + "px";
        document.addEventListener("mousemove", onMove);
        document.addEventListener("mouseup", onUp);
      };
      const onMove = (e) => {
        const dx = e.clientX - startX;
        const dy = e.clientY - startY;
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
      const height = 80;
      const margin = { top: 10, right: 10, bottom: 22, left: 10 };
      const innerWidth = width - margin.left - margin.right;
      const innerHeight = height - margin.top - margin.bottom;
      if (innerWidth <= 0) return;

      const svg = d3
        .select(this._svgNode)
        .attr("width", width)
        .attr("height", height);
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
      g.append("g")
        .attr("class", "mapgl-axis")
        .attr("transform", `translate(0,${innerHeight})`)
        .call(d3.axisBottom(x).ticks(6).tickFormat(timeFormat));

      this._brush = d3
        .brushX()
        .extent([
          [0, 0],
          [innerWidth, innerHeight],
        ])
        .on("brush end", (event) => {
          if (!event.selection) return;
          const [s0, s1] = event.selection;
          if (this._capTop) {
            this._capTop.attr("x", s0).attr("width", s1 - s0);
            this._capBottom.attr("x", s0).attr("width", s1 - s0);
          }
          const range = event.selection.map(x.invert);
          this._currentRange = range;
          this._updateLabel(range);
          this._emit("change", range);
          this._applyFilter(range);
        });
      this._brushGroup = g
        .append("g")
        .attr("class", "mapgl-brush")
        .call(this._brush);

      this._capTop = this._brushGroup
        .append("rect")
        .attr("class", "mapgl-brush-cap")
        .attr("y", -3)
        .attr("height", 6)
        .attr("rx", 3);
      this._capBottom = this._brushGroup
        .append("rect")
        .attr("class", "mapgl-brush-cap")
        .attr("y", innerHeight - 3)
        .attr("height", 6)
        .attr("rx", 3);

      let initialSelection;
      if (this.options.initialRange) {
        initialSelection = [
          x(new Date(this.options.initialRange[0])),
          x(new Date(this.options.initialRange[1])),
        ];
      } else {
        const start = bins[0].time;
        const end = new Date(
          start.getTime() + Math.min(3, bins.length) * intervalMs,
        );
        initialSelection = [x(start), x(end)];
      }
      this._brushGroup.call(this._brush.move, initialSelection);

      this._xScale = x;
      this._innerWidth = innerWidth;
    }

    _getIntervalMs() {
      switch (this.options.interval) {
        case "hour": return 3600000;
        case "day": return 86400000;
        default: return 3600000;
      }
    }

    _applyFilter(range) {
      if (!this._map) return;
      const ids = this._resolveTargetIds();
      ids.forEach((id) => this._applyToLayer(id, range));
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

    _applyToLayer(id, range) {
      const map = this._map;
      // Flowmap layer?
      if (
        window.MapGLFlowmapPlugin &&
        typeof window.MapGLFlowmapPlugin.hasLayer === "function" &&
        window.MapGLFlowmapPlugin.hasLayer(map, id)
      ) {
        window.MapGLFlowmapPlugin.setFilter(map, id, {
          selectedTimeRange: range,
        });
        return;
      }
      // Native map layer
      if (typeof map.getLayer !== "function" || !map.getLayer(id)) return;
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
      const filter = [
        "all",
        [">=", numericGet, lo],
        ["<", numericGet, hi],
      ];
      try {
        map.setFilter(id, filter);
      } catch (e) {
        console.warn("time-control: failed to setFilter on", id, e);
      }
    }

    _updateLabel(range) {
      const d3 = window.d3;
      if (!d3) return;
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
      this._animate();
      this._emit("play");
    }
    pause() {
      if (!this._isPlaying) return;
      this._isPlaying = false;
      this._playBtn.innerHTML = this._getPlayIcon();
      if (this._animationFrame) cancelAnimationFrame(this._animationFrame);
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
