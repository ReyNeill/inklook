#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /Applications/InkLook.app"
  exit 1
fi

APP_PATH="$1"
PLUGIN_PATH="$APP_PATH/Contents/PlugIns/InkLookPreview.appex"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH"
  exit 1
fi

if [[ ! -d "$PLUGIN_PATH" ]]; then
  echo "Quick Look extension not found: $PLUGIN_PATH"
  exit 1
fi

pluginkit -a "$PLUGIN_PATH"
qlmanage -r

echo "Quick Look extension re-registered."
