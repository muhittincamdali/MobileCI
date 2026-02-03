# Code Signing Guide

Comprehensive guide for managing code signing certificates and provisioning profiles for mobile applications.

## Table of Contents

- [Overview](#overview)
- [iOS Code Signing](#ios-code-signing)
- [Android Code Signing](#android-code-signing)
- [CI/CD Integration](#cicd-integration)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

Code signing is a security mechanism that ensures:

1. **Authenticity** - The app comes from a known developer
2. **Integrity** - The code hasn't been modified
3. **Trust** - Users and app stores can verify the source

### Platform Requirements

| Platform | Required For | Certificate Type |
|----------|--------------|------------------|
| iOS | All distribution | Distribution Certificate + Provisioning Profile |
| Android | Play Store | Keystore with release key |
| macOS | App Store & Notarization | Developer ID Certificate |

---

## iOS Code Signing

### Certificate Types

| Type | Purpose | Validity |
|------|---------|----------|
| Development | Testing on devices | 1 year |
| Distribution | App Store & Ad Hoc | 1 year |
| Push Services | Push notifications | 1 year |
| Enterprise | In-house distribution | 3 years |

### Provisioning Profile Types

| Type | Purpose | Device Limit |
|------|---------|--------------|
| Development | Development testing | 100 |
| Ad Hoc | Beta testing | 100 |
| App Store | App Store distribution | Unlimited |
| Enterprise | Internal distribution | Unlimited |

### Using Match (Recommended)

Match synchronizes certificates and profiles across a team using a Git repository.

#### 1. Setup Certificates Repository

```bash
# Create private repository
# github.com/yourcompany/ios-certificates

# Initialize Match
cd your-ios-project
bundle exec fastlane match init
```

#### 2. Configure Matchfile

```ruby
# fastlane/Matchfile

git_url("git@github.com:yourcompany/ios-certificates.git")
storage_mode("git")
type("appstore")

app_identifier([
  "com.yourcompany.app",
  "com.yourcompany.app.widget"
])

team_id(ENV["TEAM_ID"])
username(ENV["APPLE_ID"])

# For CI/CD
readonly(is_ci)
```

#### 3. Generate Certificates

```bash
# Development
bundle exec fastlane match development

# App Store
bundle exec fastlane match appstore

# Ad Hoc (for Firebase/TestFlight external)
bundle exec fastlane match adhoc
```

#### 4. Add New Devices

```bash
# Register device
bundle exec fastlane match development --force_for_new_devices

# Or use devices file
echo "DEVICE_UDID	Device Name" > devices.txt
bundle exec fastlane register_devices
bundle exec fastlane match development --force_for_new_devices
```

### Manual Certificate Management

If not using Match:

#### Export Certificate

```bash
# From Keychain Access
# 1. Find certificate
# 2. Right-click > Export
# 3. Save as .p12 with password
```

#### Import in CI

```bash
# Decode certificate
echo "$CERTIFICATE_BASE64" | base64 --decode > certificate.p12

# Create keychain
security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
security default-keychain -s build.keychain
security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain

# Import certificate
security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" build.keychain
```

---

## Android Code Signing

### Create Keystore

```bash
# Generate new keystore
keytool -genkey -v \
  -keystore release-keystore.jks \
  -alias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "your_store_password" \
  -keypass "your_key_password" \
  -dname "CN=Your Name, OU=Your Unit, O=Your Company, L=City, ST=State, C=US"
```

### Configure Gradle

```groovy
// android/app/build.gradle

def keystorePropertiesFile = rootProject.file("keystore.properties")
def keystoreProperties = new Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
        release {
            if (keystoreProperties['storeFile']) {
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
            }
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Keystore Properties File

```properties
# keystore.properties (don't commit!)
storeFile=release-keystore.jks
storePassword=your_store_password
keyAlias=release
keyPassword=your_key_password
```

### Google Play App Signing

Google Play App Signing manages your app's signing key:

1. Generate upload key (you keep this)
2. Google manages the app signing key
3. Benefits: Key recovery, key upgrade, optimized APKs

```bash
# Generate upload key
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

---

## CI/CD Integration

### GitHub Actions

#### iOS Signing

```yaml
- name: Setup code signing
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
  run: |
    # Create keychain
    KEYCHAIN_PATH=$RUNNER_TEMP/signing.keychain-db
    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
    
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain
    
    # Run match
    bundle exec fastlane match appstore \
      --readonly true \
      --keychain_name "$KEYCHAIN_PATH" \
      --keychain_password "$KEYCHAIN_PASSWORD"
```

#### Android Signing

```yaml
- name: Setup Android signing
  env:
    KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
    KEYSTORE_PROPERTIES: ${{ secrets.ANDROID_KEYSTORE_PROPERTIES }}
  run: |
    # Decode keystore
    echo "$KEYSTORE_BASE64" | base64 --decode > android/app/release-keystore.jks
    
    # Create properties file
    echo "$KEYSTORE_PROPERTIES" > android/keystore.properties
```

### Secrets Configuration

Store these as GitHub Secrets:

```
# iOS
MATCH_PASSWORD        - Encryption password for Match
MATCH_GIT_URL         - git@github.com:org/certs.git
MATCH_GIT_TOKEN       - PAT with repo access

# Android
ANDROID_KEYSTORE_BASE64    - base64 encoded keystore
ANDROID_KEYSTORE_PROPERTIES - keystore.properties content
```

---

## Security Best Practices

### General

1. **Never commit secrets to Git**
   - Use `.gitignore` for keystores
   - Use environment variables
   - Use secret management tools

2. **Use strong passwords**
   - Minimum 16 characters
   - Mix of letters, numbers, symbols
   - Unique per certificate

3. **Limit access**
   - Only team leads should have production keys
   - Use read-only mode in CI
   - Audit access regularly

### iOS Specific

1. **Use Match**
   - Centralized certificate management
   - Encrypted storage
   - Automatic provisioning

2. **Rotate certificates before expiry**
   - Set calendar reminders
   - Automate renewal when possible

3. **Use App Store Connect API Keys**
   - More secure than Apple ID
   - Revocable
   - No 2FA issues in CI

### Android Specific

1. **Enable Google Play App Signing**
   - Google manages app signing key
   - You only need upload key
   - Key loss recovery possible

2. **Backup keystores securely**
   - Encrypted cloud storage
   - Multiple secure locations
   - Document passwords separately

3. **Use different keys per environment**
   - Debug keystore for development
   - Upload key for production

---

## Troubleshooting

### iOS Issues

#### "No signing certificate found"

```bash
# Check installed certificates
security find-identity -v -p codesigning

# Regenerate with Match
bundle exec fastlane match appstore --force
```

#### "Provisioning profile doesn't match"

```bash
# Clear provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Re-download
bundle exec fastlane match appstore
```

#### "Keychain is locked"

```bash
# Unlock keychain
security unlock-keychain -p "$PASSWORD" login.keychain
security set-keychain-settings -t 3600 -l ~/Library/Keychains/login.keychain
```

### Android Issues

#### "Keystore was tampered with"

- Wrong password
- Corrupted keystore file
- Solution: Regenerate or restore from backup

#### "Key not found"

- Wrong alias name
- Check with: `keytool -list -keystore release.jks`

#### "Cannot recover key"

- Wrong key password (different from store password)
- Verify both passwords

### CI Issues

#### "Match timeout"

```yaml
env:
  MATCH_GIT_FULL_CLONE: 1
  FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT: 180
```

#### "Keychain not found"

```bash
# List keychains
security list-keychains

# Add to search list
security list-keychains -d user -s "$KEYCHAIN_PATH" login.keychain
```

---

## Related Guides

- [iOS Setup](./ios-setup.md)
- [Flutter Setup](./flutter-setup.md)
- [React Native Setup](./react-native-setup.md)
