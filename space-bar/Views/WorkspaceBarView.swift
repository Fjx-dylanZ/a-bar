import SwiftUI

struct WorkspaceBarView: View {
    @EnvironmentObject var store: WorkspaceStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(store.spaces) { space in
                SpaceItemView(space: space)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .fixedSize()
    }
}
