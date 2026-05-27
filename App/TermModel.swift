// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2026 Razvan Cremenescu

import SwiftUI

/// Viteza de blink pentru cursor. Off = fara blink (steady block).
enum CursorBlinkSpeed: String, CaseIterable, Identifiable {
    case off, slow, medium, fast
    var id: String { rawValue }
    var label: String {
        switch self {
        case .off: return "Oprit"
        case .slow: return "Lent"
        case .medium: return "Mediu"
        case .fast: return "Rapid"
        }
    }
    /// Durata animatiei opacity (autoreverses). Doar pentru valori != off.
    var duration: CFTimeInterval {
        switch self {
        case .off: return 0
        case .slow: return 1.2
        case .medium: return 0.7
        case .fast: return 0.3
        }
    }
}

@MainActor
final class TermModel: ObservableObject {
    @Published var theme: String = "Implicit" {
        didSet { UserDefaults.standard.set(theme, forKey: "term.theme") }
    }
    @Published var fontSize: Double = 13 {
        didSet { UserDefaults.standard.set(fontSize, forKey: "term.fontSize") }
    }
    /// Folder in care porneste fiecare tab nou. Gol = HOME (vezi `resolvedStartupDir`).
    @Published var startupDir: String = "" {
        didSet { UserDefaults.standard.set(startupDir, forKey: "term.startupDir") }
    }
    @Published var cursorBlinkSpeed: CursorBlinkSpeed = .medium {
        didSet { UserDefaults.standard.set(cursorBlinkSpeed.rawValue, forKey: "term.cursorBlinkSpeed") }
    }
    /// Numar de linii de istoric pe care le tine fiecare tab. Default SwiftTerm = 500
    /// (prea mic pentru "do you wish to see all 1217 possibilities" la tab completion).
    @Published var scrollbackLines: Int = 10000 {
        didSet { UserDefaults.standard.set(scrollbackLines, forKey: "term.scrollbackLines") }
    }
    /// Daca true, app-ul mentine in `~/.zshrc` un bloc auto-instalat cu title hook
    /// + tab cycling. Sincronizat cu fisierul real (toggle-ul instaleaza/dezinstaleaza).
    @Published var shellIntegrationEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(shellIntegrationEnabled, forKey: "term.shellIntegrationEnabled")
            if shellIntegrationEnabled { ShellIntegration.installIfNeeded() }
            else { ShellIntegration.uninstall() }
        }
    }
    @Published var tabs: [UUID] = []
    @Published var selected: UUID?
    /// Title-ul terminal primit prin OSC 0/1/2 (set window title) per tab. Cand userul
    /// face `ssh user@host`, remote-ul scrie aici "user@host:path".
    @Published var tabTitles: [UUID: String] = [:]

    init() {
        if let v = UserDefaults.standard.string(forKey: "term.theme") { theme = v }
        if let v = UserDefaults.standard.object(forKey: "term.fontSize") as? Double { fontSize = v }
        if let v = UserDefaults.standard.string(forKey: "term.startupDir") { startupDir = v }
        if let v = UserDefaults.standard.string(forKey: "term.cursorBlinkSpeed"),
           let s = CursorBlinkSpeed(rawValue: v) { cursorBlinkSpeed = s }
        if let v = UserDefaults.standard.object(forKey: "term.scrollbackLines") as? Int { scrollbackLines = v }
        // Default ON pentru shell integration (chiar daca cheia nu exista inca).
        if let v = UserDefaults.standard.object(forKey: "term.shellIntegrationEnabled") as? Bool {
            shellIntegrationEnabled = v
        }
        // Auto-install daca toggle e ON si markerul lipseste.
        if shellIntegrationEnabled { ShellIntegration.installIfNeeded() }
        newTab()
    }

    func newTab() {
        let id = UUID()
        tabs.append(id)
        selected = id
    }

    func close(_ id: UUID) {
        tabs.removeAll { $0 == id }
        tabTitles.removeValue(forKey: id)
        if selected == id { selected = tabs.last }
        if tabs.isEmpty { newTab() }
    }

    func zoom(_ delta: Double) {
        fontSize = min(28, max(8, fontSize + delta))
    }

    /// Returneaza folderul de pornire pentru tab-uri noi. Gol/invalid → HOME
    /// (app-ul lansat cu `open` are cwd `/`, deci fara fallback shell-ul ar porni in `/`).
    func resolvedStartupDir() -> String {
        let home = NSHomeDirectory()
        let s = (startupDir as NSString).expandingTildeInPath
        guard !s.isEmpty else { return home }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: s, isDirectory: &isDir), isDir.boolValue else { return home }
        return s
    }

    func setTitle(_ title: String, for id: UUID) {
        // Trim si filtreaza title-uri goale (le-am vazut din shell-uri care reseteaza).
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            tabTitles.removeValue(forKey: id)
        } else {
            tabTitles[id] = t
        }
    }

    /// Title afisat in tab pentru `id`. Daca shell-ul nu seteaza title, fallback la "Shell N".
    func displayTitle(for id: UUID, index: Int) -> String {
        if let t = tabTitles[id], !t.isEmpty { return t }
        return "Shell \(index + 1)"
    }
}
