#!/bin/bash

# React Native Project Setup Script
# Prepares development environment for React Native projects
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NODE_VERSION="${NODE_VERSION:-20}"
RUBY_VERSION="${RUBY_VERSION:-3.2.0}"

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

check_command() {
    command -v "$1" &> /dev/null
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

preflight_checks() {
    log_info "Running pre-flight checks..."
    
    # Check operating system
    OS="$(uname)"
    log_info "Operating system: $OS"
    
    # Check for Node.js
    if ! check_command node; then
        log_error "Node.js is not installed. Please install Node.js $NODE_VERSION or higher."
    fi
    
    NODE_INSTALLED=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [[ "$NODE_INSTALLED" -lt "${NODE_VERSION%%.*}" ]]; then
        log_warning "Node.js version $NODE_INSTALLED is older than recommended ($NODE_VERSION)"
    fi
    
    # Check for package manager
    if check_command yarn; then
        PKG_MANAGER="yarn"
    elif check_command npm; then
        PKG_MANAGER="npm"
    else
        log_error "No package manager found. Please install yarn or npm."
    fi
    log_info "Using package manager: $PKG_MANAGER"
    
    # Check for Watchman (recommended)
    if ! check_command watchman; then
        log_warning "Watchman is not installed. It's recommended for better performance."
        log_info "Install with: brew install watchman (macOS)"
    fi
    
    log_success "Pre-flight checks passed"
}

# ==============================================================================
# Install Dependencies
# ==============================================================================

install_dependencies() {
    log_info "Installing dependencies..."
    
    cd "$PROJECT_ROOT"
    
    if [[ "$PKG_MANAGER" == "yarn" ]]; then
        yarn install --frozen-lockfile
    else
        npm ci
    fi
    
    log_success "Dependencies installed"
}

# ==============================================================================
# Setup iOS (macOS only)
# ==============================================================================

setup_ios() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_info "Skipping iOS setup (not on macOS)"
        return 0
    fi
    
    log_info "Setting up iOS..."
    
    # Check for Xcode
    if ! check_command xcodebuild; then
        log_error "Xcode is not installed. Please install Xcode from the App Store."
    fi
    
    log_info "Xcode version: $(xcodebuild -version | head -1)"
    
    # Check Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_info "Please complete the installation and run this script again."
        exit 0
    fi
    
    # Setup Ruby
    if check_command rbenv; then
        log_info "Setting up Ruby with rbenv..."
        cd "$PROJECT_ROOT/ios"
        
        if [[ -f ".ruby-version" ]]; then
            rbenv install -s
            rbenv local $(cat .ruby-version)
        fi
    fi
    
    # Install Bundler and gems
    if [[ -f "$PROJECT_ROOT/ios/Gemfile" ]]; then
        log_info "Installing Ruby gems..."
        cd "$PROJECT_ROOT/ios"
        
        if ! check_command bundle; then
            gem install bundler --no-document
        fi
        
        bundle install
    fi
    
    # Install CocoaPods dependencies
    if [[ -f "$PROJECT_ROOT/ios/Podfile" ]]; then
        log_info "Installing CocoaPods dependencies..."
        cd "$PROJECT_ROOT/ios"
        
        if [[ -f "Gemfile" ]]; then
            bundle exec pod install
        else
            pod install
        fi
    fi
    
    log_success "iOS setup complete"
}

# ==============================================================================
# Setup Android
# ==============================================================================

setup_android() {
    log_info "Setting up Android..."
    
    # Check for ANDROID_HOME
    if [[ -z "${ANDROID_HOME:-}" ]]; then
        # Try common locations
        if [[ -d "$HOME/Library/Android/sdk" ]]; then
            export ANDROID_HOME="$HOME/Library/Android/sdk"
        elif [[ -d "$HOME/Android/Sdk" ]]; then
            export ANDROID_HOME="$HOME/Android/Sdk"
        else
            log_warning "ANDROID_HOME not set. Android builds may fail."
            log_info "Please set ANDROID_HOME to your Android SDK location."
            return 0
        fi
    fi
    
    log_info "ANDROID_HOME: $ANDROID_HOME"
    
    # Check for Java
    if ! check_command java; then
        log_warning "Java not found. Please install JDK 17 or higher."
    else
        JAVA_VERSION=$(java -version 2>&1 | head -1)
        log_info "Java version: $JAVA_VERSION"
    fi
    
    # Accept Android SDK licenses
    if [[ -f "$ANDROID_HOME/tools/bin/sdkmanager" ]]; then
        log_info "Accepting Android SDK licenses..."
        yes | "$ANDROID_HOME/tools/bin/sdkmanager" --licenses > /dev/null 2>&1 || true
    fi
    
    log_success "Android setup complete"
}

# ==============================================================================
# Setup Git Hooks
# ==============================================================================

setup_git_hooks() {
    log_info "Setting up Git hooks..."
    
    cd "$PROJECT_ROOT"
    
    # Check for husky
    if [[ -f "package.json" ]] && grep -q '"husky"' package.json; then
        log_info "Husky detected, running prepare..."
        if [[ "$PKG_MANAGER" == "yarn" ]]; then
            yarn husky install 2>/dev/null || true
        else
            npm run prepare 2>/dev/null || true
        fi
    else
        # Create basic pre-commit hook
        local hook_file="$PROJECT_ROOT/.git/hooks/pre-commit"
        
        cat > "$hook_file" << 'EOF'
#!/bin/bash
# Pre-commit hook: Run lint and type check

echo "Running pre-commit checks..."

# Run ESLint
yarn lint --quiet || exit 1

# Run TypeScript check
yarn tsc --noEmit || exit 1

echo "Pre-commit checks passed!"
EOF
        
        chmod +x "$hook_file"
        log_info "Created pre-commit hook"
    fi
    
    log_success "Git hooks setup complete"
}

# ==============================================================================
# Setup Environment
# ==============================================================================

setup_environment() {
    log_info "Setting up environment..."
    
    cd "$PROJECT_ROOT"
    
    # Copy example env file if exists
    if [[ -f ".env.example" ]] && [[ ! -f ".env" ]]; then
        cp .env.example .env
        log_info "Created .env from .env.example"
    fi
    
    # Generate native projects for Expo (if applicable)
    if [[ -f "app.json" ]] && grep -q '"expo"' app.json; then
        if [[ ! -d "ios" ]] || [[ ! -d "android" ]]; then
            log_info "Expo project detected. Generating native projects..."
            npx expo prebuild --no-install 2>/dev/null || true
        fi
    fi
    
    log_success "Environment setup complete"
}

# ==============================================================================
# Verify Setup
# ==============================================================================

verify_setup() {
    log_info "Verifying setup..."
    
    cd "$PROJECT_ROOT"
    
    local success=true
    
    # Check node_modules
    if [[ -d "node_modules" ]]; then
        log_success "node_modules installed"
    else
        log_error "node_modules not found"
        success=false
    fi
    
    # Check iOS (if on macOS)
    if [[ "$(uname)" == "Darwin" ]] && [[ -d "ios" ]]; then
        if [[ -d "ios/Pods" ]]; then
            log_success "iOS Pods installed"
        else
            log_warning "iOS Pods not installed"
            success=false
        fi
    fi
    
    # Try building Metro bundler
    log_info "Testing Metro bundler..."
    if timeout 10 npx react-native start --reset-cache &> /dev/null & then
        sleep 3
        pkill -f "react-native start" 2>/dev/null || true
        log_success "Metro bundler works"
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
    echo "  1. Start the Metro bundler: yarn start"
    echo "  2. Run on iOS: yarn ios"
    echo "  3. Run on Android: yarn android"
    echo ""
    echo "Available commands:"
    echo "  yarn start      - Start Metro bundler"
    echo "  yarn ios        - Run on iOS simulator"
    echo "  yarn android    - Run on Android emulator"
    echo "  yarn test       - Run tests"
    echo "  yarn lint       - Run ESLint"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    echo "=============================================="
    echo "React Native Project Setup"
    echo "=============================================="
    echo ""
    
    preflight_checks
    install_dependencies
    setup_environment
    setup_ios
    setup_android
    setup_git_hooks
    verify_setup
    print_summary
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ios)
            setup_ios() { log_info "Skipping iOS setup"; }
            shift
            ;;
        --skip-android)
            setup_android() { log_info "Skipping Android setup"; }
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-ios      Skip iOS setup"
            echo "  --skip-android  Skip Android setup"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            ;;
    esac
done

main
