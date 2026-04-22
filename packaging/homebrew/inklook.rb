cask "inklook" do
  version "0.1.2"
  sha256 "29d10e7d225d05e4b73adb8a624afcfcefc41a14e0c1fa36a535d5023f91f6b9"

  url "https://github.com/ReyNeill/inklook/releases/download/v#{version}/InkLook.zip"
  name "InkLook"
  desc "Native Quick Look preview extension for Markdown"
  homepage "https://github.com/ReyNeill/inklook"

  depends_on macos: ">= :sonoma"

  app "InkLook.app"

  postflight do
    app_path = "#{appdir}/InkLook.app"
    plugin_path = "#{app_path}/Contents/PlugIns/InkLookPreview.appex"

    # InkLook's default release path is unpaid distribution: an ad hoc-signed app bundle published
    # through GitHub Releases. Removing quarantine is what makes that one-command Homebrew install
    # work without forcing the user through a manual "Open Anyway" flow for the containing app.
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
