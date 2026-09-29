#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "=== Creating Glance Installers for macOS Monterey ==="

if [ ! -d "build/Glance.app" ]; then
    echo "Glance.app not found. Running build_app.sh first..."
    ./build_app.sh
fi

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

# 1. Create .pkg installer without bundle relocation (guaranteed /Applications install)
echo "--- Building Glance-macOS-Monterey.pkg ---"
PKG_ROOT="build/pkg_root"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/Applications"
cp -R build/Glance.app "$PKG_ROOT/Applications/"

PKG_PLIST="build/components.plist"
pkgbuild --analyze --root "$PKG_ROOT" "$PKG_PLIST"
# Set BundleIsRelocatable to false so PackageKit never relocates to developer or scratch directories
python3 -c '
import plistlib, sys
p = sys.argv[1]
with open(p, "rb") as f:
    pl = plistlib.load(f)
for comp in pl:
    comp["BundleIsRelocatable"] = False
with open(p, "wb") as f:
    plistlib.dump(pl, f)
' "$PKG_PLIST"

PKG_SCRIPTS="build/pkg_scripts"
mkdir -p "$PKG_SCRIPTS"
cat << 'EOF' > "$PKG_SCRIPTS/postinstall"
#!/bin/bash
# Remove quarantine attributes so Gatekeeper never displays warning on launch
xattr -cr /Applications/Glance.app 2>/dev/null || true
# Register bundle with LaunchServices so it shows up in Applications and Launchpad immediately
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Glance.app 2>/dev/null || true
exit 0
EOF
chmod +x "$PKG_SCRIPTS/postinstall"

rm -f "$DIST_DIR/Glance-macOS-Monterey.pkg"
pkgbuild --root "$PKG_ROOT" \
         --component-plist "$PKG_PLIST" \
         --scripts "$PKG_SCRIPTS" \
         --identifier com.jonathan.glance \
         --version 1.0.0 \
         "$DIST_DIR/Glance-macOS-Monterey.pkg"

rm -rf "$PKG_ROOT" "$PKG_PLIST" "$PKG_SCRIPTS"

# 2. Create .dmg installer (Clean: only Glance.app and Applications symlink)
echo "--- Building Glance-macOS-Monterey.dmg ---"
DMG_STAGING="build/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R build/Glance.app "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
xattr -cr "$DMG_STAGING" 2>/dev/null || true
find "$DMG_STAGING" -name ".DS_Store" -delete 2>/dev/null || true

rm -f "$DIST_DIR/Glance-macOS-Monterey.dmg"
hdiutil create -volname "Glance" \
               -srcfolder "$DMG_STAGING" \
               -ov -format UDZO \
               "$DIST_DIR/Glance-macOS-Monterey.dmg"

rm -rf "$DMG_STAGING"

# 3. Create .zip archive (using ditto to preserve symlinks and code signature)
echo "--- Building Glance-macOS-Monterey.zip ---"
rm -f "$DIST_DIR/Glance-macOS-Monterey.zip"
ditto -c -k --sequesterRsrc --keepParent build/Glance.app "$DIST_DIR/Glance-macOS-Monterey.zip"

echo ""
echo "=== Packaging Complete! ==="
echo "Installers generated in $DIST_DIR/:"
ls -lh "$DIST_DIR"
