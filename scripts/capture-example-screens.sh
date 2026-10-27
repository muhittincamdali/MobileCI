#!/usr/bin/env bash
# Captures the README screenshots of the WorkflowCheck example app on an iPhone simulator.
#
# The script builds and installs the app, opens it on each sample workflow with
# `-sample <name>`, and takes a simulator screenshot in light and dark appearance with a fixed
# status bar. Nothing is drawn by hand: every image is the running app linting a workflow with
# MobileCIKit.
#
# Usage: scripts/capture-example-screens.sh [simulator name or UDID]
# Without an argument it uses the first available iPhone simulator. Output: docs/images/
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
device="${1:-}"
if [[ -z "$device" ]]; then
  device="$(xcrun simctl list devices available | grep -m1 -oE 'iPhone [^(]+' | sed 's/ *$//')"
fi
if [[ -z "$device" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

bundle_id="io.github.muhittincamdali.WorkflowCheck"
samples=(firstWorkflow generated)
output_dir="$repo_root/docs/images"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$output_dir"

echo "Building WorkflowCheck for '$device'"
destination="platform=iOS Simulator,name=$device"
if [[ "$device" =~ ^[0-9A-F-]{36}$ ]]; then
  destination="platform=iOS Simulator,id=$device"
fi
xcodebuild build \
  -project "$repo_root/Examples/WorkflowCheck/WorkflowCheck.xcodeproj" \
  -scheme WorkflowCheck \
  -destination "$destination" \
  -derivedDataPath "$build_dir" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet
app="$build_dir/Build/Products/Debug-iphonesimulator/WorkflowCheck.app"

xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b >/dev/null
xcrun simctl status_bar "$device" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3
xcrun simctl install "$device" "$app"

for appearance in light dark; do
  xcrun simctl ui "$device" appearance "$appearance"
  for sample in "${samples[@]}"; do
    xcrun simctl terminate "$device" "$bundle_id" 2>/dev/null || true
    xcrun simctl launch "$device" "$bundle_id" -sample "$sample" >/dev/null
    sleep 3
    file="$output_dir/example-$sample-$appearance.png"
    xcrun simctl io "$device" screenshot "$file" >/dev/null
    echo "wrote ${file#"$repo_root"/}"
  done
done
xcrun simctl status_bar "$device" clear
xcrun simctl ui "$device" appearance light
