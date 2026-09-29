#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "=== Building Glance for macOS Monterey (12.0) ==="

APP_DIR="build/Glance.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
FRAMEWORKS_DIR="$APP_DIR/Contents/Frameworks"
CACHE_DIR="/Users/cleitonreis/.gemini/antigravity/scratch/cache"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$FRAMEWORKS_DIR"
mkdir -p "$CACHE_DIR"

# 1. Generate AppIcon.icns if needed
if [ ! -f "build/AppIcon.icns" ]; then
    echo "--- Generating AppIcon.icns ---"
    mkdir -p build/AppIcon.iconset
    SRC="glance/Assets.xcassets/appicon.imageset/appicon.png"
    sips -z 16 16     "$SRC" --out build/AppIcon.iconset/icon_16x16.png
    sips -z 32 32     "$SRC" --out build/AppIcon.iconset/icon_16x16@2x.png
    sips -z 32 32     "$SRC" --out build/AppIcon.iconset/icon_32x32.png
    sips -z 64 64     "$SRC" --out build/AppIcon.iconset/icon_32x32@2x.png
    sips -z 128 128   "$SRC" --out build/AppIcon.iconset/icon_128x128.png
    sips -z 256 256   "$SRC" --out build/AppIcon.iconset/icon_128x128@2x.png
    sips -z 256 256   "$SRC" --out build/AppIcon.iconset/icon_256x256.png
    sips -z 512 512   "$SRC" --out build/AppIcon.iconset/icon_256x256@2x.png
    sips -z 512 512   "$SRC" --out build/AppIcon.iconset/icon_512x512.png
    sips -z 1024 1024 "$SRC" --out build/AppIcon.iconset/icon_512x512@2x.png
    iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
fi

# 2. Generate MenuBar and Tab PNG icons
echo "--- Generating MenuBar and Tab PNG icons ---"
swift tools/generate_icons.swift glance/Resources

# 3. Precompile ArcFace.mlmodelc if needed
if [ ! -d "build/ArcFace.mlmodelc" ]; then
    echo "--- Compiling ArcFace model to .mlmodelc ---"
    swift -target x86_64-apple-macos12.0 tools/compile_model.swift
fi

# 4. Compile Swift binary
echo "--- Compiling Glance binary (x86_64-apple-macos12.0) ---"
SWIFT_FILES=$(find glance -name "*.swift")

swiftc -target x86_64-apple-macos12.0 \
  -module-cache-path "$CACHE_DIR" \
  -O -whole-module-optimization \
  -F Frameworks \
  -framework Sparkle -framework AVFoundation -framework Vision -framework CoreML -framework AppKit -framework SwiftUI \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  -o "$MACOS_DIR/Glance" \
  $SWIFT_FILES

# 4. Copy Frameworks
echo "--- Copying Sparkle framework ---"
rm -rf "$FRAMEWORKS_DIR/Sparkle.framework"
cp -R Frameworks/Sparkle.framework "$FRAMEWORKS_DIR/"

# 5. Copy Resources
echo "--- Copying Resources ---"
cp -R glance/Resources/* "$RESOURCES_DIR/"
cp build/AppIcon.icns "$RESOURCES_DIR/"
cp glance/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon.svg "$RESOURCES_DIR/"
cp glance/Assets.xcassets/YourFaceIcon.imageset/YourFaceIcon.svg "$RESOURCES_DIR/"
rm -rf "$RESOURCES_DIR/ArcFace.mlmodelc" "$RESOURCES_DIR/ArcFace.mlpackage"
cp -R build/ArcFace.mlmodelc "$RESOURCES_DIR/"
cp -R glance/Models/ArcFace.mlpackage "$RESOURCES_DIR/"

# 6. Write Info.plist
echo "--- Writing Info.plist ---"
cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>Glance</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.jonathan.glance</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Glance</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>12.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSCameraUsageDescription</key>
	<string>Glance uses your camera for local face recognition and liveness detection. Video never leaves your device.</string>
	<key>SUFeedURL</key>
	<string>https://tryglance.app/appcast.xml</string>
	<key>SUPublicEDKey</key>
	<string>o9uQmlzKzh7NZvFtVktVh/wqw4Ie6WshX8K8NFDweWY=</string>
	<key>SUAutomaticallyUpdate</key>
	<false/>
	<key>SUEnableInstallerLauncherService</key>
	<false/>
</dict>
</plist>
EOF

# 7. Codesign
echo "--- Codesigning Glance.app inside-out ---"
xattr -cr "$APP_DIR"

SPARKLE="$FRAMEWORKS_DIR/Sparkle.framework"
if [ -d "$SPARKLE" ]; then
    echo "--- Signing Sparkle.framework components ---"
    codesign --force --sign - "$SPARKLE/Versions/B/XPCServices/Downloader.xpc" 2>/dev/null || true
    codesign --force --sign - "$SPARKLE/Versions/B/XPCServices/Installer.xpc" 2>/dev/null || true
    codesign --force --sign - "$SPARKLE/Versions/B/Autoupdate" 2>/dev/null || true
    codesign --force --deep --sign - "$SPARKLE/Versions/B/Updater.app" 2>/dev/null || true
    codesign --force --sign - "$SPARKLE"
fi

codesign --force --sign - -r='designated => identifier "com.jonathan.glance"' --entitlements glance/glance.entitlements "$APP_DIR"

echo "--- Verifying signature validity ---"
codesign -vvv --deep --strict "$APP_DIR"

echo "=== Build Complete! Glance.app is ready at $APP_DIR ==="
