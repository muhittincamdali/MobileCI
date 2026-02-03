# Flutter Setup Guide

Complete guide for setting up Flutter CI/CD with MobileCI.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [GitHub Actions Configuration](#github-actions-configuration)
- [Android Configuration](#android-configuration)
- [iOS Configuration](#ios-configuration)
- [Web Configuration](#web-configuration)
- [Testing Setup](#testing-setup)
- [Deployment](#deployment)

---

## Prerequisites

### Flutter SDK

```bash
# Install Flutter
# macOS (with Homebrew)
brew install flutter

# Or download from flutter.dev
# https://docs.flutter.dev/get-started/install

# Verify installation
flutter doctor -v
```

### Platform-Specific

**For iOS builds:**
- macOS with Xcode 15+
- CocoaPods
- Apple Developer account

**For Android builds:**
- Java JDK 17
- Android SDK
- Android Studio (recommended)

---

## Project Setup

### 1. Copy MobileCI Templates

```bash
cd your-flutter-project

# Copy workflows
mkdir -p .github/workflows
cp MobileCI/flutter/workflows/*.yml .github/workflows/

# Copy scripts
mkdir -p scripts
cp MobileCI/flutter/scripts/*.sh scripts/
chmod +x scripts/*.sh
```

### 2. Configure pubspec.yaml

Ensure your `pubspec.yaml` has proper version:

```yaml
name: your_app
description: Your Flutter application
version: 1.0.0+1  # version_name+build_number

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.16.0'
```

### 3. Setup Code Generation (if needed)

If using build_runner:

```yaml
# pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  freezed: ^2.4.0
  freezed_annotation: ^2.4.0
```

Run code generation:

```bash
./scripts/build_runner.sh
# Or
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## GitHub Actions Configuration

### Environment Variables

Configure in workflow files:

```yaml
env:
  FLUTTER_VERSION: 'stable'  # or specific version like '3.16.0'
  JAVA_VERSION: '17'
  RUBY_VERSION: '3.2'
```

### Required Secrets

#### For Android

| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded keystore file |
| `ANDROID_KEYSTORE_PROPERTIES` | Keystore credentials |
| `GOOGLE_PLAY_JSON_KEY` | Service account JSON |
| `ANDROID_PACKAGE_NAME` | Package name (e.g., com.company.app) |

#### For iOS

| Secret | Description |
|--------|-------------|
| `TEAM_ID` | Apple Developer Team ID |
| `MATCH_PASSWORD` | Match encryption password |
| `MATCH_GIT_URL` | Certificates repository URL |
| `APP_STORE_CONNECT_API_KEY_*` | API key credentials |

---

## Android Configuration

### 1. Create Signing Key

```bash
# Generate keystore
keytool -genkey -v \
  -keystore release-keystore.jks \
  -alias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Base64 encode for GitHub secret
base64 -i release-keystore.jks | pbcopy
```

### 2. Configure Signing

Create `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=release
storeFile=release-keystore.jks
```

Update `android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3. Google Play Setup

1. Create service account in Google Cloud Console
2. Enable Google Play Developer API
3. Add service account to Play Console
4. Download JSON key

---

## iOS Configuration

### 1. Install CocoaPods

```bash
cd ios
pod install
```

### 2. Setup Match (Code Signing)

Create `ios/fastlane/Matchfile`:

```ruby
git_url(ENV['MATCH_GIT_URL'])
storage_mode('git')
type('appstore')
app_identifier(ENV['APP_IDENTIFIER'])
team_id(ENV['TEAM_ID'])
```

### 3. Initialize Certificates

```bash
cd ios
bundle exec fastlane match development
bundle exec fastlane match appstore
```

---

## Web Configuration

### 1. Enable Web Support

```bash
flutter config --enable-web
```

### 2. Build for Web

```bash
flutter build web --release --web-renderer canvaskit
```

### 3. Deploy Options

**Firebase Hosting:**
```bash
firebase init hosting
firebase deploy
```

**GitHub Pages:**
Configure in workflow to deploy to `gh-pages` branch.

**Netlify/Vercel:**
Connect repository and set build command to `flutter build web`.

---

## Testing Setup

### Unit Tests

```bash
# Run tests
flutter test

# With coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
```

### Integration Tests

Create `integration_test/app_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app test', (tester) async {
    // Your test code
  });
}
```

Run integration tests:

```bash
flutter test integration_test
```

### Golden Tests

For screenshot testing:

```dart
testWidgets('golden test', (tester) async {
  await tester.pumpWidget(MyWidget());
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});
```

---

## Deployment

### Android Deployment

**To Google Play (Internal):**
```bash
flutter build appbundle
./scripts/deploy.sh --target android --track internal
```

**To Firebase:**
```bash
flutter build apk
./scripts/deploy.sh --target android-firebase
```

### iOS Deployment

**To TestFlight:**
```bash
flutter build ios
./scripts/deploy.sh --target ios
```

### Web Deployment

**To Firebase:**
```bash
flutter build web
firebase deploy --only hosting
```

### Automated Releases

Push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## Best Practices

### 1. Version Management

```bash
# Update version in pubspec.yaml
./scripts/version-bump.sh --minor

# Or manually
# version: 1.1.0+42
```

### 2. Build Optimization

```yaml
# pubspec.yaml
flutter:
  # Remove unused assets
  assets:
    - assets/images/
  
  # Font subsetting
  fonts:
    - family: CustomFont
      fonts:
        - asset: fonts/CustomFont.ttf
```

### 3. Code Splitting

For web, use deferred loading:

```dart
import 'package:your_app/heavy_feature.dart' deferred as heavy;

// Later...
await heavy.loadLibrary();
```

---

## Troubleshooting

### Common Issues

**1. Build Runner Conflicts**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**2. iOS Pod Issues**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

**3. Android Gradle Issues**
```bash
cd android
./gradlew clean
./gradlew --refresh-dependencies
```

**4. Web Build Failures**
```bash
flutter clean
flutter pub get
flutter build web --release
```

---

## Related Guides

- [Getting Started](./getting-started.md)
- [Code Signing](./code-signing.md)
- [Best Practices](./best-practices.md)
