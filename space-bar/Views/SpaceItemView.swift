import SwiftUI

struct SpaceItemView: View {
    let space: SpaceInfo
    @EnvironmentObject var store: WorkspaceStore
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 5) {
            Text("\(space.index)")
                .font(.system(size: 13, weight: space.hasFocus ? .semibold : .regular))
                .foregroundStyle(labelColor)
                .lineLimit(1)

            let apps = store.uniqueApps(forSpaceIndex: space.index)
            if !apps.isEmpty {
                HStack(spacing: 2) {
                    ForEach(apps.prefix(5), id: \.id) { window in
                        SpaceAppIconView(appName: window.app, size: 16)
                            .opacity(window.hasFocus ? 1.0 : 0.65)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(capsuleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture { store.switchToSpace(index: space.index) }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
        .help("Space \(space.index)")
    }

    private var labelColor: Color {
        if space.hasFocus { return .primary }
        if space.isVisible { return .primary.opacity(0.85) }
        return .primary.opacity(0.5)
    }

    @ViewBuilder
    private var capsuleBackground: some View {
        if space.hasFocus {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(.primary.opacity(0.18))
        } else if space.isVisible {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(.primary.opacity(0.10))
        } else if isHovered {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(.primary.opacity(0.07))
        } else {
            Color.clear
        }
    }
}
