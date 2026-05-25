import SwiftUI
import AppKit

@main
struct TermApp: App {
    @StateObject private var model = TermModel()

    init() {
        // Dezactiveaza tab-area nativa de ferestre macOS (nu mai apare bara dublata).
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 620, minHeight: 400)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Tab nou") { model.newTab() }
                    .keyboardShortcut("t")
                Button("Inchide tab") { if let s = model.selected { model.close(s) } }
                    .keyboardShortcut("w")
            }
            CommandGroup(after: .toolbar) {
                Button("Mareste textul") { model.zoom(+1) }
                    .keyboardShortcut("=", modifiers: .command)
                Button("Micsoreaza textul") { model.zoom(-1) }
                    .keyboardShortcut("-", modifiers: .command)
            }
        }

        Settings {
            TermSettings().environmentObject(model)
        }
    }
}

struct TermSettings: View {
    @EnvironmentObject var model: TermModel
    var body: some View {
        Form {
            Section("Aspect") {
                VStack(alignment: .leading) {
                    Text("Marime text: \(Int(model.fontSize))")
                    Slider(value: $model.fontSize, in: 8...28, step: 1)
                }
                Picker("Tema", selection: $model.theme) {
                    ForEach(TerminalThemes.names, id: \.self) { Text($0).tag($0) }
                }
                Picker("Blink cursor", selection: $model.cursorBlinkSpeed) {
                    ForEach(CursorBlinkSpeed.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
            }
            Section("Shell integration") {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Integrare in ~/.zshrc (title tab + tab cycle completare)",
                           isOn: $model.shellIntegrationEnabled)
                    Text("Adauga un bloc cu markeri in ~/.zshrc (back-up salvat in ~/.zshrc.bak.term-mac). Pentru a aplica: deschide un tab nou.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Pornire") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Folder implicit pentru tab-uri noi")
                    HStack {
                        TextField("Implicit (HOME)", text: $model.startupDir)
                            .textFieldStyle(.roundedBorder)
                        Button("Alege...") { chooseFolder() }
                        Button("Reset") { model.startupDir = "" }
                            .disabled(model.startupDir.isEmpty)
                    }
                    Text("Se aplica la urmatorul tab deschis.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 460)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Alege"
        if !model.startupDir.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: (model.startupDir as NSString).expandingTildeInPath)
        }
        if panel.runModal() == .OK, let url = panel.url {
            model.startupDir = url.path
        }
    }
}
