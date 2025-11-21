#!/bin/bash

set -e

echo "Building MovieLog..."

# Build the executable
swift build -c release

# Create app bundle structure
APP_NAME="MovieLog"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "Creating app bundle structure..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS}"
mkdir -p "${RESOURCES}"

# Copy the executable
echo "Copying executable..."
cp ".build/release/${APP_NAME}" "${MACOS}/"

# Copy Info.plist
echo "Copying Info.plist..."
cp "Info.plist" "${CONTENTS}/"

# Make executable
chmod +x "${MACOS}/${APP_NAME}"

echo "✅ App bundle created successfully: ${APP_BUNDLE}"
echo ""
echo "To run the app:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To install to Applications:"
echo "  cp -r ${APP_BUNDLE} /Applications/"
