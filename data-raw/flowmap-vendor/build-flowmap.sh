#!/usr/bin/env bash
set -euo pipefail

VENDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$VENDOR_DIR/../.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/inst/htmlwidgets/lib/flowmap-gl"
COPYRIGHTS_PATH="$ROOT_DIR/inst/COPYRIGHTS"
COMMAND="${1:-build}"
BUNDLE_NAME="flowmap-gl-bundle.min.js"
MANIFEST_NAME="flowmap-gl-vendor-manifest.json"

usage() {
  cat <<'EOF'
Usage: data-raw/flowmap-vendor/build-flowmap.sh [build|check]

Commands:
  build  Rebuild the committed FlowmapGL bundle, manifest, and copyrights.
  check  Rebuild in a temporary directory and fail if committed outputs differ.
EOF
}

build_outputs() {
  local output_dir="$1"
  local copyrights_path="$2"

  cd "$VENDOR_DIR"
  npm ci --silent

  mkdir -p "$output_dir"
  npx esbuild entry.js \
    --bundle \
    --format=iife \
    --outfile="$output_dir/$BUNDLE_NAME" \
    --minify

  node scripts/generate-vendor-metadata.mjs "$output_dir" "$copyrights_path"
}

case "$COMMAND" in
  build)
    build_outputs "$OUTPUT_DIR" "$COPYRIGHTS_PATH"
    ls -lh "$OUTPUT_DIR/$BUNDLE_NAME"
    ;;
  check)
    TMP_DIR="$(mktemp -d)"
    cleanup() {
      rm -rf "$TMP_DIR"
    }
    trap cleanup EXIT

    build_outputs "$TMP_DIR" "$TMP_DIR/COPYRIGHTS"
    diff -u "$OUTPUT_DIR/$BUNDLE_NAME" "$TMP_DIR/$BUNDLE_NAME"
    diff -u "$OUTPUT_DIR/$MANIFEST_NAME" "$TMP_DIR/$MANIFEST_NAME"
    diff -u "$COPYRIGHTS_PATH" "$TMP_DIR/COPYRIGHTS"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
