#!/usr/bin/env bash
# Builds the release binary and assembles an ad-hoc signed menu-bar .app bundle.
#
#   Scripts/package_app.sh [release|dev]
#
# release → .build/app/HabitTracker.app     (bundle id from version.env, data in ~/Library/Application Support/HabitTracker)
# dev     → .build/app/HabitTrackerDev.app  (bundle id + ".dev", data in ~/Library/Application Support/HabitTracker-Dev)
# Prints the bundle path on the last line.
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=../version.env
source version.env

# Build with Xcode's toolchain when installed, as the Makefile does: the Command Line Tools for
# macOS 27 lack the SwiftUI macro plugin that @State needs.
XCODE_DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d "$XCODE_DEVELOPER_DIR" ]; then
    export DEVELOPER_DIR="$XCODE_DEVELOPER_DIR"
fi

VARIANT="${1:-release}"
case "$VARIANT" in
    release)
        BUNDLE_NAME="$APP_NAME"
        DISPLAY_NAME="$APP_NAME"
        IDENTIFIER="$BUNDLE_ID"
        ;;
    dev)
        BUNDLE_NAME="${APP_NAME}Dev"
        DISPLAY_NAME="$APP_NAME Dev"
        IDENTIFIER="$BUNDLE_ID.dev"
        ;;
    *)
        echo "usage: $0 [release|dev]" >&2
        exit 64
        ;;
esac

swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

APP="$PWD/.build/app/$BUNDLE_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# The executable is renamed per variant so `pkill -x` can tell the two apps apart.
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$BUNDLE_NAME"

# SwiftPM resource bundles (GRDB ships a privacy manifest) belong in Contents/Resources.
find "$BIN_DIR" -maxdepth 1 -name '*.bundle' -exec cp -R {} "$APP/Contents/Resources/" \;

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$BUNDLE_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$IDENTIFIER</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$BUNDLE_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

xattr -cr "$APP"
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --strict "$APP"

echo "$APP"
