## term-mac v0.1.1-alpha

### Features

- **About panel custom**: meniul "term-mac → Despre term-mac" deschide acum un About cu autor, email, link repo, versiune si build number. Inlocuieste panelul auto-generat (gol).
- **Meniu Help functional**: "Ajutor term-mac" (Cmd+?) deschide o fereastra in-app cu sectiuni: Ce este, Start rapid, Selectie & paste, Tab title pe SSH, Completare cu Tab, Limitari, plus link-uri spre GitHub / issue tracker / email. Optiuni separate: "Vezi pe GitHub", "Raporteaza o problema", "Email autor". Inlocuieste mesajul "Help isn't available for term-mac".

### Fixes

- Info.plist preia versiunea din `MARKETING_VERSION` (`$(MARKETING_VERSION)`) — pana acum era hardcodat la "1.0", iar bump-urile din `project.yml` nu se reflectau in Finder Get Info / About.

### License & packaging

- `NSHumanReadableCopyright` setat in Info.plist.
- Build number bump la 2.

Vezi [v0.1.0-alpha](https://github.com/cremenescu/term-mac/releases/tag/v0.1.0-alpha) pentru primul release.
