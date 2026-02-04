<p align="center">
  <img src="Assets/logo.png" alt="MobileCI" width="200"/>
</p>

<h1 align="center">MobileCI</h1>

<p align="center">
  <strong>🚀 Ready-to-use CI/CD templates for iOS, Flutter & React Native</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platforms-iOS%20|%20Flutter%20|%20RN-blue.svg" alt="Platforms"/>
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"/>
</p>

---

## Why MobileCI?

Setting up CI/CD for mobile apps is complex - code signing, provisioning profiles, build variants, store deployment. **MobileCI** provides battle-tested workflows you can copy and customize.

## Templates

### iOS / Swift

```yaml
# .github/workflows/ios.yml
name: iOS CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '16.0'
      
      - name: Install dependencies
        run: |
          brew install swiftlint
          swift package resolve
      
      - name: Lint
        run: swiftlint --strict
      
      - name: Build
        run: |
          xcodebuild build \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -configuration Debug
      
      - name: Test
        run: |
          xcodebuild test \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -resultBundlePath TestResults.xcresult
      
      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: TestResults.xcresult
```

### iOS Release with Fastlane

```yaml
# .github/workflows/ios-release.yml
name: iOS Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      
      - name: Install Fastlane
        run: bundle install
      
      - name: Decode certificates
        env:
          CERTIFICATES_P12: ${{ secrets.CERTIFICATES_P12 }}
          CERTIFICATES_PASSWORD: ${{ secrets.CERTIFICATES_PASSWORD }}
        run: |
          echo $CERTIFICATES_P12 | base64 --decode > certificates.p12
          security import certificates.p12 -P $CERTIFICATES_PASSWORD
      
      - name: Build & Upload
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_API_KEY }}
        run: bundle exec fastlane release
```

### Flutter

```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true
      
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      
      - uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info

  build-android:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - run: flutter build apk --release
      
      - uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    runs-on: macos-14
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - run: flutter build ios --release --no-codesign
```

### React Native (EAS Build)

```yaml
# .github/workflows/rn.yml
name: React Native CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm test -- --coverage

  build:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - uses: expo/expo-github-action@v8
        with:
          expo-version: latest
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}
      
      - run: npm ci
      - run: eas build --platform all --non-interactive
```

## Fastlane Templates

### iOS Fastfile

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(
      scheme: "MyApp",
      devices: ["iPhone 16"]
    )
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "MyApp")
    upload_to_testflight
  end

  desc "Release to App Store"
  lane :release do
    build_app(scheme: "MyApp")
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: true
    )
  end
end
```

### Flutter Fastfile

```ruby
# fastlane/Fastfile
default_platform(:android)

platform :android do
  lane :deploy do
    sh "flutter build appbundle --release"
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end
end

platform :ios do
  lane :deploy do
    sh "flutter build ipa --release"
    upload_to_testflight(
      ipa: '../build/ios/ipa/MyApp.ipa'
    )
  end
end
```

## Secrets Setup

### Required Secrets

| Platform | Secret | Description |
|----------|--------|-------------|
| iOS | `CERTIFICATES_P12` | Base64 encoded p12 |
| iOS | `CERTIFICATES_PASSWORD` | P12 password |
| iOS | `ASC_API_KEY` | App Store Connect API key |
| Android | `KEYSTORE_BASE64` | Base64 encoded keystore |
| Android | `KEYSTORE_PASSWORD` | Keystore password |
| Android | `PLAY_STORE_JSON` | Service account JSON |
| Expo | `EXPO_TOKEN` | Expo access token |

### Encoding Secrets

```bash
# Encode certificate
base64 -i Certificates.p12 | pbcopy

# Encode keystore
base64 -i keystore.jks | pbcopy
```

## Usage

1. Copy the appropriate template to your repo's `.github/workflows/`
2. Add required secrets in GitHub repo settings
3. Customize paths, scheme names, etc.
4. Push and watch it build! 🚀

## Best Practices

### Caching

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: gradle-${{ hashFiles('**/*.gradle*') }}
```

### Conditional Builds

```yaml
# Only deploy on main branch
if: github.ref == 'refs/heads/main'

# Only on version tags
if: startsWith(github.ref, 'refs/tags/v')
```

### Matrix Testing

```yaml
strategy:
  matrix:
    os: [macos-14, macos-13]
    xcode: ['16.0', '15.4']
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License

---

## 📈 Star History

<a href="https://star-history.com/#muhittincamdali/MobileCI&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/MobileCI&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muhittincamdali/MobileCI&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muhittincamdali/MobileCI&type=Date" />
 </picture>
</a>
