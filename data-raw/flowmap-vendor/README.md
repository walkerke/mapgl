# FlowmapGL Vendoring

This directory contains the reproducible npm workspace used to build the
vendored FlowmapGL browser asset shipped with mapgl.

## Package Developer Workflow

Most R package development does not need to touch FlowmapGL vendoring. The
package ships the already-built browser asset in
`inst/htmlwidgets/lib/flowmap-gl/`.

Do not hand-edit files under `inst/htmlwidgets/lib/flowmap-gl/`. They are
generated outputs from this vendoring workspace.

Run `check` before committing when you changed any FlowmapGL vendoring input,
or when you want to verify the checked-in asset still matches this workspace:

```sh
data-raw/flowmap-vendor/build-flowmap.sh check
```

Run `build` only when intentionally regenerating the vendored FlowmapGL files,
for example after:

- changing a pinned npm package version in `package.json`
- changing the FlowmapGL bundle entry point in `entry.js`
- changing a patch under `patches/`
- changing metadata or notice generation in `scripts/generate-vendor-metadata.mjs`
- refreshing the npm lockfile intentionally

Run from the repository root:

```sh
data-raw/flowmap-vendor/build-flowmap.sh build
data-raw/flowmap-vendor/build-flowmap.sh check
```

The build command runs `npm ci`, applies every `patches/*.patch` with
`git apply --check` first, bundles `entry.js` with esbuild, and writes:

- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.js`
- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.js.map`
- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js`
- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js.map`
- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-vendor-manifest.json`
- `LICENSE.note`

The check command rebuilds those files in a temporary directory and fails if
the committed copies differ.

Commit the vendoring workspace files, the generated files under
`inst/htmlwidgets/lib/flowmap-gl/`, and any tests that verify those outputs.
Do not commit `data-raw/flowmap-vendor/node_modules/`; it is recreated by
`npm ci`.

The normal supported source for FlowmapGL is the npm release pinned in
`package.json` and `package-lock.json`. The manifest records package tarball
integrity values, npm `gitHead` values where available, and the SHA256 of the
generated browser bundle.

## Local FlowmapGL Patch

mapgl adds `flow_temporal_scale_domain` for temporal flowmaps. FlowmapGL 9.3.0
only supports viewport-adaptive scaling, so mapgl carries
`patches/flowmap-temporal-scale-domain.patch` until upstream provides a native
temporal scale-domain control.

`adaptiveScalesEnabled` remains spatial: when enabled, scale domains are limited
to flows with endpoints in the current viewport. `temporalScaleDomain` is
temporal: `"selected"` uses selected-time flows for width/color domains and
`"all"` uses all-time flows for comparable widths/colors across time.

## Patch Failures

If patch application fails after bumping FlowmapGL, inspect upstream for native
temporal scale-domain support.

- If upstream supports it, remove the local patch and wire mapgl to the upstream
  prop.
- If upstream does not support it, rebase the patch against the new
  `FlowmapSelectors` and `FlowmapLayer` internals.

The acceptance invariant is: rendered flows may remain time-filtered, but
width/color domains must use selected-time flows for `"selected"` and all-time
flows for `"all"`.
