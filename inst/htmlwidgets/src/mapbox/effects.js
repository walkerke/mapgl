/**
 * Map effects and navigation for Mapbox GL JS
 * Handles terrain, fog, rain, snow effects, and map navigation operations
 */

function setupEffectsAndNavigation(map, x) {
  // Set terrain if provided
  if (x.terrain) {
    map.setTerrain({
      source: x.terrain.source,
      exaggeration: x.terrain.exaggeration,
    });
  }

  // Set fog
  if (x.fog) {
    map.setFog(x.fog);
  }

  // Set rain effect if provided
  if (x.rain) {
    map.setRain(x.rain);
  }

  // Set snow effect if provided
  if (x.snow) {
    map.setSnow(x.snow);
  }

  // Navigation operations
  if (x.fitBounds) {
    map.fitBounds(x.fitBounds.bounds, x.fitBounds.options);
  }
  if (x.flyTo) {
    map.flyTo(x.flyTo);
  }
  if (x.easeTo) {
    map.easeTo(x.easeTo);
  }
  if (x.setCenter) {
    map.setCenter(x.setCenter);
  }
  if (x.setZoom) {
    map.setZoom(x.setZoom);
  }
  if (x.jumpTo) {
    map.jumpTo(x.jumpTo);
  }

  // Set projection if provided
  if (x.setProjection) {
    x.setProjection.forEach(function (projectionConfig) {
      if (projectionConfig.projection) {
        map.setProjection(projectionConfig.projection);
      }
    });
  }

  // Add images if provided
  if (x.images && Array.isArray(x.images)) {
    x.images.forEach(function (imageInfo) {
      map.loadImage(imageInfo.url, function (error, image) {
        if (error) {
          console.error("Error loading image:", error);
          return;
        }
        if (!map.hasImage(imageInfo.id)) {
          map.addImage(imageInfo.id, image, imageInfo.options);
        }
      });
    });
  } else if (x.images) {
    console.error("x.images is not an array:", x.images);
  }
}