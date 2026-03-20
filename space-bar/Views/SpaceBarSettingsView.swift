import SwiftUI

struct SpaceBarSettingsView: View {
    @AppStorage("yabaiPath") private var yabaiPath = "/opt/homebrew/bin/yabai"
    @AppStorage("switchCommandTemplate") private var switchCommandTemplate =
        #"skhd -k "ctrl + alt + cmd - %d""#

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            row(
                label: "yabai path",
                field: $yabaiPath
            )
            VStack(alignment: .leading, spacing: 4) {
                row(label: "Switch command", field: $switchCommandTemplate)
                Text("Use %d as a placeholder for the space index.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    @ViewBuilder
    private func row(label: String, field: Binding<String>) -> some View {
        HStack {
            Text(label)
                .frame(width: 130, alignment: .trailing)
            TextField("", text: field)
                .textFieldStyle(.roundedBorder)
        }
    }
}
