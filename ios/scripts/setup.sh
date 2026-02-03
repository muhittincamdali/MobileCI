#!/bin/bash

# iOS Project Setup Script
# Prepares development environment for iOS projects
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUBY_VERSION="${RUBY_VERSION:-3.2.0}"
XCODE_VERSION="${XCODE_VERSION:-15.2}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

preflight_checks() {
    log_info "Running pre-flight checks..."
    
    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script requires macOS"
    fi
    
    # Check Xcode
    if ! check_command xcodebuild; then
        log_error "Xcode is not installed. Please install Xcode from the App Store."
    fi
    
    INSTALLED_XCODE=$(xcodebuild -version | head -1 | cut -d' ' -f2)
    log_info "Xcode version: $INSTALLED_XCODE"
    
    # Check Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log_warning "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_info "Please complete the installation and run this script again."
        exit 0
    fi
    
    log_success "Pre-flight checks passed"
}

# ==============================================================================
# Install Homebrew
# ==============================================================================

install_homebrew() {
    if check_command brew; then
        log_info "Homebrew already installed"
        log_info "Updating Homebrew..."
        brew update
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# ==============================================================================
# Install Dependencies
# ==============================================================================

install_dependencies() {
    log_info "Installing dependencies..."
    
    # Core tools
    local tools=(
        "swiftlint"
        "swiftformat"
        "xcbeautify"
        "mint"
    )
    
    for tool in "${tools[@]}"; do
        if check_command "$tool"; then
            log_info "$tool already installed"
        else
            log_info "Installing $tool..."
            brew install "$tool" || log_warning "Failed to install $tool"
        fi
    done
    
    # Optional tools
    if [[ "${INSTALL_OPTIONAL:-false}" == "true" ]]; then
        local optional_tools=(
            "periphery"
            "xcodegen"
            "sourcery"
            "swift-snapshot-testing"
        )
        
        for tool in "${optional_tools[@]}"; do
            if ! check_command "$tool"; then
                log_info "Installing optional tool: $tool..."
                brew install "$tool" 2>/dev/null || true
            fi
        done
    fi
    
    log_success "Dependencies installed"
}

# ==============================================================================
# Setup Ruby Environment
# ==============================================================================

setup_ruby() {
    log_info "Setting up Ruby environment..."
    
    # Check for rbenv or use system Ruby
    if check_command rbenv; then
        log_info "Using rbenv..."
        
        # Install Ruby version if not present
        if ! rbenv versions | grep -q "$RUBY_VERSION"; then
            log_info "Installing Ruby $RUBY_VERSION..."
            rbenv install "$RUBY_VERSION"
        fi
        
        rbenv local "$RUBY_VERSION"
        eval "$(rbenv init -)"
    else
        log_warning "rbenv not found, using system Ruby"
    fi
    
    # Install Bundler
    if ! gem list bundler -i &> /dev/null; then
        log_info "Installing Bundler..."
        gem install bundler --no-document
    fi
    
    log_success "Ruby environment ready"
}

# ==============================================================================
# Install Ruby Dependencies
# ==============================================================================

install_ruby_deps() {
    log_info "Installing Ruby dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "Gemfile" ]]; then
        bundle config set --local path 'vendor/bundle'
        bundle install --jobs 4 --retry 3
        log_success "Ruby dependencies installed"
    else
        log_warning "No Gemfile found, skipping Ruby dependencies"
    fi
}

# ==============================================================================
# Install CocoaPods Dependencies
# ==============================================================================

install_cocoapods() {
    log_info "Installing CocoaPods dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "Podfile" ]]; then
        if [[ -f "Gemfile" ]]; then
            bundle exec pod install --repo-update
        else
            pod install --repo-update
        fi
        log_success "CocoaPods dependencies installed"
    else
        log_warning "No Podfile found, skipping CocoaPods"
    fi
}

# ==============================================================================
# Setup Git Hooks
# ==============================================================================

setup_git_hooks() {
    log_info "Setting up Git hooks..."
    
    HOOKS_DIR="$PROJECT_ROOT/.githooks"
    GIT_HOOKS="$PROJECT_ROOT/.git/hooks"
    
    if [[ -d "$HOOKS_DIR" ]]; then
        # Copy hooks
        cp -r "$HOOKS_DIR/"* "$GIT_HOOKS/" 2>/dev/null || true
        
        # Make executable
        chmod +x "$GIT_HOOKS/"* 2>/dev/null || true
        
        log_success "Git hooks installed"
    else
        # Create default pre-commit hook
        cat > "$GIT_HOOKS/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook: Run SwiftLint

if command -v swiftlint &> /dev/null; then
    swiftlint --strict
fi
EOF
        chmod +x "$GIT_HOOKS/pre-commit"
        log_info "Created default pre-commit hook"
    fi
}

# ==============================================================================
# Setup Match (Code Signing)
# ==============================================================================

setup_match() {
    log_info "Setting up code signing..."
    
    if [[ -f "$PROJECT_ROOT/fastlane/Matchfile" ]]; then
        if [[ -n "${MATCH_PASSWORD:-}" ]]; then
            log_info "Syncing certificates with match..."
            bundle exec fastlane match development --readonly
            log_success "Certificates synced"
        else
            log_warning "MATCH_PASSWORD not set, skipping certificate sync"
            log_info "Run 'fastlane match development' manually to sync certificates"
        fi
    else
        log_info "No Matchfile found, skipping match setup"
    fi
}

# ==============================================================================
# Verify Setup
# ==============================================================================

verify_setup() {
    log_info "Verifying setup..."
    
    local success=true
    
    # Check Xcode project/workspace
    if ls "$PROJECT_ROOT"/*.xcworkspace &> /dev/null; then
        log_success "Xcode workspace found"
    elif ls "$PROJECT_ROOT"/*.xcodeproj &> /dev/null; then
        log_success "Xcode project found"
    else
        log_warning "No Xcode project/workspace found"
        success=false
    fi
    
    # Check dependencies
    if [[ -d "$PROJECT_ROOT/Pods" ]]; then
        log_success "CocoaPods dependencies installed"
    fi
    
    # Try building
    if [[ "${VERIFY_BUILD:-false}" == "true" ]]; then
        log_info "Attempting test build..."
        if xcodebuild build -scheme App -destination 'platform=iOS Simulator,name=iPhone 15' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO &> /dev/null; then
            log_success "Test build succeeded"
        else
            log_warning "Test build failed (this may be expected for initial setup)"
        fi
    fi
    
    if [[ "$success" == "true" ]]; then
        log_success "Setup verification complete"
    else
        log_warning "Setup completed with warnings"
    fi
}

# ==============================================================================
# Print Summary
# ==============================================================================

print_summary() {
    echo ""
    echo "=============================================="
    echo -e "${GREEN}Setup Complete!${NC}"
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "  1. Open the Xcode workspace"
    echo "  2. Select a development team in Signing & Capabilities"
    echo "  3. Build and run the project"
    echo ""
    echo "Available commands:"
    echo "  bundle exec fastlane test     - Run tests"
    echo "  bundle exec fastlane beta     - Deploy to TestFlight"
    echo "  swiftlint                     - Lint code"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    echo "=============================================="
    echo "iOS Project Setup"
    echo "=============================================="
    echo ""
    
    preflight_checks
    install_homebrew
    install_dependencies
    setup_ruby
    install_ruby_deps
    install_cocoapods
    setup_git_hooks
    setup_match
    verify_setup
    print_summary
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --optional)
            INSTALL_OPTIONAL=true
            shift
            ;;
        --verify-build)
            VERIFY_BUILD=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --optional      Install optional tools"
            echo "  --verify-build  Run a test build after setup"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            ;;
    esac
done

main
