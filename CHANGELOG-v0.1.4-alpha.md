## term-mac v0.1.4-alpha

### Fixes

- **Scrollback configurabil functioneaza acum cu adevarat.** In v0.1.2 si v0.1.3 setarea din Settings ("Buffer scrollback") nu lua efect — Buffer-ul ramanea la 500 linii indiferent de valoarea aleasa. Fix: folosim API-ul public SwiftTerm `terminal.changeScrollback(_:)` in loc de `resetNormalBuffer()` (care recreea Buffer-ul, dar `setupOptions` rulat ulterior de SwiftTerm calca peste schimbare). `changeScrollback` ajusteaza in loc `lines.maxLength` si pastreaza contentul existent.

### Improvements

- **Scrollback se aplica si la tab-urile deja deschise.** Daca schimbi valoarea din Settings, `updateNSView` cheama `changeScrollback` pe fiecare PuttyTerminalView existent — nu mai e nevoie sa inchizi/redeschizi tab-uri.

### Tehnic

- Bump 0.1.3 → 0.1.4, build 4 → 5.
- Lectie de retinut: API-ul corect pentru a schimba scrollback la SwiftTerm runtime e `Terminal.changeScrollback(_:)`, NU `Terminal.resetNormalBuffer()` sau `Terminal.setup(isReset:)`.
