<!-- i18n-source: README.md@2a3784f0203ff81e6b374c360cc6a96b1b14c541 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="CI-Status"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Aktuelle Version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Unterstützte Plattformen: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Sprachversion: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="Lizenz: MIT"></picture></a>
</p>

<p align="center">
<a href="#schnellstart"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-de-light.svg" alt="Loslegen"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-de-light.svg" alt="Dokumentation"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-de-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-de-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-de-light.svg" alt="Beispiele"></picture></a>
</p>

> Dies ist eine Übersetzung der englischen README. Bei Abweichungen gilt die englische Fassung.

<!-- brand:end -->

MobileCI ist ein Kommandozeilenwerkzeug, eine GitHub Action und eine Swift-Bibliothek für die CI
von iOS-, Flutter- und React-Native-Apps. Es liest dein Repository, schreibt einen
GitHub-Actions-Workflow, der jede App auf den aktuellen Runner-Images baut und testet, prüft
bestehende Workflows auf die Fehler, die mobile CI langsam, teuer oder unsicher machen, und hält Version und
Build-Nummer der App in Xcode-, Flutter-, Gradle- und Expo-Dateien synchron. Es richtet sich an
App-Entwickler, die eine funktionierende Pipeline möchten, ohne zuerst jedes Runner-Detail zu
lernen.

## Highlights

- **Erkennt, was die CI sehen wird** — Xcode-Projekte und ihre geteilten Schemes, die Nutzung von
  CocoaPods und Swift-Paketen, Flutter-Plattformordner, den Paketmanager einer React-Native- oder
  Expo-App und die Probleme, über die ein erster Lauf stolpert, etwa ein Scheme, das nicht
  geteilt ist.
- **Schreibt aktuelle, gepinnte Workflows** — jede Action ist auf ihren Release-Commit gepinnt,
  `macos-26` mit ausgewähltem Xcode 26.6, Berechtigungen mit `contents: read`, Timeouts, Caches
  und abgebrochene, überholte Läufe; jede erzeugte Datei besteht den Lint des Werkzeugs selbst
  und actionlint.
- **16 Lint-Regeln für mobile Workflows** — Drift bei `macos-latest`, fehlende Xcode-Auswahl,
  Testfehler, die hinter `| xcbeautify` verschwinden, fehlende Timeouts, nicht gepinnte
  Actions, Script-Injection über Pull-Request-Titel und `pull_request_target`-Checkouts, mit
  Ausgabe als Text, JSON, GitHub-Annotations und SARIF.
- **Ein Versionsbefehl** — `mobileci version bump patch --build` aktualisiert
  `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json` und `build.gradle` gemeinsam
  und lehnt Build-Nummern oberhalb des Google-Play-Limits ab, statt sie überlaufen zu lassen.
- **Sicher bei nicht vertrauenswürdigen Repositories** — Dateien werden mit Größenlimits
  gelesen, YAML-Aliase und Verschachtelung sind begrenzt, `detect` steigt nicht in symbolisch
  verlinkte Ordner ab, Meldungen zitieren nie Dateiinhalt, und die Annotation-Ausgabe kann keine
  Workflow-Befehle einschleusen.
- **Getestet und selbst im Einsatz** — 108 Swift-Testing-Tests laufen auf macOS und in einem
  iPhone-Simulator; die iOS- und Flutter-Workflows der Beispiele dieses Repositorys werden von
  `mobileci init` geschrieben, und ein CI-Job schlägt fehl, wenn sie vom Generator abweichen.

## Schnellstart

**1. Das Werkzeug installieren**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Einen Workflow für deine App schreiben**

Im Stammverzeichnis des Repositorys deiner App:

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Prüfen und pushen**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Installation

### Kommandozeilenwerkzeug

Baue es wie im Schnellstart aus dem Quellcode; das Ergebnis ist eine einzelne ausführbare Datei.
Es läuft auf macOS 14 oder neuer und auf Linux mit Swift 6.2 oder neuer.

### GitHub Action

Die Action baut das Werkzeug auf dem Runner und prüft die Workflows des Repositorys; Befunde
erscheinen als Annotations im Pull Request:

```yaml
jobs:
  workflows:
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: muhittincamdali/MobileCI@main # pin to a release commit, as MCI001 asks
        with:
          fail-on: warning
```

Eingaben: `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` und
`output` ([action.yml](action.yml)).

### Swift-Paket

Wähle in Xcode **File › Add Package Dependencies…** und gib die Repository-URL ein:

```text
https://github.com/muhittincamdali/MobileCI.git
```

Oder füge es zu den `dependencies` in deiner `Package.swift` hinzu:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/MobileCI.git", branch: "main")
],
targets: [
    .target(name: "YourTool", dependencies: [
        .product(name: "MobileCIKit", package: "MobileCI")
    ])
]
```

## Verwendung

### Sehen, was die CI sehen wird

`mobileci detect` listet jedes Projekt mit den Details auf, die sein Workflow verwendet, und
vermerkt, was zuerst zu beheben ist:

![mobileci detect](docs/images/terminal-detect-light.png)

### Einen bestehenden Workflow prüfen

`mobileci lint` prüft jede Datei in `.github/workflows` und beendet sich mit Status 1, wenn ein
Befund `--fail-on` erreicht (standardmäßig warning). So sieht der erste Workflow aus, mit dem
viele Apps beginnen:

![mobileci lint für einen ersten iOS-Workflow](docs/images/terminal-lint-light.png)

`mobileci rules` listet jede Regel mit ihrer Behebung auf; die
[Regelreferenz](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
erklärt, warum jede einzelne wichtig ist. Eine Regel, die nicht zutrifft, schaltest du mit einem
Kommentar in derselben oder der vorherigen Zeile stumm:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Einen Workflow schreiben

`mobileci init` schreibt pro Projekt eine Datei; `--stdout` gibt sie stattdessen aus, und
Optionen wie `--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` oder `--scheme` ändern die Werte:

![mobileci init und ein sauberer Lint](docs/images/terminal-init-light.png)

Der erzeugte Workflow besteht jede Regel:

![mobileci lint für den erzeugten Workflow](docs/images/terminal-lint-generated-light.png)

Der Ordner [Templates](Templates) enthält die Ausgabe für je ein Beispielprojekt jeder Art: eine
[iOS-App](Templates/ios.yml), eine [iOS-App mit CocoaPods](Templates/ios-cocoapods.yml), eine
[macOS-App](Templates/macos.yml), ein [Swift-Paket](Templates/swift-package.yml), eine
[Flutter-App](Templates/flutter.yml), eine [React-Native-App](Templates/react-native.yml) und eine
[Expo-App](Templates/expo.yml). Kopiere eine davon, wenn du das Werkzeug nicht installieren
möchtest.

### Die Version erhöhen

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` listet jede gefundene Version und Build-Nummer auf; `bump`, `set` und `build`
ändern sie in allen Dateien auf einmal, und `--dry-run` zeigt das Ergebnis, ohne zu schreiben.

### Lint aus Swift

Die [Beispiel-App](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) prüft einen Workflow
auf einem iPhone mit diesem Aufruf:

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

und zeigt den Workflow, den `mobileci init` dafür schreiben würde
([Samples.swift](Examples/WorkflowCheck/WorkflowCheck/Samples.swift)):

```swift
let project = DetectedProject(directory: ".", kind: .xcode(XcodeProject(
    projectFile: "WorkflowCheck.xcodeproj",
    workspaceFile: nil,
    schemes: [XcodeScheme(name: "WorkflowCheck", hasTests: true)],
    platform: .iOS,
    usesCocoaPods: false,
    usesBundler: false,
    usesSwiftPackages: false
)))
return try WorkflowGenerator().workflow(for: project).contents
```

## Demo

Die Beispiel-App prüft die Beispiel-Workflows mit MobileCIKit in einem iPhone-Simulator; die
Screenshots entstehen mit [`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Ein erster iOS-Workflow                                                | Geschrieben von `WorkflowGenerator`                                   |
| ---------------------------------------------------------------------- | --------------------------------------------------------------------- |
| ![Erster Workflow, hell](docs/images/example-firstWorkflow-light.png)  | ![Erzeugter Workflow, hell](docs/images/example-generated-light.png)  |
| ![Erster Workflow, dunkel](docs/images/example-firstWorkflow-dark.png) | ![Erzeugter Workflow, dunkel](docs/images/example-generated-dark.png) |

Die Terminal-Bilder im Abschnitt Verwendung sind echte Läufe des Werkzeugs auf einem
Beispiel-Repository, gerendert mit [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh)
(die dunklen Varianten liegen in [docs/images](docs/images)).

Um die App auszuführen, öffne `WorkflowCheck.xcodeproj` in [Examples/WorkflowCheck](Examples/WorkflowCheck)
mit Xcode, wähle einen iPhone-Simulator und drücke **Run**. [Examples/README.md](Examples/README.md)
beschreibt auch das Flutter-Beispiel.

## Dokumentation

API-Referenz und Artikel:

- [MobileCIKit-Referenz](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Lint-Regeln](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Grenzen und Sicherheit](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Anleitungen

- [Erste Schritte](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — installieren, detect, init, lint und version, Schritt für Schritt.
- [Workflows erzeugen](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — was jeder erzeugte Job tut und alle Optionen.
- [Versionsverwaltung](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — die Dateien, die Regeln und die Grenzen.

## Voraussetzungen

| Plattform                       | Mindestversion         |
| ------------------------------- | ---------------------- |
| macOS (Werkzeug und Bibliothek) | 14                     |
| iOS (Bibliothek)                | 17                     |
| Linux (Werkzeug und Bibliothek) | Swift-6.2-Toolchain    |
| Toolchain                       | Swift 6.2+ (Xcode 26+) |

Die erzeugten Workflows zielen auf die GitHub-Runner `macos-26` (Xcode 26.6) und `ubuntu-24.04`;
jeder Wert lässt sich per Option ändern.

## Architektur

- `Sources/MobileCIKit/Detection` — `ProjectDetector` durchläuft das Repository (3 Ebenen, ohne
  in symbolisch verlinkte Ordner abzusteigen) und liest `.xcodeproj`-Bundles, `pubspec.yaml`,
  `package.json` und `Package.swift` als Text.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` schreibt das YAML Zeile für Zeile aus
  validierten Werten; `PinnedAction` hält die Action-Commits.
- `Sources/MobileCIKit/Lint` — `YAMLValue` behält die Position jedes Knotens (geparst mit
  [Yams](https://github.com/jpsim/Yams) in einem Thread mit großem Stack und mit Grenzen für
  Knoten und Tiefe), `Workflow` stellt Jobs und Steps bereit, und pro Regel meldet eine Funktion
  `Finding`s.
- `Sources/MobileCIKit/Reporting` — Ausgabe als Text, JSON, GitHub-Annotations und SARIF.
- `Sources/MobileCIKit/Versioning` — `VersionFile` findet Versionsfelder und ersetzt sie an Ort
  und Stelle; `VersionManager` plant und wendet eine Änderung über mehrere Dateien an.
- `Sources/mobileci` — die Kommandozeilenschnittstelle
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) erzeugt `Templates/` und die
Beispiel-Workflows neu; mit `--check` schlägt es fehl, wenn sie von der Ausgabe des Generators
abweichen.

## Roadmap

- Vorkompilierte Binärdateien an den Releases, damit die Action das Werkzeug nicht bei jedem Lauf
  kompilieren muss.
- Erkennung nativer Android-Projekte (Gradle ohne React Native oder Flutter).
- Eine Regel für Simulator-Ziele, die es im gewählten Runner-Image nicht gibt.

## Mitwirken

Beiträge sind willkommen. Lies vor einem Pull Request den [Leitfaden für Beiträge](CONTRIBUTING.md) und den [Verhaltenskodex](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). Sicherheitsprobleme meldest du vertraulich, wie in der [Sicherheitsrichtlinie](SECURITY.md) beschrieben.

## Lizenz

Veröffentlicht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE).
