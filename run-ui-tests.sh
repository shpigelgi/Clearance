#!/bin/bash
# Run the Clearance adversarial XCUITest suite.
#
# DerivedData is kept OUTSIDE the project (which lives under ~/Documents) so the
# test runner does not trigger the macOS "would like to access your Documents
# folder" TCC prompt on every run. Screenshots/results land in .qa-ui-review.
set -euo pipefail

cd "$(dirname "$0")"

DERIVED_DATA="${TMPDIR%/}/ClearanceUITests-DerivedData"
RESULTS=".qa-ui-review/results.xcresult"

rm -rf "$RESULTS"
mkdir -p .qa-ui-review

xcodebuild test \
  -project Clearance.xcodeproj \
  -scheme ClearanceUITests \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULTS" "$@"

echo
echo "Result bundle: $RESULTS"
echo "Export screenshots with:"
echo "  xcrun xcresulttool export attachments --path $RESULTS --output-path .qa-ui-review/attachments"
