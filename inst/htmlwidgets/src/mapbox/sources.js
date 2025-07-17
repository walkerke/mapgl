/**
 * Source management for Mapbox GL JS
 * Handles all source types: vector, geojson, raster, raster-dem, image, video, custom
 */

function setupSources(map, x) {
  // Add sources if provided
  if (x.sources) {
    x.sources.forEach(function (source) {
      if (source.type === "vector") {
        const sourceOptions = {
          type: "vector",
          url: source.url,
        };
        // Add promoteId if provided
        if (source.promoteId) {
          sourceOptions.promoteId = source.promoteId;
        }
        // Add any other additional options
        for (const [key, value] of Object.entries(source)) {
          if (!["id", "type", "url"].includes(key)) {
            sourceOptions[key] = value;
          }
        }
        map.addSource(source.id, sourceOptions);
      } else if (source.type === "geojson") {
        const geojsonData = source.data;
        const sourceOptions = {
          type: "geojson",
          data: geojsonData,
          generateId: source.generateId,
        };

        // Add additional options
        for (const [key, value] of Object.entries(source)) {
          if (!["id", "type", "data", "generateId"].includes(key)) {
            sourceOptions[key] = value;
          }
        }

        map.addSource(source.id, sourceOptions);
      } else if (source.type === "raster") {
        if (source.url) {
          map.addSource(source.id, {
            type: "raster",
            url: source.url,
            tileSize: source.tileSize,
            maxzoom: source.maxzoom,
          });
        } else if (source.tiles) {
          map.addSource(source.id, {
            type: "raster",
            tiles: source.tiles,
            tileSize: source.tileSize,
            maxzoom: source.maxzoom,
          });
        }
      } else if (source.type === "raster-dem") {
        map.addSource(source.id, {
          type: "raster-dem",
          url: source.url,
          tileSize: source.tileSize,
          maxzoom: source.maxzoom,
        });
      } else if (source.type === "image") {
        map.addSource(source.id, {
          type: "image",
          url: source.url,
          coordinates: source.coordinates,
        });
      } else if (source.type === "video") {
        map.addSource(source.id, {
          type: "video",
          urls: source.urls,
          coordinates: source.coordinates,
        });
      } else {
        // Handle custom source types (like pmtile-source)
        const sourceOptions = { type: source.type };

        // Copy all properties except id
        for (const [key, value] of Object.entries(source)) {
          if (key !== "id") {
            sourceOptions[key] = value;
          }
        }

        map.addSource(source.id, sourceOptions);
      }
    });
  }
}