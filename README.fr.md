<!-- i18n-source: README.md@dd2916d8ed7ec53bff38f4304ac420eb57e36ab0 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="État de la CI"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Dernière version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Plateformes prises en charge: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Version du langage: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="Licence: MIT"></picture></a>
</p>

<p align="center">
<a href="#démarrage-rapide"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-fr-light.svg" alt="Commencer"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-fr-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-fr-light.svg" alt="Exemples"></picture></a>
</p>

> Ceci est une traduction du README anglais. En cas de différence, la version anglaise fait foi.

<!-- brand:end -->

MobileCI est un outil en ligne de commande, une GitHub Action et une bibliothèque Swift pour la
CI des applications iOS, Flutter et React Native. Il lit votre dépôt, écrit un workflow GitHub
Actions qui compile et teste chaque application sur les images de runner actuelles, vérifie les
workflows existants à la recherche des erreurs qui rendent la CI mobile lente, coûteuse ou peu
sûre, et maintient la version et le numéro de build de l’application alignés dans les fichiers
Xcode, Flutter, Gradle et Expo. Il s’adresse aux développeurs d’applications qui veulent un
pipeline fonctionnel sans devoir d’abord apprendre chaque détail des runners.

## Points forts

- **Détecte ce que verra la CI** — projets Xcode et leurs schemes partagés, usage de CocoaPods et
  des paquets Swift, dossiers de plateforme Flutter, gestionnaire de paquets d’une application
  React Native ou Expo, et les problèmes sur lesquels bute une première exécution, comme un
  scheme qui n’est pas partagé.
- **Écrit des workflows à jour et épinglés** — chaque action épinglée sur son commit de version,
  `macos-26` avec Xcode 26.6 sélectionné, permissions `contents: read`, délais d’expiration,
  caches et annulation des exécutions devenues obsolètes ; chaque fichier généré passe le lint de
  l’outil lui-même et actionlint.
- **16 règles de lint pour les workflows mobiles** — dérive de `macos-latest`, sélection de Xcode
  manquante, échecs de tests masqués derrière `| xcbeautify`, délais d’expiration absents, actions
  non épinglées, injection de script via les titres de pull request et checkouts
  `pull_request_target`, avec une sortie en texte, JSON, annotations GitHub et SARIF.
- **Une seule commande de version** — `mobileci version bump patch --build` met à jour ensemble
  `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json` et `build.gradle`, et refuse
  les numéros de build supérieurs à la limite de Google Play au lieu de les laisser déborder.
- **Sûr sur des dépôts non fiables** — les fichiers sont lus avec des limites de taille, les
  alias et l’imbrication YAML sont bornés, `detect` ne descend pas dans les dossiers liés
  symboliquement, les messages ne citent jamais le contenu des fichiers et la sortie
  d’annotations ne peut pas injecter de commandes de workflow.
- **Testé et utilisé en interne** — 121 tests Swift Testing s’exécutent sur macOS et sur un
  simulateur d’iPhone ; les workflows iOS et Flutter des exemples de ce dépôt sont écrits par
  `mobileci init`, et un job de CI échoue lorsqu’ils s’écartent du générateur.

## Démarrage rapide

**1. Installer l’outil**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Écrire un workflow pour votre application**

À la racine du dépôt de votre application :

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Le vérifier et pousser**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Installation

### Outil en ligne de commande

Compilez-le depuis les sources comme dans le démarrage rapide ; le résultat est un seul
exécutable. Il fonctionne sur macOS 14 ou ultérieur et sur Linux avec Swift 6.2 ou ultérieur.

### GitHub Action

L’action compile l’outil sur le runner et analyse les workflows du dépôt ; les constats
apparaissent sous forme d’annotations sur la pull request :

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

Entrées : `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` et
`output` ([action.yml](action.yml)).

### Paquet Swift

Dans Xcode, choisissez **File › Add Package Dependencies…** et saisissez l’URL du dépôt :

```text
https://github.com/muhittincamdali/MobileCI.git
```

Ou ajoutez-le aux `dependencies` de votre `Package.swift` :

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

## Utilisation

### Voir ce que verra la CI

`mobileci detect` liste chaque projet avec les détails qu’utilise son workflow et indique ce
qu’il faut corriger en premier :

![mobileci detect](docs/images/terminal-detect-light.png)

### Vérifier un workflow existant

`mobileci lint` vérifie chaque fichier de `.github/workflows` et se termine avec le statut 1
lorsqu’un constat atteint le niveau de `--fail-on` (warning par défaut). Voici le genre de
premier workflow par lequel beaucoup d’applications commencent :

![mobileci lint sur un premier workflow iOS](docs/images/terminal-lint-light.png)

`mobileci rules` liste chaque règle avec sa correction ; la
[référence des règles](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
explique pourquoi chacune compte. Désactivez une règle là où elle ne s’applique pas avec un
commentaire sur la même ligne ou sur la ligne au-dessus :

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Écrire un workflow

`mobileci init` écrit un fichier par projet ; `--stdout` l’affiche à la place, et des options
comme `--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` ou `--scheme` modifient les valeurs :

![mobileci init et un lint sans constat](docs/images/terminal-init-light.png)

Le workflow généré respecte toutes les règles :

![mobileci lint sur le workflow généré](docs/images/terminal-lint-generated-light.png)

Le dossier [Templates](Templates) contient la sortie pour un projet d’exemple de chaque type :
une [application iOS](Templates/ios.yml), une [application iOS avec CocoaPods](Templates/ios-cocoapods.yml),
une [application macOS](Templates/macos.yml), un [paquet Swift](Templates/swift-package.yml),
une [application Flutter](Templates/flutter.yml), une [application React Native](Templates/react-native.yml)
et une [application Expo](Templates/expo.yml). Copiez-en un si vous préférez ne pas installer
l’outil.

### Incrémenter la version

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` liste chaque version et numéro de build qu’il trouve ; `bump`, `set` et
`build` les modifient dans tous les fichiers à la fois, et `--dry-run` montre le résultat sans
rien écrire.

### Lint depuis Swift

L’[application d’exemple](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) vérifie un
workflow sur un iPhone avec cet appel :

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

et affiche le workflow que `mobileci init` écrirait pour lui
([Samples.swift](Examples/WorkflowCheck/WorkflowCheck/Samples.swift)) :

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

## Démo

L’application d’exemple analyse les workflows d’exemple avec MobileCIKit sur un simulateur
d’iPhone ; les captures sont réalisées par
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh) :

| Un premier workflow iOS                                                 | Écrit par `WorkflowGenerator`                                      |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------ |
| ![Premier workflow, clair](docs/images/example-firstWorkflow-light.png) | ![Workflow généré, clair](docs/images/example-generated-light.png) |
| ![Premier workflow, sombre](docs/images/example-firstWorkflow-dark.png) | ![Workflow généré, sombre](docs/images/example-generated-dark.png) |

Les images de terminal de la section Utilisation sont de vraies exécutions de l’outil sur un
dépôt d’exemple, produites par [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh) (les
versions sombres se trouvent dans [docs/images](docs/images)).

Pour lancer l’application, ouvrez `WorkflowCheck.xcodeproj` dans
[Examples/WorkflowCheck](Examples/WorkflowCheck) avec Xcode, choisissez un simulateur d’iPhone
et appuyez sur **Run**. [Examples/README.md](Examples/README.md) décrit aussi l’exemple Flutter.

## Documentation

Référence de l’API et articles :

- [Référence de MobileCIKit](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Règles de lint](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Limites et sécurité](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Guides

- [Prise en main](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — installer, detect, init, lint et version, pas à pas.
- [Générer des workflows](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — ce que fait chaque job généré et toutes les options.
- [Gestion des versions](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — les fichiers, les règles et les limites.

## Prérequis

| Plateforme                    | Version minimale          |
| ----------------------------- | ------------------------- |
| macOS (outil et bibliothèque) | 14                        |
| iOS (bibliothèque)            | 17                        |
| Linux (outil et bibliothèque) | Chaîne d’outils Swift 6.2 |
| Chaîne d’outils               | Swift 6.2+ (Xcode 26+)    |

Les workflows générés ciblent les runners `macos-26` (Xcode 26.6) et `ubuntu-24.04` de GitHub ;
chaque valeur peut être modifiée avec une option.

## Architecture

- `Sources/MobileCIKit/Detection` — `ProjectDetector` parcourt le dépôt (3 niveaux, sans
  descendre dans les dossiers liés symboliquement) et lit comme du texte les bundles
  `.xcodeproj`, `pubspec.yaml`, `package.json` et `Package.swift`.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` écrit le YAML ligne par ligne à partir
  de valeurs validées ; `PinnedAction` conserve les commits des actions.
- `Sources/MobileCIKit/Lint` — `YAMLValue` conserve la position de chaque nœud (analysé avec
  [Yams](https://github.com/jpsim/Yams) sur un thread à grande pile, avec des limites de nœuds et
  de profondeur), `Workflow` expose les jobs et les steps, et une fonction par règle signale les
  `Finding`.
- `Sources/MobileCIKit/Reporting` — sortie en texte, JSON, annotations GitHub et SARIF.
- `Sources/MobileCIKit/Versioning` — `VersionFile` repère les champs de version et les remplace
  sur place ; `VersionManager` planifie et applique un changement sur plusieurs fichiers.
- `Sources/mobileci` — l’interface en ligne de commande
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) régénère `Templates/` et les
workflows d’exemple ; avec `--check`, il échoue lorsqu’ils diffèrent de la sortie du générateur.

## Feuille de route

- Des binaires précompilés joints aux versions, pour que l’action ne compile pas l’outil à chaque
  exécution.
- Détection des projets Android natifs (Gradle sans React Native ni Flutter).
- Une règle pour les destinations de simulateur qui n’existent pas sur l’image de runner choisie.

## Contribuer

Les contributions sont les bienvenues. Lisez le [guide de contribution](CONTRIBUTING.md) et le [code de conduite](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) avant d’ouvrir une pull request. Signalez les problèmes de sécurité en privé, comme indiqué dans la [politique de sécurité](SECURITY.md).

## Licence

Publié sous licence MIT. Voir [LICENSE](LICENSE).
