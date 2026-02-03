#!/bin/bash

# Flutter Test Coverage Script
# Run tests and generate coverage reports
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Coverage settings
COVERAGE_DIR="$PROJECT_ROOT/coverage"
MIN_COVERAGE="${MIN_COVERAGE:-70}"
LCOV_FILE="$COVERAGE_DIR/lcov.info"

# Flags
GENERATE_HTML=true
OPEN_REPORT=false
FAIL_BELOW_THRESHOLD=true

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

# ==============================================================================
# Check Dependencies
# ==============================================================================

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found"
        exit 1
    fi
    
    if ! command -v lcov &> /dev/null; then
        log_warning "lcov not found. HTML reports will not be generated."
        log_info "Install with: brew install lcov (macOS) or apt-get install lcov (Linux)"
        GENERATE_HTML=false
    fi
}

# ==============================================================================
# Run Tests with Coverage
# ==============================================================================

run_tests() {
    log_info "Running tests with coverage..."
    
    cd "$PROJECT_ROOT"
    
    # Clean previous coverage
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"
    
    # Run tests
    flutter test --coverage --coverage-path="$LCOV_FILE"
    
    if [[ ! -f "$LCOV_FILE" ]]; then
        log_error "Coverage file not generated"
        exit 1
    fi
    
    log_success "Tests completed"
}

# ==============================================================================
# Filter Coverage
# ==============================================================================

filter_coverage() {
    log_info "Filtering coverage data..."
    
    if ! command -v lcov &> /dev/null; then
        log_warning "lcov not available, skipping filter"
        return 0
    fi
    
    # Remove generated files from coverage
    lcov --remove "$LCOV_FILE" \
        '*.g.dart' \
        '*.freezed.dart' \
        '*.mocks.dart' \
        '**/generated/**' \
        '**/l10n/**' \
        '**/*.config.dart' \
        -o "$LCOV_FILE" \
        --ignore-errors unused
    
    log_success "Coverage filtered"
}

# ==============================================================================
# Calculate Coverage
# ==============================================================================

calculate_coverage() {
    log_info "Calculating coverage..."
    
    if [[ ! -f "$LCOV_FILE" ]]; then
        log_error "Coverage file not found"
        exit 1
    fi
    
    # Calculate coverage from lcov
    local total_lines=0
    local covered_lines=0
    
    while IFS= read -r line; do
        if [[ "$line" == LF:* ]]; then
            total_lines=$((total_lines + ${line#LF:}))
        elif [[ "$line" == LH:* ]]; then
            covered_lines=$((covered_lines + ${line#LH:}))
        fi
    done < "$LCOV_FILE"
    
    if [[ $total_lines -eq 0 ]]; then
        log_warning "No coverage data found"
        COVERAGE=0
    else
        COVERAGE=$(echo "scale=2; $covered_lines * 100 / $total_lines" | bc)
    fi
    
    echo ""
    echo "=============================================="
    echo "Coverage Summary"
    echo "=============================================="
    echo "Total lines:   $total_lines"
    echo "Covered lines: $covered_lines"
    echo "Coverage:      ${COVERAGE}%"
    echo "Threshold:     ${MIN_COVERAGE}%"
    echo "=============================================="
    echo ""
    
    # Check threshold
    if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
        log_warning "Coverage ($COVERAGE%) is below threshold ($MIN_COVERAGE%)"
        
        if [[ "$FAIL_BELOW_THRESHOLD" == "true" ]]; then
            return 1
        fi
    else
        log_success "Coverage meets threshold"
    fi
    
    return 0
}

# ==============================================================================
# Generate HTML Report
# ==============================================================================

generate_html_report() {
    if [[ "$GENERATE_HTML" != "true" ]]; then
        return 0
    fi
    
    log_info "Generating HTML report..."
    
    local html_dir="$COVERAGE_DIR/html"
    
    genhtml "$LCOV_FILE" \
        --output-directory "$html_dir" \
        --title "Flutter Coverage Report" \
        --legend \
        --show-details \
        --highlight \
        --branch-coverage
    
    log_success "HTML report generated: $html_dir/index.html"
    
    if [[ "$OPEN_REPORT" == "true" ]]; then
        if command -v open &> /dev/null; then
            open "$html_dir/index.html"
        elif command -v xdg-open &> /dev/null; then
            xdg-open "$html_dir/index.html"
        fi
    fi
}

# ==============================================================================
# Generate Badge
# ==============================================================================

generate_badge() {
    log_info "Generating coverage badge..."
    
    local color="red"
    if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
        color="brightgreen"
    elif (( $(echo "$COVERAGE >= 60" | bc -l) )); then
        color="yellow"
    elif (( $(echo "$COVERAGE >= 40" | bc -l) )); then
        color="orange"
    fi
    
    local badge_url="https://img.shields.io/badge/coverage-${COVERAGE}%25-${color}"
    echo "Badge URL: $badge_url"
    echo "$badge_url" > "$COVERAGE_DIR/badge-url.txt"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    check_dependencies
    run_tests
    filter_coverage
    
    local result=0
    calculate_coverage || result=$?
    
    generate_html_report
    generate_badge
    
    exit $result
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --min) MIN_COVERAGE="$2"; shift 2 ;;
        --no-html) GENERATE_HTML=false; shift ;;
        --open) OPEN_REPORT=true; shift ;;
        --no-fail) FAIL_BELOW_THRESHOLD=false; shift ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --min PERCENT   Minimum coverage threshold"
            echo "  --no-html       Skip HTML report generation"
            echo "  --open          Open report in browser"
            echo "  --no-fail       Don't fail if below threshold"
            exit 0
            ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

main
