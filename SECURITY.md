# Security policy

## Supported versions

Security fixes go into the latest release and the `main` branch.

## Reporting a vulnerability

Report it privately, not in a public issue: open the repository's
[Security tab](https://github.com/muhittincamdali/MobileCI/security) and choose **Report a
vulnerability**, or follow the other channels in the
[security policy of the muhittincamdali repositories](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md). Include the input that shows the problem (a workflow, a project
layout or a version file) and the command you ran.

## What MobileCI promises

MobileCI reads repositories it did not write; the GitHub Action can run on pull requests from
anyone. These are the properties a report can hold it to:

- It never runs code from the repository: manifests, scripts and build files are read as
  text.
- It never prints file content: findings quote only short identifiers that pass a character
  allowlist, and YAML parser messages are reduced to a line and column.
- Output cannot inject workflow commands: GitHub annotation values are escaped the way
  `@actions/core` escapes them, and terminal output replaces control and bidirectional
  formatting characters.
- Every input is bounded: file sizes, YAML depth and alias expansion, folder walks and number
  sizes have fixed limits, listed in
  [Limits and safety](https://muhittincamdali.github.io/MobileCI/documentation/mobilecikit/limitsandsafety).
- Generated workflows only contain values that passed an allowlist, pass them to scripts
  through environment variables, pin every action to a commit and grant `contents: read`.

A crash, a hang, unbounded memory use, file content in the output, or a generated workflow
that runs injected text is a vulnerability.

## Out of scope

- Secret scanning: MobileCI does not look for leaked tokens in files (use a secret scanner
  such as gitleaks).
- Workflows that a rule does not cover; suggest a rule in an issue instead.
