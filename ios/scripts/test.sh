#!/bin/bash

# iOS Test Runner Script
# Executes unit tests, UI tests, and generates coverage reports
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
WORKSPACE="${WORKSPACE_NAME:-App.xcworkspace}"
SCHEME="${SCHEME_NAME:-App}"
DEVICE="${TEST_DEVICE:-iPhone 15 Pro}"
OS_VERSION="${TEST_OS:-17.2}"
TEST_PLAN="${TEST_PLAN:-}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/test-results}"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-70}"

# Test types
RUN_UNIT_TESTS=true
RUN_UI_TESTS=false
RUN_SNAPSHOT_TESTS=false
PARALLEL_TESTING=true
RETRY_FAILED=true
GENERATE_COVERAGE=true

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
    log_info "Cleaning up..."
    # Kill any remaining simulators
    xcrun simctl shutdown all 2>/dev/null || true
}

trap cleanup EXIT

# ==============================================================================
# Simulator Management
# ==============================================================================

boot_simulator() {
    log_info "Booting simulator: $DEVICE (iOS $OS_VERSION)..."
    
    # Find device UDID
    local device_id
    device_id=$(xcrun simctl list devices available | grep "$DEVICE" | grep -oE '[A-Z0-9-]{36}' | head -1)
    
    if [[ -z "$device_id" ]]; then
        log_error "Device not found: $DEVICE"
        exit 1
    fi
    
    # Boot if not already booted
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
    
    echo "$device_id"
}

# ==============================================================================
# Run Unit Tests
# ==============================================================================

run_unit_tests() {
    log_info "Running unit tests..."
    
    local result_path="$OUTPUT_DIR/UnitTests.xcresult"
    local junit_path="$OUTPUT_DIR/unit-tests.xml"
    
    # Build test arguments
    local test_args=(
        "test"
        "-workspace" "$WORKSPACE"
        "-scheme" "$SCHEME"
        "-destination" "platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION"
        "-resultBundlePath" "$result_path"
        "-enableCodeCoverage" "YES"
        "CODE_SIGN_IDENTITY="
        "CODE_SIGNING_REQUIRED=NO"
    )
    
    if [[ -n "$TEST_PLAN" ]]; then
        test_args+=("-testPlan" "$TEST_PLAN")
    fi
    
    if [[ "$PARALLEL_TESTING" == "true" ]]; then
        test_args+=("-parallel-testing-enabled" "YES")
        test_args+=("-parallel-testing-worker-count" "4")
    fi
    
    if [[ "$RETRY_FAILED" == "true" ]]; then
        test_args+=("-test-iterations" "2")
        test_args+=("-retry-tests-on-failure")
    fi
    
    # Run tests
    set +e
    xcodebuild "${test_args[@]}" 2>&1 | xcbeautify --report junit --junit-report-filename "$junit_path"
    local exit_code=$?
    set -e
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        return 1
    fi
}

# ==============================================================================
# Run UI Tests
# ==============================================================================

run_ui_tests() {
    log_info "Running UI tests..."
    
    local result_path="$OUTPUT_DIR/UITests.xcresult"
    local junit_path="$OUTPUT_DIR/ui-tests.xml"
    
    set +e
    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "${SCHEME}UITests" \
        -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS_VERSION" \
        -resultBundlePath "$result_path" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        2>&1 | xcbeautify --report junit --junit-report-filename "$junit_path"
    local exit_code=$?
    set -e
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "UI tests passed"
    else
        log_warning "UI tests failed"
        return 1
    fi
}

# ==============================================================================
# Generate Coverage Report
# ==============================================================================

generate_coverage() {
    log_info "Generating coverage report..."
    
    local result_path="$OUTPUT_DIR/UnitTests.xcresult"
    local coverage_json="$OUTPUT_DIR/coverage.json"
    local coverage_html="$OUTPUT_DIR/coverage"
    
    if [[ ! -d "$result_path" ]]; then
        log_warning "Test results not found, skipping coverage"
        return 0
    fi
    
    # Export JSON coverage
    xcrun xccov view --report --json "$result_path" > "$coverage_json"
    
    # Calculate coverage percentage
    local coverage
    coverage=$(python3 << EOF
import json
with open('$coverage_json') as f:
    data = json.load(f)
for t in data.get('targets', []):
    name = t.get('name', '')
    if '$SCHEME' in name and 'Test' not in name:
        print(f"{t.get('lineCoverage', 0) * 100:.2f}")
        break
EOF
)
    
    log_info "Code coverage: ${coverage}%"
    
    # Check threshold
    if (( $(echo "$coverage < $COVERAGE_THRESHOLD" | bc -l) )); then
        log_warning "Coverage ($coverage%) is below threshold ($COVERAGE_THRESHOLD%)"
        return 1
    else
        log_success "Coverage meets threshold"
    fi
    
    # Generate HTML report if xcov is available
    if command -v xcov &> /dev/null; then
        log_info "Generating HTML coverage report..."
        bundle exec xcov \
            --workspace "$WORKSPACE" \
            --scheme "$SCHEME" \
            --output_directory "$coverage_html" \
            --html_report true \
            --json_report true 2>/dev/null || true
    fi
}

# ==============================================================================
# Print Summary
# ==============================================================================

print_summary() {
    echo ""
    echo "=============================================="
    echo "Test Summary"
    echo "=============================================="
    echo ""
    echo "Results directory: $OUTPUT_DIR"
    echo ""
    
    if [[ -f "$OUTPUT_DIR/unit-tests.xml" ]]; then
        # Parse JUnit results
        local tests passed failed
        tests=$(grep -o 'tests="[0-9]*"' "$OUTPUT_DIR/unit-tests.xml" | head -1 | grep -o '[0-9]*' || echo "0")
        failed=$(grep -o 'failures="[0-9]*"' "$OUTPUT_DIR/unit-tests.xml" | head -1 | grep -o '[0-9]*' || echo "0")
        passed=$((tests - failed))
        
        echo "Unit Tests: $passed/$tests passed"
    fi
    
    if [[ -f "$OUTPUT_DIR/coverage.json" ]]; then
        echo "Coverage report: $OUTPUT_DIR/coverage.json"
    fi
    
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    cd "$PROJECT_ROOT"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Boot simulator
    boot_simulator
    
    # Run tests
    local failed=false
    
    if [[ "$RUN_UNIT_TESTS" == "true" ]]; then
        run_unit_tests || failed=true
    fi
    
    if [[ "$RUN_UI_TESTS" == "true" ]]; then
        run_ui_tests || failed=true
    fi
    
    if [[ "$GENERATE_COVERAGE" == "true" ]]; then
        generate_coverage || failed=true
    fi
    
    print_summary
    
    if [[ "$failed" == "true" ]]; then
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit) RUN_UNIT_TESTS=true; RUN_UI_TESTS=false; shift ;;
        --ui) RUN_UI_TESTS=true; shift ;;
        --all) RUN_UNIT_TESTS=true; RUN_UI_TESTS=true; shift ;;
        --no-coverage) GENERATE_COVERAGE=false; shift ;;
        --no-parallel) PARALLEL_TESTING=false; shift ;;
        --device) DEVICE="$2"; shift 2 ;;
        --os) OS_VERSION="$2"; shift 2 ;;
        --scheme) SCHEME="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --unit          Run unit tests only"
            echo "  --ui            Include UI tests"
            echo "  --all           Run all tests"
            echo "  --no-coverage   Skip coverage report"
            echo "  --no-parallel   Disable parallel testing"
            echo "  --device NAME   Simulator device"
            echo "  --os VERSION    iOS version"
            echo "  --scheme NAME   Xcode scheme"
            echo "  --output DIR    Output directory"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
