#!/bin/bash

# iOS Build Script
# Builds iOS applications for various configurations and destinations
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Build configuration
WORKSPACE="${WORKSPACE_NAME:-App.xcworkspace}"
SCHEME="${SCHEME_NAME:-App}"
CONFIGURATION="${BUILD_CONFIGURATION:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/build}"
ARCHIVE_PATH="${OUTPUT_DIR}/App.xcarchive"

# Export options
EXPORT_METHOD="${EXPORT_METHOD:-app-store}"
TEAM_ID="${TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_IDENTIFIER:-}"

# Flags
CLEAN_BUILD=false
INCLUDE_BITCODE=true
INCLUDE_SYMBOLS=true

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
# Pre-Build Checks
# ==============================================================================

pre_build_checks() {
    log_info "Running pre-build checks..."
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode."
    fi
    
    # Check workspace/project
    if [[ ! -f "$PROJECT_ROOT/$WORKSPACE" ]] && [[ ! -f "$PROJECT_ROOT/$WORKSPACE/contents.xcworkspacedata" ]]; then
        if [[ -f "$PROJECT_ROOT/${SCHEME}.xcodeproj/project.pbxproj" ]]; then
            log_warning "Workspace not found, using project file"
            WORKSPACE="${SCHEME}.xcodeproj"
        else
            log_error "Neither workspace nor project found"
        fi
    fi
    
    # Check signing for release builds
    if [[ "$EXPORT_METHOD" != "development" ]] && [[ -z "$TEAM_ID" ]]; then
        log_warning "TEAM_ID not set. Code signing may fail."
    fi
    
    log_success "Pre-build checks passed"
}

# ==============================================================================
# Increment Build Number
# ==============================================================================

increment_build_number() {
    log_info "Incrementing build number..."
    
    local current_build
    current_build=$(agvtool what-version -terse 2>/dev/null || echo "0")
    
    local new_build
    if [[ -n "${BUILD_NUMBER:-}" ]]; then
        new_build="$BUILD_NUMBER"
    elif [[ -n "${GITHUB_RUN_NUMBER:-}" ]]; then
        new_build="$GITHUB_RUN_NUMBER"
    else
        new_build=$((current_build + 1))
    fi
    
    agvtool new-version -all "$new_build"
    log_info "Build number: $new_build"
}

# ==============================================================================
# Build Archive
# ==============================================================================

build_archive() {
    log_info "Building archive..."
    log_info "  Workspace: $WORKSPACE"
    log_info "  Scheme: $SCHEME"
    log_info "  Configuration: $CONFIGURATION"
    
    mkdir -p "$OUTPUT_DIR"
    
    local build_args=(
        "-workspace" "$WORKSPACE"
        "-scheme" "$SCHEME"
        "-configuration" "$CONFIGURATION"
        "-archivePath" "$ARCHIVE_PATH"
        "archive"
    )
    
    if [[ "$CLEAN_BUILD" == "true" ]]; then
        build_args=("clean" "${build_args[@]}")
    fi
    
    # Add signing configuration
    if [[ -n "$TEAM_ID" ]]; then
        build_args+=("DEVELOPMENT_TEAM=$TEAM_ID")
    fi
    
    # CI-specific settings
    if [[ "${CI:-false}" == "true" ]]; then
        build_args+=("CODE_SIGN_STYLE=Manual")
    fi
    
    # Execute build
    cd "$PROJECT_ROOT"
    
    set +e
    if command -v xcbeautify &> /dev/null; then
        xcodebuild "${build_args[@]}" 2>&1 | xcbeautify
    elif command -v xcpretty &> /dev/null; then
        xcodebuild "${build_args[@]}" 2>&1 | xcpretty --color
    else
        xcodebuild "${build_args[@]}"
    fi
    local exit_code=$?
    set -e
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "Archive build failed"
    fi
    
    log_success "Archive created at: $ARCHIVE_PATH"
}

# ==============================================================================
# Create Export Options Plist
# ==============================================================================

create_export_options() {
    log_info "Creating export options..."
    
    local export_plist="$OUTPUT_DIR/ExportOptions.plist"
    
    # Determine export method settings
    local compile_bitcode="true"
    local upload_symbols="true"
    local destination="export"
    
    case "$EXPORT_METHOD" in
        app-store)
            destination="upload"
            ;;
        ad-hoc)
            compile_bitcode="false"
            ;;
        development)
            compile_bitcode="false"
            ;;
        enterprise)
            compile_bitcode="false"
            ;;
    esac
    
    if [[ "$INCLUDE_BITCODE" == "false" ]]; then
        compile_bitcode="false"
    fi
    
    cat > "$export_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>compileBitcode</key>
    <$compile_bitcode/>
    <key>uploadSymbols</key>
    <$upload_symbols/>
    <key>destination</key>
    <string>$destination</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    
    log_info "Export options created: $export_plist"
}

# ==============================================================================
# Export IPA
# ==============================================================================

export_ipa() {
    log_info "Exporting IPA..."
    
    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        log_error "Archive not found: $ARCHIVE_PATH"
    fi
    
    local export_path="$OUTPUT_DIR/Export"
    local export_plist="$OUTPUT_DIR/ExportOptions.plist"
    
    mkdir -p "$export_path"
    
    set +e
    if command -v xcbeautify &> /dev/null; then
        xcodebuild -exportArchive \
            -archivePath "$ARCHIVE_PATH" \
            -exportOptionsPlist "$export_plist" \
            -exportPath "$export_path" \
            2>&1 | xcbeautify
    else
        xcodebuild -exportArchive \
            -archivePath "$ARCHIVE_PATH" \
            -exportOptionsPlist "$export_plist" \
            -exportPath "$export_path"
    fi
    local exit_code=$?
    set -e
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "IPA export failed"
    fi
    
    # Find and rename IPA
    local ipa_file
    ipa_file=$(find "$export_path" -name "*.ipa" | head -1)
    
    if [[ -z "$ipa_file" ]]; then
        log_error "IPA file not found in export"
    fi
    
    local ipa_name="${SCHEME}-${CONFIGURATION}.ipa"
    mv "$ipa_file" "$OUTPUT_DIR/$ipa_name"
    
    log_success "IPA exported: $OUTPUT_DIR/$ipa_name"
}

# ==============================================================================
# Extract dSYMs
# ==============================================================================

extract_dsyms() {
    log_info "Extracting dSYMs..."
    
    local dsyms_path="$ARCHIVE_PATH/dSYMs"
    local output_dsyms="$OUTPUT_DIR/dSYMs"
    
    if [[ -d "$dsyms_path" ]]; then
        mkdir -p "$output_dsyms"
        cp -R "$dsyms_path/"* "$output_dsyms/"
        
        # Zip dSYMs
        cd "$OUTPUT_DIR"
        zip -r "dSYMs.zip" "dSYMs"
        
        log_success "dSYMs extracted: $OUTPUT_DIR/dSYMs.zip"
    else
        log_warning "No dSYMs found"
    fi
}

# ==============================================================================
# Print Build Info
# ==============================================================================

print_build_info() {
    echo ""
    echo "=============================================="
    echo "Build Summary"
    echo "=============================================="
    echo ""
    
    local version
    version=$(agvtool what-marketing-version -terse1 2>/dev/null || echo "unknown")
    local build
    build=$(agvtool what-version -terse 2>/dev/null || echo "unknown")
    
    echo "Version: $version ($build)"
    echo "Configuration: $CONFIGURATION"
    echo "Export Method: $EXPORT_METHOD"
    echo ""
    
    if [[ -f "$OUTPUT_DIR/${SCHEME}-${CONFIGURATION}.ipa" ]]; then
        local ipa_size
        ipa_size=$(du -h "$OUTPUT_DIR/${SCHEME}-${CONFIGURATION}.ipa" | cut -f1)
        echo "IPA Size: $ipa_size"
    fi
    
    echo "Output: $OUTPUT_DIR"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Starting iOS build..."
    
    pre_build_checks
    
    if [[ "${INCREMENT_BUILD:-true}" == "true" ]]; then
        increment_build_number
    fi
    
    build_archive
    create_export_options
    export_ipa
    extract_dsyms
    print_build_info
    
    log_success "Build complete!"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean) CLEAN_BUILD=true; shift ;;
        --debug) CONFIGURATION="Debug"; shift ;;
        --release) CONFIGURATION="Release"; shift ;;
        --scheme) SCHEME="$2"; shift 2 ;;
        --method) EXPORT_METHOD="$2"; shift 2 ;;
        --team) TEAM_ID="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --no-bitcode) INCLUDE_BITCODE=false; shift ;;
        --no-increment) INCREMENT_BUILD=false; shift ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --clean         Clean before build"
            echo "  --debug         Build Debug configuration"
            echo "  --release       Build Release configuration"
            echo "  --scheme NAME   Xcode scheme"
            echo "  --method TYPE   Export method (app-store|ad-hoc|development|enterprise)"
            echo "  --team ID       Development team ID"
            echo "  --output DIR    Output directory"
            echo "  --no-bitcode    Disable bitcode"
            echo "  --no-increment  Don't increment build number"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
