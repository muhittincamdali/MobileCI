# Examples

Both examples have a CI workflow written by `mobileci init`, which runs in this repository on
every push: [examples.yml](../.github/workflows/examples.yml) and
[example-flutter.yml](../.github/workflows/example-flutter.yml).
`scripts/generate-workflows.sh --check` fails when either differs from what the generator
writes today.

## WorkflowCheck

An iOS app that lints a GitHub Actions workflow with MobileCIKit as you edit it. It starts on
one of three samples: a typical first iOS workflow, a workflow that expands a pull request
title in a script, and the workflow `WorkflowGenerator` writes for the app itself. Each finding
shows its rule, severity, line and message. It uses the package from this checkout (a local
package reference to `../..`), so it always shows the current rules.

Run it:

1. Open `Examples/WorkflowCheck/WorkflowCheck.xcodeproj` in Xcode 26 or later.
2. Choose the **WorkflowCheck** scheme and an iPhone simulator.
3. Press **Run** (⌘R).

From the command line:

```sh
cd Examples/WorkflowCheck
xcodebuild test -scheme WorkflowCheck -destination 'platform=iOS Simulator,name=iPhone 17'
```

The tests check that each sample produces the findings its title promises and that the
generated workflow has none. The project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen); the `.xcodeproj` is committed, so XcodeGen
is only needed after changing `project.yml`.

## flutter_sample

A Flutter app (no platform folders, so its workflow only analyzes and tests) that reads a
`pubspec.yaml` version such as `1.4.0+27` the way Flutter splits it into a name and a build
number, refusing build numbers above Google Play's limit.

```sh
cd Examples/flutter_sample
flutter pub get
flutter analyze
flutter test
```
