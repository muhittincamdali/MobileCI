# Getting Started with MobileCI

Welcome to MobileCI! This guide will help you set up continuous integration and delivery for your mobile applications.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Running Your First Build](#running-your-first-build)
- [Next Steps](#next-steps)

---

## Overview

MobileCI provides comprehensive CI/CD templates for:

- **iOS** (Swift/Objective-C) - Fastlane + GitHub Actions
- **Flutter** - Multi-platform (iOS, Android, Web)
- **React Native** - Cross-platform with Detox E2E testing

### Key Features

| Feature | iOS | Flutter | React Native |
|---------|-----|---------|--------------|
| Automated builds | ✅ | ✅ | ✅ |
| Unit testing | ✅ | ✅ | ✅ |
| UI/E2E testing | ✅ | ✅ | ✅ (Detox) |
| Code signing | ✅ (Match) | ✅ | ✅ |
| App Store deployment | ✅ | ✅ | ✅ |
| Google Play deployment | - | ✅ | ✅ |
| TestFlight distribution | ✅ | ✅ | ✅ |
| Firebase distribution | ✅ | ✅ | ✅ |
| Code coverage | ✅ | ✅ | ✅ |
| Slack notifications | ✅ | ✅ | ✅ |

---

## Prerequisites

### All Platforms

- Git
- GitHub account
- Code editor (VS Code, Xcode, Android Studio)

### iOS Development

- macOS (required)
- Xcode 15.0+
- Ruby 3.0+
- Bundler
- CocoaPods

### Android Development

- Java JDK 17+
- Android Studio
- Android SDK

### Flutter Development

- Flutter SDK (latest stable)
- Dart SDK

### React Native Development

- Node.js 18+
- npm or yarn
- Watchman (recommended)

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/your-app.git
cd your-app
```

### 2. Copy the CI Templates

Choose your platform and copy the relevant files:

**For iOS:**
```bash
cp -r MobileCI/ios/workflows/* .github/workflows/
cp -r MobileCI/ios/fastlane/* fastlane/
cp -r MobileCI/ios/scripts/* scripts/
```

**For Flutter:**
```bash
cp -r MobileCI/flutter/workflows/* .github/workflows/
cp -r MobileCI/flutter/scripts/* scripts/
```

**For React Native:**
```bash
cp -r MobileCI/react-native/workflows/* .github/workflows/
cp -r MobileCI/react-native/scripts/* scripts/
```

### 3. Configure Secrets

Add the following secrets to your GitHub repository:

#### iOS Secrets
| Secret | Description |
|--------|-------------|
| `TEAM_ID` | Apple Developer Team ID |
| `MATCH_PASSWORD` | Password for Match certificates |
| `MATCH_GIT_URL` | Git URL for certificates repo |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64 encoded API key |

#### Android Secrets
| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded keystore |
| `ANDROID_KEYSTORE_PROPERTIES` | Keystore properties file content |
| `GOOGLE_PLAY_JSON_KEY` | Google Play service account JSON |

### 4. Run Setup Script

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 5. Push and Watch

```bash
git add .
git commit -m "ci: add CI/CD configuration"
git push
```

Check the Actions tab in GitHub to see your first build!

---

## Project Structure

```
your-app/
├── .github/
│   ├── workflows/           # GitHub Actions workflows
│   │   ├── ci.yml          # Main CI workflow
│   │   ├── release.yml     # Release workflow
│   │   └── ...
│   ├── CODEOWNERS          # Code ownership
│   └── dependabot.yml      # Dependency updates
├── fastlane/               # iOS: Fastlane configuration
│   ├── Fastfile
│   ├── Appfile
│   └── Matchfile
├── scripts/                # Build and deploy scripts
│   ├── setup.sh
│   ├── build.sh
│   ├── test.sh
│   └── deploy.sh
├── ios/                    # iOS project
├── android/                # Android project
└── ...
```

---

## Configuration

### Environment Variables

Create a `.env` file (don't commit it!):

```bash
# iOS
TEAM_ID=XXXXXXXXXX
BUNDLE_IDENTIFIER=com.company.app

# Android
ANDROID_PACKAGE_NAME=com.company.app

# Firebase
FIREBASE_APP_ID_IOS=1:123456:ios:abc123
FIREBASE_APP_ID_ANDROID=1:123456:android:abc123

# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

### Workflow Customization

Edit the workflow files to match your project:

```yaml
# .github/workflows/ci.yml
env:
  WORKSPACE_NAME: YourApp.xcworkspace
  SCHEME_NAME: YourApp
  XCODE_VERSION: '15.2'
```

---

## Running Your First Build

### Manual Trigger

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select a workflow
4. Click "Run workflow"

### Automatic Triggers

Builds are triggered automatically on:

- **Push to main/develop**: CI builds
- **Pull requests**: PR validation
- **Tags (v*)**: Release builds

### Local Testing

Test your CI scripts locally before pushing:

```bash
# Run tests
./scripts/test.sh

# Build
./scripts/build.sh

# Full CI simulation
act -j build  # Requires 'act' tool
```

---

## Next Steps

1. **[iOS Setup Guide](./ios-setup.md)** - Detailed iOS configuration
2. **[Flutter Setup Guide](./flutter-setup.md)** - Flutter-specific setup
3. **[React Native Setup Guide](./react-native-setup.md)** - React Native configuration
4. **[Code Signing Guide](./code-signing.md)** - Set up certificates and profiles
5. **[Troubleshooting](./troubleshooting.md)** - Common issues and solutions
6. **[Best Practices](./best-practices.md)** - CI/CD best practices

---

## Support

- **Issues**: [GitHub Issues](https://github.com/your-org/MobileCI/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/MobileCI/discussions)

---

## License

MIT License - see [LICENSE](../LICENSE) for details.
