# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

MobileCI 2 is a rewrite. The tool now does four things and tests each of them: detect the
projects in a repository, write a workflow for each, lint workflows, and version apps. The
`mobileci --version` of this code is 2.0.0.

### Added

- `mobileci detect`: finds Xcode projects (shared schemes, test actions, platform, CocoaPods
  and Bundler, Swift package use), Swift packages, Flutter apps (platform folders, an exact
  Flutter version in `pubspec.yaml` or `.fvmrc`) and React Native and Expo apps (package
  manager from `packageManager` or the lockfile, scripts, `.nvmrc`, native folders), and notes
  what a first CI run trips over, such as a scheme that is not shared or a missing lockfile.
  Text or JSON output.
- `mobileci init`: writes a workflow per project with every action pinned to its release
  commit (checkout v7.0.1, cache v6.1.0, upload-artifact v7.0.2, setup-node v7.1.0,
  setup-java v6.1.0, flutter-action v2.23.0), `macos-26` with Xcode 26.6 selected through
  `DEVELOPER_DIR`, `permissions: contents: read`, `persist-credentials: false`, a timeout on
  every job, cancelled superseded pull request runs, `paths` filters for projects in
  subfolders, Swift package, CocoaPods and Gradle caches, `set -o pipefail` before
  `xcodebuild` and the result bundle uploaded on failure. Options: `--branch`, `--xcode`,
  `--simulator`, `--macos-runner`, `--linux-runner`, `--node`, `--java`, `--flutter`,
  `--scheme`, `--project`, `--file`, `--stdout`, `--force`.
- `mobileci lint` with 16 rules (`MCI000`–`MCI015`): invalid workflow, unpinned actions and
  Docker images, macOS jobs without a timeout or a concurrency group, `macos-latest`, Xcode not
  selected, default and `write-all` token permissions, untrusted event text in scripts and in
  `actions/github-script`, also when it arrives through `${{ env.NAME }}`, `pull_request_target`
  checkouts of the pull request, `continue-on-error`, secrets expanded in scripts, persisted
  checkout credentials, unpinned Flutter and Node.js versions, and build tools piped into a
  formatter without `pipefail`. Output as text, JSON, GitHub annotations or SARIF 2.1.0;
  `--fail-on`, `--disable`, and `# mobileci-ignore` / `# mobileci-ignore-file` comments.
- `mobileci rules`: every rule with what it finds and how to fix it.
- `mobileci version` (`show`, `bump`, `set`, `build`): reads and writes the version and build
  number in Xcode `project.pbxproj` files, `pubspec.yaml`, `package.json`, Expo `app.json`
  and `android/app/build.gradle(.kts)` without reformatting them; `--dry-run`.
- A composite GitHub Action (`action.yml`) that builds the tool and lints a repository's
  workflows, with `paths`, `format`, `fail-on`, `disable` and `output` inputs.
- The `MobileCIKit` library (macOS 14, iOS 17, Linux) with `ProjectDetector`,
  `WorkflowGenerator`, `WorkflowLinter` and `VersionManager`, documented in a DocC catalog with
  articles on getting started, generated workflows, lint rules, version management and limits.
- `Templates/`: the generated workflow for an iOS app, an iOS app with CocoaPods, a macOS app,
  a Swift package, a Flutter app, a React Native app and an Expo app.
- `Examples/WorkflowCheck` (an iOS app that lints workflows with MobileCIKit) and
  `Examples/flutter_sample`; their CI workflows are written by `mobileci init`, and
  `scripts/generate-workflows.sh --check` fails when any generated file drifts.
- 121 Swift Testing tests, run on macOS and an iPhone simulator.

### Changed

- The package requires Swift 6.2 (Swift 6 language mode) and depends only on
  swift-argument-parser and Yams; `Package.resolved` is committed so the CLI and the action
  are built with fixed dependency versions.

### Removed

- The multi-provider generators (GitLab CI, Bitrise, CircleCI, Jenkins, Azure Pipelines,
  Travis CI), the build, test, deploy, App Store Connect and code signing wrappers, the
  CocoaPods podspec and the fastlane files, together with the AsyncHTTPClient, CryptoSwift,
  Rainbow and swift-log dependencies.
- The `ios/`, `flutter/`, `react-native/` and `shared/` workflow folders, whose actions were
  pinned to tags and ran on `macos-latest`; `Templates/` replaces them.
- The "Elite Swift 6 CI" composite action and its binary size check.

### Security

- Files are read with size limits (1 MiB, 32 MiB for `project.pbxproj`) and only when they
  are regular files, so a FIFO or a device cannot block the tool.
- YAML documents are limited to 64 levels and 200,000 nodes after alias expansion ("billion
  laughs" documents fail with `MCI000`) and are parsed on a thread with a 16 MiB stack.
- Linting one workflow takes time in proportion to its size: each `env:` scope keeps
  only its own names over the scope around it, and the workflow and job settings that every
  job or step needs are looked up once, so a file cannot make the work grow with the product
  of two of its parts, such as `env:` names times steps. A run's total time still grows with
  the number and size of the files it lints.
- Project search does not follow symbolic links and stops after 20,000 entries.
- Findings never quote file content; YAML parser messages, which quote the input, are reduced
  to a position. Paths are printed with control and bidirectional characters replaced, and
  GitHub annotation output is escaped so it cannot start another workflow command.
- Values written into generated workflows are checked against an allowlist; quotes, `$`,
  backslashes, braces, control characters and `${{` are refused.
- Version and build numbers are parsed digit by digit against fixed limits, so oversized
  numbers are refused instead of trapping, and a bump at the limit fails instead of wrapping.
  A build number of 0, which Google Play refuses as a `versionCode`, is not written.

## [1.0.0] - 2026-02-03

### Added

- Workflow templates for iOS, Flutter and React Native, fastlane files and shell scripts.
- A `mobileci` command-line tool with build, test, deploy and workflow generation commands.

[Unreleased]: https://github.com/muhittincamdali/MobileCI/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/muhittincamdali/MobileCI/releases/tag/v1.0.0
