// Turf.js operations module for mapgl
// Shared operations that work with both mapboxgl and maplibre maps

// Process turf operations on map initialization (for static maps)
function processTurfOperationsOnLoad(map, turfOperations, widgetId) {
  if (!turfOperations || turfOperations.length === 0) return;
  
  // Wait for map to be fully loaded, then execute operations
  map.on('load', function() {
    // Add a small delay to ensure all layers are loaded
    setTimeout(function() {
      turfOperations.forEach(function(operation) {
        try {
          handleTurfOperation(map, operation, widgetId);
        } catch (error) {
          console.error(`Error processing turf operation ${operation.type}:`, error);
        }
      });
    }, 100);
  });
}

// Main handler for all turf operations
function handleTurfOperation(map, message, widgetId) {
  try {
    switch (message.type) {
      case "turf_buffer":
        executeTurfBuffer(map, message, widgetId);
        break;
      case "turf_union":
        executeTurfUnion(map, message, widgetId);
        break;
      case "turf_intersect":
        executeTurfIntersect(map, message, widgetId);
        break;
      case "turf_difference":
        executeTurfDifference(map, message, widgetId);
        break;
      case "turf_convex_hull":
        executeTurfConvexHull(map, message, widgetId);
        break;
      case "turf_concave_hull":
        executeTurfConcaveHull(map, message, widgetId);
        break;
      case "turf_voronoi":
        executeTurfVoronoi(map, message, widgetId);
        break;
      case "turf_distance":
        executeTurfDistance(map, message, widgetId);
        break;
      case "turf_area":
        executeTurfArea(map, message, widgetId);
        break;
      case "turf_centroid":
        executeTurfCentroid(map, message, widgetId);
        break;
      default:
        console.warn(`Unknown turf operation: ${message.type}`);
    }
  } catch (error) {
    console.error(`Error executing turf operation ${message.type}:`, error);
    if (HTMLWidgets.shinyMode && message.send_to_r) {
      Shiny.setInputValue(widgetId + "_turf_error", {
        operation: message.type,
        error: error.message,
        timestamp: Date.now()
      });
    }
  }
}

// Helper function to get input data for turf operations
function getInputData(map, message) {
  // If coordinates provided, create point or points client-side
  if (message.coordinates) {
    // Handle single coordinate pair
    if (typeof message.coordinates[0] === 'number') {
      return turf.point(message.coordinates);
    }
    // Handle multiple coordinate pairs
    if (Array.isArray(message.coordinates[0])) {
      const points = message.coordinates.map(coord => turf.point(coord));
      return {
        type: "FeatureCollection",
        features: points
      };
    }
  }
  
  // If GeoJSON data provided directly
  if (message.data) {
    // Check if data is already an object (shouldn't happen) or string
    if (typeof message.data === 'string') {
      return JSON.parse(message.data);
    } else {
      // If it's already an object, return as-is
      return message.data;
    }
  }
  
  // If layer_id provided, get from existing layer
  if (message.layer_id) {
    return getSourceData(map, message.layer_id);
  }
  
  throw new Error("No valid input data provided (coordinates, data, or layer_id)");
}

// Helper function to get source data from a layer
function getSourceData(map, layerId) {
  // First try to get from existing source
  const source = map.getSource(layerId);
  if (source && source._data) {
    return source._data;
  }
  
  // Try with _source suffix (common pattern in mapgl)
  const sourceWithSuffix = map.getSource(layerId + "_source");
  if (sourceWithSuffix && sourceWithSuffix._data) {
    return sourceWithSuffix._data;
  }
  
  // Query rendered features as fallback
  const features = map.queryRenderedFeatures({ layers: [layerId] });
  if (features.length > 0) {
    return {
      type: "FeatureCollection",
      features: features
    };
  }
  
  throw new Error(`Could not find source data for layer: ${layerId}`);
}

// Helper function to add result source to map
function addResultSource(map, result, sourceId) {
  if (!sourceId) return;
  
  // Check if source exists, update data or create new
  const existingSource = map.getSource(sourceId);
  if (existingSource) {
    // Update existing source data
    existingSource.setData(result);
  } else {
    // Add new source with result data
    map.addSource(sourceId, {
      type: "geojson",
      data: result
    });
  }
}

// Helper function to send result to R
function sendResultToR(widgetId, operation, result, metadata = {}) {
  if (HTMLWidgets.shinyMode) {
    Shiny.setInputValue(widgetId + "_turf_result", {
      operation: operation,
      result: result,
      metadata: metadata,
      timestamp: Date.now()
    });
  }
}

// Buffer operation
function executeTurfBuffer(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  const buffered = turf.buffer(inputData, message.radius, {
    units: message.units || "meters"
  });
  
  if (message.source_id) {
    addResultSource(map, buffered, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "buffer", buffered, {
      radius: message.radius,
      units: message.units || "meters"
    });
  }
}

// Union operation
function executeTurfUnion(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  let result;
  if (inputData.type === "FeatureCollection") {
    // Union all features in the collection
    result = inputData.features.reduce((acc, feature) => {
      if (!acc) return feature;
      return turf.union(acc, feature);
    }, null);
    
    // Wrap in FeatureCollection
    if (result) {
      result = {
        type: "FeatureCollection",
        features: [result]
      };
    }
  } else {
    // Single feature, return as-is in FeatureCollection
    result = {
      type: "FeatureCollection",
      features: [inputData]
    };
  }
  
  if (message.source_id) {
    addResultSource(map, result, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "union", result);
  }
}

// Intersect operation
function executeTurfIntersect(map, message, widgetId) {
  const sourceData1 = getInputData(map, message);
  const sourceData2 = getSourceData(map, message.layer_id_2);
  
  // For now, intersect first features of each collection
  let feature1 = sourceData1.type === "FeatureCollection" ? 
    sourceData1.features[0] : sourceData1;
  let feature2 = sourceData2.type === "FeatureCollection" ? 
    sourceData2.features[0] : sourceData2;
  
  const intersection = turf.intersect(feature1, feature2);
  
  const result = intersection ? {
    type: "FeatureCollection",
    features: [intersection]
  } : {
    type: "FeatureCollection",
    features: []
  };
  
  if (message.source_id) {
    addResultSource(map, result, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "intersect", result);
  }
}

// Difference operation
function executeTurfDifference(map, message, widgetId) {
  const sourceData1 = getInputData(map, message);
  const sourceData2 = getSourceData(map, message.layer_id_2);
  
  let feature1 = sourceData1.type === "FeatureCollection" ? 
    sourceData1.features[0] : sourceData1;
  let feature2 = sourceData2.type === "FeatureCollection" ? 
    sourceData2.features[0] : sourceData2;
  
  const difference = turf.difference(feature1, feature2);
  
  const result = difference ? {
    type: "FeatureCollection",
    features: [difference]
  } : {
    type: "FeatureCollection",
    features: []
  };
  
  if (message.source_id) {
    addResultSource(map, result, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "difference", result);
  }
}

// Convex hull operation
function executeTurfConvexHull(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  const hull = turf.convex(inputData);
  
  const result = hull ? {
    type: "FeatureCollection",
    features: [hull]
  } : {
    type: "FeatureCollection",
    features: []
  };
  
  if (message.source_id) {
    addResultSource(map, result, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "convex_hull", result);
  }
}

// Concave hull operation
function executeTurfConcaveHull(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  const hull = turf.concave(inputData, {
    maxEdge: message.max_edge || Infinity,
    units: message.units || "kilometers"
  });
  
  const result = hull ? {
    type: "FeatureCollection",
    features: [hull]
  } : {
    type: "FeatureCollection",
    features: []
  };
  
  if (message.source_id) {
    addResultSource(map, result, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "concave_hull", result, {
      max_edge: message.max_edge,
      units: message.units || "kilometers"
    });
  }
}

// Voronoi operation
function executeTurfVoronoi(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  const options = {};
  if (message.bbox) {
    options.bbox = message.bbox;
  }
  
  const voronoi = turf.voronoi(inputData, options);
  
  if (message.source_id && voronoi) {
    addResultSource(map, voronoi, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "voronoi", voronoi, {
      bbox: message.bbox
    });
  }
}

// Distance operation
function executeTurfDistance(map, message, widgetId) {
  let feature1, feature2;
  
  // Get first feature
  if (message.coordinates) {
    feature1 = turf.point(message.coordinates);
  } else if (message.data) {
    const sourceData1 = JSON.parse(message.data);
    feature1 = sourceData1.type === "FeatureCollection" ? 
      sourceData1.features[0] : sourceData1;
  } else if (message.layer_id) {
    const sourceData1 = getSourceData(map, message.layer_id);
    feature1 = sourceData1.type === "FeatureCollection" ? 
      sourceData1.features[0] : sourceData1;
  }
  
  // Get second feature
  if (message.coordinates_2) {
    feature2 = turf.point(message.coordinates_2);
  } else if (message.layer_id_2) {
    const sourceData2 = getSourceData(map, message.layer_id_2);
    feature2 = sourceData2.type === "FeatureCollection" ? 
      sourceData2.features[0] : sourceData2;
  }
  
  const distance = turf.distance(feature1, feature2, {
    units: message.units || "kilometers"
  });
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "distance", distance, {
      units: message.units || "kilometers"
    });
  }
}

// Area operation
function executeTurfArea(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  const area = turf.area(inputData);
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "area", area, {
      units: "square_meters"
    });
  }
}

// Centroid operation
function executeTurfCentroid(map, message, widgetId) {
  const inputData = getInputData(map, message);
  
  const centroid = turf.centroid(inputData);
  
  const result = {
    type: "FeatureCollection",
    features: [centroid]
  };
  
  if (message.source_id) {
    addResultSource(map, result, message.source_id);
  }
  
  if (message.send_to_r) {
    sendResultToR(widgetId, "centroid", result);
  }
}