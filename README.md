# InkLook

InkLook is a small native macOS Quick Look preview extension for Markdown files.

The containing app is intentionally headless. It has no user-facing window, no Dock icon, and
exists only because Apple distributes Quick Look preview extensions inside a containing app.

## Goals

- No embedded web view
- No JavaScript
- No network entitlement
- No auto-update framework
- Native Markdown parsing via Apple's Foundation APIs
- Plug-and-play Homebrew distribution

## What It Supports

- Finder Quick Look previews for common Markdown extensions
- Read-only rendering with truncation for very large files
- Plain-text fallback if Markdown parsing fails
- No-window host app for extension packaging and distribution

## Project Layout

- `Sources/App`: the hidden containing app
- `Sources/Extension`: the Quick Look preview extension
- `Sources/Shared`: shared loading, rendering, and preview UI code
- `Tests`: unit tests for the shared loading/rendering logic
- `packaging/homebrew`: Homebrew cask template

## Build

Generate the project:

```bash
xcodegen generate
```

Build from Terminal:

```bash
xcodebuild \
  -project InkLook.xcodeproj \
  -scheme InkLook \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run tests:

```bash
xcodebuild \
  -project InkLook.xcodeproj \
  -scheme InkLook \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Local Install

For actual Finder integration you still need to sign the app and extension in Xcode.

Typical local flow:

1. Open `InkLook.xcodeproj` in Xcode.
2. Set your signing team for the app and extension.
3. Build `InkLook`.
4. Copy `InkLook.app` into `/Applications`.
5. Run `scripts/register-quicklook.sh /Applications/InkLook.app`.
6. If Finder still shows an old preview, run `qlmanage -r`, `killall Finder`, and `killall QuickLookUIService`.

## Homebrew Distribution

InkLook is set up to ship as a Homebrew cask rather than a formula, because the product is a
signed `.app` bundle with an embedded Quick Look extension.

Install from the tap:

```bash
brew install --cask ReyNeill/tap/inklook
```

The template cask lives at `packaging/homebrew/inklook.rb`.

Release flow:

1. Build and archive a signed `InkLook.app`.
2. Notarize it with Developer ID signing.
3. Zip the notarized app with `scripts/package-release.sh /path/to/InkLook.app <version>`.
4. Upload `InkLook.zip` to a GitHub release.
5. Copy the reported SHA256 and version into `packaging/homebrew/inklook.rb`.
6. Publish that cask in your tap.

The cask currently removes quarantine in `postflight` before running `pluginkit` and `qlmanage`.
That is the one-command, no-UI path. If you want a stricter trust model, remove the `xattr` line,
but users will need to manually open and approve the containing app before macOS enables the
extension.

## Security Notes

- The extension is sandboxed.
- The containing app is sandboxed and has no file access entitlement because it no longer exposes a UI.
- Links are rendered as text styles, but the shared preview text view suppresses link-click navigation.
- InkLook intentionally does not try to render Mermaid, HTML, or remote images.
