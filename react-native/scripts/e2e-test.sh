#!/bin/bash

# React Native E2E Test Script
# Run end-to-end tests with Detox
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
PLATFORM="${PLATFORM:-ios}"
CONFIGURATION="${CONFIGURATION:-debug}"
DEVICE="${DEVICE:-}"
HEADLESS="${HEADLESS:-false}"
CLEANUP="${CLEANUP:-true}"
RECORD_VIDEO="${RECORD_VIDEO:-false}"
RETRY_COUNT="${RETRY_COUNT:-2}"

# Output
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/e2e-results}"
ARTIFACTS_DIR="$OUTPUT_DIR/artifacts"

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
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
    if [[ "$CLEANUP" == "true" ]]; then
        log_info "Cleaning up..."
        
        # Kill Metro if running
        pkill -f "react-native start" 2>/dev/null || true
        
        # Clean up simulators
        if [[ "$PLATFORM" == "ios" ]]; then
            xcrun simctl shutdown all 2>/dev/null || true
        fi
    fi
}

trap cleanup EXIT

# ==============================================================================
# Check Dependencies
# ==============================================================================

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Detox CLI
    if ! command -v detox &> /dev/null; then
        log_info "Installing Detox CLI..."
        npm install -g detox-cli
    fi
    
    # Platform-specific checks
    if [[ "$PLATFORM" == "ios" ]]; then
        if [[ "$(uname)" != "Darwin" ]]; then
            log_error "iOS tests require macOS"
        fi
        
        # Check applesimutils
        if ! command -v applesimutils &> /dev/null; then
            log_info "Installing applesimutils..."
            brew tap wix/brew
            brew install applesimutils
        fi
    fi
    
    if [[ "$PLATFORM" == "android" ]]; then
        # Check ANDROID_HOME
        if [[ -z "${ANDROID_HOME:-}" ]]; then
            log_error "ANDROID_HOME is not set"
        fi
        
        # Check for emulator
        if ! "$ANDROID_HOME/emulator/emulator" -list-avds | grep -q .; then
            log_warning "No Android emulators found"
        fi
    fi
    
    log_success "Dependencies OK"
}

# ==============================================================================
# Build App
# ==============================================================================

build_app() {
    log_info "Building app for $PLATFORM ($CONFIGURATION)..."
    
    cd "$PROJECT_ROOT"
    
    local config="${PLATFORM}.sim.${CONFIGURATION}"
    if [[ "$PLATFORM" == "android" ]]; then
        config="${PLATFORM}.emu.${CONFIGURATION}"
    fi
    
    detox build --configuration "$config"
    
    log_success "Build complete"
}

# ==============================================================================
# Start Emulator/Simulator
# ==============================================================================

start_device() {
    log_info "Starting device..."
    
    if [[ "$PLATFORM" == "ios" ]]; then
        # Boot iOS simulator
        local sim_device="${DEVICE:-iPhone 15 Pro}"
        local device_id
        
        device_id=$(xcrun simctl list devices available | grep "$sim_device" | grep -oE '[A-Z0-9-]{36}' | head -1)
        
        if [[ -z "$device_id" ]]; then
            log_error "Simulator not found: $sim_device"
        fi
        
        # Boot if not already running
        if ! xcrun simctl list devices booted | grep -q "$device_id"; then
            xcrun simctl boot "$device_id"
            log_info "Waiting for simulator to boot..."
            sleep 5
        fi
        
        # Configure status bar
        xcrun simctl status_bar "$device_id" override \
            --time "9:41" \
            --batteryState charged \
            --batteryLevel 100 \
            --cellularBars 4 2>/dev/null || true
        
    elif [[ "$PLATFORM" == "android" ]]; then
        # Start Android emulator
        local emulator="${DEVICE:-Pixel_4_API_33}"
        
        # Check if emulator is running
        if ! adb devices | grep -q "emulator"; then
            log_info "Starting Android emulator..."
            
            "$ANDROID_HOME/emulator/emulator" -avd "$emulator" -no-snapshot -no-audio &
            
            # Wait for emulator
            log_info "Waiting for emulator to boot..."
            adb wait-for-device
            
            # Wait for boot complete
            while [[ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]]; do
                sleep 2
            done
        fi
    fi
    
    log_success "Device ready"
}

# ==============================================================================
# Run Tests
# ==============================================================================

run_tests() {
    log_info "Running E2E tests..."
    
    cd "$PROJECT_ROOT"
    mkdir -p "$ARTIFACTS_DIR"
    
    local config="${PLATFORM}.sim.${CONFIGURATION}"
    if [[ "$PLATFORM" == "android" ]]; then
        config="${PLATFORM}.emu.${CONFIGURATION}"
    fi
    
    # Build test arguments
    local test_args=(
        "--configuration" "$config"
        "--artifacts-location" "$ARTIFACTS_DIR"
        "--retries" "$RETRY_COUNT"
    )
    
    if [[ "$HEADLESS" == "true" ]]; then
        test_args+=("--headless")
    fi
    
    if [[ "$CLEANUP" == "true" ]]; then
        test_args+=("--cleanup")
    fi
    
    if [[ "$RECORD_VIDEO" == "true" ]]; then
        test_args+=("--record-videos" "all")
        test_args+=("--record-logs" "all")
    else
        test_args+=("--record-videos" "failing")
        test_args+=("--record-logs" "failing")
    fi
    
    # Run Detox
    set +e
    detox test "${test_args[@]}" 2>&1 | tee "$OUTPUT_DIR/test-output.log"
    local exit_code=${PIPESTATUS[0]}
    set -e
    
    return $exit_code
}

# ==============================================================================
# Generate Report
# ==============================================================================

generate_report() {
    log_info "Generating test report..."
    
    local report_file="$OUTPUT_DIR/report.md"
    
    cat > "$report_file" << EOF
# E2E Test Report

**Platform:** $PLATFORM
**Configuration:** $CONFIGURATION
**Date:** $(date)
**Device:** ${DEVICE:-default}

## Results

EOF
    
    # Count test results
    if [[ -f "$OUTPUT_DIR/test-output.log" ]]; then
        local passed=$(grep -c "✓\|✔\|PASS" "$OUTPUT_DIR/test-output.log" 2>/dev/null || echo "0")
        local failed=$(grep -c "✗\|✘\|FAIL" "$OUTPUT_DIR/test-output.log" 2>/dev/null || echo "0")
        
        echo "| Metric | Count |" >> "$report_file"
        echo "|--------|-------|" >> "$report_file"
        echo "| Passed | $passed |" >> "$report_file"
        echo "| Failed | $failed |" >> "$report_file"
    fi
    
    # List artifacts
    if [[ -d "$ARTIFACTS_DIR" ]]; then
        echo "" >> "$report_file"
        echo "## Artifacts" >> "$report_file"
        echo "" >> "$report_file"
        
        find "$ARTIFACTS_DIR" -type f | while read -r file; do
            echo "- $(basename "$file")" >> "$report_file"
        done
    fi
    
    log_success "Report generated: $report_file"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    echo "=============================================="
    echo "React Native E2E Tests"
    echo "=============================================="
    echo ""
    echo "Platform: $PLATFORM"
    echo "Configuration: $CONFIGURATION"
    echo ""
    
    check_dependencies
    
    # Build unless skipped
    if [[ "${SKIP_BUILD:-false}" != "true" ]]; then
        build_app
    fi
    
    start_device
    
    # Run tests
    local result=0
    run_tests || result=$?
    
    generate_report
    
    echo ""
    echo "=============================================="
    if [[ $result -eq 0 ]]; then
        log_success "All E2E tests passed!"
    else
        log_error "Some E2E tests failed"
    fi
    echo "=============================================="
    
    exit $result
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform) PLATFORM="$2"; shift 2 ;;
        --config) CONFIGURATION="$2"; shift 2 ;;
        --device) DEVICE="$2"; shift 2 ;;
        --headless) HEADLESS="true"; shift ;;
        --no-cleanup) CLEANUP="false"; shift ;;
        --record) RECORD_VIDEO="true"; shift ;;
        --skip-build) SKIP_BUILD="true"; shift ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --retries) RETRY_COUNT="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --platform PLATFORM   ios or android"
            echo "  --config CONFIG       debug or release"
            echo "  --device DEVICE       Device/emulator name"
            echo "  --headless            Run in headless mode"
            echo "  --no-cleanup          Don't cleanup after tests"
            echo "  --record              Record all test videos"
            echo "  --skip-build          Skip building the app"
            echo "  --output DIR          Output directory"
            echo "  --retries N           Number of retries"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
