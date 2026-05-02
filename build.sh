#!/bin/bash

# Exit on error
set -e

APP_NAME="SentryKit"
BUNDLE_ID="com.sentrykit.app"
VERSION="1.0.0"
DMG_NAME="$APP_NAME $VERSION.dmg"

echo "Building $APP_NAME for multiple architectures..."
# Build both architectures using xcodebuild
xcodebuild -project SentryKit.xcodeproj \
    -scheme SentryKit \
    -configuration Release \
    -derivedDataPath .build/derivedData_arm64 \
    build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO

xcodebuild -project SentryKit.xcodeproj \
    -scheme SentryKit \
    -configuration Release \
    -derivedDataPath .build/derivedData_x86_64 \
    build ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO

APP_BUNDLE_DIR="deploy"
APP_BUNDLE="$APP_BUNDLE_DIR/$APP_NAME.app"

echo "Creating App Bundle structure at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE_DIR"
mkdir -p "$APP_BUNDLE_DIR"

# Copy the build output as a base
cp -R ".build/derivedData_arm64/Build/Products/Release/$APP_NAME.app" "$APP_BUNDLE"

echo "Merging into Universal Binary..."
lipo -create \
    ".build/derivedData_arm64/Build/Products/Release/$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    ".build/derivedData_x86_64/Build/Products/Release/$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "Ad-hoc signing..."
ENTITLEMENTS="SentryKit/SentryKit.entitlements"
SIGN_OPTS="--force --verbose --sign -"

# Sign the entire app bundle
if [ -f "$ENTITLEMENTS" ]; then
    echo "Signing with entitlements: $ENTITLEMENTS"
    codesign --force --verbose --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
else
    echo "Warning: $ENTITLEMENTS not found, signing without entitlements"
    codesign --force --verbose --sign - "$APP_BUNDLE"
fi

echo "Verifying signature..."
codesign --verify --verbose --deep --strict "$APP_BUNDLE"

echo "Creating DMG..."
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

# Create a temporary directory for DMG content
TMP_DMG_DIR=$(mktemp -d)
cp -R "$APP_BUNDLE" "$TMP_DMG_DIR/"
ln -s /Applications "$TMP_DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$TMP_DMG_DIR" -ov -format UDZO "$DMG_NAME"

rm -rf "$TMP_DMG_DIR"

echo "Success! $DMG_NAME created as a Universal Binary."
