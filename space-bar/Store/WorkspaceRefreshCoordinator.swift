import AppKit

final class WorkspaceRefreshCoordinator {
    private weak var store: WorkspaceStore?
    private var yabaiProvider: YabaiWorkspaceProvider?

    private var spaceObserver: NSObjectProtocol?
    private var appObservers: [NSObjectProtocol] = []
    private var screenObserver: NSObjectProtocol?
    private var signalTimer: Timer?
    private var debounceTask: Task<Void, Never>?

    init(store: WorkspaceStore, yabaiProvider: YabaiWorkspaceProvider? = nil) {
        self.store = store
        self.yabaiProvider = yabaiProvider
    }

    func start() {
        setupObservers()
        Task { @MainActor [weak self] in self?.store?.refresh() }
        setupSignals()
        startSignalTimer()
    }

    func stop() {
        teardownObservers()
        stopSignalTimer()
        Task { await self.yabaiProvider?.removeSignals() }
    }

    private func setupObservers() {
        let nc = NSWorkspace.shared.notificationCenter

        spaceObserver = nc.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.debounceRefresh() }

        let appNotifications: [NSNotification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification,
        ]
        for name in appNotifications {
            let obs = nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.debounceRefresh()
            }
            appObservers.append(obs)
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.debounceRefresh() }
    }

    private func debounceRefresh() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            self?.store?.refresh()
        }
    }

    private func setupSignals() {
        guard let provider = yabaiProvider,
              let bundleID = Bundle.main.bundleIdentifier else { return }
        Task { await provider.setupSignals(bundleID: bundleID) }
    }

    private func startSignalTimer() {
        signalTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.setupSignals()
        }
    }

    private func stopSignalTimer() {
        signalTimer?.invalidate()
        signalTimer = nil
    }

    private func teardownObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        if let obs = spaceObserver { nc.removeObserver(obs) }
        appObservers.forEach { nc.removeObserver($0) }
        if let obs = screenObserver { NotificationCenter.default.removeObserver(obs) }
        spaceObserver = nil
        appObservers = []
        screenObserver = nil
    }
}
