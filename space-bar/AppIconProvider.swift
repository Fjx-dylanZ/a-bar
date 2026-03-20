import AppKit
import SwiftUI

/// Provides native application icons for windows
class AppIconProvider {
    static let shared = AppIconProvider()

    private var iconCache: [String: NSImage] = [:]
    private let queue = DispatchQueue(label: "com.abar.icon-provider", attributes: .concurrent)

    /// Apps currently being looked up via mdfind to avoid duplicate searches.
    private var pendingLookups = Set<String>()

    private init() {}

    /// Get the icon for an application by name.
    /// Returns a cached icon immediately, or kicks off an async lookup and
    /// returns nil (the view will re-render once the cache is populated).
    func icon(forApp appName: String) -> NSImage? {
        if let cached = queue.sync(execute: { iconCache[appName] }) {
            return cached
        }

        if let icon = findAppIconFast(appName: appName) {
            queue.async(flags: .barrier) {
                self.iconCache[appName] = icon
            }
            return icon
        }

        queue.async(flags: .barrier) {
            guard !self.pendingLookups.contains(appName) else { return }
            self.pendingLookups.insert(appName)
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            if let path = self.findAppPathViaMdfind(appName: appName) {
                let icon = NSWorkspace.shared.icon(forFile: path)
                self.queue.async(flags: .barrier) {
                    self.iconCache[appName] = icon
                    self.pendingLookups.remove(appName)
                }
            } else {
                self.queue.async(flags: .barrier) {
                    self.pendingLookups.remove(appName)
                }
            }
        }

        return nil
    }

    /// Get a SwiftUI Image for an application
    func iconImage(forApp appName: String, size: CGFloat = 16) -> Image {
        if let nsImage = icon(forApp: appName) {
            return Image(nsImage: resizedIcon(nsImage, to: size))
        }
        return Image(systemName: "app.fill")
    }

    private func findAppIconFast(appName: String) -> NSImage? {
        if let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == appName }) {
            if let icon = runningApp.icon {
                return icon
            }
            if let bundleURL = runningApp.bundleURL {
                return NSWorkspace.shared.icon(forFile: bundleURL.path)
            }
        }

        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]
        for path in searchPaths {
            let appPath = "\(path)/\(appName).app"
            if FileManager.default.fileExists(atPath: appPath) {
                return NSWorkspace.shared.icon(forFile: appPath)
            }
        }

        return nil
    }

    private func findAppPathViaMdfind(appName: String) -> String? {
        let command = "mdfind 'kMDItemKind == \"Application\" && kMDItemDisplayName == \"\(appName)\"' | head -1"
        let result = ShellExecutor.runSync(command, timeout: 5)
        let path = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else { return nil }
        return path
    }

    private func resizedIcon(_ image: NSImage, to size: CGFloat) -> NSImage {
        let newSize = NSSize(width: size, height: size)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    func clearCache() {
        queue.async(flags: .barrier) {
            self.iconCache.removeAll()
        }
    }
}
