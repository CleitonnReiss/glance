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

# 2. Create .dmg installer
echo "--- Building Glance-macOS-Monterey.dmg ---"
DMG_STAGING="build/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R build/Glance.app "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

cat << 'EOF' > "$DMG_STAGING/LEIA-ME.txt"
==================================================
Glance para macOS Monterey (12.0+)
Reconhecimento Facial e Desbloqueio Inteligente
==================================================

INSTRUÇÕES DE INSTALAÇÃO:
1. Arraste o "Glance.app" para a pasta "Applications" (Aplicativos).
2. Abra o Glance pela pasta Aplicativos ou pelo Spotlight/Launchpad.
3. Se o macOS avisar sobre desenvolvedor não verificado no primeiro acesso:
   - Abra Preferências do Sistema > Segurança e Privacidade > Geral
   - Clique em "Abrir Mesmo Assim" (Open Anyway).

⚠️ SE O MAC EXIBIR: "GLANCE ESTÁ DANIFICADO E DEVE SER MOVIDO PARA O LIXO"
O macOS Gatekeeper bloqueia automaticamente aplicativos gratuitos baixados da internet
que não possuem o certificado pago de US$ 99/ano da Apple.
COMO RESOLVER EM 1 SEGUNDO:
- Opção 1: Dê dois cliques em "Corrigir App Danificado (Liberar Acesso).command" aqui no instalador.
- Opção 2: Ou abra o Terminal e cole o comando:
      xattr -cr /Applications/Glance.app
- Opção 3: Ou instale pelo arquivo "Glance-macOS-Monterey.pkg", que remove o bloqueio automaticamente.

PERMISSÕES NECESSÁRIAS:
- Câmera: para reconhecimento facial local.
- Acessibilidade: em Preferências do Sistema > Segurança e Privacidade > Acessibilidade,
  para permitir a digitação segura da senha no login.
EOF

cat << 'EOF' > "$DMG_STAGING/Corrigir App Danificado (Liberar Acesso).command"
#!/bin/bash
clear
echo "=================================================="
echo "    Liberador de Acesso do Glance no macOS        "
echo "=================================================="
echo ""
echo "Removendo a restrição de quarentena do macOS Gatekeeper..."
xattr -cr /Applications/Glance.app 2>/dev/null || true
echo "✅ Restrição removida com sucesso!"
echo "Iniciando o Glance agora..."
open /Applications/Glance.app
exit 0
EOF
chmod +x "$DMG_STAGING/Corrigir App Danificado (Liberar Acesso).command"


cat << 'EOF' > "$DMG_STAGING/Desinstalar Glance.command"
#!/bin/bash
clear
echo "=================================================="
echo "    Desinstalador Completo do Glance (macOS)      "
echo "=================================================="
echo ""
echo "Este script removerá completamente o Glance do seu computador:"
echo " - Dados faciais em ~/Library/Application Support/glance"
echo " - Senhas e chaves salvas no Chaveiro do macOS (Keychain)"
echo " - Preferências salvas em ~/Library/Preferences"
echo " - Inicialização automática (LaunchAgent)"
echo " - O aplicativo /Applications/Glance.app"
echo ""
read -p "Deseja prosseguir com a desinstalação completa? (s/N): " confirm
if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo "Operação cancelada pelo usuário."
    exit 0
fi

echo "1. Encerrando o Glance se estiver em execução..."
killall Glance 2>/dev/null || true

echo "2. Removendo senhas e chaves salvas do Chaveiro (Keychain)..."
security delete-generic-password -s com.jonathan.glance -a encryptedPassword 2>/dev/null || true
security delete-generic-password -s com.jonathan.glance -a sessionKey 2>/dev/null || true
security delete-generic-password -s com.jonathan.glance 2>/dev/null || true

echo "3. Removendo dados de cadastro facial e suporte..."
rm -rf ~/Library/Application\ Support/glance

echo "4. Removendo preferências e configurações salvas..."
defaults delete com.jonathan.glance 2>/dev/null || true
rm -f ~/Library/Preferences/com.jonathan.glance.plist

echo "5. Removendo inicialização automática (LaunchAgent)..."
launchctl unload ~/Library/LaunchAgents/com.jonathan.glance.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.jonathan.glance.plist

echo "6. Limpando caches..."
rm -rf ~/Library/Caches/com.jonathan.glance

echo "7. Redefinindo permissões de Acessibilidade no TCC..."
tccutil reset Accessibility com.jonathan.glance 2>/dev/null || true

echo "8. Removendo o aplicativo /Applications/Glance.app..."
rm -rf /Applications/Glance.app

echo ""
echo "=================================================="
echo "✅ Pronto! O Glance e todas as suas configurações"
echo "foram completamente desinstalados do seu computador."
echo "Quando você reinstalar o app, ele iniciará 100% do zero."
echo "=================================================="
echo ""
echo "Pressione qualquer tecla para fechar esta janela."
read -n 1
exit 0
EOF
chmod +x "$DMG_STAGING/Desinstalar Glance.command"

rm -f "$DIST_DIR/Glance-macOS-Monterey.dmg"
hdiutil create -volname "Glance" \
               -srcfolder "$DMG_STAGING" \
               -ov -format UDZO \
               "$DIST_DIR/Glance-macOS-Monterey.dmg"

rm -rf "$DMG_STAGING"

# 3. Create .zip archive
echo "--- Building Glance-macOS-Monterey.zip ---"
cd build
rm -f "../$DIST_DIR/Glance-macOS-Monterey.zip"
zip -rq "../$DIST_DIR/Glance-macOS-Monterey.zip" Glance.app
cd "$DIR"

echo ""
echo "=== Packaging Complete! ==="
echo "Installers generated in $DIST_DIR/:"
ls -lh "$DIST_DIR"
