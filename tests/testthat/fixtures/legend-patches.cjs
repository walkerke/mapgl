// Event-level regression: toggle/reset may change enabled state, not patch paint.
// Tiny DOM doubles deliberately expose backgroundColor on SVG, as browsers do.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const context = {window: {}, document: {addEventListener() {}}, console};
vm.createContext(context);
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), context);
const shapes = ['square', 'circle', 'line', 'hexagon', 'custom'];
const items = shapes.map((shape, i) => {
  const svg = i >= 3;
  const patch = {
    tagName: svg ? 'svg' : 'SPAN',
    style: {backgroundColor: svg ? '' : '#619cff'},
    innerHTML: svg ? '<path fill="#619cff" fill-opacity="0.6" d="M0 0h4v4z"/>' : '',
    getAttribute: () => null
  };
  const attributes = {};
  const handlers = {};
  return {
    patch, shape, handlers,
    getAttribute: name => attributes[name] ?? null,
    setAttribute: (name, value) => { attributes[name] = String(value); },
    querySelector: () => patch,
    addEventListener: (name, callback) => { handlers[name] = callback; }
  };
});
const originalPaint = items.map(item => JSON.stringify(item.patch));
const legend = {querySelectorAll: () => items};
const base = ['==', ['get', 'modal_tie'], false];
const calls = {};
const map = {setFilter: (id, filter) => {calls[id] = JSON.parse(JSON.stringify(filter));}};
const layerIds = ['r4', 'r5'];
const state = {interactiveFilters: {}, filterStack: {}, filters: {}};
layerIds.forEach(id => {state.interactiveFilters[id] = {originalFilter: base};});
context.window._mapglLayerState = {fixture: state};
let reset;
let resetVisible;
context.addResetButton = (_legend, callback) => {reset = callback;};
context.updateResetButton = (_legend, visible) => {resetVisible = visible;};
context.initCategoricalLegend(map, 'fixture', legend, 'group_id', {
  _layerIds: layerIds, legendId: 'fixture-legend', values: shapes,
  filterValues: [1,2,3,4,5], colors: shapes.map(() => '#619cff')
});
function click(index) {
  items[index].handlers.click({preventDefault() {}, stopPropagation() {}});
}
function paintUnchanged() {
  items.forEach((item, i) => assert.equal(JSON.stringify(item.patch), originalPaint[i], item.shape));
}
for (let round = 0; round < 3; round++) {
  items.forEach((item, i) => {
    click(i);
    assert.equal(item.getAttribute('data-enabled'), 'false');
    assert.equal(resetVisible, true);
    paintUnchanged();
    layerIds.forEach(id => {
      calls[id][2][2].sort((a,b) => a-b);
      assert.deepEqual(calls[id],
        ['all', base, ['match', ['get','group_id'], [1,2,3,4,5].filter(v => v !== i+1), true, false]]);
    });
    click(i);
    assert.equal(item.getAttribute('data-enabled'), 'true');
    assert.equal(resetVisible, false);
    paintUnchanged();
  });
}
click(0); click(3); click(4);
reset();
items.forEach(item => assert.equal(item.getAttribute('data-enabled'), 'true'));
paintUnchanged();
assert.equal(resetVisible, false);
layerIds.forEach(id => assert.deepEqual(calls[id], base));
console.log('Patch paint preserved through repeated toggles and reset; filters preserved.');
