#!/bin/bash
# Generate an Xcode project from the Swift source files
# Requires: Xcode and xcodegen (brew install xcodegen)
#
# Usage: ./create-xcode-project.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Check for xcodegen
if command -v xcodegen &>/dev/null; then
    echo "Using xcodegen to generate Xcode project..."
    xcodegen generate
    echo "Done! Open Cleam.xcodeproj in Xcode."
else
    echo "xcodegen not found. You can:"
    echo ""
    echo "  Option 1: Install xcodegen and run this script again"
    echo "    brew install xcodegen"
    echo "    ./create-xcode-project.sh"
    echo ""
    echo "  Option 2: Open as Swift Package in Xcode"
    echo "    open Package.swift"
    echo ""
    echo "  Option 3: Create Xcode project manually"
    echo "    1. Open Xcode → File → New → Project"
    echo "    2. Choose macOS → App"
    echo "    3. Set Product Name: Cleam, Interface: SwiftUI, Language: Swift"
    echo "    4. Uncheck 'Use Core Data' and 'Include Tests'"
    echo "    5. Delete the auto-generated files"
    echo "    6. Drag the Cleam/ folder into the project navigator"
    echo "    7. Set deployment target to macOS 13.0"
    echo "    8. Disable App Sandbox in Signing & Capabilities"
    echo "    9. Add Cleam.entitlements from Resources/"
    echo ""
    exit 1
fi
