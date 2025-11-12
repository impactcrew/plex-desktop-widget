#!/bin/bash
# Build script for NowPlaying for Plex (Universal Binary)
# Supports both Intel (x86_64) and Apple Silicon (arm64)

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="PlexWidget"
SCHEME="PlexWidget"
CONFIGURATION="Release"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_APP_NAME="NowPlaying for Plex.app"

echo "=========================================="
echo "Building NowPlaying for Plex"
echo "Universal Binary (Intel + Apple Silicon)"
echo "=========================================="
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build for Intel (x86_64)
echo ""
echo "Building for Intel (x86_64)..."
xcodebuild \
    -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -arch x86_64 \
    -derivedDataPath "$BUILD_DIR/DerivedData-x86_64" \
    ONLY_ACTIVE_ARCH=NO

# Build for Apple Silicon (arm64)
echo ""
echo "Building for Apple Silicon (arm64)..."
xcodebuild \
    -project "$PROJECT_DIR/$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -arch arm64 \
    -derivedDataPath "$BUILD_DIR/DerivedData-arm64" \
    ONLY_ACTIVE_ARCH=NO

# Create universal binary using lipo
echo ""
echo "Creating universal binary..."

APP_NAME="$PROJECT_NAME.app"
X86_APP="$BUILD_DIR/DerivedData-x86_64/Build/Products/$CONFIGURATION/$APP_NAME"
ARM_APP="$BUILD_DIR/DerivedData-arm64/Build/Products/$CONFIGURATION/$APP_NAME"
UNIVERSAL_APP="$BUILD_DIR/$OUTPUT_APP_NAME"

# Copy one architecture as base
cp -R "$ARM_APP" "$UNIVERSAL_APP"

# Find the executable
EXECUTABLE_PATH="Contents/MacOS/$PROJECT_NAME"

# Create universal binary
lipo -create \
    "$X86_APP/$EXECUTABLE_PATH" \
    "$ARM_APP/$EXECUTABLE_PATH" \
    -output "$UNIVERSAL_APP/$EXECUTABLE_PATH"

# Code sign the app with ad-hoc identity
# This is CRITICAL for network access when hardened runtime is enabled
echo ""
echo "Code signing universal binary..."
codesign -s - --deep --force --entitlements "$PROJECT_DIR/PlexWidget/PlexWidget.entitlements" "$UNIVERSAL_APP" 2>&1 | grep -v "^Warning" || true

# Verify the signature
echo ""
echo "Verifying code signature..."
if codesign -v "$UNIVERSAL_APP" 2>&1; then
    echo "Code signature verified successfully"
else
    echo "WARNING: Code signature verification failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Universal app location:"
echo "  $UNIVERSAL_APP"
echo ""
echo "Architectures:"
lipo -info "$UNIVERSAL_APP/$EXECUTABLE_PATH"
echo ""
echo "Code Signature:"
codesign -d -v "$UNIVERSAL_APP" 2>&1 | head -3
echo ""
echo "To install:"
echo "  cp -R '$UNIVERSAL_APP' /Applications/"
echo ""
