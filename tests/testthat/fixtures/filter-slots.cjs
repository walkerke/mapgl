// Filter-slot composition: set_filter() replaces a layer's initial filter
// (#215), while legend and slider filters compose with whichever is active.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const context = {
  window: {}, document: {addEventListener() {}}, console,
  HTMLWidgets: {widget() {}, shinyMode: false}
};
vm.createContext(context);
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), context);
const applied = {};
const map = {
  getContainer: () => ({id: 'fixture'}),
  getLayer: () => true,
  setFilter: (id, filter) => { applied[id] = JSON.parse(JSON.stringify(filter)); }
};
const state = context._mapglEnsureLayerState(map);
const compose = () => context._mapglComposeAndApplyFilter(map, 'lyr');
const plain = x => JSON.parse(JSON.stringify(x));
const county = ['==', ['get', 'level'], 'county'];
const muni = ['==', ['get', 'level'], 'muni'];
const legend = ['match', ['get', 'type'], ['a'], true, false];
const slider = ['>=', ['get', 'year'], 2000];

state.filterStack.lyr = {base: county};
compose();
assert.deepEqual(applied.lyr, county, 'initial filter applies alone');

state.filterStack.lyr.user = muni;
compose();
assert.deepEqual(applied.lyr, muni, 'set_filter replaces the initial filter');
assert.deepEqual(plain(state.filters.lyr), muni, 'replay state matches');

state.filterStack.lyr.user = null;
compose();
assert.equal(applied.lyr, null, 'set_filter(NULL) clears the filter');

state.filterStack.lyr = {base: county, legend: legend, slider: slider};
compose();
assert.deepEqual(applied.lyr, ['all', county, legend, slider], 'legend and slider compose with base');

state.filterStack.lyr.user = muni;
compose();
assert.deepEqual(applied.lyr, ['all', muni, legend, slider], 'legend and slider compose with set_filter');

console.log('Filter slots compose correctly.');
