# MobileCI

[![CI](https://github.com/user/MobileCI/actions/workflows/ci.yml/badge.svg)](https://github.com/user/MobileCI/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

Comprehensive CI/CD templates for mobile applications. Production-ready workflows for iOS, Flutter, and React Native.

```
┌─────────────────────────────────────────────────────────────┐
│                        MobileCI                             │
│                                                             │
│   iOS • Flutter • React Native • GitHub Actions             │
│                                                             │
│   Build → Test → Sign → Deploy → Monitor                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

| Feature | iOS | Flutter | React Native |
|---------|:---:|:-------:|:------------:|
| Automated builds | ✅ | ✅ | ✅ |
| Unit testing | ✅ | ✅ | ✅ |
| UI/E2E testing | ✅ | ✅ | ✅ |
| Code coverage | ✅ | ✅ | ✅ |
| Code signing (Match) | ✅ | ✅ | ✅ |
| TestFlight deployment | ✅ | ✅ | ✅ |
| App Store release | ✅ | ✅ | ✅ |
| Google Play release | - | ✅ | ✅ |
| Firebase distribution | ✅ | ✅ | ✅ |
| Slack notifications | ✅ | ✅ | ✅ |
| Caching optimization | ✅ | ✅ | ✅ |
| PR checks | ✅ | ✅ | ✅ |
| Nightly builds | ✅ | ✅ | ✅ |

---

## Quick Start

### 1. Choose Your Platform

```bash
# Clone the repository
git clone https://github.com/user/MobileCI.git

# Copy templates to your project
cp -r MobileCI/ios/workflows/* your-project/.github/workflows/      # iOS
cp -r MobileCI/flutter/workflows/* your-project/.github/workflows/  # Flutter
cp -r MobileCI/react-native/workflows/* your-project/.github/workflows/  # React Native
```

### 2. Configure Secrets

Add these secrets to your GitHub repository:

**iOS:**
```
TEAM_ID                            # Apple Developer Team ID
MATCH_PASSWORD                     # Match encryption password
MATCH_GIT_URL                      # Certificates repo URL
APP_STORE_CONNECT_API_KEY_ID       # API Key ID
APP_STORE_CONNECT_ISSUER_ID        # Issuer ID
APP_STORE_CONNECT_API_KEY_CONTENT  # Base64 encoded key
```

**Android:**
```
ANDROID_KEYSTORE_BASE64            # Base64 encoded keystore
ANDROID_KEYSTORE_PROPERTIES        # Keystore properties
GOOGLE_PLAY_JSON_KEY               # Service account JSON
```

### 3. Push and Deploy

```bash
git add .
git commit -m "ci: add CI/CD workflows"
git push
```

---

## Project Structure

```
MobileCI/
├── ios/                          # iOS-specific templates
│   ├── fastlane/                 # Fastlane configuration
│   │   ├── Fastfile             # All lanes (400+ lines)
│   │   ├── Appfile              # App Store Connect config
│   │   ├── Matchfile            # Code signing config
│   │   └── Pluginfile           # Fastlane plugins
│   ├── workflows/                # GitHub Actions workflows
│   │   ├── ci.yml               # Build & test
│   │   ├── release.yml          # App Store release
│   │   ├── beta.yml             # TestFlight deployment
│   │   ├── pr.yml               # PR validation
│   │   └── nightly.yml          # Scheduled builds
│   └── scripts/                  # Shell scripts
│       ├── setup.sh             # Environment setup
│       ├── test.sh              # Test runner
│       ├── build.sh             # Build script
│       └── deploy.sh            # Deployment script
│
├── flutter/                      # Flutter templates
│   ├── workflows/
│   │   ├── ci.yml               # Multi-platform CI
│   │   ├── release-android.yml  # Google Play release
│   │   ├── release-ios.yml      # App Store release
│   │   └── web.yml              # Web deployment
│   └── scripts/
│       ├── build_runner.sh      # Code generation
│       ├── test_coverage.sh     # Coverage reports
│       └── deploy.sh            # Multi-platform deploy
│
├── react-native/                 # React Native templates
│   ├── workflows/
│   │   ├── ci.yml               # Build & test
│   │   ├── android-release.yml  # Google Play release
│   │   ├── ios-release.yml      # App Store release
│   │   └── eas-build.yml        # Expo EAS builds
│   └── scripts/
│       ├── setup.sh             # Environment setup
│       └── e2e-test.sh          # Detox E2E tests
│
├── shared/                       # Shared templates
│   ├── templates/
│   │   ├── CODEOWNERS           # Code ownership
│   │   ├── dependabot.yml       # Dependency updates
│   │   ├── pr-template.md       # PR template
│   │   ├── bug-report.yml       # Issue template
│   │   └── feature-request.yml  # Feature request
│   ├── actions/                  # Composite actions
│   │   ├── cache-setup/         # Multi-platform caching
│   │   ├── notify-slack/        # Slack notifications
│   │   └── upload-artifact/     # Artifact handling
│   └── scripts/
│       ├── version-bump.sh      # Version management
│       └── changelog-gen.sh     # Changelog generation
│
└── docs/                         # Documentation
    ├── getting-started.md
    ├── ios-setup.md
    ├── flutter-setup.md
    ├── react-native-setup.md
    ├── code-signing.md
    ├── troubleshooting.md
    └── best-practices.md
```

---

## Workflows

### iOS Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `ci.yml` | Push, PR | Build, test, lint |
| `release.yml` | Tag `v*` | App Store release |
| `beta.yml` | Push to develop | TestFlight deployment |
| `pr.yml` | Pull request | PR validation |
| `nightly.yml` | Scheduled | Comprehensive testing |

### Flutter Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `ci.yml` | Push, PR | Multi-platform build & test |
| `release-android.yml` | Tag | Google Play release |
| `release-ios.yml` | Tag | App Store release |
| `web.yml` | Push to main | Web deployment |

### React Native Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `ci.yml` | Push, PR | Build, test, lint |
| `android-release.yml` | Tag | Google Play release |
| `ios-release.yml` | Tag | App Store release |
| `eas-build.yml` | Push | Expo EAS builds |

---

## Configuration

### Environment Variables

Configure in your workflow files:

```yaml
env:
  # iOS
  WORKSPACE_NAME: App.xcworkspace
  SCHEME_NAME: App
  XCODE_VERSION: '15.2'
  
  # Android
  JAVA_VERSION: '17'
  
  # Flutter
  FLUTTER_VERSION: 'stable'
  
  # React Native
  NODE_VERSION: '20'
```

### Fastlane Configuration

Customize `fastlane/Fastfile`:

```ruby
# Update these constants
WORKSPACE = 'YourApp.xcworkspace'
SCHEME = 'YourApp'
BUNDLE_ID = 'com.company.app'
```

### Code Signing (Match)

Configure `fastlane/Matchfile`:

```ruby
git_url("git@github.com:company/certificates.git")
app_identifier("com.company.app")
team_id(ENV["TEAM_ID"])
```

---

## Deployment Targets

### App Store / Google Play

```bash
# Create version tag
git tag v1.0.0
git push origin v1.0.0
# Workflow automatically deploys
```

### TestFlight / Internal Testing

```bash
# Push to develop branch
git push origin develop
# Or trigger manually
gh workflow run ios-beta.yml
```

### Firebase App Distribution

```yaml
# Add to secrets
FIREBASE_APP_ID: your-app-id
FIREBASE_CLI_TOKEN: your-token
```

---

## Scripts

### Setup Development Environment

```bash
./scripts/setup.sh
```

### Run Tests

```bash
./scripts/test.sh --coverage
```

### Build Release

```bash
./scripts/build.sh --release
```

### Deploy

```bash
./scripts/deploy.sh --target testflight
```

### Bump Version

```bash
./shared/scripts/version-bump.sh --minor --tag
```

---

## Shared Actions

### Cache Setup

```yaml
- uses: ./shared/actions/cache-setup
  with:
    platform: ios
```

### Slack Notification

```yaml
- uses: ./shared/actions/notify-slack
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    status: ${{ job.status }}
    platform: ios
    version: '1.0.0'
```

### Upload Artifact

```yaml
- uses: ./shared/actions/upload-artifact
  with:
    name: ios-build
    path: build/*.ipa
    version: '1.0.0'
```

---

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Initial setup guide |
| [iOS Setup](docs/ios-setup.md) | iOS-specific configuration |
| [Flutter Setup](docs/flutter-setup.md) | Flutter multi-platform setup |
| [React Native Setup](docs/react-native-setup.md) | React Native configuration |
| [Code Signing](docs/code-signing.md) | Certificate management |
| [Troubleshooting](docs/troubleshooting.md) | Common issues & solutions |
| [Best Practices](docs/best-practices.md) | CI/CD recommendations |

---

## Requirements

### iOS

- macOS (for builds)
- Xcode 15.0+
- Ruby 3.0+
- CocoaPods
- Apple Developer Account

### Flutter

- Flutter SDK 3.16+
- Dart SDK 3.0+
- Xcode 15.0+ (iOS)
- Android Studio / JDK 17 (Android)

### React Native

- Node.js 18+
- React Native CLI
- Xcode 15.0+ (iOS)
- Android Studio / JDK 17 (Android)

---

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## Security

- Never commit secrets or credentials
- Use GitHub Secrets for sensitive data
- Enable Dependabot for security updates
- Report vulnerabilities via [Security Policy](SECURITY.md)

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Fastlane](https://fastlane.tools) - iOS automation
- [GitHub Actions](https://github.com/features/actions) - CI/CD platform
- [Flutter](https://flutter.dev) - Cross-platform framework
- [React Native](https://reactnative.dev) - Mobile framework
- [Detox](https://wix.github.io/Detox/) - E2E testing

---

<p align="center">
  Made with ❤️ for mobile developers
</p>
