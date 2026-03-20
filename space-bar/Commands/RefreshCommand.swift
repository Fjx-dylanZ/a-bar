import Foundation
import AppKit

/// Handles the AppleScript "refresh" command used by yabai signals.
/// Signal action: osascript -e 'tell application id "com.jeantinland.space-bar" to refresh'
class SpaceBarRefreshCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        Task { @MainActor in
            SpaceBarAppDelegate.shared?.store.refresh()
        }
        return "ok"
    }
}
