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

# 1. Create .pkg installer with postinstall script (auto-removes quarantine)
echo "--- Building Glance-macOS-Monterey.pkg ---"
PKG_SCRIPTS="build/pkg_scripts"
mkdir -p "$PKG_SCRIPTS"
cat << 'EOF' > "$PKG_SCRIPTS/postinstall"
#!/bin/bash
# Remove quarantine attributes so Gatekeeper never displays "damaged app" error
xattr -cr /Applications/Glance.app 2>/dev/null || true
exit 0
EOF
chmod +x "$PKG_SCRIPTS/postinstall"

pkgbuild --component build/Glance.app \
         --install-location /Applications \
         --scripts "$PKG_SCRIPTS" \
         --identifier com.jonathan.glance \
         --version 1.0.0 \
         "$DIST_DIR/Glance-macOS-Monterey.pkg"

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
