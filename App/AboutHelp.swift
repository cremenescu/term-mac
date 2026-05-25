// SPDX-License-Identifier: GPL-2.0-or-later
// term-mac — Copyright (c) 2026 Razvan Cremenescu
// See LICENSE for full text.

import SwiftUI
import AppKit

/// Custom About panel pentru term-mac — inlocuieste cel auto-generat ca sa
/// adaugam autor / email / link repo / atribuiri terte in fereastra standard.
enum AboutPanel {
    static func show() {
        let credits = NSMutableAttributedString()
        let body: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.alignment = .center
                p.lineSpacing = 2
                return p
            }()
        ]
        let secondary: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: body[.paragraphStyle]!
        ]

        credits.append(NSAttributedString(string: "Razvan Cremenescu\n", attributes: body))
        credits.append(linkLine(text: "razvan@cremenescu.ro",
                                url: "mailto:razvan@cremenescu.ro",
                                attributes: body))
        credits.append(NSAttributedString(string: "\n", attributes: body))
        credits.append(linkLine(text: "github.com/cremenescu/term-mac",
                                url: "https://github.com/cremenescu/term-mac",
                                attributes: body))
        credits.append(NSAttributedString(string: "\n\n", attributes: secondary))
        credits.append(NSAttributedString(
            string: "Released under GPL-2.0-or-later. Bundles SwiftTerm (MIT).",
            attributes: secondary))

        let opts: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "term-mac",
            .applicationVersion: marketingVersion(),
            .version: buildVersion(),
            .credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"):
                "Copyright \u{00A9} 2026 Razvan Cremenescu"
        ]
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: opts)
    }

    private static func linkLine(text: String, url: String,
                                 attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var attrs = attributes
        attrs[.link] = URL(string: url) as Any
        attrs[.foregroundColor] = NSColor.linkColor
        return NSAttributedString(string: text + "\n", attributes: attrs)
    }

    private static func marketingVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private static func buildVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}

// MARK: - Fereastra Help in-app

enum HelpWindow {
    private static var window: NSWindow?

    static func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hosting = NSHostingController(rootView: HelpView())
        let w = NSWindow(contentViewController: hosting)
        w.title = "term-mac — Ajutor"
        w.setContentSize(NSSize(width: 680, height: 600))
        w.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        w.center()
        w.isReleasedWhenClosed = false
        window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                section(title: "Ce este term-mac?", body: """
                    Terminal nativ macOS — shell login local rapid, cu comportament \
                    PuTTY-style (copy automat la selectie, paste cu click-dreapta), \
                    tab-uri cu title dinamic si teme.
                    """)
                section(title: "Start rapid", body: """
                    • Cmd+T deschide un tab nou.
                    • Cmd+W inchide tab-ul curent.
                    • Cmd+, deschide Settings (tema, font, blink cursor, folder de \
                    pornire, integrare shell).
                    • Cmd+= / Cmd+- zoom font.
                    """)
                section(title: "Selectie si clipboard", body: """
                    • Selectia cu mouse-ul copiaza AUTOMAT in clipboard la eliberare.
                    • Click-dreapta = paste din clipboard (stil PuTTY).
                    • Cand drag-ul iese sus/jos din fereastra, terminalul scroll-eaza \
                    continuu si selectia se extinde.
                    """)
                section(title: "Tab title (SSH)", body: """
                    Pe SSH la un server remote, tab-ul afiseaza automat \
                    "user@host:cwd" daca shell-ul remote scrie title-ul prin OSC. \
                    Dupa "exit", revine la title-ul local (necesar: hook-ul de title \
                    instalat in ~/.zshrc — bifa "Shell integration" in Settings).
                    """)
                section(title: "Completare cu Tab", body: """
                    Cand integrarea shell e activa: primul Tab afiseaza variantele de \
                    completare; al 2-lea Tab activeaza meniul interactiv (sageti sau \
                    Tab repetat = cicleaza prin variante).
                    """)
                section(title: "Limitari cunoscute", body: """
                    • Non-sandboxed — shell-ul are acces complet la disk. De-asta NU \
                    e pe Mac App Store.
                    • Binarul e ad-hoc signed (nu cu Developer ID). La prima rulare \
                    dupa download, ruleaza: \
                    `xattr -dr com.apple.quarantine /Applications/term-mac.app`.
                    """)
                links
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon).resizable().frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("term-mac").font(.title2).bold()
                Text("Terminal nativ macOS — shell local cu stil PuTTY")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 4)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(body).font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var links: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().padding(.vertical, 4)
            Text("Mai multe informatii").font(.headline)
            link("github.com/cremenescu/term-mac",
                 url: "https://github.com/cremenescu/term-mac")
            link("Raporteaza o problema",
                 url: "https://github.com/cremenescu/term-mac/issues/new")
            link("Email autor (razvan@cremenescu.ro)",
                 url: "mailto:razvan@cremenescu.ro")
        }
    }

    private func link(_ text: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        } label: {
            Label(text, systemImage: "arrow.up.right.square")
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }
}
