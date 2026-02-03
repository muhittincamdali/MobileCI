#!/bin/bash

# Flutter Deployment Script
# Deploy Flutter apps to various platforms
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Deployment target
TARGET="${DEPLOY_TARGET:-android}"
TRACK="${RELEASE_TRACK:-internal}"
ENVIRONMENT="${ENVIRONMENT:-staging}"

# Build settings
BUILD_NUMBER="${BUILD_NUMBER:-}"
VERSION="${VERSION:-}"
OBFUSCATE=true
SPLIT_DEBUG_INFO=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

get_version() {
    if [[ -n "$VERSION" ]]; then
        echo "$VERSION"
    else
        grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1
    fi
}

get_build_number() {
    if [[ -n "$BUILD_NUMBER" ]]; then
        echo "$BUILD_NUMBER"
    else
        echo "$(($(date +%s) / 60))"
    fi
}

# ==============================================================================
# Build Android
# ==============================================================================

build_android() {
    log_info "Building Android app..."
    
    cd "$PROJECT_ROOT"
    
    local version
    version=$(get_version)
    local build_number
    build_number=$(get_build_number)
    
    log_info "Version: $version+$build_number"
    
    # Build arguments
    local build_args=(
        "build" "appbundle"
        "--release"
        "--build-name=$version"
        "--build-number=$build_number"
    )
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        build_args+=("--obfuscate")
    fi
    
    if [[ "$SPLIT_DEBUG_INFO" == "true" ]]; then
        mkdir -p build/debug-info
        build_args+=("--split-debug-info=build/debug-info")
    fi
    
    flutter "${build_args[@]}"
    
    log_success "Android build complete"
}

# ==============================================================================
# Deploy to Google Play
# ==============================================================================

deploy_google_play() {
    log_info "Deploying to Google Play ($TRACK)..."
    
    local aab_file
    aab_file=$(find "$PROJECT_ROOT/build/app/outputs/bundle/release" -name "*.aab" | head -1)
    
    if [[ -z "$aab_file" ]]; then
        log_error "AAB file not found. Build first."
    fi
    
    if [[ -z "${GOOGLE_PLAY_JSON_KEY:-}" ]]; then
        log_error "GOOGLE_PLAY_JSON_KEY not set"
    fi
    
    # Create key file
    local key_file="/tmp/google-play-key.json"
    echo "$GOOGLE_PLAY_JSON_KEY" > "$key_file"
    
    # Check for fastlane
    if ! command -v fastlane &> /dev/null; then
        log_info "Installing fastlane..."
        gem install fastlane
    fi
    
    # Deploy with fastlane supply
    fastlane supply \
        --aab "$aab_file" \
        --track "$TRACK" \
        --json_key "$key_file" \
        --package_name "${ANDROID_PACKAGE_NAME:-}" \
        --skip_upload_metadata true \
        --skip_upload_images true \
        --skip_upload_screenshots true
    
    rm -f "$key_file"
    
    log_success "Deployed to Google Play ($TRACK)"
}

# ==============================================================================
# Build iOS
# ==============================================================================

build_ios() {
    log_info "Building iOS app..."
    
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "iOS builds require macOS"
    fi
    
    cd "$PROJECT_ROOT"
    
    local version
    version=$(get_version)
    local build_number
    build_number=$(get_build_number)
    
    log_info "Version: $version+$build_number"
    
    # Install pods
    cd ios && pod install && cd ..
    
    # Build arguments
    local build_args=(
        "build" "ios"
        "--release"
        "--build-name=$version"
        "--build-number=$build_number"
    )
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        build_args+=("--obfuscate")
    fi
    
    if [[ "$SPLIT_DEBUG_INFO" == "true" ]]; then
        mkdir -p build/debug-info
        build_args+=("--split-debug-info=build/debug-info")
    fi
    
    flutter "${build_args[@]}"
    
    log_success "iOS build complete"
}

# ==============================================================================
# Deploy to TestFlight
# ==============================================================================

deploy_testflight() {
    log_info "Deploying to TestFlight..."
    
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "TestFlight deployment requires macOS"
    fi
    
    cd "$PROJECT_ROOT/ios"
    
    # Archive and upload
    xcodebuild -workspace Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath ../build/Runner.xcarchive \
        archive
    
    # Create export options
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
EOF
    
    xcodebuild -exportArchive \
        -archivePath ../build/Runner.xcarchive \
        -exportOptionsPlist ExportOptions.plist \
        -exportPath ../build/ios
    
    # Upload
    xcrun altool --upload-app \
        --file ../build/ios/*.ipa \
        --type ios \
        --apiKey "${APP_STORE_CONNECT_API_KEY_ID:-}" \
        --apiIssuer "${APP_STORE_CONNECT_ISSUER_ID:-}"
    
    log_success "Deployed to TestFlight"
}

# ==============================================================================
# Build and Deploy Web
# ==============================================================================

deploy_web() {
    log_info "Building and deploying web app..."
    
    cd "$PROJECT_ROOT"
    
    # Build
    flutter build web --release --web-renderer canvaskit
    
    # Deploy based on target
    case "${WEB_HOST:-firebase}" in
        firebase)
            log_info "Deploying to Firebase Hosting..."
            firebase deploy --only hosting
            ;;
        netlify)
            log_info "Deploying to Netlify..."
            netlify deploy --prod --dir=build/web
            ;;
        vercel)
            log_info "Deploying to Vercel..."
            vercel --prod build/web
            ;;
        *)
            log_warning "Unknown web host: ${WEB_HOST:-}"
            log_info "Build available at: $PROJECT_ROOT/build/web"
            ;;
    esac
    
    log_success "Web deployment complete"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Flutter Deployment"
    log_info "Target: $TARGET"
    log_info "Environment: $ENVIRONMENT"
    
    case "$TARGET" in
        android)
            build_android
            deploy_google_play
            ;;
        ios)
            build_ios
            deploy_testflight
            ;;
        web)
            deploy_web
            ;;
        android-build)
            build_android
            ;;
        ios-build)
            build_ios
            ;;
        *)
            log_error "Unknown target: $TARGET"
            ;;
    esac
    
    log_success "Deployment complete!"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target) TARGET="$2"; shift 2 ;;
        --track) TRACK="$2"; shift 2 ;;
        --env) ENVIRONMENT="$2"; shift 2 ;;
        --version) VERSION="$2"; shift 2 ;;
        --build) BUILD_NUMBER="$2"; shift 2 ;;
        --no-obfuscate) OBFUSCATE=false; shift ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --target TYPE    Deployment target (android|ios|web)"
            echo "  --track TRACK    Release track (internal|alpha|beta|production)"
            echo "  --env ENV        Environment (staging|production)"
            echo "  --version VER    Version number"
            echo "  --build NUM      Build number"
            echo "  --no-obfuscate   Disable code obfuscation"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
