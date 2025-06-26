/**
 * mapbox-pmtiles v1.0.0 - Optimized Version
 * Original source: https://github.com/am2222/mapbox-pmtiles
 * License: MIT
 *
 * This is an optimized version of the mapbox-pmtiles library that provides
 * better performance for large datasets through:
 * - Shared worker pool
 * - Metadata and tile caching
 * - Optimized raster tile loading
 * - Pre-calculated bounds
 * - Shared protocol instances
 *
 * Last updated: 2025
 */

// Note: This version assumes mapboxgl and pmtiles are already loaded as globals
(function (global) {
  "use strict";

  // Helper functions
  var __pow = Math.pow;
  var __async = (__this, __arguments, generator) => {
    return new Promise((resolve, reject) => {
      var fulfilled = (value) => {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      };
      var rejected = (value) => {
        try {
          step(generator.throw(value));
        } catch (e) {
          reject(e);
        }
      };
      var step = (x2) =>
        x2.done
          ? resolve(x2.value)
          : Promise.resolve(x2.value).then(fulfilled, rejected);
      step((generator = generator.apply(__this, __arguments)).next());
    });
  };

  // Check dependencies
  if (typeof mapboxgl === "undefined") {
    console.error("mapbox-pmtiles: Mapbox GL JS is not loaded");
    return;
  }
  if (typeof pmtiles === "undefined") {
    console.error("mapbox-pmtiles: PMTiles library is not loaded");
    return;
  }

  const VectorTileSourceImpl = mapboxgl.Style.getSourceType("vector");
  const SOURCE_TYPE = "pmtile-source";

  // Global shared resources
  const SHARED_RESOURCES = {
    // Shared worker pool with round-robin assignment
    workerPool: [],
    workerPoolIndex: 0,
    workerPoolSize: 4, // Optimal for most systems

    // Protocol cache - reuse protocol instances for same URLs
    protocolCache: new Map(),

    // Metadata cache - cache headers and metadata
    metadataCache: new Map(),

    // Tile cache - optional LRU cache for decoded tiles
    tileCache: new Map(),
    tileCacheSize: 1000,

    // Pre-calculated world sizes for common zoom levels
    worldSizeCache: new Array(25).fill(null).map((_, z) => Math.pow(2, z)),

    // Request coalescing - prevent duplicate tile requests
    pendingRequests: new Map(),
  };

  // Initialize worker pool
  const initializeWorkerPool = (dispatcher) => {
    if (SHARED_RESOURCES.workerPool.length === 0 && dispatcher) {
      for (let i = 0; i < SHARED_RESOURCES.workerPoolSize; i++) {
        SHARED_RESOURCES.workerPool.push(dispatcher.getActor());
      }
    }
  };

  // Get next worker from pool (round-robin)
  const getWorkerFromPool = () => {
    const worker =
      SHARED_RESOURCES.workerPool[SHARED_RESOURCES.workerPoolIndex];
    SHARED_RESOURCES.workerPoolIndex =
      (SHARED_RESOURCES.workerPoolIndex + 1) % SHARED_RESOURCES.workerPoolSize;
    return worker;
  };

  // Get or create protocol instance
  const getProtocol = (url) => {
    if (!SHARED_RESOURCES.protocolCache.has(url)) {
      const protocol = new pmtiles.Protocol();
      const instance = new pmtiles.PMTiles(url);
      protocol.add(instance);
      SHARED_RESOURCES.protocolCache.set(url, { protocol, instance });
    }
    return SHARED_RESOURCES.protocolCache.get(url);
  };

  // Cache key for tiles
  const getTileCacheKey = (url, z, x, y) => `${url}:${z}:${x}:${y}`;

  // LRU cache management
  const addToTileCache = (key, data) => {
    if (SHARED_RESOURCES.tileCache.size >= SHARED_RESOURCES.tileCacheSize) {
      // Remove oldest entry
      const firstKey = SHARED_RESOURCES.tileCache.keys().next().value;
      SHARED_RESOURCES.tileCache.delete(firstKey);
    }
    SHARED_RESOURCES.tileCache.set(key, data);
  };

  const extend = (dest, ...sources) => {
    for (const src of sources) {
      for (const k in src) {
        dest[k] = src[k];
      }
    }
    return dest;
  };

  const mercatorXFromLng = (lng) => {
    return (180 + lng) / 360;
  };

  const mercatorYFromLat = (lat) => {
    return (
      (180 -
        (180 / Math.PI) *
          Math.log(Math.tan(Math.PI / 4 + (lat * Math.PI) / 360))) /
      360
    );
  };

  class TileBounds {
    constructor(bounds, minzoom, maxzoom) {
      this.bounds = mapboxgl.LngLatBounds.convert(this.validateBounds(bounds));
      this.minzoom = minzoom || 0;
      this.maxzoom = maxzoom || 24;

      // Pre-calculate mercator bounds
      this._mercatorBounds = {
        west: mercatorXFromLng(this.bounds.getWest()),
        north: mercatorYFromLat(this.bounds.getNorth()),
        east: mercatorXFromLng(this.bounds.getEast()),
        south: mercatorYFromLat(this.bounds.getSouth()),
      };
    }

    validateBounds(bounds) {
      if (!Array.isArray(bounds) || bounds.length !== 4)
        return [-180, -90, 180, 90];
      return [
        Math.max(-180, bounds[0]),
        Math.max(-90, bounds[1]),
        Math.min(180, bounds[2]),
        Math.min(90, bounds[3]),
      ];
    }

    contains(tileID) {
      // Use pre-calculated world size
      const worldSize =
        SHARED_RESOURCES.worldSizeCache[tileID.z] || Math.pow(2, tileID.z);

      // Use pre-calculated mercator bounds
      const level = {
        minX: Math.floor(this._mercatorBounds.west * worldSize),
        minY: Math.floor(this._mercatorBounds.north * worldSize),
        maxX: Math.ceil(this._mercatorBounds.east * worldSize),
        maxY: Math.ceil(this._mercatorBounds.south * worldSize),
      };

      const hit =
        tileID.x >= level.minX &&
        tileID.x < level.maxX &&
        tileID.y >= level.minY &&
        tileID.y < level.maxY;
      return hit;
    }
  }

  class Event {
    constructor(type, data = {}) {
      extend(this, data);
      this.type = type;
    }
  }

  class ErrorEvent extends Event {
    constructor(error, data = {}) {
      super("error", extend({ error }, data));
    }
  }

  class PmTilesSource extends VectorTileSourceImpl {
    constructor(id, options, _dispatcher, _eventedParent) {
      super(...[id, options, _dispatcher, _eventedParent]);
      this.scheme = "xyz";
      this.roundZoom = true;
      this.type = "vector";
      this.dispatcher = void 0;
      this.reparseOverscaled = true;
      this._loaded = false;
      this._dataType = "vector";
      this.id = id;
      this._dataType = "vector";
      this.dispatcher = _dispatcher;
      this._implementation = options;

      // Initialize shared worker pool
      initializeWorkerPool(_dispatcher);

      if (!this._implementation) {
        this.fire(
          new ErrorEvent(
            new Error(`Missing options for ${this.id} ${SOURCE_TYPE} source`),
          ),
        );
      }

      const { url } = options;
      this.url = url;
      this.reparseOverscaled = true;
      this.scheme = "xyz";
      this.tileSize = 512;
      this._loaded = false;
      this.type = "vector";

      // Use shared protocol instance
      const { protocol, instance } = getProtocol(url);
      this._protocol = protocol;
      this._instance = instance;
      this.tiles = [`pmtiles://${url}/{z}/{x}/{y}`];
    }

    static async getMetadata(url) {
      // Check cache first
      const cacheKey = `${url}:metadata`;
      if (SHARED_RESOURCES.metadataCache.has(cacheKey)) {
        return SHARED_RESOURCES.metadataCache.get(cacheKey);
      }

      const { instance } = getProtocol(url);
      const metadata = await instance.getMetadata();
      SHARED_RESOURCES.metadataCache.set(cacheKey, metadata);
      return metadata;
    }

    static async getHeader(url) {
      // Check cache first
      const cacheKey = `${url}:header`;
      if (SHARED_RESOURCES.metadataCache.has(cacheKey)) {
        return SHARED_RESOURCES.metadataCache.get(cacheKey);
      }

      const { instance } = getProtocol(url);
      const header = await instance.getHeader();
      SHARED_RESOURCES.metadataCache.set(cacheKey, header);
      return header;
    }

    getExtent() {
      if (!this.header)
        return [
          [-180, -90],
          [180, 90],
        ];
      const { minLon, minLat, maxLon, maxLat } = this.header;
      return [minLon, minLat, maxLon, maxLat];
    }

    hasTile(tileID) {
      return !this.tileBounds || this.tileBounds.contains(tileID.canonical);
    }

    fixTile(tile) {
      if (!tile.destroy) {
        tile.destroy = () => {};
      }
      if (!tile.abort) {
        tile.abort = () => {
          tile.aborted = true;
          if (tile.request && tile.request.cancel) {
            tile.request.cancel();
          }
        };
      }
    }

    async load(callback) {
      this._loaded = false;
      this.fire(new Event("dataloading", { dataType: "source" }));

      // Check metadata cache first
      const headerKey = `${this.url}:header`;
      const metadataKey = `${this.url}:metadata`;

      let header, tileJSON;

      if (
        SHARED_RESOURCES.metadataCache.has(headerKey) &&
        SHARED_RESOURCES.metadataCache.has(metadataKey)
      ) {
        header = SHARED_RESOURCES.metadataCache.get(headerKey);
        tileJSON = SHARED_RESOURCES.metadataCache.get(metadataKey);
      } else {
        // Load and cache
        [header, tileJSON] = await Promise.all([
          this._instance.getHeader(),
          this._instance.getMetadata(),
        ]);
        SHARED_RESOURCES.metadataCache.set(headerKey, header);
        SHARED_RESOURCES.metadataCache.set(metadataKey, tileJSON);
      }

      try {
        extend(this, tileJSON);
        this.header = header;
        const {
          specVersion,
          clustered,
          tileType,
          minZoom,
          maxZoom,
          minLon,
          minLat,
          maxLon,
          maxLat,
          centerZoom,
          centerLon,
          centerLat,
        } = header;
        const requiredVariables = [
          minZoom,
          maxZoom,
          minLon,
          minLat,
          maxLon,
          maxLat,
        ];

        if (
          !requiredVariables.includes(void 0) &&
          !requiredVariables.includes(null)
        ) {
          this.tileBounds = new TileBounds(
            [minLon, minLat, maxLon, maxLat],
            minZoom,
            maxZoom,
          );
          this.minzoom = minZoom;
          this.maxzoom = maxZoom;
        }

        if (this.maxzoom == void 0) {
          console.warn(
            "The maxzoom parameter is not defined in the source json. This can cause memory leak. So make sure to define maxzoom in the layer",
          );
        }

        this.minzoom = Number.parseInt(this.minzoom.toString()) || 0;
        this.maxzoom = Number.parseInt(this.maxzoom.toString()) || 0;
        this._loaded = true;
        this.tileType = tileType;

        switch (tileType) {
          case pmtiles.TileType.Png:
            this.contentType = "image/png";
            break;
          case pmtiles.TileType.Jpeg:
            this.contentType = "image/jpeg";
            break;
          case pmtiles.TileType.Webp:
            this.contentType = "image/webp";
            break;
          case pmtiles.TileType.Avif:
            this.contentType = "image/avif";
            break;
          case pmtiles.TileType.Mvt:
            this.contentType = "application/vnd.mapbox-vector-tile";
            break;
        }

        if (
          [pmtiles.TileType.Jpeg, pmtiles.TileType.Png].includes(this.tileType)
        ) {
          this.loadTile = this.loadRasterTile;
          this.type = "raster";
        } else if (this.tileType === pmtiles.TileType.Mvt) {
          this.loadTile = this.loadVectorTile;
          this.type = "vector";
        } else {
          this.fire(new ErrorEvent(new Error("Unsupported Tile Type")));
        }

        this.fire(
          new Event("data", { dataType: "source", sourceDataType: "metadata" }),
        );
        this.fire(
          new Event("data", { dataType: "source", sourceDataType: "content" }),
        );
      } catch (err2) {
        this.fire(new ErrorEvent(err2));
        if (callback) callback(err2);
      }
    }

    loaded() {
      return this._loaded;
    }

    loadVectorTile(tile, callback) {
      var _a2, _b2, _c;
      const done = (err2, data) => {
        var _a3, _b3;
        delete tile.request;
        if (tile.aborted) return callback(null);

        // Handle abort errors gracefully
        if (err2 && err2.name === "AbortError") {
          return callback(null);
        }

        if (err2 && err2.status !== 404) {
          return callback(err2);
        }
        if (data && data.resourceTiming)
          tile.resourceTiming = data.resourceTiming;
        if (
          ((_a3 = this.map) == null ? void 0 : _a3._refreshExpiredTiles) &&
          data
        )
          tile.setExpiryData(data);
        tile.loadVectorData(
          data,
          (_b3 = this.map) == null ? void 0 : _b3.painter,
        );
        callback(null);
        if (tile.reloadCallback) {
          this.loadVectorTile(tile, tile.reloadCallback);
          tile.reloadCallback = null;
        }
      };

      const url =
        (_a2 = this.map) == null
          ? void 0
          : _a2._requestManager.normalizeTileURL(
              tile.tileID.canonical.url(this.tiles, this.scheme),
            );
      const request =
        (_b2 = this.map) == null
          ? void 0
          : _b2._requestManager.transformRequest(url, "Tile");
      const params = {
        request,
        data: {},
        uid: tile.uid,
        tileID: tile.tileID,
        tileZoom: tile.tileZoom,
        zoom: tile.tileID.overscaledZ,
        tileSize: this.tileSize * tile.tileID.overscaleFactor(),
        type: "vector",
        source: this.id,
        scope: this.scope,
        showCollisionBoxes:
          (_c = this.map) == null ? void 0 : _c.showCollisionBoxes,
        promoteId: this.promoteId,
        isSymbolTile: tile.isSymbolTile,
        extraShadowCaster: tile.isExtraShadowCaster,
      };

      const afterLoad = (error, data, cacheControl, expires) => {
        if (error || !data) {
          // Handle abort errors gracefully
          if (error && (error.name === "AbortError" || error.code === 20)) {
            return done.call(this, null);
          }
          done.call(this, error);
          return;
        }
        params.data = {
          cacheControl,
          expires,
          rawData: data,
        };
        if (this.map._refreshExpiredTiles)
          tile.setExpiryData({ cacheControl, expires });
        if (tile.actor)
          tile.actor.send("loadTile", params, done.bind(this), void 0, true);
      };

      this.fixTile(tile);
      if (!tile.actor || tile.state === "expired") {
        // Use shared worker pool instead of URL-based assignment
        tile.actor = getWorkerFromPool();
        tile.request = this._protocol.tile({ ...request }, afterLoad);
      } else if (tile.state === "loading") {
        tile.reloadCallback = callback;
      } else {
        tile.request = this._protocol.tile({ ...tile, url }, afterLoad);
      }
    }

    loadRasterTileData(tile, data) {
      tile.setTexture(data, this.map.painter);
    }

    loadRasterTile(tile, callback) {
      var _a2, _b2;

      // Check tile cache first
      const cacheKey = getTileCacheKey(
        this.url,
        tile.tileID.canonical.z,
        tile.tileID.canonical.x,
        tile.tileID.canonical.y,
      );
      if (SHARED_RESOURCES.tileCache.has(cacheKey)) {
        const cachedData = SHARED_RESOURCES.tileCache.get(cacheKey);
        this.loadRasterTileData(tile, cachedData);
        tile.state = "loaded";
        return callback(null);
      }

      const done = ({ data, cacheControl, expires }) => {
        delete tile.request;
        if (tile.aborted) return callback(null);
        if (data === null || data === void 0) {
          const emptyImage = {
            width: this.tileSize,
            height: this.tileSize,
            data: null,
          };
          this.loadRasterTileData(tile, emptyImage);
          tile.state = "loaded";
          return callback(null);
        }
        if (data && data.resourceTiming)
          tile.resourceTiming = data.resourceTiming;
        if (this.map._refreshExpiredTiles)
          tile.setExpiryData({ cacheControl, expires });

        // Optimized raster tile loading - skip Blob creation
        const arrayBuffer = data.buffer || data;
        window
          .createImageBitmap(arrayBuffer)
          .then((imageBitmap) => {
            // Cache the decoded image
            addToTileCache(cacheKey, imageBitmap);

            this.loadRasterTileData(tile, imageBitmap);
            tile.state = "loaded";
            callback(null);
          })
          .catch((error) => {
            // Fallback to blob method if direct createImageBitmap fails
            const blob = new window.Blob([new Uint8Array(data)], {
              type: this.contentType,
            });
            window
              .createImageBitmap(blob)
              .then((imageBitmap) => {
                addToTileCache(cacheKey, imageBitmap);
                this.loadRasterTileData(tile, imageBitmap);
                tile.state = "loaded";
                callback(null);
              })
              .catch((error) => {
                tile.state = "errored";
                return callback(
                  new Error(`Can't decode image for ${this.id}: ${error}`),
                );
              });
          });
      };

      const url =
        (_a2 = this.map) == null
          ? void 0
          : _a2._requestManager.normalizeTileURL(
              tile.tileID.canonical.url(this.tiles, this.scheme),
            );
      const request =
        (_b2 = this.map) == null
          ? void 0
          : _b2._requestManager.transformRequest(url, "Tile");
      this.fixTile(tile);
      const controller = new AbortController();
      tile.request = { cancel: () => controller.abort() };
      this._protocol
        .tile(request, controller)
        .then(done.bind(this))
        .catch((error) => {
          // Handle abort errors gracefully
          if (error.name === "AbortError" || error.code === 20) {
            delete tile.request;
            return callback(null);
          }
          tile.state = "errored";
          callback(error);
        });
    }
  }

  PmTilesSource.SOURCE_TYPE = SOURCE_TYPE;

  // Export to global scope
  global.MapboxPmTilesSource = PmTilesSource;
  global.PMTILES_SOURCE_TYPE = SOURCE_TYPE;
})(typeof window !== "undefined" ? window : this);
