## term-mac v0.1.2-alpha

### Features

- **Buffer scrollback configurabil** (Settings → Aspect → "Buffer scrollback"): 1.000 / 5.000 / **10.000 (default)** / 25.000 / 50.000 / 100.000 linii. SwiftTerm default era 500 — prea mic pentru cazuri uzuale gen `mdls Downloads/` + Tab cand zsh listeaza 1217 fisiere si nu poti scrolla in sus sa vezi care. Se aplica la **tab-urile noi** (existente raman cu valoarea cu care au pornit).

### Tehnic

- `terminal.options.scrollback` setat inainte de `startProcess`; apoi `terminal.setup(isReset: false)` recreeaza Buffer-ul cu noua dimensiune (Buffer-ul aloca `CircularList` de marime `scrollback + rows`, fixata la init).
- Persistat in `UserDefaults` la cheia `term.scrollbackLines`.
- Bump 0.1.1 → 0.1.2, build 2 → 3.
