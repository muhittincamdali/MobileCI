# Limits and safety

What MobileCI reads, what it refuses, and what it never does.

## Overview

MobileCI reads repositories it did not write — including pull requests from strangers when the
GitHub Action runs on them — so every input is bounded and every output is checked.

### It never runs project code

Projects are read as text: `Package.swift` is not compiled, `package.json` scripts are not
started, Gradle and CocoaPods are not invoked. The workflows MobileCI writes run your tools on
GitHub's runners; MobileCI itself only reads files.

### It never repeats file content

A ``Finding`` message is written by MobileCI. When it names something from the file — an
action reference, a job name, an expression such as `github.event.pull_request.title` or a
secret's _name_ — that text first has to match a short pattern of letters, digits and `-_./@:`
of at most 120 characters; otherwise the message uses a generic description. Values are never
shown, and YAML parser messages, which quote the input, are reduced to a line and column. Paths
are printed with control and bidirectional formatting characters replaced by `?`, so a file
name cannot rewrite the terminal line or reorder the text. GitHub annotations escape `%`,
carriage returns and newlines (and `:` and `,` in properties) the way `@actions/core` does, so a
value cannot end the annotation or start another workflow command.

### Input limits

| Input                            | Limit                    | When exceeded                                   |
| -------------------------------- | ------------------------ | ----------------------------------------------- |
| Workflow, manifest, scheme file  | 1 MiB                    | Not read; `MCI000` for a workflow               |
| `project.pbxproj`                | 32 MiB                   | Not read                                        |
| YAML nesting                     | 64 levels                | `MCI000`                                        |
| YAML nodes after alias expansion | 200,000                  | `MCI000` ("billion laughs" documents stop here) |
| JSON nesting while editing       | 64 levels                | The field is not edited                         |
| Folders searched by `detect`     | 3 levels, 20,000 entries | The search stops with a note                    |
| Shared schemes read per project  | 200                      | The rest are ignored                            |
| Files listed per workflow folder | 10,000                   | The rest are not linted                         |
| Version numbers                  | 999,999,999 per part     | Refused with ``VersionError``                     |
| Build numbers                    | 2,100,000,000            | Refused with ``VersionError``                     |

Only regular files are read: a file is opened without waiting for a FIFO writer and its type is
checked on the open descriptor, so a FIFO or a device (which would block or never end) is
refused even when it replaces a regular file after the path was looked up, and a file that
grows while it is read is cut off at the limit and refused. `detect` lists symbolic links as files and does not descend into a linked folder, so a link
back to the root cannot make it loop, and it skips `node_modules`, `Pods`, `build`, `DerivedData`,
`.build`, hidden folders and bundles.

YAML is parsed on a thread with a 16 MiB stack, so a deeply nested document fails with a
finding on every thread it is checked from — including the small-stack threads of Swift
concurrency and test runners — instead of overflowing the stack.

### Generated values

Everything the generator writes into a workflow (scheme, project, workspace, folder, branch,
runner, versions, file name) is checked against an allowlist of characters and refused when it
contains quotes, `$`, backticks, backslashes, braces, control characters or `${{`, or when it
is longer than 200 characters. Folders must be relative, without `.` or `..` segments. Values
are written as single-quoted YAML and read in scripts through environment variables.
