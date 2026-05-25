## term-mac v0.1.0-alpha

Primul build public. Terminal nativ macOS cu shell login local.

### Features

- Shell login local (zsh/bash din `$SHELL`), tab-uri (Cmd+T / Cmd+W).
- **Tab title dinamic** prin OSC 0/1/2: SSH remote arata automat `user@host:cwd`.
- **Copy on select** + **paste pe click-dreapta** (stil PuTTY).
- **Auto-scroll in timpul drag-ului de selectie** — workaround pentru un bug upstream in SwiftTerm care seteaza `autoScrollDelta` dar nu il consuma niciodata.
- **Blink cursor configurabil**: Off / Lent / Mediu / Rapid. Durata custom implementata prin acces reflection la `caretView` (SwiftTerm hardcodeaza 0.7s).
- **Folder default de pornire** in Settings (gol = HOME).
- **Teme** (Implicit, Solarized Dark/Light, Dracula, Nord, macOS Light, etc.).
- **Font reglabil** (Cmd+= / Cmd+-).
- **Shell integration auto-install** in `~/.zshrc` (toggle in Settings): adauga un bloc cu marker idempotent pentru `precmd` (title hook) si `AUTO_MENU` + `menu select` (tab completion interactiv). Back-up la `~/.zshrc.bak.term-mac`.

### Tehnic

- Swift / SwiftUI + AppKit, [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) (MIT).
- macOS 14+ (Sonoma).
- **Non-sandboxed** intentionat — shell-ul local are nevoie de acces complet la disk. De-asta NU e pe Mac App Store.

### Instalare

1. Descarca `.dmg`, drag in Applications.
2. La prima rulare, `xattr -dr com.apple.quarantine /Applications/term-mac.app` (Gatekeeper warning fiindca e ad-hoc signed; nu am inca Developer ID).

### Licenta

GPL-2.0-or-later. Sursa: https://github.com/cremenescu/term-mac
