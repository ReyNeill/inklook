#!/bin/zsh
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /path/to/InkLook.app <version>"
  exit 1
fi

APP_PATH="$1"
VERSION="$2"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/dist/$VERSION"
STAGE_ROOT="$OUTPUT_DIR/stage"
STAGED_APP_PATH="$STAGE_ROOT/InkLook.app"
ZIP_PATH="$OUTPUT_DIR/InkLook.zip"
PLUGIN_PATH="$STAGED_APP_PATH/Contents/PlugIns/InkLookPreview.appex"
APP_BINARY="$STAGED_APP_PATH/Contents/MacOS/InkLook"
PLUGIN_BINARY="$PLUGIN_PATH/Contents/MacOS/InkLookPreview"
APP_ENTITLEMENTS="$PROJECT_ROOT/Sources/App/InkLook.entitlements"
PLUGIN_ENTITLEMENTS="$PROJECT_ROOT/Sources/Extension/InkLookPreview.entitlements"

sign_if_present() {
  local path="$1"

  if [[ -e "$path" ]]; then
    /usr/bin/codesign --force --sign - --timestamp=none "$path"
  fi
}

remove_signature_if_present() {
  local path="$1"

  if [[ -e "$path" ]]; then
    /usr/bin/codesign --remove-signature "$path" 2>/dev/null || true
  fi
}

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH"
  exit 1
fi

if [[ ! -f "$APP_ENTITLEMENTS" ]]; then
  echo "Missing app entitlements: $APP_ENTITLEMENTS"
  exit 1
fi

if [[ ! -f "$PLUGIN_ENTITLEMENTS" ]]; then
  echo "Missing extension entitlements: $PLUGIN_ENTITLEMENTS"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$STAGE_ROOT"
rm -f "$ZIP_PATH"

ditto "$APP_PATH" "$STAGED_APP_PATH"

# Re-sign the staged copy ad hoc so the release artifact does not pretend to be a Developer ID or
# Apple Development build. For the Homebrew/quarantine-stripping path, honest ad hoc signing is a
# better description of the trust model than shipping a local-development signature.
remove_signature_if_present "$PLUGIN_PATH/Contents/MacOS/InkLookPreview.debug.dylib"
remove_signature_if_present "$PLUGIN_PATH/Contents/MacOS/__preview.dylib"
remove_signature_if_present "$PLUGIN_BINARY"
remove_signature_if_present "$STAGED_APP_PATH/Contents/MacOS/InkLook.debug.dylib"
remove_signature_if_present "$STAGED_APP_PATH/Contents/MacOS/__preview.dylib"
remove_signature_if_present "$APP_BINARY"
remove_signature_if_present "$PLUGIN_PATH"
remove_signature_if_present "$STAGED_APP_PATH"
sign_if_present "$PLUGIN_PATH/Contents/MacOS/InkLookPreview.debug.dylib"
sign_if_present "$PLUGIN_PATH/Contents/MacOS/__preview.dylib"
sign_if_present "$PLUGIN_BINARY"
/usr/bin/codesign --force --sign - --timestamp=none --entitlements "$PLUGIN_ENTITLEMENTS" "$PLUGIN_PATH"
sign_if_present "$STAGED_APP_PATH/Contents/MacOS/InkLook.debug.dylib"
sign_if_present "$STAGED_APP_PATH/Contents/MacOS/__preview.dylib"
sign_if_present "$APP_BINARY"
/usr/bin/codesign --force --sign - --timestamp=none --entitlements "$APP_ENTITLEMENTS" "$STAGED_APP_PATH"
/usr/bin/codesign --verify --deep --strict "$STAGED_APP_PATH"

ditto -c -k --keepParent "$STAGED_APP_PATH" "$ZIP_PATH"
SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

echo "Staged app: $STAGED_APP_PATH"
echo "Release artifact: $ZIP_PATH"
echo "SHA256: $SHA256"
echo "Signature:"
/usr/bin/codesign -dv --verbose=2 "$STAGED_APP_PATH" 2>&1 | /usr/bin/grep -E "^Authority=|^Identifier=|^TeamIdentifier=|^Signature size="
echo "Update packaging/homebrew/inklook.rb with version $VERSION and the SHA256 above."
