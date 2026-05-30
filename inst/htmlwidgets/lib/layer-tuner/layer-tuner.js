(function() {
  window.MapGLLayerTuner = {
    init: function(map, x, el, HTMLWidgets) {
      if (typeof lil === 'undefined') {
        console.warn('lil-gui is not loaded. Layer tuner cannot be initialized.');
        return;
      }

      // Check if tuner is already initialized to avoid duplication
      if (map._layerTunerInitialized) {
        return;
      }
      map._layerTunerInitialized = true;

      const config = x.layer_tuner || {};
      const gui = new lil.GUI({ title: 'Layer Tuner 🎨' });
      
      // Keep references to clean up if map is destroyed
      map._layerTunerGui = gui;

      // Adjust default styling to avoid overlapping controls (e.g. expanded layers control in top-right)
      gui.domElement.style.top = '10px';
      gui.domElement.style.left = '10px';
      gui.domElement.style.right = 'auto'; // Anchor to left side by default
      gui.domElement.style.zIndex = '9999'; // Stay on top of other controls

      // Store tuned changes for programmatic R code generation
      map._layerTunerChanges = {};

      // Global tuner UI and deparse state
      const tunerState = {
        showAllArgs: config.show_all_args || false
      };

      const allLayerControllers = [];

      const updateControllerVisibilities = function() {
        const showAll = tunerState.showAllArgs;
        allLayerControllers.forEach(function(meta) {
          const isTuned = map._layerTunerChanges[meta.layerId] && 
                          map._layerTunerChanges[meta.layerId].props[meta.prop] !== undefined;
          const isVisible = showAll || meta.originallyPresent || meta.hasInStyle || isTuned;
          
          if (isVisible) {
            meta.controller.show();
          } else {
            meta.controller.hide();
          }
        });
      };

      // Helper function to format JS values to standard R syntax
      const formatRValue = function(val) {
        if (typeof val === 'string') {
          return `"${val}"`;
        }
        if (typeof val === 'boolean') {
          return val ? 'TRUE' : 'FALSE';
        }
        if (typeof val === 'number') {
          return val;
        }
        if (Array.isArray(val)) {
          return `c(${val.map(formatRValue).join(', ')})`;
        }
        return JSON.stringify(val);
      };

      // Bulletproof copy to clipboard fallback for file:// URLs and secure/unsecure contexts
      const copyToClipboardFallback = function(text) {
        return new Promise(function(resolve, reject) {
          if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(resolve).catch(reject);
          } else {
            // Fallback for file:// or unsecure contexts
            const textArea = document.createElement('textarea');
            textArea.value = text;
            textArea.style.position = 'fixed'; // Avoid scrolling to bottom
            textArea.style.top = '0';
            textArea.style.left = '0';
            textArea.style.opacity = '0';
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            try {
              const successful = document.execCommand('copy');
              document.body.removeChild(textArea);
              if (successful) {
                resolve();
              } else {
                reject(new Error('execCommand copy returned false'));
              }
            } catch (err) {
              document.body.removeChild(textArea);
              reject(err);
            }
          }
        });
      };

      // Programmatic translator from underlying JS/Mapbox properties to R function arguments!
      const getRName = function(type, prop) {
        if (type === 'flowmap') {
          if (prop === 'colorScheme') return 'flow_color_scheme';
          if (prop === 'darkMode') return 'flow_dark_mode';
          if (prop === 'opacity') return 'flow_opacity';
          if (prop === 'blendMode') return 'flow_blend';
          return 'flow_' + prop.replace(/([A-Z])/g, "_$1").toLowerCase();
        }
        return prop.replace(/-/g, '_');
      };

      const TUNER_SCHEMA = {
        'fill': {
          'fill-antialias': { type: 'boolean', default: true, method: 'paint' },
          'fill-color': { type: 'color', default: '#000000', method: 'paint' },
          'fill-emissive-strength': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
          'fill-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'fill-outline-color': { type: 'color', default: '#000000', method: 'paint' },
          'fill-sort-key': { type: 'slider', min: 0, max: 100, step: 1, default: 0, method: 'layout' }
        },
        'line': {
          'line-blur': { type: 'slider', min: 0, max: 20, step: 0.5, default: 0, method: 'paint' },
          'line-cap': { type: 'select', options: ['butt', 'round', 'square'], default: 'butt', method: 'layout' },
          'line-color': { type: 'color', default: '#000000', method: 'paint' },
          'line-emissive-strength': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
          'line-gap-width': { type: 'slider', min: 0, max: 30, step: 0.5, default: 0, method: 'paint' },
          'line-join': { type: 'select', options: ['bevel', 'miter', 'round'], default: 'miter', method: 'layout' },
          'line-miter-limit': { type: 'slider', min: 0, max: 20, step: 0.5, default: 2, method: 'layout' },
          'line-offset': { type: 'slider', min: -20, max: 20, step: 0.5, default: 0, method: 'paint' },
          'line-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'line-round-limit': { type: 'slider', min: 0, max: 20, step: 0.5, default: 1, method: 'layout' },
          'line-sort-key': { type: 'slider', min: 0, max: 100, step: 1, default: 0, method: 'layout' },
          'line-width': { type: 'slider', min: 0, max: 20, step: 0.5, default: 1, method: 'paint' }
        },
        'circle': {
          'circle-blur': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
          'circle-color': { type: 'color', default: '#000000', method: 'paint' },
          'circle-emissive-strength': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
          'circle-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'circle-pitch-alignment': { type: 'select', options: ['map', 'viewport'], default: 'viewport', method: 'paint' },
          'circle-pitch-scale': { type: 'select', options: ['map', 'viewport'], default: 'map', method: 'paint' },
          'circle-radius': { type: 'slider', min: 0, max: 50, step: 0.5, default: 5, method: 'paint' },
          'circle-sort-key': { type: 'slider', min: 0, max: 100, step: 1, default: 0, method: 'layout' },
          'circle-stroke-color': { type: 'color', default: '#000000', method: 'paint' },
          'circle-stroke-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'circle-stroke-width': { type: 'slider', min: 0, max: 10, step: 0.5, default: 0, method: 'paint' }
        },
        'symbol': {
          'icon-allow-overlap': { type: 'boolean', default: false, method: 'layout' },
          'icon-anchor': { type: 'select', options: ['center', 'left', 'right', 'top', 'bottom', 'top-left', 'top-right', 'bottom-left', 'bottom-right'], default: 'center', method: 'layout' },
          'icon-color': { type: 'color', default: '#ffffff', method: 'paint' },
          'icon-emissive-strength': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
          'icon-halo-blur': { type: 'slider', min: 0, max: 10, step: 0.5, default: 0, method: 'paint' },
          'icon-halo-color': { type: 'color', default: '#000000', method: 'paint' },
          'icon-halo-width': { type: 'slider', min: 0, max: 10, step: 0.5, default: 0, method: 'paint' },
          'icon-ignore-placement': { type: 'boolean', default: false, method: 'layout' },
          'icon-image': { type: 'text', default: '', method: 'layout' },
          'icon-keep-upright': { type: 'boolean', default: false, method: 'layout' },
          'icon-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'icon-optional': { type: 'boolean', default: false, method: 'layout' },
          'icon-padding': { type: 'slider', min: 0, max: 50, step: 1, default: 2, method: 'layout' },
          'icon-pitch-alignment': { type: 'select', options: ['map', 'viewport', 'auto'], default: 'auto', method: 'layout' },
          'icon-rotate': { type: 'slider', min: 0, max: 360, step: 1, default: 0, method: 'layout' },
          'icon-rotation-alignment': { type: 'select', options: ['map', 'viewport', 'auto'], default: 'auto', method: 'layout' },
          'icon-size': { type: 'slider', min: 0.1, max: 5, step: 0.05, default: 1, method: 'layout' },
          'text-allow-overlap': { type: 'boolean', default: false, method: 'layout' },
          'text-anchor': { type: 'select', options: ['center', 'left', 'right', 'top', 'bottom', 'top-left', 'top-right', 'bottom-left', 'bottom-right'], default: 'center', method: 'layout' },
          'text-color': { type: 'color', default: '#000000', method: 'paint' },
          'text-emissive-strength': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
          'text-field': { type: 'text', default: '', method: 'layout' },
          'text-halo-blur': { type: 'slider', min: 0, max: 10, step: 0.5, default: 0, method: 'paint' },
          'text-halo-color': { type: 'color', default: '#000000', method: 'paint' },
          'text-halo-width': { type: 'slider', min: 0, max: 10, step: 0.5, default: 0, method: 'paint' },
          'text-ignore-placement': { type: 'boolean', default: false, method: 'layout' },
          'text-justify': { type: 'select', options: ['auto', 'left', 'center', 'right'], default: 'auto', method: 'layout' },
          'text-keep-upright': { type: 'boolean', default: true, method: 'layout' },
          'text-letter-spacing': { type: 'slider', min: 0, max: 2, step: 0.05, default: 0, method: 'layout' },
          'text-line-height': { type: 'slider', min: 0.5, max: 3, step: 0.1, default: 1.2, method: 'layout' },
          'text-max-angle': { type: 'slider', min: 0, max: 360, step: 5, default: 45, method: 'layout' },
          'text-max-width': { type: 'slider', min: 0, max: 50, step: 0.5, default: 10, method: 'layout' },
          'text-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'text-padding': { type: 'slider', min: 0, max: 50, step: 1, default: 2, method: 'layout' },
          'text-pitch-alignment': { type: 'select', options: ['map', 'viewport', 'auto'], default: 'auto', method: 'layout' },
          'text-rotate': { type: 'slider', min: 0, max: 360, step: 1, default: 0, method: 'layout' },
          'text-rotation-alignment': { type: 'select', options: ['map', 'viewport', 'auto'], default: 'auto', method: 'layout' },
          'text-size': { type: 'slider', min: 4, max: 72, step: 1, default: 16, method: 'layout' },
          'text-transform': { type: 'select', options: ['none', 'uppercase', 'lowercase'], default: 'none', method: 'layout' }
        }
      };

      // Add "Export R Code" action button at the top of the Tuner panel
      gui.add({
        exportCode: function() {
          const changes = map._layerTunerChanges;
          const showAllArgs = tunerState.showAllArgs;
          let codeStr = '# Copy-paste this complete pipeline to recreate your styled map:\n\n';
          
          const parts = [];
          const originalCalls = config.original_calls;

          if (originalCalls && Array.isArray(originalCalls) && originalCalls.length > 0) {
            originalCalls.forEach(function(call) {
              const fun = call.fun;
              const args = call.args.map(a => ({ name: a.name, value: a.value }));
              
              const isLayerCall = fun.startsWith('add_') && fun.endsWith('_layer');
              const isFlowmapCall = fun === 'add_flowmap';
              
              let layerId = null;
              const idArg = args.find(a => a.name === 'id');
              if (idArg) {
                layerId = idArg.value.replace(/^["']|["']$/g, '');
              }
              
              if (layerId) {
                const layerChanges = changes[layerId];
                if (isLayerCall) {
                  const funToType = {
                    'add_circle_layer': 'circle',
                    'add_fill_layer': 'fill',
                    'add_line_layer': 'line',
                    'add_symbol_layer': 'symbol'
                  };
                  const type = funToType[fun];
                  if (type) {
                    const typeSchema = TUNER_SCHEMA[type] || {};
                    Object.keys(typeSchema).forEach(function(propName) {
                      const rName = getRName(type, propName);
                      let propVal = undefined;
                      
                      if (layerChanges && layerChanges.props[propName] !== undefined) {
                        propVal = layerChanges.props[propName].value;
                      } else {
                        const originallyPresent = args.some(a => a.name === rName);
                        if (originallyPresent || showAllArgs) {
                          const spec = typeSchema[propName];
                          try {
                            if (spec.method === 'paint') {
                              propVal = map.getPaintProperty(layerId, propName);
                            } else {
                              propVal = map.getLayoutProperty(layerId, propName);
                            }
                          } catch (e) {}
                          if (propVal === undefined || typeof propVal === 'object') {
                            propVal = spec.default;
                          }
                        }
                      }
                      
                      if (propVal !== undefined && typeof propVal !== 'object') {
                        const formattedVal = formatRValue(propVal);
                        const existingArg = args.find(a => a.name === rName);
                        if (existingArg) {
                          existingArg.value = formattedVal;
                        } else {
                          args.push({ name: rName, value: formattedVal });
                        }
                      }
                    });
                  }
                } else if (isFlowmapCall) {
                  const flowmapProps = (layerChanges && layerChanges.props) || {};
                  const flowmapMappings = {
                    colorScheme: 'flow_color_scheme',
                    darkMode: 'flow_dark_mode',
                    opacity: 'flow_opacity',
                    blendMode: 'flow_blend'
                  };
                  
                  let originalFlowmapData = null;
                  if (x.flowmaps) {
                    originalFlowmapData = x.flowmaps.find(f => (f.id || 'manual-flowmap') === layerId);
                  }
                  
                  Object.keys(flowmapMappings).forEach(function(propKey) {
                    const rName = flowmapMappings[propKey];
                    let propVal = undefined;
                    
                    if (flowmapProps[propKey] !== undefined) {
                      propVal = flowmapProps[propKey];
                    } else {
                      const originallyPresent = args.some(a => a.name === rName);
                      if (originallyPresent || showAllArgs) {
                        if (originalFlowmapData) {
                          if (propKey === 'colorScheme') propVal = originalFlowmapData.colorScheme;
                          else if (propKey === 'darkMode') propVal = originalFlowmapData.darkMode;
                          else if (propKey === 'opacity') propVal = originalFlowmapData.opacity;
                          else if (propKey === 'blendMode') propVal = originalFlowmapData.flowBlend;
                        }
                        if (propVal === undefined) {
                          if (propKey === 'colorScheme') propVal = 'Teal';
                          else if (propKey === 'darkMode') propVal = true;
                          else if (propKey === 'opacity') propVal = 1.0;
                          else if (propKey === 'blendMode') propVal = 'screen';
                        }
                      }
                    }
                    
                    if (propVal !== undefined) {
                      const formattedVal = formatRValue(propVal);
                      const existingArg = args.find(a => a.name === rName);
                      if (existingArg) {
                        existingArg.value = formattedVal;
                      } else {
                        args.push({ name: rName, value: formattedVal });
                      }
                    }
                  });
                }
              }
              
              let callStr = '';
              if (fun === 'maplibre' || fun === 'mapboxgl' || fun === 'maplibre_compare' || fun === 'mapboxgl_compare') {
                const styleArg = args.find(a => a.name === 'style');
                if (styleArg && styleArg.value.includes('basemaps.cartocdn.com')) {
                  const valStr = styleArg.value.replace(/^["']|["']$/g, '');
                  const cParts = valStr.split('/');
                  const folder = cParts[cParts.length - 2] || '';
                  const name = folder.replace('-gl-style', '').replace('nolabels', 'no-labels');
                  styleArg.value = `carto_style("${name || 'dark-matter'}")`;
                }
                
                const cParams = args.map(a => `  ${a.name} = ${a.value}`);
                callStr = `${fun}(\n${cParams.join(',\n')}\n)`;
                parts.push(callStr);
              } else {
                const lParams = args.map(a => {
                  if (a.name) {
                    return `    ${a.name} = ${a.value}`;
                  } else {
                    return `    ${a.value}`;
                  }
                });
                callStr = `  ${fun}(\n${lParams.join(',\n')}\n  )`;
                parts.push(callStr);
              }
            });
            
            codeStr += parts.join(' |>\n') + ' |>\n  add_layer_tuner()';
          } else {
            // Fallback Constructor
            const constructorName = config.map_type === 'mapboxgl' ? 'mapboxgl' : 'maplibre';
            let mapConstructor = `${constructorName}(\n`;
            const cParams = [];
            if (x.style) {
              let styleStr = formatRValue(x.style);
              if (x.style.startsWith('mapbox://styles/mapbox/')) {
                const name = x.style.replace('mapbox://styles/mapbox/', '').split('-')[0];
                styleStr = `mapbox_style("${name}")`;
              } else if (x.style.includes('basemaps.cartocdn.com')) {
                const cParts = x.style.split('/');
                const folder = cParts[cParts.length - 2] || '';
                const name = folder.replace('-gl-style', '').replace('nolabels', 'no-labels');
                styleStr = `carto_style("${name || 'dark-matter'}")`;
              }
              cParams.push(`  style = ${styleStr}`);
            } else {
              cParams.push(`  style = NULL`);
            }
            if (x.center) {
              cParams.push(`  center = c(${x.center[0]}, ${x.center[1]})`);
            }
            if (x.zoom !== undefined) {
              cParams.push(`  zoom = ${x.zoom}`);
            }
            if (x.projection && x.projection !== 'globe') {
              cParams.push(`  projection = "${x.projection}"`);
            }
            if (constructorName === 'mapboxgl' && x.access_token) {
              cParams.push(`  access_token = mapbox_token`);
            }
            mapConstructor += cParams.join(',\n') + '\n)';
            parts.push(mapConstructor);

            // 2. Layer Tuner
            parts.push('  add_layer_tuner()');

            // 3. Regular Layers (Mapbox/MapLibre)
            if (x.layers) {
              x.layers.forEach(function(layer) {
                const layerId = layer.id;
                const type = layer.type;
                
                if (layerId.includes('-clusters') || layerId.includes('-cluster-count')) return;
                
                const rFuncName = {
                  'fill': 'add_fill_layer',
                  'line': 'add_line_layer',
                  'circle': 'add_circle_layer',
                  'symbol': 'add_symbol_layer'
                }[type] || 'add_layer';
                
                const isTuned = changes[layerId] !== undefined;
                
                let layerCode = `  ${rFuncName}(\n`;
                const lParams = [];
                lParams.push(`    id = "${layerId}"`);
                
                let sourceVal = layer.source;
                if (typeof sourceVal === 'string') {
                  lParams.push(`    source = "${sourceVal}"`);
                } else {
                  lParams.push(`    source = source`);
                }
                
                if (layer.before_id) lParams.push(`    before_id = "${layer.before_id}"`);
                if (layer.slot) lParams.push(`    slot = "${layer.slot}"`);
                if (layer.popup) lParams.push(`    popup = "${layer.popup}"`);
                if (layer.tooltip) lParams.push(`    tooltip = "${layer.tooltip}"`);
                
                const typeSchema = TUNER_SCHEMA[type] || {};
                Object.keys(typeSchema).forEach(function(propName) {
                  const spec = typeSchema[propName];
                  const rName = getRName(type, propName);
                  
                  let propVal = undefined;
                  
                  if (isTuned && changes[layerId].props[propName] !== undefined) {
                    propVal = changes[layerId].props[propName].value;
                  } else {
                    if (spec.method === 'paint' && layer.paint && layer.paint[propName] !== undefined) {
                      propVal = layer.paint[propName];
                    } else if (spec.method === 'layout' && layer.layout && layer.layout[propName] !== undefined) {
                      propVal = layer.layout[propName];
                    } else if (showAllArgs) {
                      try {
                        if (spec.method === 'paint') {
                          propVal = map.getPaintProperty(layerId, propName);
                        } else {
                          propVal = map.getLayoutProperty(layerId, propName);
                        }
                      } catch (e) {}
                      if (propVal === undefined || typeof propVal === 'object') {
                        propVal = spec.default;
                      }
                    }
                  }
                  
                  if (propVal !== undefined && typeof propVal !== 'object') {
                    lParams.push(`    ${rName} = ${formatRValue(propVal)}`);
                  }
                });
                
                layerCode += lParams.join(',\n') + '\n  )';
                parts.push(layerCode);
              });
            }

            // 4. Flowmap layers
            if (x.flowmaps) {
              x.flowmaps.forEach(function(flowmap) {
                const layerId = flowmap.id || `manual-flowmap`;
                const isTuned = changes[layerId] !== undefined;
                
                let flowCode = `  add_flowmap(\n`;
                const fParams = [];
                fParams.push(`    id = "${layerId}"`);
                fParams.push(`    locations = locations`);
                fParams.push(`    flows = flows`);
                
                let scheme = flowmap.colorScheme;
                let opacity = flowmap.opacity;
                let darkMode = flowmap.darkMode;
                let blend = flowmap.flowBlend;
                
                if (isTuned) {
                  scheme = changes[layerId].props.colorScheme;
                  opacity = changes[layerId].props.opacity;
                  darkMode = changes[layerId].props.darkMode;
                  blend = changes[layerId].props.blendMode;
                }
                
                if (scheme || showAllArgs) fParams.push(`    flow_color_scheme = "${scheme || 'Teal'}"`);
                if (opacity !== undefined || showAllArgs) fParams.push(`    flow_opacity = ${opacity !== undefined ? opacity : 1.0}`);
                if (darkMode !== undefined || showAllArgs) {
                  const dmVal = darkMode !== undefined ? darkMode : true;
                  fParams.push(`    flow_dark_mode = ${dmVal ? 'TRUE' : 'FALSE'}`);
                }
                if (blend !== undefined || showAllArgs) fParams.push(`    flow_blend = "${blend || 'screen'}"`);
                
                if (flowmap.beforeId) fParams.push(`    before_id = "${flowmap.beforeId}"`);
                if (flowmap.slot) fParams.push(`    slot = "${flowmap.slot}"`);
                
                flowCode += fParams.join(',\n') + '\n  )';
                parts.push(flowCode);
              });
            }

            // 5. Navigation Control
            if (x.navigation_control) {
              let navCode = `  add_navigation_control(\n`;
              const nParams = [];
              nParams.push(`    position = "${x.navigation_control.position}"`);
              nParams.push(`    show_compass = ${x.navigation_control.show_compass ? 'TRUE' : 'FALSE'}`);
              nParams.push(`    show_zoom = ${x.navigation_control.show_zoom ? 'TRUE' : 'FALSE'}`);
              nParams.push(`    visualize_pitch = ${x.navigation_control.visualize_pitch ? 'TRUE' : 'FALSE'}`);
              navCode += nParams.join(',\n') + '\n  )';
              parts.push(navCode);
            }

            // 6. Scale Control
            if (x.scale_control) {
              let scaleCode = `  add_scale_control(\n`;
              const sParams = [];
              sParams.push(`    position = "${x.scale_control.position}"`);
              sParams.push(`    maxWidth = ${x.scale_control.maxWidth}`);
              sParams.push(`    unit = "${x.scale_control.unit}"`);
              scaleCode += sParams.join(',\n') + '\n  )';
              parts.push(scaleCode);
            }

            // 7. Globe Minimap
            if (x.globe_minimap && x.globe_minimap.enabled) {
              let minimapCode = `  add_globe_minimap(\n`;
              const gParams = [];
              gParams.push(`    position = "${x.globe_minimap.position}"`);
              gParams.push(`    globe_size = ${x.globe_minimap.globe_size}`);
              gParams.push(`    land_color = "${x.globe_minimap.land_color}"`);
              gParams.push(`    water_color = "${x.globe_minimap.water_color}"`);
              gParams.push(`    marker_color = "${x.globe_minimap.marker_color}"`);
              gParams.push(`    marker_size = ${x.globe_minimap.marker_size}`);
              minimapCode += gParams.join(',\n') + '\n  )';
              parts.push(minimapCode);
            }

            // 8. Layers Control
            if (x.layers_control) {
              let layersListStr = 'list(\n';
              if (x.layers_control.layers_config) {
                const items = [];
                x.layers_control.layers_config.forEach(function(item) {
                  const ids = Array.isArray(item.ids) ? item.ids : [item.ids];
                  const val = ids.length === 1 ? `"${ids[0]}"` : `c(${ids.map(id => `"${id}"`).join(', ')})`;
                  items.push(`      "${item.label}" = ${val}`);
                });
                layersListStr += items.join(',\n') + '\n    )';
              } else if (x.layers_control.layers) {
                layersListStr += `      ` + formatRValue(x.layers_control.layers) + '\n    )';
              }
              
              let layersCode = `  add_layers_control(\n`;
              const lcParams = [];
              lcParams.push(`    position = "${x.layers_control.position}"`);
              lcParams.push(`    layers = ${layersListStr}`);
              layersCode += lcParams.join(',\n') + '\n  )';
              parts.push(layersCode);
            }

            codeStr += parts.join(' |>\n');
          }

          // Create premium Glassmorphic overlay modal dynamically
          const modalOverlay = document.createElement('div');
          modalOverlay.style.position = 'fixed';
          modalOverlay.style.top = '0';
          modalOverlay.style.left = '0';
          modalOverlay.style.width = '100vw';
          modalOverlay.style.height = '100vh';
          modalOverlay.style.backgroundColor = 'rgba(0,0,0,0.6)';
          modalOverlay.style.zIndex = '100000';
          modalOverlay.style.display = 'flex';
          modalOverlay.style.alignItems = 'center';
          modalOverlay.style.justifyContent = 'center';
          modalOverlay.id = 'layer-tuner-modal-overlay';
          
          if (!document.getElementById('layer-tuner-modal-styles')) {
            const style = document.createElement('style');
            style.id = 'layer-tuner-modal-styles';
            style.textContent = `
              .layer-tuner-modal {
                background: rgba(20, 20, 20, 0.9);
                backdrop-filter: blur(10px);
                -webkit-backdrop-filter: blur(10px);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 12px;
                color: #fff;
                padding: 24px;
                width: 85%;
                max-width: 520px;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                animation: tunerFadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
              }
              @keyframes tunerFadeIn {
                from { opacity: 0; transform: scale(0.96); }
                to { opacity: 1; transform: scale(1); }
              }
              .layer-tuner-modal h3 {
                margin: 0 0 8px 0;
                font-size: 18px;
                font-weight: 600;
                color: #00bcd4;
              }
              .layer-tuner-modal pre {
                background: rgba(0, 0, 0, 0.4);
                border-radius: 6px;
                padding: 16px;
                overflow-x: auto;
                font-family: "SFMono-Regular", Consolas, Menlo, monospace;
                font-size: 12px;
                line-height: 1.5;
                color: #8ae4b4;
                margin-bottom: 20px;
                border: 1px solid rgba(255, 255, 255, 0.05);
                max-height: 250px;
                overflow-y: auto;
              }
              .layer-tuner-modal-buttons {
                display: flex;
                justify-content: flex-end;
                gap: 12px;
              }
              .layer-tuner-modal-btn {
                padding: 8px 18px;
                border-radius: 6px;
                font-size: 13px;
                font-weight: 500;
                cursor: pointer;
                border: none;
                transition: all 0.2s ease;
              }
              .layer-tuner-modal-btn.primary {
                background: #00bcd4;
                color: #121212;
                font-weight: 600;
              }
              .layer-tuner-modal-btn.primary:hover {
                background: #00acc1;
                box-shadow: 0 0 12px rgba(0, 188, 212, 0.4);
              }
              .layer-tuner-modal-btn.secondary {
                background: rgba(255, 255, 255, 0.08);
                color: #eee;
              }
              .layer-tuner-modal-btn.secondary:hover {
                background: rgba(255, 255, 255, 0.12);
              }
            `;
            document.head.appendChild(style);
          }
          
          modalOverlay.innerHTML = `
            <div class="layer-tuner-modal">
              <h3>Exported R Code 🚀</h3>
              <p style="margin: 0 0 14px 0; font-size: 13px; color: #aaa; line-height: 1.4;">Copy and paste this pipeline directly into your R script to apply your new styled settings permanently.</p>
              <pre><code>${codeStr}</code></pre>
              <div class="layer-tuner-modal-buttons">
                <button class="layer-tuner-modal-btn secondary" id="layer-tuner-modal-close">Close</button>
                <button class="layer-tuner-modal-btn primary" id="layer-tuner-modal-copy">Copy Code</button>
              </div>
            </div>
          `;
          
          document.body.appendChild(modalOverlay);
          
          // Close events
          document.getElementById('layer-tuner-modal-close').addEventListener('click', function() {
            document.body.removeChild(modalOverlay);
          });
          
          // Copy event using bulletproof clipboard fallback and automatic highlight selection
          document.getElementById('layer-tuner-modal-copy').addEventListener('click', function() {
            copyToClipboardFallback(codeStr).then(function() {
              const copyBtn = document.getElementById('layer-tuner-modal-copy');
              copyBtn.textContent = 'Copied! ✓';
              copyBtn.style.background = '#4caf50';
              copyBtn.style.color = '#fff';
              setTimeout(function() {
                copyBtn.textContent = 'Copy Code';
                copyBtn.style.background = '#00bcd4';
                copyBtn.style.color = '#121212';
              }, 2000);
            }).catch(function(err) {
              // Highlight the text inside the code block automatically for quick manual copy!
              const preElement = modalOverlay.querySelector('pre');
              const range = document.createRange();
              range.selectNodeContents(preElement);
              const selection = window.getSelection();
              selection.removeAllRanges();
              selection.addRange(range);
              
              const copyBtn = document.getElementById('layer-tuner-modal-copy');
              copyBtn.textContent = 'Selected! Press Cmd+C';
              copyBtn.style.background = '#ff9800'; // Orange highlight indicator
              copyBtn.style.color = '#fff';
              setTimeout(function() {
                copyBtn.textContent = 'Copy Code';
                copyBtn.style.background = '#00bcd4';
                copyBtn.style.color = '#121212';
              }, 4000);
            });
          });
        }
      }, 'exportCode').name('Export R Code 🚀');

      gui.add(tunerState, 'showAllArgs')
        .name('Show All Args 📝')
        .onChange(function(value) {
          updateControllerVisibilities();
        });

      const filterLayers = config.layers || 'all';
      const isLayerIncluded = function(layerId) {
        if (filterLayers === 'all') return true;
        if (Array.isArray(filterLayers)) return filterLayers.includes(layerId);
        return false;
      };

      // Make the widget fully DRAGGABLE!
      const titleEl = gui.domElement.querySelector('.title');
      if (titleEl) {
        titleEl.style.cursor = 'move';
        
        let isDragging = false;
        let dragged = false;
        let startX, startY;
        let elemStartX, elemStartY;
        
        titleEl.addEventListener('mousedown', function(e) {
          isDragging = true;
          dragged = false;
          startX = e.clientX;
          startY = e.clientY;
          
          const rect = gui.domElement.getBoundingClientRect();
          const parentRect = el.getBoundingClientRect();
          
          gui.domElement.style.position = 'absolute';
          gui.domElement.style.right = 'auto'; // Disable default right anchoring
          
          elemStartX = rect.left - parentRect.left;
          elemStartY = rect.top - parentRect.top;
          
          gui.domElement.style.left = elemStartX + 'px';
          gui.domElement.style.top = elemStartY + 'px';
          
          e.preventDefault();
        });
        
        window.addEventListener('mousemove', function(e) {
          if (!isDragging) return;
          
          const dx = e.clientX - startX;
          const dy = e.clientY - startY;
          
          if (Math.hypot(dx, dy) > 5) {
            dragged = true;
          }
          
          let newX = elemStartX + dx;
          let newY = elemStartY + dy;
          
          const rect = gui.domElement.getBoundingClientRect();
          const parentRect = el.getBoundingClientRect();
          
          newX = Math.max(0, Math.min(newX, parentRect.width - rect.width));
          newY = Math.max(0, Math.min(newY, parentRect.height - rect.height));
          
          gui.domElement.style.left = newX + 'px';
          gui.domElement.style.top = newY + 'px';
        });
        
        window.addEventListener('mouseup', function() {
          isDragging = false;
        });

        titleEl.addEventListener('click', function(e) {
          if (dragged) {
            e.stopPropagation();
            e.preventDefault();
            dragged = false;
          }
        }, true);
      }

      // 1. Process regular Mapbox/MapLibre layers
      const mapStyle = map.getStyle();
      if (mapStyle && mapStyle.layers) {
        mapStyle.layers.forEach(function(layer) {
          const type = layer.type;
          const layerId = layer.id;

          // Skip basemap layers (if tracking is available and it was in the basemap)
          if (map._basemapLayerIds && map._basemapLayerIds.has(layerId)) {
            return;
          }

          if (TUNER_SCHEMA[type] && isLayerIncluded(layerId)) {
            const schema = TUNER_SCHEMA[type];
            const folder = gui.addFolder(`${type.toUpperCase()}: ${layerId}`);
            folder.close(); // Collapsed by default

            const state = {};
            
            Object.keys(schema).forEach(function(prop) {
              const spec = schema[prop];
              
              let currentVal = undefined;
              try {
                if (spec.method === 'paint') {
                  currentVal = map.getPaintProperty(layerId, prop);
                } else {
                  currentVal = map.getLayoutProperty(layerId, prop);
                }
              } catch (e) {
                // Ignore
              }

              if (currentVal === undefined || typeof currentVal === 'object') {
                currentVal = spec.default;
              }

              state[prop] = currentVal;

              // Check if this property was explicitly customized in R function call
              let originallyPresent = false;
              if (config.original_calls && Array.isArray(config.original_calls)) {
                const rName = getRName(type, prop);
                const matchingCall = config.original_calls.find(function(call) {
                  const idArg = call.args.find(a => a.name === 'id');
                  return idArg && idArg.value.replace(/^["']|["']$/g, '') === layerId;
                });
                if (matchingCall) {
                  originallyPresent = matchingCall.args.some(a => a.name === rName);
                }
              }

              // Check if it exists in the active style definition
              let hasInStyle = false;
              if (spec.method === 'paint' && layer.paint && layer.paint[prop] !== undefined) {
                hasInStyle = true;
              } else if (spec.method === 'layout' && layer.layout && layer.layout[prop] !== undefined) {
                hasInStyle = true;
              }

              let ctrl;
              if (spec.type === 'color') {
                ctrl = folder.addColor(state, prop);
              } else if (spec.type === 'slider') {
                ctrl = folder.add(state, prop, spec.min, spec.max, spec.step);
              } else if (spec.type === 'boolean') {
                ctrl = folder.add(state, prop);
              } else if (spec.type === 'select') {
                ctrl = folder.add(state, prop, spec.options);
              } else if (spec.type === 'text') {
                ctrl = folder.add(state, prop);
              }

              if (ctrl) {
                ctrl.name(getRName(type, prop));
                
                // Track controller metadata
                allLayerControllers.push({
                  controller: ctrl,
                  type: type,
                  prop: prop,
                  layerId: layerId,
                  originallyPresent: originallyPresent,
                  hasInStyle: hasInStyle
                });
                
                ctrl.onChange(function(newVal) {
                  try {
                    if (spec.method === 'paint') {
                      map.setPaintProperty(layerId, prop, newVal);
                    } else {
                      map.setLayoutProperty(layerId, prop, newVal);
                    }

                    // Log change dynamically
                    if (!map._layerTunerChanges[layerId]) {
                      map._layerTunerChanges[layerId] = { type: type, props: {} };
                    }
                    map._layerTunerChanges[layerId].props[prop] = { method: spec.method, value: newVal };

                    // Make sure visibilities are updated (since it's now tuned/customized!)
                    updateControllerVisibilities();

                  } catch (err) {
                    console.error(`Failed to update ${prop} for layer ${layerId}:`, err);
                  }
                });
              }
            });
          }
        });
      }

      // 2. Process Deck.gl Flowmap layers
      const flowmapLayers = map._mapglFlowmapLayers;
      if (flowmapLayers && flowmapLayers.length > 0) {
        flowmapLayers.forEach(function(layer, idx) {
          const layerId = layer.id || `flowmap-${idx}`;
          if (!isLayerIncluded(layerId)) {
            return;
          }

          const overlay = map._mapglFlowmapOverlay || map._deckgl;
          if (!overlay) return;

          const folder = gui.addFolder(`FLOWMAP: ${layerId}`);
          folder.close(); // Collapsed by default

          const flowState = {
            colorScheme: layer.props.colorScheme || 'Teal',
            darkMode: layer.props.darkMode !== undefined ? layer.props.darkMode : true,
            opacity: layer.props.opacity !== undefined ? layer.props.opacity : 1,
            blendMode: 'screen'
          };

          const canvas = map._deckCanvas;
          if (canvas && canvas.style.mixBlendMode) {
            flowState.blendMode = canvas.style.mixBlendMode;
          }

          const updateFlowmap = function() {
            try {
              const currentLayers = map._mapglFlowmapLayers;
              if (!currentLayers || currentLayers.length <= idx) return;

              const targetLayer = currentLayers[idx];
              const updated = targetLayer.clone({
                colorScheme: flowState.colorScheme,
                darkMode: flowState.darkMode,
                opacity: flowState.opacity
              });

              const newLayersArray = [...currentLayers];
              newLayersArray[idx] = updated;
              map._mapglFlowmapLayers = newLayersArray;

              overlay.setProps({ layers: map._mapglFlowmapLayers });

              if (canvas) {
                canvas.style.mixBlendMode = flowState.blendMode;
              }

              // Log changes
              map._layerTunerChanges[layerId] = {
                type: 'flowmap',
                props: {
                  colorScheme: flowState.colorScheme,
                  darkMode: flowState.darkMode,
                  opacity: flowState.opacity,
                  blendMode: flowState.blendMode
                }
              };

              if (typeof map.triggerRepaint === 'function') {
                map.triggerRepaint();
              }
            } catch (err) {
              console.error('Error updating flowmap layer:', err);
            }
          };

          const schemes = config.flowmap_color_schemes || ['Teal', 'Blues', 'Burg', 'Sunset'];

          folder.add(flowState, 'colorScheme', schemes).name(getRName('flowmap', 'colorScheme')).onChange(updateFlowmap);
          folder.add(flowState, 'darkMode').name(getRName('flowmap', 'darkMode')).onChange(updateFlowmap);
          folder.add(flowState, 'opacity', 0, 1, 0.05).name(getRName('flowmap', 'opacity')).onChange(updateFlowmap);
          folder.add(flowState, 'blendMode', [
            'normal', 'screen', 'multiply', 'overlay', 'color-dodge', 'difference', 'exclusion'
          ]).name(getRName('flowmap', 'blendMode')).onChange(updateFlowmap);
        });
      }

      // Apply initial controller visibilities based on initial show_all_args setting
      updateControllerVisibilities();
    }
  };
})();
