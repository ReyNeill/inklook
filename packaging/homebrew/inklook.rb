cask "inklook" do
  version "0.1.0"
  sha256 "236524db1663a8c0a0430ae8abd2f3f88786ca8ce234c7ff2883c00954ea0a8c"

  url "https://github.com/ReyNeill/inklook/releases/download/v#{version}/InkLook.zip"
  name "InkLook"
  desc "Native Quick Look preview extension for Markdown"
  homepage "https://github.com/ReyNeill/inklook"

  depends_on macos: ">= :sonoma"

  app "InkLook.app"

  postflight do
    app_path = "#{appdir}/InkLook.app"
    plugin_path = "#{app_path}/Contents/PlugIns/InkLookPreview.appex"

    # Removing quarantine is the only reliable way to make an independently distributed Quick
    # Look extension available without requiring the user to manually launch and approve the
    # containing app first. Keep this only if you want one-command installation.
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", app_path]
    system_command "/usr/bin/pluginkit", args: ["-a", plugin_path]
    system_command "/usr/bin/qlmanage", args: ["-r"]
  end

  uninstall quit: "dev.reyneill.InkLook",
            delete: "#{appdir}/InkLook.app"

  zap trash: [
    "~/Library/Application Support/InkLook",
    "~/Library/Preferences/dev.reyneill.InkLook.plist",
  ]
end
