#!/bin/bash

# Flutter Build Runner Script
# Manages code generation with build_runner
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
WATCH_MODE=false
DELETE_CONFLICTING=true
VERBOSE=false

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ==============================================================================
# Check Dependencies
# ==============================================================================

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found. Please install Flutter."
    fi
    
    # Check for build_runner in pubspec
    if ! grep -q "build_runner" "$PROJECT_ROOT/pubspec.yaml"; then
        log_error "build_runner not found in pubspec.yaml"
    fi
    
    log_success "Dependencies OK"
}

# ==============================================================================
# Clean Generated Files
# ==============================================================================

clean_generated() {
    log_info "Cleaning generated files..."
    
    # Find and delete generated files
    find "$PROJECT_ROOT/lib" -name "*.g.dart" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT/lib" -name "*.freezed.dart" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT/lib" -name "*.mocks.dart" -type f -delete 2>/dev/null || true
    find "$PROJECT_ROOT/test" -name "*.mocks.dart" -type f -delete 2>/dev/null || true
    
    # Clean build_runner cache
    rm -rf "$PROJECT_ROOT/.dart_tool/build" 2>/dev/null || true
    
    log_success "Generated files cleaned"
}

# ==============================================================================
# Run Build Runner
# ==============================================================================

run_build_runner() {
    log_info "Running build_runner..."
    
    cd "$PROJECT_ROOT"
    
    # Build arguments
    local args=("build")
    
    if [[ "$DELETE_CONFLICTING" == "true" ]]; then
        args+=("--delete-conflicting-outputs")
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        args+=("--verbose")
    fi
    
    # Run build_runner
    flutter pub run build_runner "${args[@]}"
    
    log_success "Code generation complete"
}

# ==============================================================================
# Watch Mode
# ==============================================================================

run_watch() {
    log_info "Starting build_runner in watch mode..."
    
    cd "$PROJECT_ROOT"
    
    local args=("watch")
    
    if [[ "$DELETE_CONFLICTING" == "true" ]]; then
        args+=("--delete-conflicting-outputs")
    fi
    
    flutter pub run build_runner "${args[@]}"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    check_dependencies
    
    if [[ "$WATCH_MODE" == "true" ]]; then
        run_watch
    else
        run_build_runner
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --watch|-w) WATCH_MODE=true; shift ;;
        --clean|-c) clean_generated; shift ;;
        --verbose|-v) VERBOSE=true; shift ;;
        --no-delete) DELETE_CONFLICTING=false; shift ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --watch, -w     Run in watch mode"
            echo "  --clean, -c     Clean generated files"
            echo "  --verbose, -v   Verbose output"
            echo "  --no-delete     Don't delete conflicting outputs"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
