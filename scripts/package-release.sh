#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /path/to/InkLook.app 0.1.0"
  exit 1
fi

APP_PATH="$1"
VERSION="$2"
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/dist/$VERSION"
ZIP_PATH="$OUTPUT_DIR/InkLook.zip"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -f "$ZIP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

echo "Release artifact: $ZIP_PATH"
echo "SHA256: $SHA256"
echo "Update packaging/homebrew/inklook.rb with version $VERSION and the SHA256 above."
