#!/bin/bash

# Version Bump Script
# Manages semantic versioning across mobile platforms
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Version components
BUMP_TYPE="${BUMP_TYPE:-patch}"
NEW_VERSION="${NEW_VERSION:-}"
DRY_RUN="${DRY_RUN:-false}"

# Platform flags
UPDATE_IOS="${UPDATE_IOS:-true}"
UPDATE_ANDROID="${UPDATE_ANDROID:-true}"
UPDATE_FLUTTER="${UPDATE_FLUTTER:-true}"
UPDATE_RN="${UPDATE_RN:-true}"

# Git options
CREATE_TAG="${CREATE_TAG:-false}"
PUSH_TAG="${PUSH_TAG:-false}"
COMMIT_CHANGES="${COMMIT_CHANGES:-true}"

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

# ==============================================================================
# Get Current Version
# ==============================================================================

get_current_version() {
    local version=""
    
    # Try package.json (React Native)
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        version=$(grep '"version"' "$PROJECT_ROOT/package.json" | head -1 | sed 's/.*": "\([^"]*\)".*/\1/')
    fi
    
    # Try pubspec.yaml (Flutter)
    if [[ -z "$version" ]] && [[ -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
        version=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1)
    fi
    
    # Try iOS Info.plist
    if [[ -z "$version" ]] && [[ -f "$PROJECT_ROOT/ios/App/Info.plist" ]]; then
        version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PROJECT_ROOT/ios/App/Info.plist" 2>/dev/null || echo "")
    fi
    
    # Try Android build.gradle
    if [[ -z "$version" ]] && [[ -f "$PROJECT_ROOT/android/app/build.gradle" ]]; then
        version=$(grep 'versionName' "$PROJECT_ROOT/android/app/build.gradle" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    fi
    
    if [[ -z "$version" ]]; then
        version="1.0.0"
    fi
    
    echo "$version"
}

# ==============================================================================
# Calculate New Version
# ==============================================================================

calculate_new_version() {
    local current="$1"
    local bump_type="$2"
    
    # Parse version
    IFS='.' read -r major minor patch <<< "$current"
    
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            # Assume it's a specific version
            echo "$bump_type"
            return
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# ==============================================================================
# Update Package.json (React Native)
# ==============================================================================

update_package_json() {
    local version="$1"
    local file="$PROJECT_ROOT/package.json"
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    log_info "Updating package.json to $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would update: $file"
        return 0
    fi
    
    # Use npm version (without git tag)
    cd "$PROJECT_ROOT"
    npm version "$version" --no-git-tag-version
    
    log_success "Updated package.json"
}

# ==============================================================================
# Update pubspec.yaml (Flutter)
# ==============================================================================

update_pubspec() {
    local version="$1"
    local build_number="${2:-}"
    local file="$PROJECT_ROOT/pubspec.yaml"
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    log_info "Updating pubspec.yaml to $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would update: $file"
        return 0
    fi
    
    if [[ -n "$build_number" ]]; then
        sed -i.bak "s/^version: .*/version: ${version}+${build_number}/" "$file"
    else
        # Preserve existing build number
        sed -i.bak "s/^version: [^+]*/version: ${version}/" "$file"
    fi
    
    rm -f "$file.bak"
    log_success "Updated pubspec.yaml"
}

# ==============================================================================
# Update iOS Version
# ==============================================================================

update_ios() {
    local version="$1"
    local build_number="${2:-}"
    
    if [[ "$UPDATE_IOS" != "true" ]]; then
        return 0
    fi
    
    # Find project directory
    local ios_dir=""
    if [[ -d "$PROJECT_ROOT/ios" ]]; then
        ios_dir="$PROJECT_ROOT/ios"
    else
        return 0
    fi
    
    log_info "Updating iOS version to $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would update iOS in: $ios_dir"
        return 0
    fi
    
    cd "$ios_dir"
    
    # Use agvtool if available
    if command -v agvtool &> /dev/null; then
        agvtool new-marketing-version "$version"
        
        if [[ -n "$build_number" ]]; then
            agvtool new-version -all "$build_number"
        fi
    else
        # Manual update of Info.plist files
        find . -name "Info.plist" -type f | while read -r plist; do
            if [[ -f "$plist" ]]; then
                /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$plist" 2>/dev/null || true
                if [[ -n "$build_number" ]]; then
                    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$plist" 2>/dev/null || true
                fi
            fi
        done
    fi
    
    log_success "Updated iOS version"
}

# ==============================================================================
# Update Android Version
# ==============================================================================

update_android() {
    local version="$1"
    local version_code="${2:-}"
    
    if [[ "$UPDATE_ANDROID" != "true" ]]; then
        return 0
    fi
    
    local gradle_file="$PROJECT_ROOT/android/app/build.gradle"
    
    if [[ ! -f "$gradle_file" ]]; then
        # Try Kotlin DSL
        gradle_file="$PROJECT_ROOT/android/app/build.gradle.kts"
    fi
    
    if [[ ! -f "$gradle_file" ]]; then
        return 0
    fi
    
    log_info "Updating Android version to $version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would update: $gradle_file"
        return 0
    fi
    
    # Update versionName
    sed -i.bak "s/versionName \"[^\"]*\"/versionName \"$version\"/" "$gradle_file"
    sed -i.bak "s/versionName = \"[^\"]*\"/versionName = \"$version\"/" "$gradle_file"
    
    # Update versionCode if provided
    if [[ -n "$version_code" ]]; then
        sed -i.bak "s/versionCode [0-9]*/versionCode $version_code/" "$gradle_file"
        sed -i.bak "s/versionCode = [0-9]*/versionCode = $version_code/" "$gradle_file"
    fi
    
    rm -f "$gradle_file.bak"
    log_success "Updated Android version"
}

# ==============================================================================
# Commit and Tag
# ==============================================================================

commit_and_tag() {
    local version="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would commit with message: chore(release): bump version to $version"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    if [[ "$COMMIT_CHANGES" == "true" ]]; then
        log_info "Committing changes..."
        git add -A
        git commit -m "chore(release): bump version to $version"
        log_success "Changes committed"
    fi
    
    if [[ "$CREATE_TAG" == "true" ]]; then
        log_info "Creating tag v$version..."
        git tag -a "v$version" -m "Release v$version"
        log_success "Tag created"
        
        if [[ "$PUSH_TAG" == "true" ]]; then
            log_info "Pushing tag..."
            git push origin "v$version"
            log_success "Tag pushed"
        fi
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Version Bump Script"
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    log_info "Current version: $current_version"
    
    # Calculate new version
    local new_version
    if [[ -n "$NEW_VERSION" ]]; then
        new_version="$NEW_VERSION"
    else
        new_version=$(calculate_new_version "$current_version" "$BUMP_TYPE")
    fi
    
    log_info "New version: $new_version"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "Dry run mode - no changes will be made"
    fi
    
    # Update all platforms
    update_package_json "$new_version"
    update_pubspec "$new_version" "${BUILD_NUMBER:-}"
    update_ios "$new_version" "${BUILD_NUMBER:-}"
    update_android "$new_version" "${VERSION_CODE:-${BUILD_NUMBER:-}}"
    
    # Commit and tag
    commit_and_tag "$new_version"
    
    echo ""
    log_success "Version bumped to $new_version"
    echo "NEW_VERSION=$new_version" >> "${GITHUB_OUTPUT:-/dev/null}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --major) BUMP_TYPE="major"; shift ;;
        --minor) BUMP_TYPE="minor"; shift ;;
        --patch) BUMP_TYPE="patch"; shift ;;
        --version) NEW_VERSION="$2"; shift 2 ;;
        --build) BUILD_NUMBER="$2"; shift 2 ;;
        --tag) CREATE_TAG="true"; shift ;;
        --push) PUSH_TAG="true"; CREATE_TAG="true"; shift ;;
        --dry-run) DRY_RUN="true"; shift ;;
        --no-commit) COMMIT_CHANGES="false"; shift ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --major       Bump major version"
            echo "  --minor       Bump minor version"
            echo "  --patch       Bump patch version (default)"
            echo "  --version VER Set specific version"
            echo "  --build NUM   Set build number"
            echo "  --tag         Create git tag"
            echo "  --push        Push tag to remote"
            echo "  --dry-run     Show what would be done"
            echo "  --no-commit   Don't commit changes"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
