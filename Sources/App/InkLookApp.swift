import AppKit
import SwiftUI

@main
struct InkLookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // InkLook stays headless because the embedded Quick Look extension is the actual product.
        NSApp.setActivationPolicy(.prohibited)

        // The containing app only exists to satisfy Apple's extension packaging model, so there is
        // no reason to keep a background process alive after launch.
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }
}
