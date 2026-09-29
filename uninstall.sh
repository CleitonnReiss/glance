#!/bin/bash
set -e

echo "=================================================="
echo "    Desinstalador Completo do Glance (macOS)      "
echo "=================================================="
echo ""
echo "Este script removerá o aplicativo Glance e todos os dados associados:"
echo " - Dados de reconhecimento facial em ~/Library/Application Support/glance"
echo " - Senhas e chaves salvas no Chaveiro do macOS (Keychain)"
echo " - Preferências do aplicativo em ~/Library/Preferences"
echo " - Inicialização automática (LaunchAgent)"
echo " - O aplicativo /Applications/Glance.app"
echo ""

read -p "Deseja prosseguir com a desinstalação completa? (s/N): " confirm
if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo "Operação cancelada pelo usuário."
    exit 0
fi

echo "1. Encerrando o aplicativo Glance..."
killall Glance 2>/dev/null || true

echo "2. Removendo senhas e chaves salvas do Chaveiro (Keychain)..."
security delete-generic-password -s com.jonathan.glance -a encryptedPassword 2>/dev/null || true
security delete-generic-password -s com.jonathan.glance -a sessionKey 2>/dev/null || true
security delete-generic-password -s com.jonathan.glance 2>/dev/null || true

echo "3. Removendo dados cadastrais faciais..."
rm -rf ~/Library/Application\ Support/glance

echo "4. Removendo preferências e configurações salvas..."
defaults delete com.jonathan.glance 2>/dev/null || true
rm -f ~/Library/Preferences/com.jonathan.glance.plist

echo "5. Desativando inicialização automática no login..."
launchctl unload ~/Library/LaunchAgents/com.jonathan.glance.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.jonathan.glance.plist

echo "6. Limpando caches de sistema..."
rm -rf ~/Library/Caches/com.jonathan.glance

echo "7. Redefinindo permissões de Acessibilidade no TCC..."
tccutil reset Accessibility com.jonathan.glance 2>/dev/null || true

echo "8. Removendo /Applications/Glance.app..."
rm -rf /Applications/Glance.app

echo ""
echo "=================================================="
echo "✅ Desinstalação concluída com sucesso!"
echo "O Glance foi removido do seu sistema sem deixar nenhum arquivo residual."
echo "Se você reinstalá-lo no futuro, ele iniciará 100% do zero."
echo "=================================================="
