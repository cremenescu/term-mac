# term-mac

Terminal nativ macOS — shell local rapid, cu comportament PuTTY-style si tab-uri.

## Features

- Shell login local (zsh/bash din `$SHELL`)
- **Tab-uri** cu **title dinamic** primit prin OSC 0/1/2 — pe SSH remote arata automat `user@host:cwd`
- **Copy on select** + **paste pe click-dreapta** (stil PuTTY)
- **Auto-scroll in timpul drag-ului de selectie** (cursor sub/peste view → scroll continuu + extindere selectie)
- **Blink cursor configurabil**: Off / Slow / Medium / Fast
- **Folder default de pornire** (Settings → Pornire; gol = HOME)
- **Teme** integrate (Implicit, Solarized Dark/Light, Dracula, Nord, macOS Light, etc.)
- **Font reglabil** (Cmd+= / Cmd+- / slider in Settings)
- **Shell integration auto-install** in `~/.zshrc`: hook pentru title `user@host:cwd` + tab completion cu meniu interactiv (toggle on/off in Settings)
- Bundle ID stabil `ro.local.term-mac`

## Build

Necesar: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate
xcodebuild -project term-mac.xcodeproj -scheme term-mac -configuration Release \
  -derivedDataPath .build-xcode build
cp -R .build-xcode/Build/Products/Release/term-mac.app /Applications/
open /Applications/term-mac.app
```

## Tehnic

- Swift / SwiftUI + AppKit
- Emulator: [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) (MIT)
- macOS 14+ (Sonoma)
- **NON-sandboxed** — shell-ul local are acces complet la disk (cum trebuie pentru un terminal real). De-asta NU e pe Mac App Store; pentru versiunea sandboxed/MAS-target vezi proiectul separat [VTerm](https://github.com/cremenescu/vterm).

## Note de implementare interesante

- **Auto-scroll la selectie**: SwiftTerm seteaza `autoScrollDelta` in `mouseDragged` cand cursorul iese din view, dar nu programeaza timer-ul (bug upstream). Suplim cu NSEvent monitor + Timer la 50ms care cheama `scrollUp/scrollDown(lines:)` si posteaza un drag sintetic la aceeasi pozitie ca selectia sa se extinda.
- **Blink cursor cu durata custom**: SwiftTerm hardcodeaza 0.7s in `MacCaretView.updateAnimation`. `caretView` e internal — accesat prin `Mirror(reflecting:)`, suprascris cu CABasicAnimation propriu. Re-aplicat la `NSWindow.didBecomeKeyNotification` fiindca SwiftTerm reseteaza animatia in `becomeFirstResponder`.
- **Title tab fara loop**: `TerminalCoordinator` separat ca `processDelegate` (nu PuttyTerminalView ca propriul delegate — MacLocalTerminalView forwards `hostCurrentDirectoryUpdate`/`processTerminated` la `processDelegate` cu aceeasi semnatura = recursie).

## Licenta

MIT. Vezi [LICENSE](LICENSE).
