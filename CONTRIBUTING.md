# Contributing to MobileCI

Thank you for helping. This guide covers the checks a pull request has to pass and the parts
of the repository that change together.

## Set up

You need Xcode 26 or later (or Swift 6.2 on Linux), Node.js 24 for the screenshot scripts and,
for the Flutter example, Flutter 3.41 or later.

```sh
swift build
swift test
```

## Before you open a pull request

Run the checks CI runs:

```sh
swift test                                                    # macOS
xcodebuild test -scheme MobileCI-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17'        # iPhone simulator
scripts/generate-workflows.sh --check                         # templates match the generator
swift run mobileci lint .github/workflows Templates
actionlint .github/workflows/*.yml Templates/*.yml
```

- **A new lint rule** needs a `RuleID` case with its name, severity, summary and fix, one check
  function in `Sources/MobileCIKit/Lint`, tests for a workflow that triggers it and one that
  does not, and a section in `MobileCIKit.docc/LintRules.md`. Messages must not quote file
  content beyond a short identifier passed through `Rules.quoted`.
- **A generator change** changes the generated files: run `scripts/generate-workflows.sh` and
  commit `Templates/` and the example workflows with it. Every generated workflow must keep
  passing `mobileci lint` without findings (`GeneratorTests`).
- **A new action version**: update `PinnedAction.swift` with the commit the release tag points
  to (`gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`), then regenerate. Dependabot
  updates the example workflows; its pull request needs the same change to pass.
- **Screenshots** come from code: `scripts/capture-terminal.sh` for the terminal images and
  `scripts/capture-example-screens.sh` for the example app. Do not edit images by hand.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat(lint): …`,
`fix(version): …`), one change per commit, and describe why in the body. Add a line to the
`Unreleased` section of [CHANGELOG.md](CHANGELOG.md) for anything a user notices.

## Code of conduct

This project follows the
[code of conduct](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md)
of the muhittincamdali repositories.
