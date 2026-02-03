#!/bin/bash

# Changelog Generation Script
# Generates changelogs from git commits using conventional commits
# Version: 2.0.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"

# Output settings
OUTPUT_FILE="${OUTPUT_FILE:-CHANGELOG.md}"
FORMAT="${FORMAT:-markdown}"
SINCE="${SINCE:-}"
UNTIL="${UNTIL:-HEAD}"

# Filtering
INCLUDE_BREAKING="${INCLUDE_BREAKING:-true}"
INCLUDE_FEATURES="${INCLUDE_FEATURES:-true}"
INCLUDE_FIXES="${INCLUDE_FIXES:-true}"
INCLUDE_DOCS="${INCLUDE_DOCS:-false}"
INCLUDE_CHORES="${INCLUDE_CHORES:-false}"

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
# Get Version Info
# ==============================================================================

get_latest_tag() {
    git describe --tags --abbrev=0 2>/dev/null || echo ""
}

get_version() {
    local tag
    tag=$(get_latest_tag)
    
    if [[ -n "$tag" ]]; then
        echo "${tag#v}"
    else
        # Try to get from package.json or pubspec
        if [[ -f "package.json" ]]; then
            grep '"version"' package.json | head -1 | sed 's/.*": "\([^"]*\)".*/\1/'
        elif [[ -f "pubspec.yaml" ]]; then
            grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f1
        else
            echo "0.0.0"
        fi
    fi
}

# ==============================================================================
# Parse Commits
# ==============================================================================

parse_commit() {
    local message="$1"
    local type=""
    local scope=""
    local subject=""
    local breaking=false
    
    # Check for conventional commit format: type(scope): subject
    if [[ "$message" =~ ^([a-z]+)(\([^)]+\))?!?:\ (.+)$ ]]; then
        type="${BASH_REMATCH[1]}"
        scope="${BASH_REMATCH[2]}"
        subject="${BASH_REMATCH[3]}"
        
        # Remove parentheses from scope
        scope="${scope#(}"
        scope="${scope%)}"
        
        # Check for breaking change indicator
        if [[ "$message" =~ ^[a-z]+(\([^)]+\))?!: ]]; then
            breaking=true
        fi
    else
        # Not a conventional commit, treat as misc
        type="misc"
        subject="$message"
    fi
    
    echo "$type|$scope|$subject|$breaking"
}

# ==============================================================================
# Generate Changelog
# ==============================================================================

generate_changelog() {
    local since="$1"
    local until="$2"
    
    cd "$PROJECT_ROOT"
    
    # Build git log command
    local range=""
    if [[ -n "$since" ]]; then
        range="${since}..${until}"
    else
        range="$until"
    fi
    
    # Get commits
    local commits
    commits=$(git log "$range" --pretty=format:"%H|%s|%an|%ad" --date=short 2>/dev/null || echo "")
    
    if [[ -z "$commits" ]]; then
        log_warning "No commits found"
        return 1
    fi
    
    # Categorize commits
    local breaking_changes=()
    local features=()
    local fixes=()
    local docs=()
    local chores=()
    local others=()
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        local hash message author date
        IFS='|' read -r hash message author date <<< "$line"
        
        local parsed
        parsed=$(parse_commit "$message")
        
        local type scope subject is_breaking
        IFS='|' read -r type scope subject is_breaking <<< "$parsed"
        
        local entry
        if [[ -n "$scope" ]]; then
            entry="**$scope:** $subject"
        else
            entry="$subject"
        fi
        
        # Add commit hash link
        entry="$entry ([${hash:0:7}](../../commit/$hash))"
        
        # Categorize
        if [[ "$is_breaking" == "true" ]]; then
            breaking_changes+=("$entry")
        fi
        
        case "$type" in
            feat|feature)
                features+=("$entry")
                ;;
            fix|bugfix)
                fixes+=("$entry")
                ;;
            docs|doc)
                docs+=("$entry")
                ;;
            chore|build|ci)
                chores+=("$entry")
                ;;
            *)
                others+=("$entry")
                ;;
        esac
        
    done <<< "$commits"
    
    # Generate output
    local version
    version=$(get_version)
    local date
    date=$(date +%Y-%m-%d)
    
    {
        echo "## [$version] - $date"
        echo ""
        
        if [[ "$INCLUDE_BREAKING" == "true" ]] && [[ ${#breaking_changes[@]} -gt 0 ]]; then
            echo "### BREAKING CHANGES"
            echo ""
            for item in "${breaking_changes[@]}"; do
                echo "- $item"
            done
            echo ""
        fi
        
        if [[ "$INCLUDE_FEATURES" == "true" ]] && [[ ${#features[@]} -gt 0 ]]; then
            echo "### Features"
            echo ""
            for item in "${features[@]}"; do
                echo "- $item"
            done
            echo ""
        fi
        
        if [[ "$INCLUDE_FIXES" == "true" ]] && [[ ${#fixes[@]} -gt 0 ]]; then
            echo "### Bug Fixes"
            echo ""
            for item in "${fixes[@]}"; do
                echo "- $item"
            done
            echo ""
        fi
        
        if [[ "$INCLUDE_DOCS" == "true" ]] && [[ ${#docs[@]} -gt 0 ]]; then
            echo "### Documentation"
            echo ""
            for item in "${docs[@]}"; do
                echo "- $item"
            done
            echo ""
        fi
        
        if [[ "$INCLUDE_CHORES" == "true" ]] && [[ ${#chores[@]} -gt 0 ]]; then
            echo "### Maintenance"
            echo ""
            for item in "${chores[@]}"; do
                echo "- $item"
            done
            echo ""
        fi
    }
}

# ==============================================================================
# Update Changelog File
# ==============================================================================

update_changelog_file() {
    local content="$1"
    local file="$PROJECT_ROOT/$OUTPUT_FILE"
    
    if [[ -f "$file" ]]; then
        # Insert after header
        local header="# Changelog"
        local temp_file
        temp_file=$(mktemp)
        
        {
            echo "$header"
            echo ""
            echo "All notable changes to this project will be documented in this file."
            echo ""
            echo "$content"
            
            # Append existing content (skip header)
            tail -n +6 "$file" 2>/dev/null || true
        } > "$temp_file"
        
        mv "$temp_file" "$file"
    else
        # Create new file
        {
            echo "# Changelog"
            echo ""
            echo "All notable changes to this project will be documented in this file."
            echo ""
            echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
            echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
            echo ""
            echo "$content"
        } > "$file"
    fi
    
    log_success "Updated $OUTPUT_FILE"
}

# ==============================================================================
# Generate Release Notes
# ==============================================================================

generate_release_notes() {
    local since="$1"
    local until="$2"
    
    cd "$PROJECT_ROOT"
    
    local range=""
    if [[ -n "$since" ]]; then
        range="${since}..${until}"
    else
        # Get last 20 commits
        range="-20"
    fi
    
    echo "### What's Changed"
    echo ""
    
    git log $range --pretty=format:"- %s by @%an" --no-merges 2>/dev/null | head -20
    
    echo ""
    echo ""
    echo "**Full Changelog**: https://github.com/\${GITHUB_REPOSITORY}/compare/${since}...${until}"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log_info "Generating changelog..."
    
    cd "$PROJECT_ROOT"
    
    # Determine range
    local since="$SINCE"
    if [[ -z "$since" ]]; then
        since=$(get_latest_tag)
    fi
    
    log_info "Range: ${since:-beginning}..${UNTIL}"
    
    case "$FORMAT" in
        markdown)
            local content
            content=$(generate_changelog "$since" "$UNTIL")
            
            if [[ -n "$content" ]]; then
                if [[ "$OUTPUT_FILE" == "-" ]]; then
                    echo "$content"
                else
                    update_changelog_file "$content"
                fi
            fi
            ;;
        release-notes)
            generate_release_notes "$since" "$UNTIL"
            ;;
        json)
            # JSON output for automation
            log_error "JSON format not yet implemented"
            ;;
        *)
            log_error "Unknown format: $FORMAT"
            ;;
    esac
    
    log_success "Changelog generated"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output|-o) OUTPUT_FILE="$2"; shift 2 ;;
        --format|-f) FORMAT="$2"; shift 2 ;;
        --since|-s) SINCE="$2"; shift 2 ;;
        --until|-u) UNTIL="$2"; shift 2 ;;
        --include-all)
            INCLUDE_DOCS="true"
            INCLUDE_CHORES="true"
            shift
            ;;
        --release-notes)
            FORMAT="release-notes"
            OUTPUT_FILE="-"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --output, -o FILE    Output file (default: CHANGELOG.md)"
            echo "  --format, -f FORMAT  Output format (markdown, release-notes)"
            echo "  --since, -s REF      Start reference (tag or commit)"
            echo "  --until, -u REF      End reference (default: HEAD)"
            echo "  --include-all        Include docs and chores"
            echo "  --release-notes      Generate release notes to stdout"
            exit 0
            ;;
        *) log_error "Unknown option: $1" ;;
    esac
done

main
