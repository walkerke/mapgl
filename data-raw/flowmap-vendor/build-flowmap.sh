#!/usr/bin/env bash
set -euo pipefail

VENDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$VENDOR_DIR/../.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/inst/htmlwidgets/lib/flowmap-gl"
LICENSE_NOTE_PATH="$ROOT_DIR/LICENSE.note"
COMMAND="${1:-build}"
BUNDLE_NAME="flowmap-gl-bundle.min.js"
DEBUG_BUNDLE_NAME="flowmap-gl-bundle.js"
MANIFEST_NAME="flowmap-gl-vendor-manifest.json"
GENERATED_FILES=(
  "$DEBUG_BUNDLE_NAME"
  "$DEBUG_BUNDLE_NAME.map"
  "$BUNDLE_NAME"
  "$BUNDLE_NAME.map"
  "$MANIFEST_NAME"
)

usage() {
  cat <<'EOF'
Usage: data-raw/flowmap-vendor/build-flowmap.sh [build|check]

Commands:
  build  Rebuild the committed FlowmapGL bundle, manifest, and license note.
  check  Rebuild in a temporary directory and fail if committed outputs differ.
EOF
}

build_outputs() {
  local output_dir="$1"
  local license_note_path="$2"

  cd "$VENDOR_DIR"
  npm ci --silent
  apply_patches

  mkdir -p "$output_dir"
  npx esbuild entry.js \
    --bundle \
    --format=iife \
    --outfile="$output_dir/$DEBUG_BUNDLE_NAME" \
    --sourcemap \
    --sources-content=true
  normalize_sourcemap "$output_dir/$DEBUG_BUNDLE_NAME.map"

  npx esbuild entry.js \
    --bundle \
    --format=iife \
    --outfile="$output_dir/$BUNDLE_NAME" \
    --minify \
    --sourcemap \
    --sources-content=true
  normalize_sourcemap "$output_dir/$BUNDLE_NAME.map"

  node scripts/generate-vendor-metadata.mjs "$output_dir" "$license_note_path"
}

normalize_sourcemap() {
  local sourcemap_path="$1"

  node - "$sourcemap_path" <<'NODE'
const {readFileSync, writeFileSync} = require('node:fs');

const sourcemapPath = process.argv[2];
const marker = 'data-raw/flowmap-vendor/';
const sourcemap = JSON.parse(readFileSync(sourcemapPath, 'utf8'));

sourcemap.sources = sourcemap.sources.map((source) => {
  const markerIndex = source.indexOf(marker);
  if (markerIndex >= 0) {
    return source.slice(markerIndex + marker.length);
  }
  return source;
});

writeFileSync(sourcemapPath, `${JSON.stringify(sourcemap)}\n`);
NODE
}

apply_patches() {
  local patches=()
  shopt -s nullglob
  patches=("$VENDOR_DIR"/patches/*.patch)
  shopt -u nullglob

  if ((${#patches[@]} == 0)); then
    return 0
  fi

  for patch in "${patches[@]}"; do
    git -C "$ROOT_DIR" apply --check --directory="data-raw/flowmap-vendor" "$patch"
  done

  for patch in "${patches[@]}"; do
    git -C "$ROOT_DIR" apply --directory="data-raw/flowmap-vendor" "$patch"
  done
}

case "$COMMAND" in
  build)
    build_outputs "$OUTPUT_DIR" "$LICENSE_NOTE_PATH"
    ls -lh "$OUTPUT_DIR/$DEBUG_BUNDLE_NAME" "$OUTPUT_DIR/$BUNDLE_NAME"
    ;;
  check)
    TMP_DIR="$(mktemp -d)"
    cleanup() {
      rm -rf "$TMP_DIR"
    }
    trap cleanup EXIT

    build_outputs "$TMP_DIR" "$TMP_DIR/LICENSE.note"
    for file in "${GENERATED_FILES[@]}"; do
      diff -u "$OUTPUT_DIR/$file" "$TMP_DIR/$file"
    done
    diff -u "$LICENSE_NOTE_PATH" "$TMP_DIR/LICENSE.note"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
