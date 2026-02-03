# Troubleshooting Guide

Common issues and solutions for mobile CI/CD pipelines.

## Table of Contents

- [General Issues](#general-issues)
- [iOS Issues](#ios-issues)
- [Android Issues](#android-issues)
- [Flutter Issues](#flutter-issues)
- [React Native Issues](#react-native-issues)
- [GitHub Actions Issues](#github-actions-issues)
- [Getting Help](#getting-help)

---

## General Issues

### Build Times Are Too Long

**Symptoms:** Builds take 30+ minutes

**Solutions:**

1. **Enable caching**
   ```yaml
   - uses: actions/cache@v4
     with:
       path: |
         ~/.gradle/caches
         ~/Library/Caches/CocoaPods
       key: ${{ runner.os }}-deps-${{ hashFiles('**/lockfile') }}
   ```

2. **Use incremental builds**
   - Don't clean build every time
   - Only clean when dependencies change

3. **Parallelize tests**
   ```yaml
   strategy:
     matrix:
       shard: [1, 2, 3, 4]
   ```

4. **Use faster runners**
   - GitHub larger runners
   - Self-hosted runners

### Out of Disk Space

**Symptoms:** Build fails with "No space left on device"

**Solutions:**

```bash
# Clean before build
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/.gradle/caches

# In workflow
- name: Free disk space
  run: |
    sudo rm -rf /usr/local/lib/android
    sudo rm -rf /usr/share/dotnet
    df -h
```

### Secret Not Available

**Symptoms:** `Error: Input required and not supplied`

**Solutions:**

1. Verify secret exists in repository settings
2. Check secret name spelling (case-sensitive)
3. For forks, secrets aren't available from PRs
4. Check workflow permissions

---

## iOS Issues

### Code Signing Failed

**Error:** `Code Sign error: No signing certificate`

**Solutions:**

```bash
# Check certificates
security find-identity -v -p codesigning

# Regenerate with Match
bundle exec fastlane match appstore --force

# For CI, ensure keychain is unlocked
security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
```

### Profile Doesn't Include Device

**Error:** `Provisioning profile doesn't include device`

**Solutions:**

```bash
# Register device
bundle exec fastlane register_device

# Force new profiles
bundle exec fastlane match development --force_for_new_devices
```

### Xcode Version Mismatch

**Error:** `Project requires Xcode 15`

**Solution:**

```yaml
- name: Select Xcode version
  run: sudo xcode-select -s /Applications/Xcode_15.2.app
```

### CocoaPods Issues

**Error:** `Unable to find a specification for`

**Solutions:**

```bash
# Update repo
pod repo update

# Clean install
rm -rf Pods Podfile.lock
pod install --repo-update

# For CI
pod install --repo-update || pod install --repo-update
```

### Archive Failed

**Error:** `xcodebuild: error: Archive failed`

**Solutions:**

1. Check scheme is shared
2. Verify build settings
3. Clean derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### TestFlight Upload Failed

**Error:** `ERROR ITMS-90062`

**Solutions:**

1. Increment build number
2. Check version format (must be x.y.z)
3. Verify API key permissions

---

## Android Issues

### Gradle Build Failed

**Error:** `Could not determine java version`

**Solution:**

```yaml
- uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '17'
```

### Keystore Issues

**Error:** `Keystore was tampered with`

**Solutions:**

1. Verify password is correct
2. Re-encode base64 without newlines:
   ```bash
   base64 -w 0 release.jks > keystore.b64
   ```

### SDK Not Found

**Error:** `SDK location not found`

**Solution:**

```bash
# Create local.properties
echo "sdk.dir=$ANDROID_HOME" > android/local.properties
```

### APK Signing Failed

**Error:** `Unsigned APK`

**Solutions:**

1. Check signingConfig in build.gradle
2. Verify keystore.properties exists
3. Check key alias matches

### Play Store Upload Failed

**Error:** `403 Forbidden`

**Solutions:**

1. Verify service account has permissions
2. Check API is enabled in Google Cloud
3. Ensure app exists in Play Console

---

## Flutter Issues

### Build Runner Conflicts

**Error:** `Conflicting outputs`

**Solution:**

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Pod Install Failed

**Error:** `CocoaPods could not find compatible versions`

**Solutions:**

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### Dart Analyzer Errors

**Error:** `Analysis failed`

**Solutions:**

1. Run `flutter analyze` locally
2. Fix all errors before pushing
3. Check `analysis_options.yaml`

### Web Build Failed

**Error:** `Target of URI doesn't exist`

**Solutions:**

```bash
flutter clean
flutter pub get
flutter build web
```

### iOS Build Archive Failed

**Error:** `No Provisioning Profile`

**Solutions:**

1. Run `flutter clean`
2. Delete `ios/Pods` and `ios/Podfile.lock`
3. Run `cd ios && pod install`
4. Ensure signing is configured

---

## React Native Issues

### Metro Bundler Errors

**Error:** `Unable to resolve module`

**Solutions:**

```bash
# Clear cache
watchman watch-del-all
rm -rf node_modules
yarn install
yarn start --reset-cache
```

### iOS Build Failed

**Error:** `The following build commands failed`

**Solutions:**

```bash
cd ios
rm -rf Pods Podfile.lock build
pod install
cd ..
npx react-native run-ios
```

### Android Build Failed

**Error:** `Execution failed for task ':app:mergeReleaseResources'`

**Solutions:**

```bash
cd android
./gradlew clean
./gradlew --refresh-dependencies
cd ..
npx react-native run-android
```

### Detox Tests Failing

**Error:** `Device not found`

**Solutions:**

```bash
# iOS
xcrun simctl list devices

# Create simulator
xcrun simctl create "iPhone 15 Pro" "iPhone 15 Pro"

# Android
$ANDROID_HOME/emulator/emulator -list-avds
```

### Hermes Issues

**Error:** `TypeError: undefined is not a function`

**Solutions:**

```bash
cd android && ./gradlew clean
cd ios && pod install
```

---

## GitHub Actions Issues

### Workflow Not Triggered

**Symptoms:** Push doesn't trigger workflow

**Solutions:**

1. Check branch/path filters match
2. Verify workflow file syntax (lint YAML)
3. Check Actions is enabled for repo
4. Verify file is in `.github/workflows/`

### Cache Not Working

**Symptoms:** Cache miss every time

**Solutions:**

1. Check cache key includes relevant files
2. Verify paths exist
3. Cache size limit is 10GB per repo

### Timeout Errors

**Error:** `The operation was canceled`

**Solutions:**

```yaml
jobs:
  build:
    timeout-minutes: 60  # Increase timeout
```

### Concurrency Issues

**Error:** Jobs cancelled unexpectedly

**Solution:**

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # or false
```

### Self-Hosted Runner Issues

**Error:** `No runner matching the specified labels`

**Solutions:**

1. Check runner is online
2. Verify labels match
3. Check runner has required software

---

## Getting Help

### Before Asking

1. **Search existing issues** on GitHub
2. **Check logs** thoroughly
3. **Reproduce locally** if possible
4. **Update dependencies** to latest

### Useful Commands

```bash
# iOS
xcodebuild -version
xcrun simctl list devices
security find-identity -v

# Android
java -version
./gradlew --version
adb devices

# Flutter
flutter doctor -v
flutter analyze

# React Native
npx react-native info
```

### Reporting Issues

Include:
- Full error message
- Workflow file (redact secrets)
- Steps to reproduce
- Environment info (OS, tool versions)
- Any recent changes

### Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Fastlane Docs](https://docs.fastlane.tools)
- [Flutter Docs](https://docs.flutter.dev)
- [React Native Docs](https://reactnative.dev/docs)
