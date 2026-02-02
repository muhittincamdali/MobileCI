<p align="center">
  <h1 align="center">🚀 MobileCI</h1>
  <p align="center">Ready-to-use CI/CD templates for iOS, Flutter & React Native</p>
</p>

<p align="center">
  <a href="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml">
    <img src="https://github.com/muhittincamdali/MobileCI/actions/workflows/ci.yml/badge.svg" alt="CI Status">
  </a>
  <a href="https://github.com/muhittincamdali/MobileCI/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/muhittincamdali/MobileCI" alt="License">
  </a>
  <a href="https://github.com/muhittincamdali/MobileCI/stargazers">
    <img src="https://img.shields.io/github/stars/muhittincamdali/MobileCI?style=social" alt="Stars">
  </a>
  <a href="https://github.com/muhittincamdali/MobileCI/issues">
    <img src="https://img.shields.io/github/issues/muhittincamdali/MobileCI" alt="Issues">
  </a>
</p>

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [iOS Templates](#ios-templates)
- [Flutter Templates](#flutter-templates)
- [React Native Templates](#react-native-templates)
- [Shared Templates](#shared-templates)
- [Fastlane Integration](#fastlane-integration)
- [Scripts](#scripts)
- [Configuration](#configuration)
- [Secrets Setup](#secrets-setup)
- [Benchmarks](#benchmarks)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**MobileCI** is a curated collection of production-ready GitHub Actions workflows for mobile app development. Stop writing CI/CD pipelines from scratch — grab a template, configure your secrets, and ship.

Each template is battle-tested, well-documented, and follows current best practices for build performance, caching, and code signing.

### Why MobileCI?

- **Save hours** of pipeline configuration per project
- **Battle-tested** workflows used in production apps
- **Modular design** — pick only what you need
- **Comprehensive caching** for fast builds
- **Automatic code signing** for iOS
- **Multi-store deployment** — App Store, Play Store, TestFlight
- **Notification integrations** — Slack, Discord
- **Fastlane integration** out of the box

---

## Features

### 🍎 iOS

| Feature | Template | Description |
|---------|----------|-------------|
| Build & Test | `templates/ios/ci.yml` | Xcode build, unit tests, UI tests |
| Release | `templates/ios/release.yml` | TestFlight & App Store deployment |
| Code Signing | `templates/ios/code-signing.yml` | Automatic provisioning & certificates |
| Linting | `templates/ios/swiftlint.yml` | SwiftLint integration |

### 🐦 Flutter

| Feature | Template | Description |
|---------|----------|-------------|
| Build & Test | `templates/flutter/ci.yml` | Flutter analyze, test, build |
| Android Release | `templates/flutter/release-android.yml` | Play Store deployment |
| iOS Release | `templates/flutter/release-ios.yml` | App Store deployment |
| Code Quality | `templates/flutter/code-quality.yml` | Dart analyze, formatting, coverage |

### ⚛️ React Native

| Feature | Template | Description |
|---------|----------|-------------|
| Build & Test | `templates/react-native/ci.yml` | RN build, Jest tests |
| Release | `templates/react-native/release.yml` | Both stores deployment |
| E2E Tests | `templates/react-native/e2e.yml` | Detox end-to-end testing |

### 🔗 Shared

| Feature | Template | Description |
|---------|----------|-------------|
| Slack Notify | `templates/shared/notify-slack.yml` | Build notifications to Slack |
| Discord Notify | `templates/shared/notify-discord.yml` | Build notifications to Discord |
| Cache | `templates/shared/cache.yml` | Reusable caching strategies |

---

## Quick Start

### 1. Copy the template

```bash
# Clone this repository
git clone https://github.com/muhittincamdali/MobileCI.git

# Copy the iOS CI template to your project
cp MobileCI/templates/ios/ci.yml your-project/.github/workflows/ci.yml
```

### 2. Configure secrets

Go to your repository **Settings → Secrets and variables → Actions** and add the required secrets for your chosen template.

### 3. Push and watch

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add iOS CI workflow"
git push
```

That's it! Your CI pipeline is now running.

---

## iOS Templates

### CI — Build & Test (`templates/ios/ci.yml`)

Full Xcode build and test pipeline with caching, parallel testing, and artifact uploads.

**Required Secrets:**
| Secret | Description |
|--------|-------------|
| None | Basic CI needs no secrets |

**Optional Secrets:**
| Secret | Description |
|--------|-------------|
| `CODECOV_TOKEN` | Upload coverage to Codecov |

**Triggers:** Push to `main`/`develop`, pull requests

**What it does:**
1. Checks out code
2. Restores SPM/CocoaPods cache
3. Installs dependencies
4. Builds the project
5. Runs unit tests with parallel testing
6. Runs UI tests on simulator
7. Uploads test results and coverage
8. Posts status to PR

### Release — TestFlight & App Store (`templates/ios/release.yml`)

Automated deployment to TestFlight (on tags) and App Store (manual trigger).

**Required Secrets:**
| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Private key (.p8 content) |
| `MATCH_PASSWORD` | Fastlane match encryption password |
| `MATCH_GIT_URL` | Git URL for match certificates repo |

### Code Signing (`templates/ios/code-signing.yml`)

Reusable workflow for setting up Apple code signing using Fastlane Match.

### SwiftLint (`templates/ios/swiftlint.yml`)

Runs SwiftLint and posts inline annotations on pull requests.

---

## Flutter Templates

### CI — Analyze & Test (`templates/flutter/ci.yml`)

Complete Flutter CI with analyze, test, and build for all platforms.

**Customizable inputs:**
- `flutter_version` — Flutter SDK version (default: `stable`)
- `working_directory` — Path to Flutter project
- `run_integration_tests` — Enable/disable integration tests

**What it does:**
1. Sets up Flutter SDK
2. Restores pub cache
3. Runs `flutter analyze`
4. Runs `flutter test` with coverage
5. Builds APK and IPA
6. Uploads artifacts

### Android Release (`templates/flutter/release-android.yml`)

Deploys Flutter Android apps to Google Play Store using Fastlane Supply.

**Required Secrets:**
| Secret | Description |
|--------|-------------|
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play service account key |
| `ANDROID_KEYSTORE_BASE64` | Signing keystore (base64 encoded) |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_STORE_PASSWORD` | Store password |

### iOS Release (`templates/flutter/release-ios.yml`)

Deploys Flutter iOS apps to TestFlight and App Store.

### Code Quality (`templates/flutter/code-quality.yml`)

Enforces code formatting, analysis rules, and minimum test coverage.

---

## React Native Templates

### CI — Build & Test (`templates/react-native/ci.yml`)

Full React Native CI with Jest tests, TypeScript checking, and native builds.

**What it does:**
1. Sets up Node.js environment
2. Installs npm/yarn dependencies with cache
3. Runs ESLint
4. Runs TypeScript compiler check
5. Runs Jest unit tests
6. Builds Android APK
7. Builds iOS app on macOS runner
8. Uploads build artifacts

### Release (`templates/react-native/release.yml`)

Deploys to both App Store and Google Play Store.

### E2E — Detox (`templates/react-native/e2e.yml`)

End-to-end testing with Detox on iOS simulator and Android emulator.

**What it does:**
1. Sets up test environment
2. Builds Detox test app
3. Runs E2E tests on iOS simulator
4. Runs E2E tests on Android emulator
5. Captures screenshots on failure
6. Uploads test artifacts

---

## Shared Templates

### Slack Notifications (`templates/shared/notify-slack.yml`)

Reusable workflow that sends build status notifications to a Slack channel.

**Required Secrets:**
| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK_URL` | Slack incoming webhook URL |

**Features:**
- Success/failure/cancelled status messages
- Build duration and commit info
- Direct link to workflow run
- Custom channel override

### Discord Notifications (`templates/shared/notify-discord.yml`)

Same as Slack but for Discord webhooks with rich embeds.

### Cache (`templates/shared/cache.yml`)

Reusable caching strategies for all platforms:
- SPM package cache
- CocoaPods cache
- Gradle cache
- Flutter pub cache
- Node modules cache
- Yarn cache

---

## Fastlane Integration

### iOS Fastfile (`fastlane/ios/Fastfile`)

Complete Fastlane configuration for iOS projects:
- `test` — Run all tests
- `beta` — Deploy to TestFlight
- `release` — Submit to App Store
- `screenshots` — Capture App Store screenshots
- `certificates` — Sync signing certificates
- `lint` — Run SwiftLint

### Flutter Fastfile (`fastlane/flutter/Fastfile`)

Fastlane configuration for Flutter projects:
- `build_android` — Build release APK/AAB
- `build_ios` — Build release IPA
- `deploy_android` — Upload to Play Store
- `deploy_ios` — Upload to App Store
- `test` — Run Flutter tests

---

## Scripts

### `scripts/setup-signing.sh`

Automates iOS code signing setup:
- Installs certificates from base64 secrets
- Creates provisioning profile directory
- Imports into temporary keychain
- Cleans up after build

### `scripts/bump-version.sh`

Bumps version numbers across platforms:
- iOS: Updates `Info.plist` and `project.pbxproj`
- Android: Updates `build.gradle`
- Flutter: Updates `pubspec.yaml`
- React Native: Updates `package.json`

### `scripts/generate-changelog.sh`

Generates changelogs from git history:
- Conventional Commits parsing
- Grouped by type (features, fixes, etc.)
- Links to commits and PRs
- Markdown output

---

## Configuration

### Environment Variables

All templates support these common environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `XCODE_VERSION` | Xcode version to use | Latest |
| `FLUTTER_VERSION` | Flutter SDK version | `stable` |
| `NODE_VERSION` | Node.js version | `20` |
| `JAVA_VERSION` | Java version for Android | `17` |
| `RUBY_VERSION` | Ruby version for Fastlane | `3.2` |

### Customization

Each template has clearly marked sections for customization:

```yaml
# ===== CUSTOMIZE START =====
env:
  SCHEME: "YourApp"          # Your Xcode scheme
  PROJECT: "YourApp.xcodeproj"  # Your project file
  DESTINATION: "platform=iOS Simulator,name=iPhone 15 Pro"
# ===== CUSTOMIZE END =====
```

---

## Secrets Setup

### iOS Secrets Guide

1. **App Store Connect API Key:**
   - Go to [App Store Connect → Users → Keys](https://appstoreconnect.apple.com/access/api)
   - Generate a new key with "App Manager" role
   - Save the Key ID, Issuer ID, and downloaded .p8 file

2. **Code Signing with Match:**
   - Create a private repository for certificates
   - Run `fastlane match init` and configure
   - Set `MATCH_PASSWORD` and `MATCH_GIT_URL` secrets

3. **Add to GitHub Secrets:**
   ```bash
   gh secret set APP_STORE_CONNECT_API_KEY_ID --body "YOUR_KEY_ID"
   gh secret set APP_STORE_CONNECT_API_ISSUER_ID --body "YOUR_ISSUER_ID"
   gh secret set APP_STORE_CONNECT_API_KEY_CONTENT < AuthKey_XXXXX.p8
   ```

### Android Secrets Guide

1. **Play Store Service Account:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a service account with Play Store permissions
   - Download the JSON key

2. **Signing Keystore:**
   ```bash
   base64 -i your-release.keystore | pbcopy
   gh secret set ANDROID_KEYSTORE_BASE64 --body "$(pbpaste)"
   ```

---

## Benchmarks

See [Benchmarks/README.md](Benchmarks/README.md) for detailed build time comparisons.

| Platform | Cold Build | Cached Build | Savings |
|----------|-----------|--------------|---------|
| iOS | ~12 min | ~4 min | 67% |
| Flutter | ~8 min | ~3 min | 63% |
| React Native | ~10 min | ~3.5 min | 65% |

---

## Project Structure

```
MobileCI/
├── templates/
│   ├── ios/
│   │   ├── ci.yml              # Build & test
│   │   ├── release.yml         # TestFlight & App Store
│   │   ├── code-signing.yml    # Certificate management
│   │   └── swiftlint.yml       # Linting
│   ├── flutter/
│   │   ├── ci.yml              # Analyze & test
│   │   ├── release-android.yml # Play Store
│   │   ├── release-ios.yml     # App Store
│   │   └── code-quality.yml    # Quality checks
│   ├── react-native/
│   │   ├── ci.yml              # Build & test
│   │   ├── release.yml         # Both stores
│   │   └── e2e.yml             # Detox E2E
│   └── shared/
│       ├── notify-slack.yml    # Slack notifications
│       ├── notify-discord.yml  # Discord notifications
│       └── cache.yml           # Caching strategies
├── fastlane/
│   ├── ios/Fastfile            # iOS lanes
│   └── flutter/Fastfile        # Flutter lanes
├── scripts/
│   ├── setup-signing.sh        # Code signing setup
│   ├── bump-version.sh         # Version bumping
│   └── generate-changelog.sh   # Changelog generation
├── Benchmarks/
│   └── README.md               # Build time benchmarks
├── README.md
├── LICENSE
└── CONTRIBUTING.md
```

---

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-template`)
3. Add or improve a template
4. Test the template in a real project
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## Related Projects

- [fastlane](https://github.com/fastlane/fastlane) — Automate mobile development
- [Detox](https://github.com/wix/Detox) — Mobile E2E testing
- [SwiftLint](https://github.com/realm/SwiftLint) — Swift linting

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Author

**Muhittin Camdali**
- GitHub: [@muhittincamdali](https://github.com/muhittincamdali)

---

<p align="center">
  If you find this useful, please consider giving it a ⭐
</p>
