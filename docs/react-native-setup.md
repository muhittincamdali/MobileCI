# React Native Setup Guide

Complete guide for setting up React Native CI/CD with MobileCI.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [GitHub Actions Configuration](#github-actions-configuration)
- [iOS Configuration](#ios-configuration)
- [Android Configuration](#android-configuration)
- [Testing Setup](#testing-setup)
- [EAS Build (Expo)](#eas-build-expo)
- [Deployment](#deployment)

---

## Prerequisites

### Development Environment

```bash
# Node.js 18+ (use nvm)
nvm install 20
nvm use 20

# Yarn (recommended)
npm install -g yarn

# React Native CLI
npm install -g react-native-cli

# Watchman (macOS)
brew install watchman
```

### Platform-Specific

**iOS:**
- macOS with Xcode 15+
- CocoaPods
- Ruby 3.0+

**Android:**
- Java JDK 17
- Android Studio
- Android SDK

---

## Project Setup

### 1. Copy MobileCI Templates

```bash
cd your-react-native-project

# Copy workflows
mkdir -p .github/workflows
cp MobileCI/react-native/workflows/*.yml .github/workflows/

# Copy scripts
mkdir -p scripts
cp MobileCI/react-native/scripts/*.sh scripts/
chmod +x scripts/*.sh

# Copy shared templates
cp MobileCI/shared/templates/CODEOWNERS .github/
cp MobileCI/shared/templates/pr-template.md .github/pull_request_template.md
```

### 2. Install Dependencies

```bash
# Install npm packages
yarn install

# iOS: Install pods
cd ios
bundle install
bundle exec pod install
cd ..
```

### 3. Configure ESLint

Ensure `.eslintrc.js` exists:

```javascript
module.exports = {
  root: true,
  extends: '@react-native',
  rules: {
    'react-native/no-inline-styles': 'warn',
    'react-hooks/exhaustive-deps': 'warn',
  },
};
```

### 4. Configure TypeScript

Ensure `tsconfig.json` is properly configured:

```json
{
  "compilerOptions": {
    "target": "esnext",
    "module": "commonjs",
    "lib": ["es2017"],
    "jsx": "react-native",
    "strict": true,
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

---

## GitHub Actions Configuration

### Required Secrets

#### iOS Secrets
| Secret | Description |
|--------|-------------|
| `TEAM_ID` | Apple Developer Team ID |
| `MATCH_PASSWORD` | Match encryption password |
| `MATCH_GIT_URL` | Certificates repo URL |
| `MATCH_GIT_TOKEN` | PAT for certificates repo |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64 API key |

#### Android Secrets
| Secret | Description |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 keystore |
| `ANDROID_KEYSTORE_PROPERTIES` | Keystore properties |
| `GOOGLE_PLAY_JSON_KEY` | Service account JSON |
| `ANDROID_PACKAGE_NAME` | Package name |

#### Optional
| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK_URL` | Slack notifications |
| `CODECOV_TOKEN` | Code coverage upload |
| `FIREBASE_APP_ID_*` | Firebase distribution |

---

## iOS Configuration

### 1. Fastlane Setup

Create `ios/Gemfile`:

```ruby
source "https://rubygems.org"

gem "fastlane"
gem "cocoapods"
```

Create `ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and deploy to TestFlight"
  lane :beta do
    match(type: "appstore", readonly: true)
    
    increment_build_number(
      build_number: ENV['BUILD_NUMBER'] || latest_testflight_build_number + 1
    )
    
    build_app(
      workspace: "App.xcworkspace",
      scheme: "App",
      configuration: "Release"
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end
```

### 2. Match Setup

Create `ios/fastlane/Matchfile`:

```ruby
git_url(ENV['MATCH_GIT_URL'])
storage_mode('git')
type('appstore')
app_identifier(ENV['APP_IDENTIFIER'] || 'com.yourcompany.app')
team_id(ENV['TEAM_ID'])
```

### 3. Initialize Certificates

```bash
cd ios
bundle exec fastlane match development
bundle exec fastlane match appstore
```

---

## Android Configuration

### 1. Create Signing Key

```bash
# Generate keystore
keytool -genkey -v \
  -keystore android/app/release-keystore.jks \
  -alias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### 2. Configure Signing

Create `android/keystore.properties`:

```properties
storeFile=release-keystore.jks
storePassword=your_password
keyAlias=release
keyPassword=your_password
```

Update `android/app/build.gradle`:

```groovy
def keystorePropertiesFile = rootProject.file("keystore.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            storeFile file(keystoreProperties['storeFile'] ?: 'debug.keystore')
            storePassword keystoreProperties['storePassword'] ?: ''
            keyAlias keystoreProperties['keyAlias'] ?: ''
            keyPassword keystoreProperties['keyPassword'] ?: ''
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

---

## Testing Setup

### Unit Tests with Jest

```bash
# Run tests
yarn test

# With coverage
yarn test --coverage

# Watch mode
yarn test --watch
```

Configure `jest.config.js`:

```javascript
module.exports = {
  preset: 'react-native',
  setupFilesAfterEnv: ['@testing-library/jest-native/extend-expect'],
  transformIgnorePatterns: [
    'node_modules/(?!(react-native|@react-native|@react-navigation)/)',
  ],
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
};
```

### E2E Tests with Detox

Install Detox:

```bash
yarn add -D detox @types/detox
brew tap wix/brew
brew install applesimutils
```

Configure `.detoxrc.js`:

```javascript
module.exports = {
  testRunner: {
    args: {
      $0: 'jest',
      config: 'e2e/jest.config.js',
    },
    jest: {
      setupTimeout: 120000,
    },
  },
  apps: {
    'ios.debug': {
      type: 'ios.app',
      binaryPath: 'ios/build/Build/Products/Debug-iphonesimulator/App.app',
      build: 'xcodebuild -workspace ios/App.xcworkspace -scheme App -configuration Debug -sdk iphonesimulator -derivedDataPath ios/build',
    },
    'android.debug': {
      type: 'android.apk',
      binaryPath: 'android/app/build/outputs/apk/debug/app-debug.apk',
      build: 'cd android && ./gradlew assembleDebug',
    },
  },
  devices: {
    simulator: {
      type: 'ios.simulator',
      device: {
        type: 'iPhone 15 Pro',
      },
    },
    emulator: {
      type: 'android.emulator',
      device: {
        avdName: 'Pixel_4_API_33',
      },
    },
  },
  configurations: {
    'ios.sim.debug': {
      device: 'simulator',
      app: 'ios.debug',
    },
    'android.emu.debug': {
      device: 'emulator',
      app: 'android.debug',
    },
  },
};
```

Run E2E tests:

```bash
# Build
detox build --configuration ios.sim.debug

# Test
detox test --configuration ios.sim.debug
```

---

## EAS Build (Expo)

If using Expo, configure EAS Build:

### 1. Install EAS CLI

```bash
npm install -g eas-cli
eas login
```

### 2. Configure eas.json

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {}
  },
  "submit": {
    "production": {}
  }
}
```

### 3. Build with EAS

```bash
# Development build
eas build --platform all --profile development

# Production build
eas build --platform all --profile production
```

---

## Deployment

### TestFlight

```bash
cd ios
bundle exec fastlane beta
```

### Google Play

```bash
cd android
./gradlew bundleRelease
bundle exec fastlane supply --aab app/build/outputs/bundle/release/app-release.aab --track internal
```

### Firebase App Distribution

```bash
# iOS
firebase appdistribution:distribute ios/build/App.ipa --app YOUR_APP_ID --groups "testers"

# Android
firebase appdistribution:distribute android/app/build/outputs/apk/release/app-release.apk --app YOUR_APP_ID --groups "testers"
```

---

## Troubleshooting

### Common Issues

**1. Metro Bundler Issues**
```bash
# Clear cache
yarn start --reset-cache

# Clean everything
watchman watch-del-all
rm -rf node_modules
yarn install
```

**2. iOS Build Failures**
```bash
cd ios
rm -rf Pods Podfile.lock
bundle exec pod install --repo-update
```

**3. Android Build Failures**
```bash
cd android
./gradlew clean
./gradlew --refresh-dependencies
```

**4. Detox Issues**
```bash
detox clean-framework-cache
detox build-framework-cache
```

---

## Related Guides

- [Getting Started](./getting-started.md)
- [Code Signing](./code-signing.md)
- [Troubleshooting](./troubleshooting.md)
