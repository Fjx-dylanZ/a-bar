import SwiftUI
import AppKit

struct SpaceAppIconView: View {
    let appName: String
    var size: CGFloat = 13
    @State private var icon: NSImage? = nil

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear { loadIcon() }
        .onChange(of: appName) { _ in
            icon = nil
            loadIcon()
        }
    }

    private func loadIcon() {
        if let img = AppIconProvider.shared.icon(forApp: appName) {
            icon = img
        } else {
            // AppIconProvider is doing async mdfind; poll until it's ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard icon == nil else { return }
                loadIcon()
            }
        }
    }
}
