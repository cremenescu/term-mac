// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (c) 2026 Razvan Cremenescu

import SwiftUI
import SwiftTerm
import AppKit

/// Terminal cu comportament stil PuTTY: copy-on-select + paste pe click-dreapta.
///
/// In plus: **auto-scroll in timpul drag-ului** cand cursorul iese sus/jos din view.
/// SwiftTerm seteaza `autoScrollDelta` in mouseDragged dar nu programeaza timer-ul
/// (bug upstream) — il programam noi aici si re-trimitem un mouseDragged sintetic
/// la fiecare tick ca selectia sa se extinda peste continutul nou aparut.
final class PuttyTerminalView: LocalProcessTerminalView {
    private var mouseUpMonitor: Any?
    private var autoScrollTimer: Timer?
    private var lastDragWindowLocation: NSPoint?
    /// > 0 = scroll DOWN (cursor sub view, vrem continut mai nou),
    /// < 0 = scroll UP (cursor deasupra view-ului, vrem continut mai vechi).
    private var autoScrollLinesPerTick: Int = 0
    /// Observer pentru re-aplicare blink dupa focus changes (SwiftTerm reseteaza animatia in becomeFirstResponder).
    private var focusObserver: Any?
    private var currentBlinkSpeed: CursorBlinkSpeed = .medium

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMouse()
        installFocusObserver()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMouse()
        installFocusObserver()
    }

    private func setupMouse() {
        let rightClick = NSClickGestureRecognizer(target: self, action: #selector(rightClickPaste))
        rightClick.buttonMask = 0x2
        addGestureRecognizer(rightClick)

        mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .leftMouseDragged]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            switch event.type {
            case .leftMouseUp:
                self.stopAutoScroll()
                if self.selectionActive {
                    let pt = self.convert(event.locationInWindow, from: nil)
                    if self.bounds.contains(pt), let text = self.getSelection(), !text.isEmpty {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                }
            case .leftMouseDragged:
                self.handleDragForAutoScroll(event: event)
            default:
                break
            }
            return event
        }
    }

    @objc private func rightClickPaste() {
        if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
            send(txt: text)
        }
    }

    // MARK: - Auto-scroll in timpul drag-ului pentru selectie
    //
    // SwiftTerm declara mouseDragged ca `public` (NU `open`), deci nu putem face
    // override din afara modulului. Solutia: NSEvent monitor (vede drag-urile in
    // paralel cu SwiftTerm) + post sintetic in coada de evenimente la fiecare
    // tick al timer-ului ca SwiftTerm sa extinda selectia peste continutul nou.

    private func handleDragForAutoScroll(event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        lastDragWindowLocation = event.locationInWindow
        // NSView non-flipped: y=0 e jos. Sub view → pt.y < 0. Deasupra → pt.y > bounds.height.
        let edgeMargin: CGFloat = 6
        if pt.y < edgeMargin {
            let dist = max(0, edgeMargin - pt.y)
            autoScrollLinesPerTick = max(1, Int(dist / 10) + 1)
            startAutoScrollIfNeeded()
        } else if pt.y > bounds.height - edgeMargin {
            let dist = max(0, pt.y - (bounds.height - edgeMargin))
            autoScrollLinesPerTick = -max(1, Int(dist / 10) + 1)
            startAutoScrollIfNeeded()
        } else {
            stopAutoScroll()
        }
    }

    private func startAutoScrollIfNeeded() {
        if autoScrollTimer != nil { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tickAutoScroll()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
        autoScrollLinesPerTick = 0
    }

    private func tickAutoScroll() {
        let n = autoScrollLinesPerTick
        if n == 0 { return }
        if n > 0 {
            scrollDown(lines: n)
        } else {
            scrollUp(lines: -n)
        }
        // Post un drag sintetic la aceeasi pozitie window: dupa scroll, randul-buffer
        // de sub cursor s-a schimbat → SwiftTerm.dragExtend va extinde selectia cu N randuri.
        // Folosim NSApp.postEvent (nu super, fiindca mouseDragged nu e open).
        guard let win = window, let loc = lastDragWindowLocation else { return }
        if let synth = NSEvent.mouseEvent(
            with: .leftMouseDragged,
            location: loc,
            modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: win.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        ) {
            NSApp.postEvent(synth, atStart: false)
        }
    }

    // MARK: - Cursor blink speed

    /// Aplica viteza de blink. Off → DECSCUSR steady block. Slow/Medium/Fast →
    /// DECSCUSR blink block + override pe animatia layer-ului caretView (via reflection
    /// fiindca SwiftTerm nu expune timing-ul).
    func applyCursorBlinkSpeed(_ speed: CursorBlinkSpeed) {
        currentBlinkSpeed = speed
        // DECSCUSR: 2 = steady block, 1 = blink block.
        let code: String = (speed == .off) ? "\u{1B}[2 q" : "\u{1B}[1 q"
        terminal.feed(text: code)
        // Suprascrie animatia (numai cand vrem blink cu durata custom).
        DispatchQueue.main.async { [weak self] in self?.reapplyCursorAnimation() }
    }

    /// Cauta caretView via Mirror (e internal in SwiftTerm) si seteaza CABasicAnimation cu durata corecta.
    private func reapplyCursorAnimation() {
        let mirror = Mirror(reflecting: self)
        guard let cv = mirror.children.first(where: { $0.label == "caretView" })?.value as? NSView,
              let layer = cv.layer else { return }
        layer.removeAllAnimations()
        layer.opacity = 1
        guard currentBlinkSpeed != .off else { return }
        let anim = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        anim.duration = currentBlinkSpeed.duration
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.fromValue = 1.0
        anim.toValue = 0.0
        anim.timingFunction = CAMediaTimingFunction(name: .easeIn)
        layer.add(anim, forKey: #keyPath(CALayer.opacity))
    }

    /// SwiftTerm cheama `caretView.updateCursorStyle()` in `becomeFirstResponder` (line 723
    /// in MacTerminalView.swift), care reseteaza animatia la default 0.7s. Asculta orice
    /// schimbare de key window si re-aplica.
    private func installFocusObserver() {
        focusObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.reapplyCursorAnimation() }
        }
    }

    deinit {
        autoScrollTimer?.invalidate()
        if let m = mouseUpMonitor { NSEvent.removeMonitor(m) }
        if let o = focusObserver { NotificationCenter.default.removeObserver(o) }
    }
}

/// Coordinator separat ca delegate pentru a evita recursia infinita din
/// MacLocalTerminalView (forwards `hostCurrentDirectoryUpdate` etc. la `processDelegate`).
final class TerminalCoordinator: NSObject, LocalProcessTerminalViewDelegate {
    var onTitleChange: (String) -> Void = { _ in }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func processTerminated(source: TerminalView, exitCode: Int32?) {}

    /// SwiftTerm primeste OSC 0/1/2 (set window title) si ne notifica aici.
    /// Pe SSH remote, shell-ul remote scrie "user@host:cwd" prin precmd → ajunge aici.
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        onTitleChange(title)
    }
}

/// Wrapper SwiftUI: shell local (login) intr-un PuttyTerminalView.
struct LocalTerminal: NSViewRepresentable {
    let isActive: Bool
    let fontSize: Double
    let theme: String
    let startupDir: String
    let cursorBlinkSpeed: CursorBlinkSpeed
    let scrollbackLines: Int
    let onTitleChange: (String) -> Void

    func makeCoordinator() -> TerminalCoordinator { TerminalCoordinator() }

    func makeNSView(context: Context) -> PuttyTerminalView {
        let term = PuttyTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 480))
        term.font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        TerminalThemes.apply(theme, to: term)
        // Scrollback: SwiftTerm default = 500 linii. `changeScrollback(_:)` e API-ul
        // public oficial — schimba Buffer.scrollback + lines.maxLength + refresh,
        // fara sa pierda contentul. (`resetNormalBuffer()` recreeaza Buffer dar are
        // side-effects pe care setupOptions ulterior le sterge — bug v0.1.3.)
        term.terminal.changeScrollback(max(500, scrollbackLines))
        context.coordinator.onTitleChange = onTitleChange
        term.processDelegate = context.coordinator
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let execName = "-" + (shell as NSString).lastPathComponent // login shell (argv0 cu '-')

        // Pornire intr-un folder anume: schimbam temporar cwd-ul procesului inainte
        // de forkpty (startProcess fork-uieste sincron), apoi il restauram.
        // Copilul mosteneste cwd-ul curent la momentul fork.
        let fm = FileManager.default
        let savedCwd = fm.currentDirectoryPath
        let changed = fm.changeCurrentDirectoryPath(startupDir)
        term.startProcess(executable: shell, args: [], environment: nil, execName: execName)
        if changed { _ = fm.changeCurrentDirectoryPath(savedCwd) }
        // Aplicare initiala blink (dupa ce shell-ul a pornit ca DECSCUSR sa fie procesat).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            term.applyCursorBlinkSpeed(cursorBlinkSpeed)
        }
        return term
    }

    func updateNSView(_ nsView: PuttyTerminalView, context: Context) {
        let desired = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        if nsView.font.pointSize != desired.pointSize { nsView.font = desired }
        TerminalThemes.apply(theme, to: nsView)
        context.coordinator.onTitleChange = onTitleChange
        nsView.applyCursorBlinkSpeed(cursorBlinkSpeed)
        // Re-aplica scrollback daca user-ul l-a schimbat in Settings (changeScrollback
        // pastreaza contentul existent, doar reajusteaza marimea lines.maxLength).
        let want = max(500, scrollbackLines)
        if nsView.terminal.options.scrollback != want {
            nsView.terminal.changeScrollback(want)
        }
        guard isActive else { return }
        DispatchQueue.main.async {
            if let w = nsView.window, w.firstResponder !== nsView { w.makeFirstResponder(nsView) }
        }
    }
}
