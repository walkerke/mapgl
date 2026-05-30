# FlowmapGL Vendoring

This directory contains the reproducible npm workspace used to build the
vendored FlowmapGL browser asset shipped with mapgl.

## Package Developer Workflow

Most R package development does not need to touch FlowmapGL vendoring. The
package ships the already-built browser asset in
`inst/htmlwidgets/lib/flowmap-gl/`.

Run `check` before committing when you changed any FlowmapGL vendoring input,
or when you want to verify the checked-in asset still matches this workspace:

```sh
data-raw/flowmap-vendor/build-flowmap.sh check
```

Run `build` only when intentionally regenerating the vendored FlowmapGL files,
for example after:

- changing a pinned npm package version in `package.json`
- changing the FlowmapGL bundle entry point in `entry.js`
- changing metadata or notice generation in `scripts/generate-vendor-metadata.mjs`
- refreshing the npm lockfile intentionally

Run from the repository root:

```sh
data-raw/flowmap-vendor/build-flowmap.sh build
data-raw/flowmap-vendor/build-flowmap.sh check
```

The build command runs `npm ci`, bundles `entry.js` with esbuild, and writes:

- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-bundle.min.js`
- `inst/htmlwidgets/lib/flowmap-gl/flowmap-gl-vendor-manifest.json`
- `inst/COPYRIGHTS`

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
