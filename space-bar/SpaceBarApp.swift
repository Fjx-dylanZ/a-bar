import SwiftUI

@main
struct SpaceBarApp: App {
    @NSApplicationDelegateAdaptor(SpaceBarAppDelegate.self) var delegate

    var body: some Scene {
        // No scenes needed — UI lives entirely in the status bar item.
        // Settings are opened via SettingsWindowController.
    }
}
