<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/banner-light.svg" alt="MobileCI: Write, check and version the CI of iOS, Flutter and React Native apps."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
<a href="https://github.com/muhittincamdali/MobileCI/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-version-light.svg" alt="Latest version: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-platforms-light.svg" alt="Supported platforms: macOS 14+ · iOS 17+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-language-light.svg" alt="Language version: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/badge-license-light.svg" alt="License: MIT"></picture></a>
</p>

<p align="center">
<a href="#quick-start"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-start-en-light.svg" alt="Get started"></picture></a>
<a href="https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-docs-en-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/MobileCI/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-en-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-en-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/MobileCI/main/.github/brand/button-examples-en-light.svg" alt="Examples"></picture></a>
</p>

<!-- brand:end -->

MobileCI is a command-line tool, a GitHub Action and a Swift library for the CI of iOS,
Flutter and React Native apps. It reads your repository, writes a GitHub Actions workflow that
builds and tests each app on the current runner images, checks existing workflows for the
mistakes that make mobile CI slow, expensive or unsafe, and keeps the app's version and build
number in step across Xcode, Flutter, Gradle and Expo files. It is for app developers who want
a working pipeline without learning every runner detail first.

## Highlights

- **Detects what CI will see** — Xcode projects and their shared schemes, CocoaPods and Swift
  package use, Flutter platform folders, the package manager of a React Native or Expo app,
  and the problems a first run trips over, such as a scheme that is not shared.
- **Writes current, pinned workflows** — every action pinned to its release commit,
  `macos-26` with Xcode 26.6 selected, `contents: read` permissions, timeouts, caches and
  cancelled superseded runs; each generated file passes the tool's own lint and actionlint.
- **16 lint rules for mobile workflows** — `macos-latest` drift, a missing Xcode selection,
  test failures hidden behind `| xcbeautify`, missing timeouts, unpinned actions, script
  injection from pull request titles and `pull_request_target` checkouts, with text, JSON,
  GitHub annotation and SARIF output.
- **One version command** — `mobileci version bump patch --build` updates
  `MARKETING_VERSION`, `pubspec.yaml`, `package.json`, `app.json` and `build.gradle`
  together, and refuses build numbers above Google Play's limit instead of overflowing.
- **Safe on untrusted repositories** — files are read with size limits, YAML aliases and
  nesting are bounded, symbolic links are never followed, messages never quote file content,
  and annotation output cannot inject workflow commands.
- **Tested and dogfooded** — 108 Swift Testing tests run on macOS and an iPhone simulator;
  the iOS and Flutter workflows of this repository's examples are written by `mobileci init`
  and a CI job fails when they drift from the generator.

## Quick start

**1. Install the tool**

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

**2. Write a workflow for your app**

In the root of your app's repository:

```sh
mobileci detect   # what CI will see
mobileci init     # writes .github/workflows/ios.yml, flutter.yml or react-native.yml
```

**3. Check it and push**

```sh
mobileci lint
git add .github/workflows && git commit -m "ci: build and test on GitHub Actions" && git push
```

## Installation

### Command-line tool

Build it from source as in the quick start; the result is a single executable. It runs on
macOS 14 or later and on Linux with Swift 6.2 or later.

### GitHub Action

The action builds the tool on the runner and lints the repository's workflows; findings appear
as annotations on the pull request:

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

Inputs: `paths`, `format` (`github`, `text`, `json`, `sarif`), `fail-on`, `disable` and
`output` ([action.yml](action.yml)).

### Swift package

In Xcode, choose **File › Add Package Dependencies…** and enter the repository URL:

```text
https://github.com/muhittincamdali/MobileCI.git
```

Or add it to the `dependencies` in your `Package.swift`:

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

## Usage

### See what CI will see

`mobileci detect` lists each project with the details its workflow uses, and notes what to fix
first:

![mobileci detect](docs/images/terminal-detect-light.png)

### Check an existing workflow

`mobileci lint` checks every file in `.github/workflows` and exits with status 1 when a
finding reaches `--fail-on` (warning by default). This is the kind of first workflow many
apps start with:

![mobileci lint on a first iOS workflow](docs/images/terminal-lint-light.png)

`mobileci rules` lists each rule with its fix; the
[rule reference](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
explains why each one matters. Silence a rule where it does not apply with a comment on the
line or the line above:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

### Write a workflow

`mobileci init` writes one file per project; `--stdout` prints instead, and options such as
`--xcode 26.4.1`, `--simulator "iPhone 17 Pro"` or `--scheme` change the values:

![mobileci init and a clean lint](docs/images/terminal-init-light.png)

The generated workflow passes every rule:

![mobileci lint on the generated workflow](docs/images/terminal-lint-generated-light.png)

The [Templates](Templates) folder holds the output for one sample project of each kind: an
[iOS app](Templates/ios.yml), an [iOS app with CocoaPods](Templates/ios-cocoapods.yml), a
[macOS app](Templates/macos.yml), a [Swift package](Templates/swift-package.yml), a
[Flutter app](Templates/flutter.yml), a [React Native app](Templates/react-native.yml) and an
[Expo app](Templates/expo.yml). Copy one if you prefer not to install the tool.

### Bump the version

![mobileci version bump](docs/images/terminal-version-light.png)

`mobileci version` lists every version and build number it finds; `bump`, `set` and `build`
change them in all files at once, and `--dry-run` shows the result without writing.

### Lint from Swift

The [example app](Examples/WorkflowCheck/WorkflowCheck/CheckModel.swift) checks a workflow
on an iPhone with this call:

```swift
static func check(_ text: String) -> [Finding] {
    WorkflowLinter().lint(text: text, path: "workflow.yml")
}
```

and shows the workflow `mobileci init` would write for it
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

The example app lints the sample workflows with MobileCIKit on an iPhone simulator, captured
by [`scripts/capture-example-screens.sh`](scripts/capture-example-screens.sh):

| A first iOS workflow                                                  | Written by `WorkflowGenerator`                                        |
| --------------------------------------------------------------------- | --------------------------------------------------------------------- |
| ![First workflow, light](docs/images/example-firstWorkflow-light.png) | ![Generated workflow, light](docs/images/example-generated-light.png) |
| ![First workflow, dark](docs/images/example-firstWorkflow-dark.png)   | ![Generated workflow, dark](docs/images/example-generated-dark.png)   |

The terminal images in the Usage section are real runs of the tool on a sample repository,
rendered by [`scripts/capture-terminal.sh`](scripts/capture-terminal.sh) (dark versions are in
[docs/images](docs/images)).

To run the app, open `WorkflowCheck.xcodeproj` in [Examples/WorkflowCheck](Examples/WorkflowCheck)
with Xcode, choose an iPhone simulator and press **Run**. [Examples/README.md](Examples/README.md)
also describes the Flutter example.

## Documentation

Reference documentation and articles:

- [MobileCIKit reference](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/)
- [Lint rules](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/lintrules)
- [Limits and safety](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety)

## Guides

- [Getting started](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/gettingstarted) — install, detect, init, lint and version, step by step.
- [Generating workflows](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/generatingworkflows) — what each generated job does and every option.
- [Version management](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/versionmanagement) — the files, the rules and the limits.

## Requirements

| Platform                 | Minimum version        |
| ------------------------ | ---------------------- |
| macOS (tool and library) | 14                     |
| iOS (library)            | 17                     |
| Linux (tool and library) | Swift 6.2 toolchain    |
| Toolchain                | Swift 6.2+ (Xcode 26+) |

Generated workflows target GitHub's `macos-26` (Xcode 26.6) and `ubuntu-24.04` runners;
every value can be changed with an option.

## Architecture

- `Sources/MobileCIKit/Detection` — `ProjectDetector` walks the repository (3 levels, no
  symbolic links) and reads `.xcodeproj` bundles, `pubspec.yaml`, `package.json` and
  `Package.swift` as text.
- `Sources/MobileCIKit/Generation` — `WorkflowGenerator` writes the YAML line by line from
  validated values; `PinnedAction` holds the action commits.
- `Sources/MobileCIKit/Lint` — `YAMLValue` keeps the position of every node (parsed with
  [Yams](https://github.com/jpsim/Yams) on a large-stack thread with node and depth limits),
  `Workflow` exposes jobs and steps, and one function per rule reports `Finding`s.
- `Sources/MobileCIKit/Reporting` — text, JSON, GitHub annotation and SARIF output.
- `Sources/MobileCIKit/Versioning` — `VersionFile` locates version fields and replaces them in
  place; `VersionManager` plans and applies a change across files.
- `Sources/mobileci` — the command-line interface
  ([swift-argument-parser](https://github.com/apple/swift-argument-parser)).

[`scripts/generate-workflows.sh`](scripts/generate-workflows.sh) regenerates `Templates/` and
the example workflows; with `--check` it fails when they differ from the generator's output.

## Roadmap

- Prebuilt binaries attached to releases, so the action does not compile the tool on each run.
- Detection of native Android projects (Gradle without React Native or Flutter).
- A rule for simulator destinations that do not exist on the selected runner image.

## Contributing

Contributions are welcome. Read the [contributing guide](CONTRIBUTING.md) and the [code of conduct](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) before opening a pull request. Report security issues privately as described in the [security policy](SECURITY.md).

## License

Released under the MIT license. See [LICENSE](LICENSE).
