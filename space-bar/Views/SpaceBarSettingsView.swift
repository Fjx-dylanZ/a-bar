import SwiftUI
import ServiceManagement

struct SpaceBarSettingsView: View {
    @AppStorage("yabaiPath") private var yabaiPath = "/opt/homebrew/bin/yabai"
    @AppStorage("switchCommandTemplate") private var switchCommandTemplate =
        #"skhd -k "ctrl + alt + cmd - %d""#

    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            row(label: "yabai path", field: $yabaiPath)
            VStack(alignment: .leading, spacing: 4) {
                row(label: "Switch command", field: $switchCommandTemplate)
                Text("Use %d as a placeholder for the space index.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Launch at login")
                    .frame(width: 130, alignment: .trailing)
                Toggle("", isOn: $launchAtLogin)
                    .labelsHidden()
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Launch at login error: \(error)")
                            launchAtLogin = (SMAppService.mainApp.status == .enabled)
                        }
                    }
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
