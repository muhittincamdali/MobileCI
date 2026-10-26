# ``MobileCIKit``

Write, check and version the GitHub Actions CI of iOS, Flutter and React Native apps.

## Overview

MobileCIKit is the library behind the `mobileci` command-line tool and the MobileCI GitHub
Action. It does four things, each usable on its own:

- **Detect** the projects in a repository — Xcode projects with their shared schemes, Swift
  packages, Flutter apps with their platform folders, React Native and Expo apps with their
  package manager — and explain what a first CI run would trip over (``ProjectDetector``).
- **Generate** a workflow for each project with pinned actions, an explicit Xcode version,
  read-only permissions, timeouts and caches (``WorkflowGenerator``).
- **Lint** existing workflows for the problems that cost mobile teams time and money: unpinned
  actions, `macos-latest` drift, a missing Xcode selection, test failures hidden behind a pipe,
  script injection and more (``WorkflowLinter``, ``RuleID``).
- **Version** an app in every file that holds its version and build number
  (``VersionManager``).

```swift
import MobileCIKit

let findings = WorkflowLinter().lint(text: yaml, path: ".github/workflows/ios.yml")
for finding in findings {
    print("\(finding.location.line): \(finding.rule.rawValue) \(finding.message)")
}
```

The library runs on macOS 14 and iOS 17 and later, and on Linux. It reads files with size
limits, does not descend into symlinked folders while searching, never runs anything from a
project and never repeats file content in its messages; <doc:LimitsAndSafety> lists every
limit.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:GeneratingWorkflows>
- <doc:LintRules>
- <doc:VersionManagement>
- <doc:LimitsAndSafety>

### Detecting projects

- ``ProjectDetector``
- ``DetectionReport``
- ``DetectionNote``
- ``DetectedProject``
- ``XcodeProject``
- ``XcodeScheme``
- ``ApplePlatform``
- ``SwiftPackage``
- ``FlutterProject``
- ``ReactNativeProject``
- ``PackageManager``

### Generating workflows

- ``WorkflowGenerator``
- ``GeneratorOptions``
- ``GeneratedWorkflow``
- ``GeneratorError``
- ``PinnedAction``

### Linting workflows

- ``WorkflowLinter``
- ``RuleID``
- ``Finding``
- ``Severity``
- ``SourceLocation``
- ``ReportFormat``
- ``YAMLValue``
- ``YAMLMember``
- ``YAMLLoadError``

### Versioning apps

- ``VersionManager``
- ``VersionChange``
- ``VersionPlan``
- ``VersionFile``
- ``VersionFileFormat``
- ``MarketingVersion``
- ``BuildNumber``
- ``VersionPart``
- ``VersionError``

### Files and output

- ``TextFile``
- ``TextFileError``
- ``MobileCIInfo``
