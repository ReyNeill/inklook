# InkLook

InkLook is a small native macOS Quick Look preview extension for Markdown files.

The containing app is intentionally headless. It has no user-facing window, no Dock icon, and
exists only because Apple distributes Quick Look preview extensions inside a containing app.

This project defaults to the non-paid distribution path: publish a locally built `.app` bundle,
re-sign it ad hoc for honesty, and let the Homebrew cask remove quarantine and register the
extension on install.

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

Typical local flow:

1. Open `InkLook.xcodeproj` in Xcode and build `InkLook`, or use the command-line build above.
2. Copy the built `InkLook.app` into `/Applications`.
3. Run `scripts/register-quicklook.sh /Applications/InkLook.app`.
4. If Finder still shows an old preview, run `qlmanage -r`, `killall Finder`, and `killall QuickLookUIService`.

You do not need a paid Apple Developer account for this local flow. Local builds typically avoid
Gatekeeper friction because they never pass through a quarantined download.

## Homebrew Distribution

InkLook ships as a Homebrew cask rather than a formula because the product is an `.app` bundle
with an embedded Quick Look extension.

Install from the tap:

```bash
brew install --cask ReyNeill/tap/inklook
```

The template cask lives at `packaging/homebrew/inklook.rb`.

Release flow:

1. Build `InkLook.app` locally.
2. Run `scripts/package-release.sh /path/to/InkLook.app <version>`.
3. Upload the generated `InkLook.zip` to a GitHub release.
4. Copy the reported SHA256 and version into `packaging/homebrew/inklook.rb`.
5. Publish that cask in your tap.

`scripts/package-release.sh` copies the app to a staging directory and re-signs it ad hoc before
zipping. That matters because the default distribution path here is not the Apple Developer ID
path, so the release artifact should not carry a misleading local-development signature.

The cask removes quarantine in `postflight` before running `pluginkit` and `qlmanage`. That is the
actual plug-and-play path for unpaid distribution. Without that `xattr` step, users may need to
manually open and approve the containing app before macOS enables the extension.

This is a deliberate tradeoff:

- Pro: no Apple Developer subscription required
- Pro: one-command Homebrew install still works
- Con: Gatekeeper is not giving users the normal notarized Developer ID assurance
- Con: future macOS releases could make quarantine-stripping installs less reliable

## Security Notes

- The extension is sandboxed.
- The containing app is sandboxed and has no file access entitlement because it no longer exposes a UI.
- Links are rendered as text styles, but the shared preview text view suppresses link-click navigation.
- InkLook intentionally does not try to render Mermaid, HTML, or remote images.
- The default release process produces an ad hoc-signed app and relies on the Homebrew cask to
  clear quarantine and register the extension.
