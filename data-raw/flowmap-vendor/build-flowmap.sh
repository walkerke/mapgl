#!/usr/bin/env bash
set -euo pipefail

VENDOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$VENDOR_DIR/../.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/inst/htmlwidgets/lib/flowmap-gl"
LICENSE_NOTE_PATH="$ROOT_DIR/LICENSE.note"
COMMAND="${1:-build}"
BUNDLE_NAME="flowmap-gl-bundle.min.js"
MANIFEST_NAME="flowmap-gl-vendor-manifest.json"
GENERATED_FILES=(
  "$BUNDLE_NAME"
  "$MANIFEST_NAME"
)
OBSOLETE_FILES=(
  "flowmap-gl-bundle.js"
  "flowmap-gl-bundle.js.map"
  "flowmap-gl-bundle.min.js.map"
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
    --outfile="$output_dir/$BUNDLE_NAME" \
    --minify

  node scripts/generate-vendor-metadata.mjs "$output_dir" "$license_note_path"
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
    for file in "${OBSOLETE_FILES[@]}"; do
      rm -f "$OUTPUT_DIR/$file"
    done
    build_outputs "$OUTPUT_DIR" "$LICENSE_NOTE_PATH"
    ls -lh "$OUTPUT_DIR/$BUNDLE_NAME"
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
    for file in "${OBSOLETE_FILES[@]}"; do
      if [[ -e "$OUTPUT_DIR/$file" ]]; then
        printf 'Obsolete generated file remains: %s\n' "$OUTPUT_DIR/$file" >&2
        exit 1
      fi
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
