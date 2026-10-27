# Generating workflows

What `mobileci init` writes for each kind of project, and how to change it.

## Overview

``WorkflowGenerator`` turns a ``DetectedProject`` into one workflow file. All generated
workflows share the same skeleton:

```yaml
on:
  push:
    branches: ["main"]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

- **Read-only token.** The jobs only read the repository, so `GITHUB_TOKEN` gets
  `contents: read` and `actions/checkout` does not keep it in `.git/config`
  (`persist-credentials: false`).
- **Superseded runs stop.** A new push to a pull request cancels its older runs; macOS minutes
  cost more than Linux minutes, so this is where most CI money goes. Runs on the branch are
  never cancelled, so `main` always has a result.
- **Every job has a timeout.** A simulator that never boots fails after 45 minutes instead of
  six hours.
- **Pinned actions.** Each `uses:` names the commit of a release with the tag in a comment
  (``PinnedAction``); Dependabot's `github-actions` updates keep them current.
- **Values go through `env:`.** The scheme, the workspace and the simulator are written as
  quoted YAML values and read as `"$SCHEME"` in the script, never pasted into the script text.
- **Projects in subfolders** get a `paths:` filter, so `apps/ios` only builds when its files
  or its workflow change.

The generated file passes `mobileci lint` without findings and `actionlint` without errors;
the tests and `scripts/generate-workflows.sh --check` keep it that way. The files in the
repository's `Templates` folder are the generator's output for one sample project of each
kind.

## iOS and macOS apps

One job on `macos-26` with `DEVELOPER_DIR` pointing at Xcode 26.6:

1. `xcodebuild -version`, so the log shows the toolchain.
2. With Swift package dependencies: a cache of the cloned packages, keyed by
   `Package.resolved`, and `-clonedSourcePackagesDirPath SourcePackages`.
3. With a `Podfile`: a cache of `Pods` keyed by `Podfile.lock`, then `pod install`, or
   `bundle install` and `bundle exec pod install` when a `Gemfile` sits next to it.
4. `xcodebuild test` when the scheme has tests (a testable or a test plan), otherwise
   `xcodebuild build`, with `set -o pipefail`, a result bundle and code signing turned off.
   iOS apps run on `platform=iOS Simulator,name=iPhone 17,OS=latest`; macOS apps on
   `platform=macOS`.
5. When the step fails, the `.xcresult` bundle is uploaded as an artifact, so failed tests
   can be opened in Xcode.

The scheme is the shared scheme named like the project, else the first one with tests. Pass
`--scheme` to choose another.

## Swift packages

`swift build --build-tests` and `swift test --skip-build --parallel` on `macos-26`, with the
`.build` folder cached by `Package.swift` and `Package.resolved`.

## Flutter

- **Analyze and test** on `ubuntu-24.04`: `flutter pub get`, `flutter analyze`, and
  `flutter test` when a `test` folder exists.
- **Android** (with an `android` folder): Temurin JDK 17 and `flutter build apk --debug`.
- **iOS** (with an `ios` folder): `flutter build ios --simulator --debug` on `macos-26`, which
  needs no signing.

The Flutter version comes from `pubspec.yaml` when `environment: flutter:` is an exact version
(`3.47.8`), from `.fvmrc` when there is one, and otherwise from `--flutter` (3.47.8 by
default). `subosito/flutter-action` caches the SDK.

## React Native and Expo

- **Lint and test** on `ubuntu-24.04`: Node.js from `.nvmrc` or `.node-version` (24 by
  default), the install command of the package manager the lockfile names (`npm ci`,
  `yarn install --frozen-lockfile`, `yarn install --immutable`,
  `pnpm install --frozen-lockfile`), then the `lint`, `typecheck` (or `type-check` / `tsc`)
  and `test` scripts that `package.json` defines.
- **Android** (with an `android` folder): JDK 17 with the Gradle cache and
  `./gradlew assembleDebug`.
- **iOS** (with an `ios` folder): CocoaPods (through Bundler when the project root has a
  `Gemfile`, as the React Native template does), then an unsigned simulator build of the
  workspace.

An Expo app without native folders gets the first job only; build its binaries with EAS
Build.

## Options

| Option                              | Default                     | Use                                                |
| ----------------------------------- | --------------------------- | -------------------------------------------------- |
| `--branch`                          | `origin/HEAD`, `main`       | The branch whose pushes run the workflow           |
| `--xcode`                           | `26.6`                      | The Xcode in `/Applications/Xcode_<version>.app`   |
| `--simulator`                       | `iPhone 17`                 | The device for `xcodebuild test`                   |
| `--macos-runner` / `--linux-runner` | `macos-26` / `ubuntu-24.04` | Larger or self-hosted runners                      |
| `--node`, `--java`, `--flutter`     | `24`, `17`, `3.47.8`        | Used when the project does not pin its own         |
| `--scheme`                          | picked                      | Another shared scheme                              |
| `--project` and `--file`            | all projects                | One project, optionally with its own file name     |
| `--stdout`, `--force`               | off                         | Print instead of writing; overwrite existing files |

Values that would not survive in YAML or a shell script — quotes, `$`, backslashes, braces,
control characters, `${{` — are refused with ``GeneratorError/invalidValue(field:reason:)``
rather than escaped.

## After generating

The file is yours: add signing, a release job or a matrix as needed, then run
`mobileci lint` to check the result. Running `mobileci init --force` again overwrites it, so
keep changes you want to preserve in a separate workflow file.
