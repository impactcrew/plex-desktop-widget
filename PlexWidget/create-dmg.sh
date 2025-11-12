#!/bin/bash
set -e

# Ignore errors when ejecting old disks (they may not exist or be busy)
set +e
hdiutil detach /dev/disk4 -force 2>/dev/null
set -e

APP_NAME="NowPlaying for Plex"
DMG_NAME="NowPlaying-for-Plex"
SOURCE_APP="build/NowPlaying for Plex.app"
DMG_DIR="dmg_temp"
BG_IMAGE="dmg_background.png"

echo "Creating professional DMG installer..."

# Clean up
rm -rf "$DMG_DIR"
rm -f "${DMG_NAME}.dmg"
rm -f "${DMG_NAME}_temp.dmg"

# Create temp directory
mkdir -p "$DMG_DIR"

# Copy app
echo "Copying application..."
cp -R "$SOURCE_APP" "$DMG_DIR/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create beautiful orange-to-yellow gradient background (smooth diagonal)
echo "Creating orange-to-yellow gradient background..."

# Create a smooth 3-stop diagonal gradient matching the app icon design
# Orange #FF6B35 (top-left) → Blend #FFAB3B (75%) → Yellow #FFC93C (bottom-right)
convert -size 660x400 xc: \
    -sparse-color Barycentric \
    "0,0 #FF6B35  495,0 #FFAB3B  660,400 #FFC93C" \
    dmg_background.png
echo "✓ Gradient created"

# Create hidden background folder and copy background
mkdir -p "$DMG_DIR/.background"
cp dmg_background.png "$DMG_DIR/.background/background.png"

# Copy app icon for DMG volume icon
# TODO: This will use the new landscape icon once we regenerate AppIcon.icns
cp "$SOURCE_APP/Contents/Resources/AppIcon.icns" "$DMG_DIR/.VolumeIcon.icns"

# Create temporary DMG
echo "Creating temporary DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDRW "${DMG_NAME}_temp.dmg"

# Mount the DMG
echo "Mounting DMG for customization..."
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "${DMG_NAME}_temp.dmg" -mountpoint "$MOUNT_DIR"

# Wait for mount to complete
sleep 2

# Hide the folders using SetFile (makes them invisible to Finder)
echo "Hiding system files..."
if [ -d "$MOUNT_DIR/.background" ]; then
    SetFile -a V "$MOUNT_DIR/.background"
    chflags hidden "$MOUNT_DIR/.background"
fi

if [ -d "$MOUNT_DIR/.fseventsd" ]; then
    SetFile -a V "$MOUNT_DIR/.fseventsd" 2>/dev/null || true
    chflags hidden "$MOUNT_DIR/.fseventsd" 2>/dev/null || true
fi

if [ -f "$MOUNT_DIR/.DS_Store" ]; then
    SetFile -a V "$MOUNT_DIR/.DS_Store" 2>/dev/null || true
    chflags hidden "$MOUNT_DIR/.DS_Store" 2>/dev/null || true
fi

# Hide the volume icon file
if [ -f "$MOUNT_DIR/.VolumeIcon.icns" ]; then
    SetFile -a V "$MOUNT_DIR/.VolumeIcon.icns"
    chflags hidden "$MOUNT_DIR/.VolumeIcon.icns"
fi

# Set custom icon attribute on the volume
SetFile -a C "$MOUNT_DIR"

# Set user's Finder preference to not show hidden files (temporary)
defaults write com.apple.finder AppleShowAllFiles -bool false
killall Finder 2>/dev/null || true
sleep 2

# Configure DMG appearance using AppleScript
echo "Configuring DMG appearance..."
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open

        -- Set window bounds (increased height for better icon visibility)
        -- Window: x, y, width, height from top-left
        -- Size: 660x480 (added 80px height for better spacing)
        set the bounds of container window to {100, 100, 760, 580}

        -- Basic window settings
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false

        -- Icon view options
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set text size of viewOptions to 14
        set shows item info of viewOptions to false
        set shows icon preview of viewOptions to true
        set label position of viewOptions to bottom

        -- Note: "shows hidden files" is not a valid property in icon view options

        -- Set background picture
        set background picture of viewOptions to file ".background:background.png"

        -- Position icons (better centered for visual balance)
        -- Y position: 200 provides optimal centering with 128px icons + ~40px label
        -- This accounts for visual weight and creates better spacing from edges
        set position of item "$APP_NAME.app" to {150, 200}
        set position of item "Applications" to {510, 200}

        -- Force update
        update without registering applications
        delay 2

        -- Close all windows
        close
    end tell

    -- Additional delay to ensure settings persist
    delay 1
end tell
EOF

# Additional wait to ensure settings are saved
sleep 2

# Unmount
echo "Finalizing DMG..."
hdiutil detach "$MOUNT_DIR"

# Wait for unmount
sleep 1

# Convert to compressed, read-only DMG
echo "Compressing DMG..."
hdiutil convert "${DMG_NAME}_temp.dmg" -format UDZO -o "${DMG_NAME}.dmg"

# Clean up
rm -f "${DMG_NAME}_temp.dmg"
rm -rf "$DMG_DIR"
rm -f dmg_background.png

echo ""
echo "=========================================="
echo "DMG created successfully: ${DMG_NAME}.dmg"
echo "=========================================="
echo ""
echo "The DMG includes:"
echo "  - Universal binary (Intel + Apple Silicon)"
echo "  - Drag-and-drop installation"
echo "  - Professional layout with large icons"
echo "  - Smooth orange-to-yellow gradient background"
echo ""
