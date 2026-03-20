import Foundation

final class YabaiWorkspaceProvider: WorkspaceProvider {
    let identifier = "yabai"
    let displayName = "yabai"

    var yabaiPath: String {
        UserDefaults.standard.string(forKey: "yabaiPath") ?? "/opt/homebrew/bin/yabai"
    }

    func fetchSpaces() async throws -> [SpaceInfo] {
        let output = try await ShellExecutor.run("\(yabaiPath) -m query --spaces")
        let cleaned = cleanupJSON(output)
        let raw = try JSONDecoder().decode([RawSpace].self, from: Data(cleaned.utf8))
        return raw.map { space in
            SpaceInfo(
                id: space.id,
                index: space.index,
                label: space.label.flatMap { $0.isEmpty ? nil : $0 },
                displayIndex: space.display - 1,
                hasFocus: space.hasFocus ?? false,
                isVisible: space.isVisible ?? false,
                windowIDs: space.windows
            )
        }
    }

    func fetchWindows() async throws -> [WindowInfo] {
        let output = try await ShellExecutor.run("\(yabaiPath) -m query --windows")
        let cleaned = cleanupJSON(output)
        let raw = try JSONDecoder().decode([RawWindow].self, from: Data(cleaned.utf8))
        return raw.compactMap { w -> WindowInfo? in
            guard let subrole = w.subrole, !subrole.isEmpty, subrole != "AXDialog" else { return nil }
            return WindowInfo(
                id: w.id,
                app: w.app,
                spaceIndex: w.space,
                displayIndex: w.display - 1,
                hasFocus: w.hasFocus ?? false,
                isMinimized: w.isMinimized ?? false,
                isHidden: w.isHidden ?? false,
                isSticky: w.isSticky ?? false,
                frameX: w.frame.x
            )
        }
    }

    var switchCommandTemplate: String {
        UserDefaults.standard.string(forKey: "switchCommandTemplate")
            ?? #"skhd -k "ctrl + alt + cmd - %d""#
    }

    func switchToSpace(index: Int) async throws {
        let cmd = String(format: switchCommandTemplate, index)
        try await ShellExecutor.run(cmd)
    }

    // MARK: - Signal management

    func setupSignals(bundleID: String) async {
        do {
            let output = try await ShellExecutor.run("\(yabaiPath) -m signal --list")
            let existing = try JSONDecoder().decode([RawSignal].self, from: Data(output.utf8))
            let labels = Set(existing.map(\.label))

            let signals: [(event: String, label: String)] = [
                ("window_destroyed", "spacebar-window-destroyed"),
                ("window_focused", "spacebar-window-focused"),
                ("space_changed", "spacebar-space-changed"),
            ]

            for (event, label) in signals {
                guard !labels.contains(label) else { continue }
                let action = "osascript -e 'tell application id \\\"\(bundleID)\\\" to refresh'"
                let cmd = "\(yabaiPath) -m signal --add event=\(event) action=\"\(action)\" label=\"\(label)\""
                try await ShellExecutor.run(cmd)
            }
        } catch {
            print("⚠️ space-bar: Failed to register yabai signals: \(error)")
        }
    }

    func removeSignals() async {
        let labels = ["spacebar-window-destroyed", "spacebar-window-focused", "spacebar-space-changed"]
        for label in labels {
            _ = try? await ShellExecutor.run("\(yabaiPath) -m signal --remove \(label)")
        }
    }

    // MARK: - JSON cleanup (mirrors YabaiService.cleanupJSON)

    private func cleanupJSON(_ json: String) -> String {
        var cleaned = json
        cleaned = cleaned.replacingOccurrences(of: "\\\n", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\[,+", with: "[", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ",+\\]", with: "]", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ",+,", with: ",", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\[,", with: "[", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ",\\]", with: "]", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\", with: "\\\\")
        cleaned = cleaned.replacingOccurrences(of: "\\\\\"", with: "\"")
        cleaned = cleaned.replacingOccurrences(of: "00000", with: "0")
        return cleaned
    }
}

// MARK: - Private Codable structs

private struct RawSpace: Codable {
    let id: Int
    let index: Int
    let label: String?
    let display: Int
    let windows: [Int]
    let hasFocus: Bool?
    let isVisible: Bool?

    enum CodingKeys: String, CodingKey {
        case id, index, label, display, windows
        case hasFocus = "has-focus"
        case isVisible = "is-visible"
    }
}

private struct RawWindow: Codable {
    struct Frame: Codable { let x: Double; let y: Double }
    let id: Int
    let app: String
    let space: Int
    let display: Int
    let subrole: String?
    let frame: Frame
    let hasFocus: Bool?
    let isMinimized: Bool?
    let isHidden: Bool?
    let isSticky: Bool?

    enum CodingKeys: String, CodingKey {
        case id, app, space, display, subrole, frame
        case hasFocus = "has-focus"
        case isMinimized = "is-minimized"
        case isHidden = "is-hidden"
        case isSticky = "is-sticky"
    }
}

private struct RawSignal: Codable {
    let label: String
}
