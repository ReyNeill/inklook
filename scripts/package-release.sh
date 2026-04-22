#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /path/to/InkLook.app 0.1.0"
  exit 1
fi

APP_PATH="$1"
VERSION="$2"
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/dist/$VERSION"
STAGE_ROOT="$OUTPUT_DIR/stage"
STAGED_APP_PATH="$STAGE_ROOT/InkLook.app"
ZIP_PATH="$OUTPUT_DIR/InkLook.zip"
PLUGIN_PATH="$STAGED_APP_PATH/Contents/PlugIns/InkLookPreview.appex"
APP_BINARY="$STAGED_APP_PATH/Contents/MacOS/InkLook"
PLUGIN_BINARY="$PLUGIN_PATH/Contents/MacOS/InkLookPreview"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$STAGE_ROOT"
rm -f "$ZIP_PATH"

ditto "$APP_PATH" "$STAGED_APP_PATH"

# Re-sign the staged copy ad hoc so the release artifact does not pretend to be a Developer ID or
# Apple Development build. For the Homebrew/quarantine-stripping path, honest ad hoc signing is a
# better description of the trust model than shipping a local-development signature.
/usr/bin/codesign --remove-signature "$PLUGIN_BINARY" 2>/dev/null || true
/usr/bin/codesign --remove-signature "$APP_BINARY" 2>/dev/null || true
/usr/bin/codesign --remove-signature "$PLUGIN_PATH" 2>/dev/null || true
/usr/bin/codesign --remove-signature "$STAGED_APP_PATH" 2>/dev/null || true
/usr/bin/codesign --force --sign - --timestamp=none "$PLUGIN_BINARY"
/usr/bin/codesign --force --sign - --timestamp=none "$PLUGIN_PATH"
/usr/bin/codesign --force --sign - --timestamp=none "$APP_BINARY"
/usr/bin/codesign --force --sign - --timestamp=none "$STAGED_APP_PATH"
/usr/bin/codesign --verify --deep --strict "$STAGED_APP_PATH"

ditto -c -k --keepParent "$STAGED_APP_PATH" "$ZIP_PATH"
SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

echo "Staged app: $STAGED_APP_PATH"
echo "Release artifact: $ZIP_PATH"
echo "SHA256: $SHA256"
echo "Signature:"
/usr/bin/codesign -dv --verbose=2 "$STAGED_APP_PATH" 2>&1 | /usr/bin/grep -E "^Authority=|^Identifier=|^TeamIdentifier=|^Signature size="
echo "Update packaging/homebrew/inklook.rb with version $VERSION and the SHA256 above."
