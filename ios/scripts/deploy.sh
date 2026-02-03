#!/bin/bash

# iOS Deployment Script
# Deploys iOS applications to various distribution channels
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Deployment target
TARGET="${DEPLOY_TARGET:-testflight}"
IPA_PATH="${IPA_PATH:-}"
DSYM_PATH="${DSYM_PATH:-}"

# App Store Connect
ASC_API_KEY_ID="${APP_STORE_CONNECT_API_KEY_ID:-}"
ASC_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-}"
ASC_API_KEY_CONTENT="${APP_STORE_CONNECT_API_KEY_CONTENT:-}"
ASC_API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-}"

# TestFlight
TESTFLIGHT_GROUPS="${TESTFLIGHT_GROUPS:-Internal Testers}"
DISTRIBUTE_EXTERNAL="${DISTRIBUTE_EXTERNAL:-false}"
CHANGELOG="${CHANGELOG:-Bug fixes and improvements}"

# Firebase App Distribution
FIREBASE_APP_ID="${FIREBASE_APP_ID:-}"
FIREBASE_TOKEN="${FIREBASE_CLI_TOKEN:-}"
FIREBASE_GROUPS="${FIREBASE_GROUPS:-qa-team}"

# AppCenter
APPCENTER_TOKEN="${APPCENTER_API_TOKEN:-}"
APPCENTER_OWNER="${APPCENTER_OWNER_NAME:-}"
APPCENTER_APP="${APPCENTER_APP_NAME:-}"
APPCENTER_GROUP="${APPCENTER_DISTRIBUTION_GROUP:-Collaborators}"

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

find_ipa() {
    if [[ -n "$IPA_PATH" ]] && [[ -f "$IPA_PATH" ]]; then
        echo "$IPA_PATH"
        return 0
    fi
    
    # Search in build directory
    local ipa
    ipa=$(find "$PROJECT_ROOT/build" -name "*.ipa" -type f 2>/dev/null | head -1)
    
    if [[ -n "$ipa" ]]; then
        echo "$ipa"
        return 0
    fi
    
    log_error "No IPA file found. Please build first or specify --ipa path"
}

find_dsyms() {
    if [[ -n "$DSYM_PATH" ]] && [[ -e "$DSYM_PATH" ]]; then
        echo "$DSYM_PATH"
        return 0
    fi
    
    # Search for dSYMs
    local dsyms
    dsyms=$(find "$PROJECT_ROOT/build" -name "*.dSYM" -o -name "dSYMs.zip" 2>/dev/null | head -1)
    
    if [[ -n "$dsyms" ]]; then
        echo "$dsyms"
    fi
}

# ==============================================================================
# Setup App Store Connect API Key
# ==============================================================================

setup_asc_api_key() {
    log_info "Setting up App Store Connect API key..."
    
    if [[ -n "$ASC_API_KEY_PATH" ]] && [[ -f "$ASC_API_KEY_PATH" ]]; then
        log_info "Using API key from path: $ASC_API_KEY_PATH"
        return 0
    fi
    
    if [[ -z "$ASC_API_KEY_CONTENT" ]]; then
        log_error "API key not configured. Set APP_STORE_CONNECT_API_KEY_CONTENT or APP_STORE_CONNECT_API_KEY_PATH"
    fi
    
    # Create temporary key file
    local key_dir="$HOME/.appstoreconnect/private_keys"
    mkdir -p "$key_dir"
    
    ASC_API_KEY_PATH="$key_dir/AuthKey_${ASC_API_KEY_ID}.p8"
    echo "$ASC_API_KEY_CONTENT" | base64 --decode > "$ASC_API_KEY_PATH"
    
    log_success "API key configured"
}

# ==============================================================================
# Deploy to TestFlight
# ==============================================================================

deploy_testflight() {
    log_info "Deploying to TestFlight..."
    
    local ipa
    ipa=$(find_ipa)
    
    # Validate required credentials
    if [[ -z "$ASC_API_KEY_ID" ]] || [[ -z "$ASC_ISSUER_ID" ]]; then
        log_error "App Store Connect credentials not configured"
    fi
    
    setup_asc_api_key
    
    # Validate IPA
    log_info "Validating IPA..."
    xcrun altool --validate-app \
        --file "$ipa" \
        --type ios \
        --apiKey "$ASC_API_KEY_ID" \
        --apiIssuer "$ASC_ISSUER_ID"
    
    # Upload to App Store Connect
    log_info "Uploading to App Store Connect..."
    xcrun altool --upload-app \
        --file "$ipa" \
        --type ios \
        --apiKey "$ASC_API_KEY_ID" \
        --apiIssuer "$ASC_ISSUER_ID"
    
    log_success "IPA uploaded to App Store Connect"
    
    # Distribute to TestFlight groups (requires fastlane)
    if command -v fastlane &> /dev/null && [[ -f "$PROJECT_ROOT/fastlane/Fastfile" ]]; then
        log_info "Distributing to TestFlight groups..."
        
        cd "$PROJECT_ROOT"
        bundle exec fastlane pilot distribute \
            --changelog "$CHANGELOG" \
            --groups "$TESTFLIGHT_GROUPS" \
            --distribute_external "$DISTRIBUTE_EXTERNAL" \
            --skip_waiting_for_build_processing true
    else
        log_info "Build uploaded. Distribute manually in App Store Connect."
    fi
}

# ==============================================================================
# Deploy to App Store
# ==============================================================================

deploy_appstore() {
    log_info "Deploying to App Store..."
    
    local ipa
    ipa=$(find_ipa)
    
    if [[ -z "$ASC_API_KEY_ID" ]] || [[ -z "$ASC_ISSUER_ID" ]]; then
        log_error "App Store Connect credentials not configured"
    fi
    
    setup_asc_api_key
    
    # Upload
    log_info "Uploading to App Store Connect..."
    xcrun altool --upload-app \
        --file "$ipa" \
        --type ios \
        --apiKey "$ASC_API_KEY_ID" \
        --apiIssuer "$ASC_ISSUER_ID"
    
    log_success "IPA uploaded to App Store Connect"
    log_info "Complete the submission in App Store Connect"
}

# ==============================================================================
# Deploy to Firebase App Distribution
# ==============================================================================

deploy_firebase() {
    log_info "Deploying to Firebase App Distribution..."
    
    local ipa
    ipa=$(find_ipa)
    
    if [[ -z "$FIREBASE_APP_ID" ]]; then
        log_error "FIREBASE_APP_ID not configured"
    fi
    
    # Check for Firebase CLI
    if ! command -v firebase &> /dev/null; then
        log_info "Installing Firebase CLI..."
        curl -sL https://firebase.tools | bash
    fi
    
    # Deploy
    local firebase_args=(
        "appdistribution:distribute" "$ipa"
        "--app" "$FIREBASE_APP_ID"
        "--groups" "$FIREBASE_GROUPS"
        "--release-notes" "$CHANGELOG"
    )
    
    if [[ -n "$FIREBASE_TOKEN" ]]; then
        firebase_args+=("--token" "$FIREBASE_TOKEN")
    fi
    
    firebase "${firebase_args[@]}"
    
    log_success "Deployed to Firebase App Distribution"
}

# ==============================================================================
# Deploy to AppCenter
# ==============================================================================

deploy_appcenter() {
    log_info "Deploying to AppCenter..."
    
    local ipa
    ipa=$(find_ipa)
    
    if [[ -z "$APPCENTER_TOKEN" ]] || [[ -z "$APPCENTER_OWNER" ]] || [[ -z "$APPCENTER_APP" ]]; then
        log_error "AppCenter configuration incomplete"
    fi
    
    # Check for AppCenter CLI
    if ! command -v appcenter &> /dev/null; then
        log_info "Installing AppCenter CLI..."
        npm install -g appcenter-cli
    fi
    
    # Login
    appcenter login --token "$APPCENTER_TOKEN"
    
    # Upload
    appcenter distribute release \
        --app "$APPCENTER_OWNER/$APPCENTER_APP" \
        --file "$ipa" \
        --group "$APPCENTER_GROUP" \
        --release-notes "$CHANGELOG"
    
    log_success "Deployed to AppCenter"
}

# ==============================================================================
# Upload dSYMs to Crashlytics
# ==============================================================================

upload_dsyms_crashlytics() {
    log_info "Uploading dSYMs to Crashlytics..."
    
    local dsyms
    dsyms=$(find_dsyms)
    
    if [[ -z "$dsyms" ]]; then
        log_warning "No dSYMs found, skipping"
        return 0
    fi
    
    if [[ -z "$FIREBASE_APP_ID" ]]; then
        log_warning "FIREBASE_APP_ID not set, skipping dSYM upload"
        return 0
    fi
    
    # Check for Firebase CLI
    if ! command -v firebase &> /dev/null; then
        log_info "Installing Firebase CLI..."
        curl -sL https://firebase.tools | bash
    fi
    
    firebase crashlytics:symbols:upload \
        --app "$FIREBASE_APP_ID" \
        "$dsyms"
    
    log_success "dSYMs uploaded to Crashlytics"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Starting deployment to: $TARGET"
    
    case "$TARGET" in
        testflight)
            deploy_testflight
            upload_dsyms_crashlytics
            ;;
        appstore)
            deploy_appstore
            upload_dsyms_crashlytics
            ;;
        firebase)
            deploy_firebase
            upload_dsyms_crashlytics
            ;;
        appcenter)
            deploy_appcenter
            ;;
        dsyms)
            upload_dsyms_crashlytics
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
        --ipa) IPA_PATH="$2"; shift 2 ;;
        --dsyms) DSYM_PATH="$2"; shift 2 ;;
        --changelog) CHANGELOG="$2"; shift 2 ;;
        --groups) TESTFLIGHT_GROUPS="$2"; FIREBASE_GROUPS="$2"; shift 2 ;;
        --external) DISTRIBUTE_EXTERNAL="true"; shift ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --target TYPE    Deployment target (testflight|appstore|firebase|appcenter|dsyms)"
            echo "  --ipa PATH       Path to IPA file"
            echo "  --dsyms PATH     Path to dSYMs"
            echo "  --changelog TEXT Release notes"
            echo "  --groups NAMES   Distribution groups"
            echo "  --external       Include external testers (TestFlight)"
            echo ""
            echo "Environment variables:"
            echo "  APP_STORE_CONNECT_API_KEY_ID"
            echo "  APP_STORE_CONNECT_ISSUER_ID"
            echo "  APP_STORE_CONNECT_API_KEY_CONTENT"
            echo "  FIREBASE_APP_ID"
            echo "  FIREBASE_CLI_TOKEN"
            echo "  APPCENTER_API_TOKEN"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
