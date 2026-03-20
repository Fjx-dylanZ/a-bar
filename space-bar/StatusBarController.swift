import AppKit
import SwiftUI
import Combine

// MARK: - Right-click container

/// Transparent NSView that intercepts right-click to show the context menu,
/// letting left-click pass through to the SwiftUI content below.
private final class RightClickContainerView: NSView {
    var onRightClick: (() -> Void)?

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}

// MARK: - StatusBarController

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var hostingView: NSHostingView<AnyView>?
    private let store: WorkspaceStore
    private var cancellables = Set<AnyCancellable>()

    init(store: WorkspaceStore) {
        self.store = store
    }

    func setup() {
        buildStatusItem()

        store.$spaces
            .combineLatest(store.$windows)
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.updateWidth() }
            .store(in: &cancellables)
    }

    func teardown() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
        hostingView = nil
        cancellables.removeAll()
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let content = WorkspaceBarView().environmentObject(store)
        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.translatesAutoresizingMaskIntoConstraints = false

        // Overlay that captures right-click without blocking left-click hit-testing
        let overlay = RightClickContainerView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.onRightClick = { [weak self, weak item] in
            self?.showContextMenu(for: item)
        }

        if let button = item.button {
            button.image = nil
            button.title = ""
            button.addSubview(hosting)
            button.addSubview(overlay)
            NSLayoutConstraint.activate([
                hosting.topAnchor.constraint(equalTo: button.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                overlay.topAnchor.constraint(equalTo: button.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                overlay.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            ])
        }

        statusItem = item
        hostingView = hosting
    }

    private func showContextMenu(for item: NSStatusItem?) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit space-bar", action: #selector(quitApp), keyEquivalent: "q")
            .target = self
        if let button = item?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 2), in: button)
        }
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func updateWidth() {
        guard let hosting = hostingView, let item = statusItem else { return }
        DispatchQueue.main.async {
            item.length = max(hosting.fittingSize.width, 20)
        }
    }
}
