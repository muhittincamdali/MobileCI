#!/usr/bin/env bash
# Writes every workflow in this repository that `mobileci init` produces:
#
#   Templates/*.yml                      one per project kind, from small fixture projects built
#                                        in a temporary folder
#   .github/workflows/examples.yml       for Examples/WorkflowCheck (runs on every push)
#   .github/workflows/example-flutter.yml for Examples/flutter_sample (runs on every push)
#
# With --check nothing is written: the script fails when a committed file differs from what the
# generator writes now, so a generator change cannot land without its templates.
#
# Usage: scripts/generate-workflows.sh [--check] [path to a built mobileci]
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
check=false
if [[ "${1:-}" == "--check" ]]; then
  check=true
  shift
fi
mobileci="${1:-}"
if [[ -z "$mobileci" ]]; then
  swift build --package-path "$repo_root" --configuration release --product mobileci >&2
  mobileci="$repo_root/.build/release/mobileci"
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
differences=0

# emit <file relative to the repository> <arguments for mobileci init>
emit() {
  local destination="$1"
  shift
  "$mobileci" init --stdout --branch main "$@" > "$work/output.yml"
  if [[ "$check" == true ]]; then
    if ! diff -u "$repo_root/$destination" "$work/output.yml"; then
      echo "::error file=$destination::$destination is not what mobileci init writes; run scripts/generate-workflows.sh" >&2
      differences=$((differences + 1))
    fi
  else
    mkdir -p "$(dirname "$repo_root/$destination")"
    cp "$work/output.yml" "$repo_root/$destination"
    echo "wrote $destination"
  fi
}

# xcode_project <folder> <name> <SDKROOT> <tests: yes|no> [remote-package]
xcode_project() {
  local project="$1/$2.xcodeproj"
  mkdir -p "$project/xcshareddata/xcschemes"
  {
    printf '// !$*UTF8*$!\n{\n\tobjects = {\n'
    if [[ "${5:-}" == "remote-package" ]]; then
      printf '\t\tP1 /* XCRemoteSwiftPackageReference */ = {isa = XCRemoteSwiftPackageReference;};\n'
    fi
    printf '\t\tC1 /* Debug */ = {\n\t\t\tbuildSettings = {\n\t\t\t\tSDKROOT = %s;\n\t\t\t};\n\t\t};\n\t};\n}\n' "$3"
  } > "$project/project.pbxproj"
  if [[ "$4" == "yes" ]]; then
    printf '<Scheme>\n  <TestAction>\n    <Testables>\n      <TestableReference skipped = "NO"/>\n    </Testables>\n  </TestAction>\n</Scheme>\n'
  else
    printf '<Scheme>\n  <TestAction>\n  </TestAction>\n</Scheme>\n'
  fi > "$project/xcshareddata/xcschemes/$2.xcscheme"
}

fixture() {
  mkdir -p "$work/$1"
  echo "$work/$1"
}

dir="$(fixture ios)"
xcode_project "$dir" App iphoneos yes remote-package
emit Templates/ios.yml "$dir"

dir="$(fixture ios-cocoapods)"
xcode_project "$dir" App iphoneos yes
printf "platform :ios, '17.0'\n" > "$dir/Podfile"
printf "source 'https://rubygems.org'\ngem 'cocoapods', '~> 1.17'\n" > "$dir/Gemfile"
emit Templates/ios-cocoapods.yml "$dir"

dir="$(fixture macos)"
xcode_project "$dir" MacApp macosx yes
emit Templates/macos.yml "$dir"

dir="$(fixture swift-package)"
printf '// swift-tools-version: 6.2\nimport PackageDescription\n\nlet package = Package(name: "Kit")\n' > "$dir/Package.swift"
mkdir -p "$dir/Tests"
emit Templates/swift-package.yml "$dir"

dir="$(fixture flutter)"
printf 'name: app\nversion: 1.0.0+1\nenvironment:\n  sdk: ^3.13.0\n  flutter: 3.47.8\ndependencies:\n  flutter:\n    sdk: flutter\n' > "$dir/pubspec.yaml"
mkdir -p "$dir/android" "$dir/ios" "$dir/test"
emit Templates/flutter.yml "$dir"

dir="$(fixture react-native)"
printf '{"name": "App", "scripts": {"lint": "eslint .", "typecheck": "tsc", "test": "jest"},\n "dependencies": {"react-native": "0.87.0"}}\n' > "$dir/package.json"
printf '{}\n' > "$dir/package-lock.json"
printf '24\n' > "$dir/.nvmrc"
printf "source 'https://rubygems.org'\ngem 'cocoapods', '~> 1.17'\n" > "$dir/Gemfile"
mkdir -p "$dir/android/app" "$dir/ios"
xcode_project "$dir/ios" App iphoneos no
printf "platform :ios, '17.0'\n" > "$dir/ios/Podfile"
emit Templates/react-native.yml "$dir"

dir="$(fixture expo)"
printf '{"name": "app", "scripts": {"lint": "expo lint", "test": "jest"},\n "dependencies": {"expo": "~57.0.0", "react-native": "0.87.0"}}\n' > "$dir/package.json"
printf '{}\n' > "$dir/package-lock.json"
emit Templates/expo.yml "$dir"

emit .github/workflows/examples.yml "$repo_root" --project Examples/WorkflowCheck --file examples.yml
emit .github/workflows/example-flutter.yml "$repo_root" --project Examples/flutter_sample --file example-flutter.yml

if [[ "$differences" -gt 0 ]]; then
  echo "$differences generated workflow(s) differ from the committed files." >&2
  exit 1
fi
