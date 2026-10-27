<!-- i18n-source: README.md@bf610a4983a4fc55b272c414917e6ff504f5763f status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="Статус CI"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Последняя версия: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Поддерживаемые платформы: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Версия языка: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="Лицензия: MIT"></picture></a>
</p>

<p align="center">
<a href="#быстрый-старт"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-ru-light.svg" alt="Начать"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-ru-light.svg" alt="Документация"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ru-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ru-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-ru-light.svg" alt="Примеры"></picture></a>
</p>

> Это перевод README на английском языке. Если они расходятся, актуальна английская версия.

<!-- brand:end -->

MobileCI — это инструмент командной строки, GitHub Action и библиотека на Swift для CI
приложений iOS, Flutter и React Native. Он читает ваш репозиторий, пишет workflow для GitHub
Actions, который собирает и тестирует каждое приложение на актуальных образах runner, проверяет
существующие workflow на ошибки, из-за которых мобильный CI становится медленным, дорогим или
небезопасным, и поддерживает согласованность версии и номера сборки приложения в файлах Xcode,
Flutter, Gradle и Expo. Он предназначен для разработчиков приложений, которым нужен рабочий
пайплайн без предварительного изучения всех деталей runner.

## Основные возможности

- **Определяет, что увидит CI** — проекты Xcode и их общие scheme, использование CocoaPods и
  пакетов Swift, платформенные папки Flutter, менеджер пакетов приложения на React Native или
  Expo и проблемы, на которых спотыкается первый запуск, например scheme, не помеченная как
  общая.
- **Пишет актуальные workflow с закреплёнными версиями** — каждый action закреплён на коммите
  своего релиза, используется `macos-26` с выбранным Xcode 26.6, права `contents: read`, тайм-ауты,
  кэши и отмена устаревших запусков; каждый сгенерированный файл проходит собственный lint
  инструмента и actionlint.
- **16 правил lint для мобильных workflow** — дрейф `macos-latest`, отсутствие выбора Xcode,
  сбои тестов, скрытые за `| xcbeautify`, отсутствие тайм-аутов, незакреплённые action,
  внедрение скриптов через заголовки pull request и checkout с `pull_request_target`; вывод
  доступен в виде текста, JSON, аннотаций GitHub и SARIF.
- **Одна команда для версии** — `mobileci version bump patch --build` обновляет
  `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json` и `build.gradle` одновременно
  и отклоняет номера сборки выше лимита Google Play, а не допускает переполнения.
- **Безопасен на недоверенных репозиториях** — файлы читаются с ограничением размера, алиасы и
  вложенность YAML ограничены, `detect` не заходит в папки по символическим ссылкам, сообщения
  никогда не цитируют содержимое файлов, а вывод аннотаций не может внедрить команды workflow.
- **Протестирован и используется самим проектом** — 125 тестов Swift Testing выполняются на
  macOS и в симуляторе iPhone; workflow для iOS и Flutter в примерах этого репозитория пишет
  `mobileci init`, а задание CI падает, если они расходятся с генератором.

## Быстрый старт

**1. Установите инструмент**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Создайте workflow для вашего приложения**

В корне репозитория вашего приложения:

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Проверьте и отправьте**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Установка

### Инструмент командной строки

Соберите его из исходников, как в разделе «Быстрый старт»; результат — один исполняемый файл.
Он работает на macOS 14 и новее, а также на Linux с Swift 6.2 и новее.

### GitHub Action

Action собирает инструмент на runner и проверяет workflow репозитория; найденные проблемы
появляются как аннотации в pull request:

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

Входные параметры: `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` и
`output` ([action.yml](action.yml)).

### Пакет Swift

В Xcode выберите **File › Add Package Dependencies…** и введите адрес репозитория:

```text
https://github.com/muhittincamdali/MobileCI.git
```

Или добавьте его в `dependencies` вашего `Package.swift`:

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

## Использование

### Посмотрите, что увидит CI

`mobileci detect` перечисляет каждый проект с теми сведениями, которые использует его workflow,
и отмечает, что нужно исправить в первую очередь:

![mobileci detect](docs/images/terminal-detect-light.png)

### Проверьте существующий workflow

`mobileci lint` проверяет каждый файл в `.github/workflows` и завершается со статусом 1, если
найденная проблема достигает уровня `--fail-on` (по умолчанию warning). Вот примерно такого вида
первый workflow бывает у многих приложений:

![mobileci lint для первого workflow iOS](docs/images/terminal-lint-light.png)

`mobileci rules` перечисляет каждое правило со способом исправления;
[справочник правил](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
объясняет, почему важно каждое из них. Отключить правило там, где оно неприменимо, можно
комментарием в той же строке или в строке выше:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Создайте workflow

`mobileci init` записывает по одному файлу на проект; `--stdout` выводит результат вместо записи,
а такие параметры, как `--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` или `--scheme`, меняют
значения:

![mobileci init и lint без замечаний](docs/images/terminal-init-light.png)

Сгенерированный workflow проходит все правила:

![mobileci lint для сгенерированного workflow](docs/images/terminal-lint-generated-light.png)

В папке [Templates](Templates) лежит результат для одного примера проекта каждого вида:
[приложение iOS](Templates/ios.yml), [приложение iOS с CocoaPods](Templates/ios-cocoapods.yml),
[приложение macOS](Templates/macos.yml), [пакет Swift](Templates/swift-package.yml),
[приложение Flutter](Templates/flutter.yml), [приложение React Native](Templates/react-native.yml)
и [приложение Expo](Templates/expo.yml). Скопируйте любой из них, если не хотите устанавливать
инструмент.

### Повысьте версию

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` перечисляет все найденные версии и номера сборки; `bump`, `set` и `build`
меняют их сразу во всех файлах, а `--dry-run` показывает результат без записи.

### Lint из Swift

[Приложение-пример](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) проверяет workflow
на iPhone таким вызовом:

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

и показывает workflow, который `mobileci init` записал бы для него
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

## Демо

Приложение-пример проверяет образцы workflow с помощью MobileCIKit в симуляторе iPhone;
скриншоты делает
[`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| Первый workflow для iOS                                                       | Записан `WorkflowGenerator`                                                        |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| ![Первый workflow, светлая тема](docs/images/example-firstWorkflow-light.png) | ![Сгенерированный workflow, светлая тема](docs/images/example-generated-light.png) |
| ![Первый workflow, тёмная тема](docs/images/example-firstWorkflow-dark.png)   | ![Сгенерированный workflow, тёмная тема](docs/images/example-generated-dark.png)   |

Изображения терминала в разделе «Использование» — это настоящие запуски инструмента на образцовом
репозитории, отрисованные скриптом [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh)
(тёмные версии лежат в [docs/images](docs/images)).

Чтобы запустить приложение, откройте `WorkflowCheck.xcodeproj` из
[Examples/WorkflowCheck](Examples/WorkflowCheck) в Xcode, выберите симулятор iPhone и нажмите
**Run**. [Examples/README.md](Examples/README.md) также описывает пример на Flutter.

## Документация

Справочник API и статьи:

- [Справочник MobileCIKit](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Правила lint](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Ограничения и безопасность](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Руководства

- [Начало работы](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — установка, detect, init, lint и version, шаг за шагом.
- [Генерация workflow](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — что делает каждое сгенерированное задание и все параметры.
- [Управление версиями](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — файлы, правила и ограничения.

## Требования

| Платформа                       | Минимальная версия       |
| ------------------------------- | ------------------------ |
| macOS (инструмент и библиотека) | 14                       |
| iOS (библиотека)                | 17                       |
| Linux (инструмент и библиотека) | Инструментарий Swift 6.2 |
| Инструменты                     | Swift 6.2+ (Xcode 26+)   |

Сгенерированные workflow рассчитаны на runner GitHub `macos-26` (Xcode 26.6) и `ubuntu-24.04`;
каждое значение можно изменить параметром.

## Архитектура

- `Sources/MobileCIKit/Detection` — `ProjectDetector` обходит репозиторий (3 уровня, без захода
  в папки по символическим ссылкам) и читает как текст пакеты `.xcodeproj`, `pubspec.yaml`,
  `package.json` и `Package.swift`.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` строка за строкой пишет YAML из
  проверенных значений; `PinnedAction` хранит коммиты action.
- `Sources/MobileCIKit/Lint` — `YAMLValue` хранит позицию каждого узла (разбор выполняется с
  помощью [Yams](https://github.com/jpsim/Yams) в потоке с большим стеком и с ограничениями на
  число узлов и глубину), `Workflow` предоставляет задания и шаги, а по одной функции на каждое
  правило сообщает о `Finding`.
- `Sources/MobileCIKit/Reporting` — вывод в виде текста, JSON, аннотаций GitHub и SARIF.
- `Sources/MobileCIKit/Versioning` — `VersionFile` находит поля версии и заменяет их на месте;
  `VersionManager` планирует и применяет изменение сразу в нескольких файлах.
- `Sources/mobileci` — интерфейс командной строки
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) заново создаёт `Templates/` и
workflow из примеров; с флагом `--check` он завершается ошибкой, если они отличаются от вывода
генератора.

## План развития

- Готовые бинарные файлы в составе релизов, чтобы action не компилировал инструмент при каждом
  запуске.
- Определение нативных проектов Android (Gradle без React Native и Flutter).
- Правило для целевых симуляторов, которых нет в выбранном образе runner.

## Участие в разработке

Мы рады вашему участию. Перед открытием pull request прочитайте [руководство для участников](CONTRIBUTING.md) и [кодекс поведения](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md). О проблемах безопасности сообщайте конфиденциально, как описано в [политике безопасности](SECURITY.md).

## Лицензия

Распространяется по лицензии MIT. Подробнее — в файле [LICENSE](LICENSE).
