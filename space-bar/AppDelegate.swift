import AppKit

final class SpaceBarAppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: SpaceBarAppDelegate?

    private(set) var store: WorkspaceStore!
    private var provider: YabaiWorkspaceProvider!
    private var coordinator: WorkspaceRefreshCoordinator!
    private var statusBarController: StatusBarController!
    private var screenObserver: NSObjectProtocol?

    override init() {
        super.init()
        Self.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        provider = YabaiWorkspaceProvider()
        store = WorkspaceStore(provider: provider)
        coordinator = WorkspaceRefreshCoordinator(store: store, yabaiProvider: provider)
        statusBarController = StatusBarController(store: store)

        statusBarController.setup()
        coordinator.start()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Rebuild status item after screen reconfiguration
            Task { @MainActor [weak self] in
                self?.statusBarController.teardown()
                self?.statusBarController.setup()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
        statusBarController.teardown()
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
