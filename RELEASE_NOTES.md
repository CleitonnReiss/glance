# 🚀 Glance para macOS (Monterey 12.0+) — v1.0.0

Desbloqueio biométrico facial inteligente no estilo **Face ID** para computadores Mac com macOS Monterey (12.0 ou superior). Compatível com processadores **Intel (`x86_64`)** e **Apple Silicon (`arm64`)**.

---

## 📥 Downloads e Instaladores

| Arquivo | Formato | Descrição |
|---|---|---|
| **`Glance-macOS-Monterey.dmg`** | Imagem de Disco (.dmg) | **Recomendado**. Arraste e solte direto para a pasta Aplicativos. |
| **`Glance-macOS-Monterey.pkg`** | Pacote Nativo (.pkg) | Assistente guiado de instalação padrão do macOS. |
| **`Glance-macOS-Monterey.zip`** | Arquivo Compactado (.zip) | Aplicativo pronto para execução direta. |

---

## ✨ Recursos

- ⚡ **Desbloqueio Facial Instantâneo**: Desbloqueie a tela de bloqueio do seu Mac apenas olhando para a webcam.
- 🔐 **Cofre de Credenciais Permanente**: Armazenamento seguro de senha no Apple Keychain local, mantendo o desbloqueio ativo de forma contínua e sem bloqueios por tempo.
- 🌐 **Multi-idioma**: Interface completa e seletor rápido de idiomas em **Português (pt)**, **Inglês (en)** e **Espanhol (es)**.
- 💻 **Compatibilidade Ampla**: Funciona nativamente a partir do macOS Monterey (12.0+) até as versões mais recentes, tanto em Macs Intel quanto Apple Silicon.
- 🔒 **Privacidade Total**: Todo o processamento biométrico (ArcFace Core ML) roda 100% offline no seu dispositivo. Nenhuma imagem ou dado sai do seu computador.
- 🧹 **Desinstalação Limpa**: Opção integrada para desinstalação completa e limpeza automática de dados ao mover para a Lixeira.

---

## 🛠️ Instruções de Instalação e Permissões

### ⚡ Instalação Rápida em 1 Clique (Terminal):
Cole o comando abaixo no Terminal do Mac:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cleitonnreiss/glance/main/install.sh)"
```

### Pelo Instalador DMG:
1. Baixe o **`Glance-macOS-Monterey.dmg`**.
2. Abra o arquivo `.dmg` (se o macOS avisar *"desenvolvedor não identificado"*, clique com o botão direito nele e escolha **Abrir**).
3. Arraste o **Glance.app** para a pasta **Aplicativos**.
4. Abra o Glance pela pasta Aplicativos e siga o assistente inicial.

### Pelo Instalador PKG:
1. Baixe o **`Glance-macOS-Monterey.pkg`**.
2. Clique com o botão direito -> **Abrir** -> **Abrir**.
3. Conclua as etapas do assistente e abra o Glance na pasta Aplicativos.

---

### 🔑 Permissões Necessárias
Na primeira execução, conceda as permissões solicitadas:
1. **Câmera**: Para detecção facial instantânea via webcam.
2. **Acessibilidade**: Em *Preferências do Sistema > Segurança e Privacidade > Acessibilidade*, marque o **Glance** para permitir o desbloqueio automático na tela de bloqueio.
