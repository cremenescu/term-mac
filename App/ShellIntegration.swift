import Foundation

/// Adauga / elimina automat un bloc in `~/.zshrc` pentru:
/// - title de tab live (`%n@%m: %~` via OSC 0/1/2; persista si dupa `exit` din SSH).
/// - tab-completion cycling (MENU_COMPLETE + menu select).
///
/// Bloc idempotent intre markeri START/END. Operatie atomica (tmp + rename).
enum ShellIntegration {
    private static let markerStart = "# term-mac: zsh hook v2 (auto-installed)"
    private static let markerEnd = "# term-mac: end hook v2"
    /// Markeri vechi pe care ii curatam la migrare (idempotent).
    private static let legacyMarkers: [(start: String, end: String)] = [
        ("# term-mac: zsh hook v1 (auto-installed)", "# term-mac: end hook v1"),
    ]

    private static let zshrcPath: String = NSHomeDirectory() + "/.zshrc"

    /// Continutul blocului. Folosim `add-zsh-hook precmd` ca sa nu suprascriem
    /// un `precmd` definit deja de user — hook-urile coexista.
    private static let block: String = """
    \(markerStart)
    autoload -Uz add-zsh-hook
    _term_mac_title() { print -Pn "\\e]0;%n@%m: %~\\a" }
    add-zsh-hook precmd _term_mac_title
    # Tab completion cu meniu interactiv (al 2-lea Tab cicleaza prin variante).
    autoload -Uz compinit && compinit -u 2>/dev/null
    setopt AUTO_MENU
    unsetopt MENU_COMPLETE
    zstyle ':completion:*' menu select
    \(markerEnd)
    """

    /// True daca shell-ul user-ului e zsh (login shell din `$SHELL`).
    private static var userShellIsZsh: Bool {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        return (shell as NSString).lastPathComponent == "zsh"
    }

    private static func currentContent() -> String {
        (try? String(contentsOfFile: zshrcPath, encoding: .utf8)) ?? ""
    }

    /// E instalata integrarea?
    static var isInstalled: Bool {
        return currentContent().contains(markerStart)
    }

    /// Adauga blocul daca lipseste si shell-ul user-ului e zsh. Curata si blocurile vechi (alte versiuni).
    /// Returneaza true daca a scris ceva.
    @discardableResult
    static func installIfNeeded() -> Bool {
        guard userShellIsZsh else { return false }
        var content = currentContent()
        // Migrare: scoate markeri vechi (v1 etc.).
        for legacy in legacyMarkers {
            content = removeBlock(in: content, start: legacy.start, end: legacy.end)
        }
        if content.contains(markerStart) {
            // Daca cumva am scris doar v1 si l-am sters mai sus, scrie content curatat.
            if content != currentContent() { _ = atomicWrite(content) }
            return false
        }
        var newContent = content
        if !newContent.isEmpty && !newContent.hasSuffix("\n") { newContent += "\n" }
        if !newContent.isEmpty { newContent += "\n" }
        newContent += block + "\n"
        return atomicWrite(newContent)
    }

    /// Sterge blocul curent + orice marker vechi. Returneaza true daca a sters ceva.
    @discardableResult
    static func uninstall() -> Bool {
        var content = currentContent()
        let original = content
        content = removeBlock(in: content, start: markerStart, end: markerEnd)
        for legacy in legacyMarkers {
            content = removeBlock(in: content, start: legacy.start, end: legacy.end)
        }
        guard content != original else { return false }
        return atomicWrite(content)
    }

    private static func removeBlock(in source: String, start: String, end: String) -> String {
        guard source.contains(start) else { return source }
        let lines = source.components(separatedBy: "\n")
        var out: [String] = []
        var skip = false
        for line in lines {
            if line == start {
                if let last = out.last, last.isEmpty { _ = out.popLast() }
                skip = true
                continue
            }
            if skip {
                if line == end { skip = false }
                continue
            }
            out.append(line)
        }
        return out.joined(separator: "\n")
    }

    private static func atomicWrite(_ content: String) -> Bool {
        let tmp = zshrcPath + ".tmp.term-mac"
        do {
            try content.write(toFile: tmp, atomically: true, encoding: .utf8)
            // rename peste fisierul original.
            _ = try? FileManager.default.removeItem(atPath: zshrcPath + ".bak.term-mac")
            if FileManager.default.fileExists(atPath: zshrcPath) {
                try? FileManager.default.copyItem(atPath: zshrcPath, toPath: zshrcPath + ".bak.term-mac")
            }
            try FileManager.default.removeItem(atPath: zshrcPath)
            try FileManager.default.moveItem(atPath: tmp, toPath: zshrcPath)
            return true
        } catch {
            NSLog("term-mac: nu am putut scrie ~/.zshrc: \(error.localizedDescription)")
            try? FileManager.default.removeItem(atPath: tmp)
            return false
        }
    }
}
