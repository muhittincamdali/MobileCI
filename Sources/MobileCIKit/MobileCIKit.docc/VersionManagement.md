# Version management

Change the version and build number of an app in every file that holds them, in one command.

## Overview

An app's version lives in several places at once: `MARKETING_VERSION` in each build
configuration of each Xcode target, `version:` in `pubspec.yaml`, `versionName` and
`versionCode` in Gradle, `expo.version` in `app.json`. ``VersionManager`` finds them, reads
the highest values and writes the new ones everywhere, leaving every other byte of each file
as it was.

```sh
mobileci version
```

```text
React Native in .
  package.json: version 0.0.1, build -
  ios/Shop.xcodeproj/project.pbxproj: version 1.4.0, build 12
  android/app/build.gradle: version 1.3.9, build 11
  current: version 1.4.0, build 12
```

```sh
mobileci version bump minor --build   # 1.5.0, build 13, in all three files
mobileci version set 2.0.0 --build 1
mobileci version build                # build number only: 14
mobileci version build --set 200
```

Add `--dry-run` to see the result without writing, and `--project <folder>` when the
repository holds more than one app.

## Files

| Project      | File                                  | Version                   | Build number                                       |
| ------------ | ------------------------------------- | ------------------------- | -------------------------------------------------- |
| iOS / macOS  | `<App>.xcodeproj/project.pbxproj`     | every `MARKETING_VERSION` | every `CURRENT_PROJECT_VERSION`                    |
| Flutter      | `pubspec.yaml`                        | `version:` before `+`     | after `+` (added when missing)                     |
| React Native | `package.json`                        | `version`                 | —                                                  |
|              | `ios/<App>.xcodeproj/project.pbxproj` | as for iOS                | as for iOS                                         |
|              | `android/app/build.gradle(.kts)`      | literal `versionName`     | literal `versionCode`                              |
| Expo         | `app.json`                            | `expo.version`            | `expo.ios.buildNumber`, `expo.android.versionCode` |

A Flutter app's iOS and Android projects read the version from `pubspec.yaml`, so they are not
edited. Values that are not literals — `$(inherited)`, `flutterVersionCode.toInteger()` — are
left alone. Swift packages are versioned by git tags and have no version file.

## Rules

- A version is one to three numbers (`2`, `2.4`, `2.4.1`) with an optional semver
  `-prerelease` suffix. Each number is at most 999,999,999. ``MarketingVersion``
- A bump starts from the highest version found, increments the part (`2.4.1` → minor
  `2.5.0`), resets the parts after it and drops a prerelease suffix.
- A build number is digits only, at most 2,100,000,000: the largest `versionCode` Google Play
  accepts, which Flutter's build number and Expo's `android.versionCode` become.
  ``BuildNumber``
- A build number that `version set --build` or `version build --set` writes is at least 1,
  since Google Play refuses a `versionCode` of 0. A 0 already in a file is incremented to 1.
- Numbers are read digit by digit against these limits, so `99999999999999999999` is refused
  with a message instead of trapping on an integer overflow, and a bump at the limit fails
  instead of wrapping around.
- Each file is written atomically: a crash leaves either the old or the new file.
