(function() {
  window.MapGLLayerTuner = {
    init: function(map, x, el, HTMLWidgets) {
      if (typeof lil === 'undefined') {
        console.warn('lil-gui is not loaded. Layer tuner cannot be initialized.');
        return;
      }

      if (map._layerTunerInitialized) return;
      map._layerTunerInitialized = true;

      const config = x.layer_tuner || {};
      
      const formatRValue = function(val) {
        if (typeof val === 'string') return `"${val}"`;
        if (typeof val === 'boolean') return val ? 'TRUE' : 'FALSE';
        if (typeof val === 'number') return val;
        if (Array.isArray(val)) return `c(${val.map(formatRValue).join(', ')})`;
        return JSON.stringify(val);
      };

      const copyToClipboardFallback = function(text) {
        return new Promise(function(resolve, reject) {
          if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(resolve).catch(reject);
          } else {
            const textArea = document.createElement('textarea');
            textArea.value = text;
            textArea.style.position = 'fixed'; textArea.style.top = '0'; textArea.style.left = '0'; textArea.style.opacity = '0';
            document.body.appendChild(textArea);
            textArea.focus(); textArea.select();
            try { if (document.execCommand('copy')) resolve(); else reject(); } catch (err) { reject(err); }
            document.body.removeChild(textArea);
          }
        });
      };

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
          'fill-opacity': { type: 'slider', min: 0, max: 1, step: 0.05, default: 1, method: 'paint' },
          'fill-outline-color': { type: 'color', default: '#000000', method: 'paint' },
          'fill-emissive-strength': { type: 'slider', min: 0, max: 1, step: 0.05, default: 0, method: 'paint' },
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
          'circle-stroke-width': { type: 'slider', min: 0, max: 10, step: 0.5, default: 0, method: 'paint' },
          'circle-translate': { type: 'text', default: '0,0', method: 'paint' }
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

      const gui = new lil.GUI({ title: 'Layer Tuner 🎨', container: el });
      map._layerTunerGui = gui;

      // 1. Initial styles
      const dom = gui.domElement;
      dom.style.position = 'absolute'; dom.style.top = '10px'; dom.style.left = '10px'; dom.style.right = 'auto'; dom.style.zIndex = '9999'; dom.style.width = '245px'; dom.style.height = 'auto'; dom.style.maxHeight = 'calc(100% - 20px)'; dom.style.display = 'flex'; dom.style.flexDirection = 'column';

      const children = dom.querySelector('.children');
      if (children) { children.style.flex = '1 1 auto'; children.style.overflowY = 'auto'; }

      // Resize handles
      const corners = ['tl', 'tr', 'bl', 'br'];
      let isResizing = false, hasBeenManuallyResized = false, manualWidth = '245px', manualHeight = 'auto';
      corners.forEach(c => {
        const handle = document.createElement('div');
        handle.style.position = 'absolute'; handle.style.width = '12px'; handle.style.height = '12px'; handle.style.zIndex = '10001'; handle.style.background = 'transparent';
        if (c==='tl') { handle.style.top='-4px'; handle.style.left='-4px'; handle.style.cursor='nw-resize'; }
        else if (c==='tr') { handle.style.top='-4px'; handle.style.right='-4px'; handle.style.cursor='ne-resize'; }
        else if (c==='bl') { handle.style.bottom='-4px'; handle.style.left='-4px'; handle.style.cursor='sw-resize'; }
        else if (c==='br') { 
          handle.style.bottom='-4px'; handle.style.right='-4px'; handle.style.cursor='se-resize'; 
          handle.innerHTML = '<div style="position:absolute;bottom:6px;right:6px;width:0;height:0;border-style:solid;border-width:0 0 6px 6px;border-color:transparent transparent rgba(255,255,255,0.4) transparent;"></div>';
        }
        dom.appendChild(handle);
        handle.onmousedown = (e) => {
          isResizing = true; hasBeenManuallyResized = true;
          const sw = dom.offsetWidth, sh = dom.offsetHeight, sx = e.clientX, sy = e.clientY, st = dom.offsetTop, sl = dom.offsetLeft;
          const onMove = (me) => {
            if (!isResizing) return;
            const dx = me.clientX - sx, dy = me.clientY - sy;
            if (c.includes('r')) dom.style.width = Math.max(180, sw + dx) + 'px';
            if (c.includes('l')) { const nw = Math.max(180, sw - dx); dom.style.width = nw + 'px'; dom.style.left = (sl + (sw - nw)) + 'px'; }
            if (c.includes('b')) dom.style.height = Math.max(100, sh + dy) + 'px';
            if (c.includes('t')) { const nh = Math.max(100, sh - dy); dom.style.height = nh + 'px'; dom.style.top = (st + (sh - nh)) + 'px'; }
            manualWidth = dom.style.width; manualHeight = dom.style.height; dom.style.maxHeight = 'none';
          };
          const onUp = () => { isResizing = false; window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); };
          window.addEventListener('mousemove', onMove); window.addEventListener('mouseup', onUp);
          e.preventDefault(); e.stopPropagation();
        };
      });

      gui.onOpenClose(g => {
        if (g === gui) {
          if (gui._closed) { dom.style.height = 'auto'; dom.querySelectorAll('div').forEach(d => { if(d.style.cursor.includes('resize')) d.style.display='none'; }); }
          else {
            if (hasBeenManuallyResized) { dom.style.width = manualWidth; dom.style.height = manualHeight; dom.style.maxHeight = 'none'; }
            else { dom.style.width = '245px'; dom.style.height = 'auto'; dom.style.maxHeight = 'calc(100% - 20px)'; }
            dom.querySelectorAll('div').forEach(d => { if(d.style.cursor.includes('resize')) d.style.display='block'; });
          }
        }
      });

      map._layerTunerChanges = {};
      const tunerState = { showMode: config.show_all_args ? 'All Options' : 'Customized', searchQuery: '', propSearchQuery: '' };
      const allLayerControllers = [];
      const layerFolders = [];
      const layerMeta = {}; // To store initial values for reset

      const updateControllerVisibilities = function() {
        const showAll = tunerState.showMode === 'All Options';
        const propQuery = (tunerState.propSearchQuery || '').toLowerCase();
        allLayerControllers.forEach(function(meta) {
          const rName = (meta.controller._name || '').toLowerCase();
          const propMatches = !propQuery || rName.includes(propQuery);
          const isTuned = map._layerTunerChanges[meta.layerId] && map._layerTunerChanges[meta.layerId].props[meta.prop] !== undefined;
          const logicVisible = showAll || meta.originallyPresent || meta.hasInStyle || isTuned;
          if (propMatches && logicVisible) meta.controller.show(); else meta.controller.hide();
        });
      };

      const updateFolderVisibilities = function() {
        const query = (tunerState.searchQuery || '').toLowerCase();
        layerFolders.forEach(f => { const title = (f._title || '').toLowerCase(); if (!query || title.includes(query)) f.show(); else f.hide(); });
      };

      // 2. Export & Layout Reset
      gui.add({ exportCode: function() {
        try {
          const changes = map._layerTunerChanges;
          const showAllArgs = tunerState.showMode === 'All Options';
          let codeStr = '# Copy-paste this complete pipeline to recreate your styled map:\n\n';
          const parts = []; const originalCalls = config.original_calls; const processedLayerIds = new Set();
          if (originalCalls && Array.isArray(originalCalls) && originalCalls.length > 0) {
            originalCalls.forEach(function(call) {
              const fun = call.fun; const args = call.args.map(a => ({ name: a.name, value: a.value }));
              let layerId = null; const idArg = args.find(a => a.name === 'id');
              if (idArg) { layerId = idArg.value.replace(/^["']|["']$/g, ''); processedLayerIds.add(layerId); }
              if (layerId) {
                const layerChanges = changes[layerId];
                const type = fun.startsWith('add_') && fun.endsWith('_layer') ? { 'add_circle_layer': 'circle', 'add_fill_layer': 'fill', 'add_line_layer': 'line', 'add_symbol_layer': 'symbol' }[fun] : null;
                if (type && TUNER_SCHEMA[type]) {
                  const schema = TUNER_SCHEMA[type];
                  Object.keys(schema).forEach(function(propName) {
                    const rName = getRName(type, propName); let propVal = undefined;
                    if (layerChanges && layerChanges.props[propName] !== undefined) propVal = layerChanges.props[propName].value;
                    else if (args.some(a => a.name === rName) || showAllArgs) {
                      try { propVal = schema[propName].method === 'paint' ? map.getPaintProperty(layerId, propName) : map.getLayoutProperty(layerId, propName); } catch (e) {}
                      if (propVal === undefined || typeof propVal === 'object') propVal = schema[propName].default;
                    }
                    if (propVal !== undefined && typeof propVal !== 'object') {
                      const formattedVal = formatRValue(propVal); const existing = args.find(a => a.name === rName);
                      if (existing) existing.value = formattedVal; else args.push({ name: rName, value: formattedVal });
                    }
                  });
                }
              }
              if (['maplibre', 'mapboxgl', 'maplibre_compare', 'mapboxgl_compare'].includes(fun)) {
                const sArg = args.find(a => a.name === 'style');
                if (sArg && sArg.value.includes('basemaps.cartocdn.com')) {
                  const valStr = sArg.value.replace(/^["']|["']$/g, ''); const name = (valStr.split('/').slice(-2, -1)[0] || '').replace('-gl-style', '').replace('nolabels', 'no-labels');
                  sArg.value = `carto_style("${name || 'dark-matter'}")`;
                }
                parts.push(`${fun}(\n${args.map(a => `  ${a.name} = ${a.value}`).join(',\n')}\n)`);
              } else parts.push(`  ${fun}(\n${args.map(a => a.name ? `    ${a.name} = ${a.value}` : `    ${a.value}`).join(',\n')}\n  )`);
            });
          } else {
            const mt = config.map_type === 'mapboxgl' ? 'mapboxgl' : 'maplibre';
            let s = x.style || '';
            if (s.includes('basemaps.cartocdn.com')) { const n = (s.split('/').slice(-2, -1)[0] || '').replace('-gl-style', '').replace('nolabels', 'no-labels'); s = `carto_style("${n || 'dark-matter'}")`; } else s = `"${s}"`;
            parts.push(`${mt}(\n  style = ${s}${x.center ? `,\n  center = c(${x.center[0]}, ${x.center[1]})` : ''}${x.zoom ? `,\n  zoom = ${x.zoom}` : ''}\n)`);
          }
          const styleObj = map.getStyle();
          if (styleObj && styleObj.layers) {
            styleObj.layers.forEach(l => {
              if (processedLayerIds.has(l.id) || (map._basemapLayerIds && map._basemapLayerIds.has(l.id))) return;
              if (!TUNER_SCHEMA[l.type]) return;
              const rf = { 'circle': 'add_circle_layer', 'fill': 'add_fill_layer', 'line': 'add_line_layer', 'symbol': 'add_symbol_layer' }[l.type];
              let lc = `  ${rf}(\n    id = "${l.id}",\n    source = "${l.source}"`;
              const sch = TUNER_SCHEMA[l.type]; const lCh = (changes[l.id] && changes[l.id].props) || {};
              Object.keys(sch).forEach(p => {
                let v = lCh[p] ? lCh[p].value : (showAllArgs ? (function(){ try { return sch[p].method === 'paint' ? map.getPaintProperty(l.id, p) : map.getLayoutProperty(l.id, p); } catch(e){} })() : undefined);
                if (v === undefined && showAllArgs) v = sch[p].default;
                if (v !== undefined && typeof v !== 'object') lc += `,\n    ${getRName(l.type, p)} = ${formatRValue(v)}`;
              });
              parts.push(lc + '\n  )');
            });
          }
          codeStr += parts.join(' |>\n') + ' |>\n  add_layer_tuner()';
          const overlay = document.createElement('div');
          overlay.style = 'position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(0,0,0,0.6);z-index:100000;display:flex;align-items:center;justify-content:center;';
          overlay.innerHTML = `<div style="background:rgba(20,20,20,0.9);backdrop-filter:blur(10px);border:1px solid rgba(255,255,255,0.1);border-radius:12px;color:#fff;padding:24px;width:85%;max-width:520px;box-shadow:0 20px 40px rgba(0,0,0,0.6);font-family:sans-serif;"><h3>Exported R Code 🚀</h3><p style="font-size:13px;color:#aaa;">Copy and paste into your R script.</p><pre id="tuner-code-block" style="background:rgba(0,0,0,0.4);padding:16px;overflow:auto;font-family:monospace;font-size:12px;color:#8ae4b4;max-height:300px;user-select:text;-webkit-user-select:text;"><code>${codeStr}</code></pre><div style="display:flex;justify-content:flex-end;gap:12px;"><button id="tuner-close-btn" style="padding:8px 18px;border-radius:6px;cursor:pointer;border:none;background:rgba(255,255,255,0.08);color:#eee;">Close</button><button id="tuner-copy-btn" style="padding:8px 18px;border-radius:6px;cursor:pointer;border:none;background:#00bcd4;color:#121212;font-weight:600;">Copy Code</button></div></div>`;
          document.body.appendChild(overlay); document.getElementById('tuner-close-btn').onclick = () => document.body.removeChild(overlay);
          document.getElementById('tuner-copy-btn').onclick = function() {
            copyToClipboardFallback(codeStr).then(() => {
              this.textContent = 'Copied! ✓'; this.style.background = '#4caf50'; this.style.color = '#fff';
              setTimeout(() => { this.textContent = 'Copy Code'; this.style.background = '#00bcd4'; this.style.color = '#121212'; }, 2000);
            });
          };
        } catch (err) { console.error('Export Error:', err); alert('Export failed. Check console.'); }
      } }, 'exportCode').name('Export R Code 🚀');

      const resetAllLayers = function() {
        console.log('Layer Tuner: Global reset triggered');
        Object.keys(layerMeta).forEach(lid => {
          try {
            const meta = layerMeta[lid];
            if (meta.type === 'flowmap') {
              const current = map._mapglFlowmapLayers;
              if (current && current[meta.idx]) {
                const updated = current[meta.idx].clone({ ...meta.initial });
                const newArr = [...current]; newArr[meta.idx] = updated; map._mapglFlowmapLayers = newArr;
                if (map._mapglFlowmapOverlay || map._deckgl) (map._mapglFlowmapOverlay || map._deckgl).setProps({ layers: map._mapglFlowmapLayers });
                Object.assign(meta.state, meta.initial);
              }
            } else {
              Object.keys(meta.rawInitial).forEach(p => {
                const spec = TUNER_SCHEMA[meta.type][p];
                const rawVal = meta.rawInitial[p];
                try {
                  // If rawVal was undefined originally, some map properties cannot be unset to undefined.
                  // Try to apply it, or gracefully fail.
                  if (rawVal !== undefined) {
                    if (spec.method === 'paint') map.setPaintProperty(lid, p, rawVal);
                    else map.setLayoutProperty(lid, p, rawVal);
                  }
                } catch (e) { console.warn(`Layer Tuner: Reset property ${p} failed on ${lid}`, e); }
                meta.state[p] = meta.initial[p]; // Update UI state
              });
            }
            delete map._layerTunerChanges[lid];
          } catch (e) { console.error(`Layer Tuner: Failed resetting layer ${lid}`, e); }
        });
        
        try {
          gui.controllersRecursive().forEach(c => { if(c && typeof c.updateDisplay === 'function') c.updateDisplay(); });
          updateControllerVisibilities();
        } catch (e) { console.error('Layer Tuner: Failed updating UI post-reset', e); }
      };

      gui.add({ resetAll: resetAllLayers }, 'resetAll').name('♻️ Reset All Layers');
      gui.add({ resetLayout: function() { hasBeenManuallyResized = false; manualWidth = '245px'; manualHeight = 'auto'; dom.style.width = manualWidth; dom.style.height = manualHeight; dom.style.maxHeight = 'calc(100% - 20px)'; dom.style.top = '10px'; dom.style.left = '10px'; } }, 'resetLayout').name('🔄 Reset UI Layout');

      // 3. Toggles & Search
      const modeRow = document.createElement('div');
      modeRow.style.display = 'flex'; modeRow.style.gap = '2px'; modeRow.style.padding = '0 4px'; modeRow.style.margin = '4px 0';
      const bCust = document.createElement('button'); bCust.textContent = '🎯 Customized'; bCust.style.flex = '1'; bCust.style.fontSize = '10px'; bCust.style.padding = '6px 0'; bCust.style.background = tunerState.showMode === 'Customized' ? '#00bcd4' : '#424242'; bCust.style.color = tunerState.showMode === 'Customized' ? '#121212' : '#fff'; bCust.style.border = 'none'; bCust.style.borderRadius = '2px'; bCust.style.cursor = 'pointer'; bCust.style.fontWeight = '600';
      const bAll = document.createElement('button'); bAll.textContent = '🌐 All Options'; bAll.style.flex = '1'; bAll.style.fontSize = '10px'; bAll.style.padding = '6px 0'; bAll.style.background = tunerState.showMode === 'All Options' ? '#00bcd4' : '#424242'; bAll.style.color = tunerState.showMode === 'All Options' ? '#121212' : '#fff'; bAll.style.border = 'none'; bAll.style.borderRadius = '2px'; bAll.style.cursor = 'pointer'; bAll.style.fontWeight = '600';
      const setMode = (m) => { tunerState.showMode = m; bCust.style.background = m === 'Customized' ? '#00bcd4' : '#424242'; bCust.style.color = m === 'Customized' ? '#121212' : '#fff'; bAll.style.background = m === 'All Options' ? '#00bcd4' : '#424242'; bAll.style.color = m === 'All Options' ? '#121212' : '#fff'; updateControllerVisibilities(); };
      bCust.onclick = () => setMode('Customized'); bAll.onclick = () => setMode('All Options'); modeRow.appendChild(bCust); modeRow.appendChild(bAll); dom.querySelector('.children').prepend(modeRow);

      const searchCtrl = gui.add(tunerState, 'searchQuery').name('🔍 Search Layers').onChange(updateFolderVisibilities);
      try { const input = searchCtrl.domElement.querySelector('input'); if (input) input.addEventListener('input', function() { tunerState.searchQuery = this.value; updateFolderVisibilities(); }); } catch (e) {}
      const propSearchCtrl = gui.add(tunerState, 'propSearchQuery').name('🔍 Search Args').onChange(updateControllerVisibilities);
      try { const input = propSearchCtrl.domElement.querySelector('input'); if (input) input.addEventListener('input', function() { tunerState.propSearchQuery = this.value; updateControllerVisibilities(); }); } catch (e) {}

      const btnRow = document.createElement('div');
      btnRow.style.display = 'flex'; btnRow.style.gap = '2px'; btnRow.style.padding = '0 4px'; btnRow.style.margin = '4px 0';
      const bExpand = document.createElement('button'); bExpand.textContent = '📂 Expand All'; bExpand.style.flex = '1'; bExpand.style.fontSize = '10px'; bExpand.style.padding = '4px 0'; bExpand.style.background = '#424242'; bExpand.style.color = '#fff'; bExpand.style.border = 'none'; bExpand.style.borderRadius = '2px'; bExpand.style.cursor = 'pointer'; bExpand.onclick = () => layerFolders.forEach(f => f.open());
      const bCollapse = document.createElement('button'); bCollapse.textContent = '📁 Collapse All'; bCollapse.style.flex = '1'; bCollapse.style.fontSize = '10px'; bCollapse.style.padding = '4px 0'; bCollapse.style.background = '#424242'; bCollapse.style.color = '#fff'; bCollapse.style.border = 'none'; bCollapse.style.borderRadius = '2px'; bCollapse.style.cursor = 'pointer'; bCollapse.onclick = () => layerFolders.forEach(f => f.close());
      btnRow.appendChild(bExpand); btnRow.appendChild(bCollapse); dom.querySelector('.children').insertBefore(btnRow, searchCtrl.domElement);

      // 4. Robust Draggability
      const titleEl = dom.querySelector('.title');
      if (titleEl) {
        titleEl.style.cursor = 'move'; let dragging = false, moved = false, sx, sy, ex, ey;
        titleEl.addEventListener('mousedown', (e) => {
          if (e.button !== 0 || isResizing) return;
          dragging = true; moved = false; sx = e.clientX; sy = e.clientY;
          const r = dom.getBoundingClientRect(); const pr = el.getBoundingClientRect(); ex = r.left - pr.left; ey = r.top - pr.top;
          dom.style.height = r.height + 'px'; dom.style.width = r.width + 'px'; dom.style.maxHeight = 'none';
        });
        window.addEventListener('mousemove', (e) => {
          if (!dragging) return; const dx = e.clientX - sx, dy = e.clientY - sy; if (Math.hypot(dx, dy) > 5) moved = true;
          if (moved) { const pr = el.getBoundingClientRect(); let nx = ex + dx, ny = ey + dy; nx = Math.max(0, Math.min(nx, pr.width - 50)); ny = Math.max(0, Math.min(ny, pr.height - 30)); dom.style.left = nx + 'px'; dom.style.top = ny + 'px'; }
        });
        window.addEventListener('mouseup', () => { dragging = false; if (!hasBeenManuallyResized && !gui._closed) { dom.style.height = 'auto'; dom.style.maxHeight = 'calc(100% - 20px)'; } });
        titleEl.addEventListener('click', (e) => { if (moved) { e.stopImmediatePropagation(); e.preventDefault(); moved = false; } }, { capture: true });
      }

      // 5. Process Layers
      const style = map.getStyle();
      if (style && style.layers) {
        style.layers.forEach(function(l) {
          if ((map._basemapLayerIds && map._basemapLayerIds.has(l.id)) || !TUNER_SCHEMA[l.type]) return;
          if (config.layers && config.layers !== 'all' && !config.layers.includes(l.id)) return;
          const folder = gui.addFolder(`${l.type.toUpperCase()}: ${l.id}`);
          folder.close(); layerFolders.push(folder);
          const s = {}, initial = {}, rawInitial = {};
          layerMeta[l.id] = { type: l.type, state: s, initial: initial, rawInitial: rawInitial };
          Object.keys(TUNER_SCHEMA[l.type]).forEach(p => {
            const spec = TUNER_SCHEMA[l.type][p]; let v = undefined;
            try { v = spec.method === 'paint' ? map.getPaintProperty(l.id, p) : map.getLayoutProperty(l.id, p); } catch (e) {}
            rawInitial[p] = v; // Store original format (could be an object/expression)
            if (v === undefined || typeof v === 'object') v = spec.default;
            s[p] = v; initial[p] = v;
            let orig = false;
            if (config.original_calls) {
              const rn = getRName(l.type, p); const mc = config.original_calls.find(c => { const ia = c.args.find(a => a.name === 'id'); return ia && ia.value.replace(/^["']|["']$/g, '') === l.id; });
              if (mc) orig = mc.args.some(a => a.name === rn);
            }
            const hasS = (spec.method === 'paint' && l.paint && l.paint[p] !== undefined) || (spec.method === 'layout' && l.layout && l.layout[p] !== undefined);
            const ctrl = spec.type === 'color' ? folder.addColor(s, p) : (spec.type === 'slider' ? folder.add(s, p, spec.min, spec.max, spec.step) : folder.add(s, p));
            if (ctrl) {
              ctrl.name(getRName(l.type, p)); allLayerControllers.push({ controller: ctrl, type: l.type, prop: p, layerId: l.id, originallyPresent: orig, hasInStyle: hasS });
              ctrl.onChange(nv => {
                try {
                  if (spec.method === 'paint') map.setPaintProperty(l.id, p, nv); else map.setLayoutProperty(l.id, p, nv);
                  if (!map._layerTunerChanges[l.id]) map._layerTunerChanges[l.id] = { type: l.type, props: {} };
                  map._layerTunerChanges[l.id].props[p] = { method: spec.method, value: nv };
                  updateControllerVisibilities();
                } catch (e) {}
              });
            }
          });
          folder.add({ reset: function() {
            console.log(`Layer Tuner: Resetting layer ${l.id}`);
            try {
              Object.keys(rawInitial).forEach(p => {
                const sp = TUNER_SCHEMA[l.type][p];
                const rawVal = rawInitial[p];
                try {
                  if (rawVal !== undefined) {
                    if (sp.method === 'paint') map.setPaintProperty(l.id, p, rawVal);
                    else map.setLayoutProperty(l.id, p, rawVal);
                  }
                } catch(e) {}
                s[p] = initial[p];
              });
              delete map._layerTunerChanges[l.id];
              try {
                folder.controllersRecursive().forEach(c => { if(c && typeof c.updateDisplay === 'function') c.updateDisplay(); });
                updateControllerVisibilities();
              } catch(e){}
            } catch(e) { console.error(`Failed to reset layer ${l.id}`, e); }
          }}, 'reset').name('♻️ Reset Layer');
        });
      }

      // 6. Flowmaps
      if (map._mapglFlowmapLayers) {
        map._mapglFlowmapLayers.forEach((l, i) => {
          const lid = l.id || `flowmap-${i}`; if (config.layers && config.layers !== 'all' && !config.layers.includes(lid)) return;
          const folder = gui.addFolder(`FLOWMAP: ${lid}`); folder.close(); layerFolders.push(folder);
          const initial = { colorScheme: l.props.colorScheme || 'Teal', darkMode: l.props.darkMode !== undefined ? l.props.darkMode : true, opacity: l.props.opacity !== undefined ? l.props.opacity : 1, blendMode: map._deckCanvas && map._deckCanvas.style.mixBlendMode ? map._deckCanvas.style.mixBlendMode : 'screen' };
          const fs = { ...initial };
          layerMeta[lid] = { type: 'flowmap', state: fs, initial: initial, idx: i };
          const up = () => {
            try {
              const cur = map._mapglFlowmapLayers; const nL = cur[i].clone({ colorScheme: fs.colorScheme, darkMode: fs.darkMode, opacity: fs.opacity }); const nArr = [...cur]; nArr[i] = nL; map._mapglFlowmapLayers = nArr;
              (map._mapglFlowmapOverlay || map._deckgl).setProps({ layers: map._mapglFlowmapLayers }); if (map._deckCanvas) map._deckCanvas.style.mixBlendMode = fs.blendMode;
              map._layerTunerChanges[lid] = { type: 'flowmap', props: { ...fs } }; if (map.triggerRepaint) map.triggerRepaint();
            } catch (e) {}
          };
          folder.add(fs, 'colorScheme', config.flowmap_color_schemes || ['Teal', 'Blues', 'Burg', 'Sunset', 'Greens', 'Oranges', 'Purples', 'Reds']).name(getRName('flowmap', 'colorScheme')).onChange(up);
          folder.add(fs, 'darkMode').name(getRName('flowmap', 'darkMode')).onChange(up);
          folder.add(fs, 'opacity', 0, 1, 0.05).name(getRName('flowmap', 'opacity')).onChange(up);
          folder.add(fs, 'blendMode', ['normal', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 'color-dodge', 'color-burn', 'hard-light', 'soft-light', 'difference', 'exclusion', 'hue', 'saturation', 'color', 'luminosity']).name(getRName('flowmap', 'blendMode')).onChange(up);
          folder.add({ reset: function() {
            console.log(`Layer Tuner: Resetting flowmap ${lid}`);
            try {
              Object.assign(fs, initial); 
              up(); 
              delete map._layerTunerChanges[lid];
              try {
                folder.controllersRecursive().forEach(c => { if(c && typeof c.updateDisplay === 'function') c.updateDisplay(); });
                updateControllerVisibilities();
              } catch(e){}
            } catch(e) { console.error(`Failed to reset flowmap ${lid}`, e); }
          }}, 'reset').name('♻️ Reset Layer');
        });
      }

      updateControllerVisibilities(); updateFolderVisibilities();
    }
  };
})();
