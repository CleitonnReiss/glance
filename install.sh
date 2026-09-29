#!/bin/bash
set -e

echo "=== Glance para macOS Monterey — Instalador Automático ==="
echo "Baixando a versão mais recente..."

TEMP_DMG=$(mktemp /tmp/Glance-Monterey-XXXXXX.dmg)
curl -fSL "https://github.com/CleitonnReiss/glance/releases/latest/download/Glance-macOS-Monterey.dmg" -o "$TEMP_DMG"

echo "Instalando Glance em /Applications..."
MOUNT_DIR=$(mktemp -d /tmp/glance_mount_XXXXXX)
hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

# Fecha Glance se estiver rodando
pkill -x Glance 2>/dev/null || true

# Copia para Aplicativos
rm -rf /Applications/Glance.app
cp -R "$MOUNT_DIR/Glance.app" /Applications/

# Desmonta e limpa arquivos temporários
hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
rm -rf "$MOUNT_DIR" "$TEMP_DMG"

# Remove atributos de quarentena do Gatekeeper
xattr -cr /Applications/Glance.app 2>/dev/null || true

echo "✓ Glance instalado com sucesso em /Applications/Glance.app!"
echo "Abrindo o Glance..."
open /Applications/Glance.app
