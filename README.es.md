<!-- i18n-source: README.md@bf610a4983a4fc55b272c414917e6ff504f5763f status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="Estado de CI"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Última versión: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Plataformas compatibles: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Versión del lenguaje: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="Licencia: MIT"></picture></a>
</p>

<p align="center">
<a href="#inicio-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-es-light.svg" alt="Empezar"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-es-light.svg" alt="Documentación"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-es-light.svg" alt="Ejemplos"></picture></a>
</p>

> Esta es una traducción del README en inglés. Si hay diferencias, la versión en inglés es la vigente.

<!-- brand:end -->

MobileCI es una herramienta de línea de comandos, una GitHub Action y una biblioteca Swift para
el CI de apps de iOS, Flutter y React Native. Lee tu repositorio, escribe un workflow de GitHub
Actions que compila y prueba cada app en las imágenes de runner actuales, revisa los workflows
existentes en busca de los errores que vuelven lento, caro o inseguro el CI móvil, y mantiene
sincronizados la versión y el número de compilación de la app en los archivos de Xcode, Flutter,
Gradle y Expo. Está pensada para desarrolladores de apps que quieren un pipeline que funcione
sin tener que aprender antes todos los detalles de los runners.

## Lo más destacado

- **Detecta lo que verá el CI** — proyectos de Xcode y sus schemes compartidos, uso de
  CocoaPods y de paquetes Swift, carpetas de plataforma de Flutter, el gestor de paquetes de
  una app de React Native o Expo, y los problemas con los que tropieza una primera ejecución,
  como un scheme que no está compartido.
- **Escribe workflows actuales y fijados** — cada action fijada a su commit de versión,
  `macos-26` con Xcode 26.6 seleccionado, permisos `contents: read`, tiempos de espera,
  cachés y cancelación de las ejecuciones superadas; cada archivo generado pasa el lint de la
  propia herramienta y actionlint.
- **16 reglas de lint para workflows móviles** — deriva de `macos-latest`, falta de selección
  de Xcode, fallos de tests ocultos tras `| xcbeautify`, tiempos de espera ausentes, actions
  sin fijar, inyección de scripts desde títulos de pull request y checkouts con
  `pull_request_target`, con salida en texto, JSON, anotaciones de GitHub y SARIF.
- **Un solo comando de versión** — `mobileci version bump patch --build` actualiza a la vez
  `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json` y `build.gradle`, y rechaza
  los números de compilación que superan el límite de Google Play en lugar de desbordarlos.
- **Seguro con repositorios no confiables** — los archivos se leen con límites de tamaño, los
  alias y el anidamiento de YAML están acotados, `detect` no entra en carpetas enlazadas
  simbólicamente, los mensajes nunca citan el contenido de los archivos y la salida de
  anotaciones no puede inyectar comandos de workflow.
- **Probado y usado en el propio proyecto** — 125 tests de Swift Testing se ejecutan en macOS
  y en un simulador de iPhone; los workflows de iOS y Flutter de los ejemplos de este
  repositorio los escribe `mobileci init`, y un job de CI falla cuando se desvían del
  generador.

## Inicio rápido

**1. Instala la herramienta**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Escribe un workflow para tu app**

En la raíz del repositorio de tu app:

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Revísalo y haz push**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Instalación

### Herramienta de línea de comandos

Compílala desde el código fuente como en el inicio rápido; el resultado es un único
ejecutable. Funciona en macOS 14 o posterior y en Linux con Swift 6.2 o posterior.

### GitHub Action

La action compila la herramienta en el runner y revisa los workflows del repositorio; los
hallazgos aparecen como anotaciones en la pull request:

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

Entradas: `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` y
`output` ([action.yml](action.yml)).

### Paquete Swift

En Xcode, elige **File › Add Package Dependencies…** e introduce la URL del repositorio:

```text
https://github.com/muhittincamdali/MobileCI.git
```

O añádelo a las `dependencies` de tu `Package.swift`:

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

## Uso

### Mira lo que verá el CI

`mobileci detect` enumera cada proyecto con los detalles que usa su workflow y señala qué
corregir primero:

![mobileci detect](docs/images/terminal-detect-light.png)

### Revisa un workflow existente

`mobileci lint` revisa todos los archivos de `.github/workflows` y termina con estado 1 cuando
un hallazgo alcanza el nivel de `--fail-on` (warning por defecto). Este es el tipo de primer
workflow con el que empiezan muchas apps:

![mobileci lint sobre un primer workflow de iOS](docs/images/terminal-lint-light.png)

`mobileci rules` enumera cada regla con su solución; la
[referencia de reglas](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
explica por qué importa cada una. Silencia una regla donde no se aplique con un comentario en
la misma línea o en la anterior:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Escribe un workflow

`mobileci init` escribe un archivo por proyecto; `--stdout` lo imprime en lugar de escribirlo, y
opciones como `--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` o `--scheme` cambian los
valores:

![mobileci init y un lint limpio](docs/images/terminal-init-light.png)

El workflow generado pasa todas las reglas:

![mobileci lint sobre el workflow generado](docs/images/terminal-lint-generated-light.png)

La carpeta [Templates](Templates) contiene la salida para un proyecto de ejemplo de cada tipo:
una [app de iOS](Templates/ios.yml), una [app de iOS con CocoaPods](Templates/ios-cocoapods.yml),
una [app de macOS](Templates/macos.yml), un [paquete Swift](Templates/swift-package.yml),
una [app de Flutter](Templates/flutter.yml), una [app de React Native](Templates/react-native.yml)
y una [app de Expo](Templates/expo.yml). Copia una si prefieres no instalar la herramienta.

### Sube la versión

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` enumera todas las versiones y números de compilación que encuentra; `bump`,
`set` y `build` los cambian a la vez en todos los archivos, y `--dry-run` muestra el
resultado sin escribir nada.

### Lint desde Swift

La [app de ejemplo](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) revisa un workflow
en un iPhone con esta llamada:

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

y muestra el workflow que escribiría `mobileci init` para él
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

La app de ejemplo revisa los workflows de muestra con MobileCIKit en un simulador de iPhone;
las capturas las hace [`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Un primer workflow de iOS                                              | Escrito por `WorkflowGenerator`                                      |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------- |
| ![Primer workflow, claro](docs/images/example-firstWorkflow-light.png) | ![Workflow generado, claro](docs/images/example-generated-light.png) |
| ![Primer workflow, oscuro](docs/images/example-firstWorkflow-dark.png) | ![Workflow generado, oscuro](docs/images/example-generated-dark.png) |

Las imágenes de terminal de la sección Uso son ejecuciones reales de la herramienta sobre un
repositorio de muestra, renderizadas con [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh)
(las versiones oscuras están en [docs/images](docs/images)).

Para ejecutar la app, abre `WorkflowCheck.xcodeproj` de [Examples/WorkflowCheck](Examples/WorkflowCheck)
con Xcode, elige un simulador de iPhone y pulsa **Run**. [Examples/README.md](Examples/README.md)
también describe el ejemplo de Flutter.

## Documentación

Referencia de la API y artículos:

- [Referencia de MobileCIKit](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Reglas de lint](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Límites y seguridad](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Guías

- [Primeros pasos](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — instalar, detect, init, lint y version, paso a paso.
- [Generar workflows](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — qué hace cada job generado y todas las opciones.
- [Gestión de versiones](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — los archivos, las reglas y los límites.

## Requisitos

| Plataforma                       | Versión mínima         |
| -------------------------------- | ---------------------- |
| macOS (herramienta y biblioteca) | 14                     |
| iOS (biblioteca)                 | 17                     |
| Linux (herramienta y biblioteca) | Toolchain de Swift 6.2 |
| Herramientas                     | Swift 6.2+ (Xcode 26+) |

Los workflows generados apuntan a los runners `macos-26` (Xcode 26.6) y `ubuntu-24.04` de
GitHub; cada valor se puede cambiar con una opción.

## Arquitectura

- `Sources/MobileCIKit/Detection` — `ProjectDetector` recorre el repositorio (3 niveles, sin
  entrar en carpetas enlazadas simbólicamente) y lee como texto los paquetes `.xcodeproj`,
  `pubspec.yaml`, `package.json` y `Package.swift`.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` escribe el YAML línea por línea a
  partir de valores validados; `PinnedAction` guarda los commits de las actions.
- `Sources/MobileCIKit/Lint` — `YAMLValue` conserva la posición de cada nodo (se analiza con
  [Yams](https://github.com/jpsim/Yams) en un hilo con pila grande y con límites de nodos y
  profundidad), `Workflow` expone jobs y steps, y una función por regla informa de los
  `Finding`.
- `Sources/MobileCIKit/Reporting` — salida en texto, JSON, anotaciones de GitHub y SARIF.
- `Sources/MobileCIKit/Versioning` — `VersionFile` localiza los campos de versión y los
  reemplaza en el sitio; `VersionManager` planifica y aplica un cambio en varios archivos.
- `Sources/mobileci` — la interfaz de línea de comandos
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) regenera `Templates/` y los
workflows de ejemplo; con `--check` falla cuando difieren de la salida del generador.

## Hoja de ruta

- Binarios precompilados adjuntos a las versiones, para que la action no compile la
  herramienta en cada ejecución.
- Detección de proyectos Android nativos (Gradle sin React Native ni Flutter).
- Una regla para destinos de simulador que no existen en la imagen de runner seleccionada.

## Contribuir

Las contribuciones son bienvenidas. Lee la [guía de contribución](CONTRIBUTING.md) y el [código de conducta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir una pull request. Informa de los problemas de seguridad de forma privada, como se describe en la [política de seguridad](SECURITY.md).

## Licencia

Publicado bajo la licencia MIT. Consulta [LICENSE](LICENSE).
