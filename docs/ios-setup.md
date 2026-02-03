# iOS Setup Guide

Complete guide for setting up iOS CI/CD with MobileCI.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [Fastlane Configuration](#fastlane-configuration)
- [Code Signing with Match](#code-signing-with-match)
- [GitHub Actions Setup](#github-actions-setup)
- [TestFlight Deployment](#testflight-deployment)
- [App Store Release](#app-store-release)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Development Machine

```bash
# Check Xcode version
xcodebuild -version
# Required: Xcode 15.0+

# Check Ruby version
ruby -v
# Required: Ruby 3.0+

# Install Bundler
gem install bundler

# Install CocoaPods
gem install cocoapods
```

### Apple Developer Account

1. [Apple Developer Account](https://developer.apple.com) (paid membership)
2. App registered in App Store Connect
3. API Key created for App Store Connect

### GitHub Repository

1. Private repository for certificates (for Match)
2. Secrets configured in your main repository

---

## Project Setup

### 1. Initialize Fastlane

```bash
cd your-ios-project
fastlane init
```

### 2. Copy MobileCI Templates

```bash
# Copy Fastlane files
cp MobileCI/ios/fastlane/Fastfile fastlane/
cp MobileCI/ios/fastlane/Appfile fastlane/
cp MobileCI/ios/fastlane/Matchfile fastlane/
cp MobileCI/ios/fastlane/Pluginfile fastlane/

# Copy workflows
mkdir -p .github/workflows
cp MobileCI/ios/workflows/*.yml .github/workflows/

# Copy scripts
mkdir -p scripts
cp MobileCI/ios/scripts/*.sh scripts/
chmod +x scripts/*.sh
```

### 3. Install Dependencies

```bash
# Create Gemfile if not exists
cat > Gemfile << 'EOF'
source "https://rubygems.org"

gem "fastlane"
gem "cocoapods"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
EOF

# Install gems
bundle install
```

---

## Fastlane Configuration

### Appfile

Edit `fastlane/Appfile`:

```ruby
app_identifier(ENV['APP_IDENTIFIER'] || 'com.yourcompany.app')
apple_id(ENV['APPLE_ID'] || 'developer@yourcompany.com')
team_id(ENV['TEAM_ID'] || 'XXXXXXXXXX')
itc_team_id(ENV['ITC_TEAM_ID'] || ENV['TEAM_ID'])
```

### Matchfile

Edit `fastlane/Matchfile`:

```ruby
git_url(ENV['MATCH_GIT_URL'] || 'git@github.com:yourcompany/certificates.git')
storage_mode('git')
type('appstore')
app_identifier([
  'com.yourcompany.app',
  'com.yourcompany.app.widget'  # Add extensions
])
team_id(ENV['TEAM_ID'])
```

### Fastfile Customization

Key lanes to customize in `fastlane/Fastfile`:

```ruby
# Update these constants
WORKSPACE = 'YourApp.xcworkspace'
PROJECT = 'YourApp.xcodeproj'
SCHEME = 'YourApp'
BUNDLE_ID = 'com.yourcompany.app'
```

---

## Code Signing with Match

### 1. Create Certificates Repository

```bash
# Create a new private repository for certificates
# Example: github.com/yourcompany/ios-certificates
```

### 2. Initialize Match

```bash
bundle exec fastlane match init
```

### 3. Generate Certificates

```bash
# Development certificates
bundle exec fastlane match development

# App Store certificates
bundle exec fastlane match appstore

# Ad-hoc certificates (for testing)
bundle exec fastlane match adhoc
```

### 4. Add New Devices

```bash
# Create devices.txt
echo "Device ID	Device Name" > devices.txt
echo "00000000-0000000000000000	John's iPhone" >> devices.txt

# Register devices
bundle exec fastlane match development --force_for_new_devices
```

---

## GitHub Actions Setup

### Required Secrets

Add these secrets in GitHub (Settings > Secrets > Actions):

| Secret | Description | How to Get |
|--------|-------------|------------|
| `TEAM_ID` | Apple Developer Team ID | [Developer Portal](https://developer.apple.com/account/#/membership) |
| `MATCH_PASSWORD` | Encryption password for Match | Create a strong password |
| `MATCH_GIT_URL` | URL to certificates repo | `git@github.com:org/certs.git` |
| `MATCH_GIT_TOKEN` | Token for certificates repo | Create a PAT with repo access |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | [App Store Connect](https://appstoreconnect.apple.com/access/api) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | [App Store Connect](https://appstoreconnect.apple.com/access/api) |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64 API Key | `base64 -i AuthKey_XXXX.p8` |

### Creating App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/access/api)
2. Click "+" to create a new key
3. Give it a name and Admin access
4. Download the `.p8` file (only available once!)
5. Note the Key ID and Issuer ID
6. Base64 encode the key:
   ```bash
   base64 -i AuthKey_XXXXXX.p8 | pbcopy
   ```

---

## TestFlight Deployment

### Automatic Deployment

Push to `develop` branch triggers TestFlight deployment:

```bash
git checkout develop
git push origin develop
```

### Manual Deployment

```bash
# Using Fastlane
bundle exec fastlane beta

# Or trigger GitHub Action
gh workflow run ios-beta.yml
```

### TestFlight Groups

Configure groups in `fastlane/Fastfile`:

```ruby
lane :beta do
  upload_to_testflight(
    groups: ['Internal Testers', 'QA Team'],
    distribute_external: false
  )
end
```

---

## App Store Release

### Automatic Release

Create a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Manual Release

```bash
# Using Fastlane
bundle exec fastlane release version:1.0.0

# Or trigger GitHub Action
gh workflow run ios-release.yml -f version=1.0.0
```

### Release Checklist

- [ ] All tests passing
- [ ] Version number updated
- [ ] Screenshots updated (if needed)
- [ ] Release notes prepared
- [ ] Privacy policy URL valid
- [ ] App Store metadata current

---

## Troubleshooting

### Common Issues

#### 1. Code Signing Errors

**Error:** `No signing certificate "iOS Distribution" found`

**Solution:**
```bash
# Regenerate certificates
bundle exec fastlane match appstore --force

# Clear Xcode cache
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### 2. Match Git Authentication

**Error:** `Authentication failed for certificates repo`

**Solution:**
```bash
# Use SSH URL
git_url("git@github.com:org/certs.git")

# Or set token
export MATCH_GIT_BASIC_AUTHORIZATION=$(echo -n "user:token" | base64)
```

#### 3. API Key Issues

**Error:** `Invalid API key`

**Solution:**
- Verify base64 encoding is correct
- Check key hasn't expired
- Ensure key has Admin access

#### 4. Build Number Conflicts

**Error:** `Build already exists`

**Solution:**
```bash
# Use latest TestFlight build number
bundle exec fastlane run latest_testflight_build_number
# Increment in your Fastfile
```

### Debug Mode

Enable verbose logging:

```bash
# Fastlane
bundle exec fastlane beta --verbose

# Match
bundle exec fastlane match appstore --verbose
```

### Getting Help

1. Check [Fastlane Docs](https://docs.fastlane.tools)
2. Search [Fastlane Issues](https://github.com/fastlane/fastlane/issues)
3. Ask in [Fastlane Forum](https://github.com/fastlane/fastlane/discussions)

---

## Related Guides

- [Code Signing Deep Dive](./code-signing.md)
- [Best Practices](./best-practices.md)
- [Troubleshooting](./troubleshooting.md)
