#!/usr/bin/env bash
# Renders the terminal screenshots in docs/images/ from real runs of mobileci.
#
# It builds the tool, creates a small iOS app repository in a temporary folder (an Xcode
# project with a shared scheme, CocoaPods through Bundler, and the kind of first workflow many
# apps start with), runs detect, lint, init and version in it, and renders each command with
# its output through scripts/render-terminal.mjs. Nothing in the output is edited.
#
# Usage: scripts/capture-terminal.sh
# Needs: Swift, Node.js 24 and Google Chrome or Chromium (CHROME_PATH).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$repo_root/docs/images"
swift build --package-path "$repo_root" --configuration release --product mobileci >&2
mobileci="$repo_root/.build/release/mobileci"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
app="$work/Shop"
mkdir -p "$app/Shop.xcodeproj/xcshareddata/xcschemes" "$app/.github/workflows"

printf '// !$*UTF8*$!\n{\n\tobjects = {\n\t\tC1 /* Debug */ = {\n\t\t\tbuildSettings = {\n\t\t\t\tCURRENT_PROJECT_VERSION = 41;\n\t\t\t\tMARKETING_VERSION = 2.3.0;\n\t\t\t\tSDKROOT = iphoneos;\n\t\t\t};\n\t\t};\n\t\tC2 /* Release */ = {\n\t\t\tbuildSettings = {\n\t\t\t\tCURRENT_PROJECT_VERSION = 41;\n\t\t\t\tMARKETING_VERSION = 2.3.0;\n\t\t\t\tSDKROOT = iphoneos;\n\t\t\t};\n\t\t};\n\t};\n}\n' \
  > "$app/Shop.xcodeproj/project.pbxproj"
printf '<Scheme>\n  <TestAction>\n    <Testables>\n      <TestableReference skipped = "NO"/>\n    </Testables>\n  </TestAction>\n</Scheme>\n' \
  > "$app/Shop.xcodeproj/xcshareddata/xcschemes/Shop.xcscheme"
printf "platform :ios, '17.0'\ntarget 'Shop' do\n  pod 'Kingfisher'\nend\n" > "$app/Podfile"
printf "source 'https://rubygems.org'\ngem 'cocoapods', '~> 1.17'\n" > "$app/Gemfile"
cat > "$app/.github/workflows/ios.yml" <<'YAML'
name: iOS
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: pod install
      - name: Test
        run: |
          xcodebuild test -workspace Shop.xcworkspace -scheme Shop \
            -destination 'platform=iOS Simulator,name=iPhone 17' | xcbeautify
      - name: Greet
        run: echo "Building ${{ github.head_ref }}"
YAML

# capture <image name> <arguments for mobileci>
capture() {
  local name="$1"
  shift
  local session="$work/$name.txt"
  echo "mobileci $*" > "$session"
  (cd "$app" && "$mobileci" "$@" >> "$session" 2>&1) || true
  node "$repo_root/scripts/render-terminal.mjs" "$session" "$output_dir/terminal-$name"
}

capture detect detect
capture lint lint
mv "$app/.github/workflows/ios.yml" "$work/first-ios.yml"
capture init init
capture lint-generated lint
capture version version bump patch --build
