import Foundation
import Combine

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var spaces: [SpaceInfo] = []
    @Published private(set) var windows: [WindowInfo] = []
    @Published private(set) var isConnected = false

    private let provider: WorkspaceProvider
    private var refreshTask: Task<Void, Never>?

    init(provider: WorkspaceProvider) {
        self.provider = provider
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await performRefresh()
        }
    }

    private func performRefresh() async {
        guard !Task.isCancelled else { return }
        do {
            async let fetchedSpaces = provider.fetchSpaces()
            async let fetchedWindows = provider.fetchWindows()
            let (s, w) = try await (fetchedSpaces, fetchedWindows)
            guard !Task.isCancelled else { return }
            spaces = s
            windows = w
            isConnected = true
        } catch {
            isConnected = false
        }
    }

    func switchToSpace(index: Int) {
        Task {
            try? await provider.switchToSpace(index: index)
            try? await Task.sleep(nanoseconds: 150_000_000)
            await performRefresh()
        }
    }

    func windows(forSpaceIndex index: Int) -> [WindowInfo] {
        windows.filter { $0.spaceIndex == index && !$0.isMinimized && !$0.isHidden }
    }

    func uniqueApps(forSpaceIndex index: Int) -> [WindowInfo] {
        var seen = Set<String>()
        return windows(forSpaceIndex: index)
            .sorted { $0.frameX < $1.frameX }
            .filter { seen.insert($0.app).inserted }
    }
}
