import Foundation

struct SpaceInfo: Identifiable, Equatable {
    let id: Int
    let index: Int
    let label: String?
    let displayIndex: Int
    let hasFocus: Bool
    let isVisible: Bool
    let windowIDs: [Int]
}

struct WindowInfo: Identifiable, Equatable {
    let id: Int
    let app: String
    let spaceIndex: Int
    let displayIndex: Int
    let hasFocus: Bool
    let isMinimized: Bool
    let isHidden: Bool
    let isSticky: Bool
    let frameX: Double
}

protocol WorkspaceProvider: AnyObject {
    var identifier: String { get }
    var displayName: String { get }
    func fetchSpaces() async throws -> [SpaceInfo]
    func fetchWindows() async throws -> [WindowInfo]
    func switchToSpace(index: Int) async throws
}
