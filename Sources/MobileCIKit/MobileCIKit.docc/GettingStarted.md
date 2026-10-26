# Getting started

Install the `mobileci` tool, write a workflow for your app and keep it healthy.

## Overview

You need a Mac with Xcode 26 or later (or Linux with Swift 6.2 or later) and a repository that
holds an Xcode project, a Swift package, a Flutter app or a React Native app.

### Install the tool

Build it from source; the result is one executable without runtime dependencies:

```sh
git clone https://github.com/muhittincamdali/MobileCI.git
cd MobileCI
swift build --configuration release --product mobileci
sudo install .build/release/mobileci /usr/local/bin/mobileci
```

Run `mobileci --help` to check it.

### See what CI will see

In the root of your repository:

```sh
mobileci detect
```

```text
iOS app in .
  project: Shop.xcodeproj
  workspace: Shop.xcworkspace
  shared schemes: Shop (tests)
  workflow scheme: Shop
  platform: iOS
  CocoaPods: yes (through Bundler)
  workflow: .github/workflows/ios.yml
```

If the output says that a project has **no shared scheme**, fix that first: CI machines only
see schemes that are shared. In Xcode choose Product › Scheme › Manage Schemes…, tick
**Shared** for the app's scheme, and commit the new `.xcscheme` file.

### Write the workflow

```sh
mobileci init
```

This writes `.github/workflows/ios.yml` (or `flutter.yml`, `react-native.yml`…) for each
project. Commit it and push: the workflow builds and tests on every push to `main` and every
pull request. <doc:GeneratingWorkflows> describes each line and the options, such as
`--xcode 26.4.1` or `--simulator "iPhone 17 Pro"`.

### Check workflows

```sh
mobileci lint
```

```text
.github/workflows/release.yml:7:14: warning[MCI004] `macos-latest` moves to a new macOS image and default Xcode without a change in this repository; use a versioned label such as `macos-26`.
1 file checked: 0 error(s), 1 warning(s), 0 note(s).
```

`lint` exits with status 1 when a finding reaches `--fail-on` (warning by default), so it can
guard pull requests. <doc:LintRules> explains each rule.

To run it on every pull request without installing anything, add the MobileCI action to a
workflow; findings appear as annotations on the changed lines:

```yaml
jobs:
  workflows:
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: muhittincamdali/MobileCI@main # pin to a release commit, as MCI001 asks
```

### Version the app

```sh
mobileci version              # list every version and build number
mobileci version bump patch --build
```

<doc:VersionManagement> lists the files and the rules for each.

### Use the library

Add the package to `Package.swift` and depend on the ``MobileCIKit`` product:

```swift
.package(url: "https://github.com/muhittincamdali/MobileCI.git", branch: "main")
```

```swift
import MobileCIKit

let report = ProjectDetector().detect(in: URL(fileURLWithPath: "."))
for project in report.projects {
    let workflow = try WorkflowGenerator().workflow(for: project)
    print(workflow.fileName)
}
```

The example app in `Examples/WorkflowCheck` lints workflows on an iPhone with the same code.
