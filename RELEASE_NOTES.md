# 🚀 Glance para macOS Monterey (12.0+) — v1.0.0-monterey

Port completo do aplicativo **Glance** (reconhecimento facial e desbloqueio inteligente no estilo Face ID) para funcionar nativamente no **macOS Monterey (12.0 ou superior)**, com suporte a processadores **Intel (`x86_64`)** e **Apple Silicon (`arm64`)**.

---

## 📥 Downloads e Instaladores

| Arquivo | Formato | Descrição |
|---|---|---|
| **`Glance-macOS-Monterey.dmg`** | Imagem de Disco (.dmg) | **Recomendado**. Instalador padrão com arrastar e soltar direto para a pasta Aplicativos. |
| **`Glance-macOS-Monterey.pkg`** | Pacote Nativo (.pkg) | Assistente guiado de instalação automática do macOS. |
| **`Glance-macOS-Monterey.zip`** | Arquivo Compactado (.zip) | Aplicativo compilado pronto para execução portátil. |

---

## ✨ Principais Mudanças e Correções desta Versão

### 1. 🔄 Retrocompatibilidade com macOS Monterey (macOS 12.0+)
- **Migração do Observation Framework para Combine**: Todas as classes reativas (`AppEnvironment`, `FaceUnlockCoordinator`, `GlanceSettings`, etc.) foram convertidas de `@Observable` / `@Bindable` para `ObservableObject` com `@Published`.
- **Interface e Geometria**:
  - Implementada a forma customizada `NotchShape` para substituir `UnevenRoundedRectangle` (recurso do macOS 14+).
  - Criado o componente nativo `CalibrationChartView` para substituir a dependência de Apple `Charts` (recurso do macOS 13+).
  - Removidos efeitos de símbolo `.symbolEffect` e transições numéricas não suportadas no macOS 12.
- **Concorrência e Clocks**: Substituídos `ContinuousClock` e `Duration` por `TimeInterval` monotônico com `systemUptime`.
- **Câmeras e AVFoundation**: Mapeamento seguro de dispositivos de captura para evitar APIs introduzidas apenas no macOS 14.
- **Inicialização Automática**: Implementado fallback com LaunchAgent (`~/Library/LaunchAgents/com.jonathan.glance.plist`) substituindo `SMAppService` (macOS 13+).

### 2. 🧠 Modelo ArcFace Core ML Down-Targeted (Spec Version 6)
- O modelo original exigia especificação v8 (macOS 14).
- O modelo foi convertido para especificação v6 (iOS 15 / macOS 12 Monterey) com precisão FP32 e validado com **similaridade de cosseno de 0.999845** com o original.
- Pré-compilado para `.mlmodelc` dentro do bundle do app para inicialização ultrarrápida.

### 3. 🔐 Correções Críticas no Keychain e Autenticação
- **Fallback para Builds Ad-hoc e Forks**: Eliminado o erro `-34018 (errSecMissingEntitlement)` ao salvar senhas em builds sem Apple Developer Team ID oficial pago, permitindo que qualquer usuário use o app.
- **Ação Real de Bloqueio de Tela**: Adicionado o atalho **⌃⌘L** e item de menu **"Lock Screen"** chamando `SACLockScreenImmediate()` do macOS para bloquear a tela do computador de verdade.
- **Prevenção de Crash em Cores Dinâmicas**: Corrigido o `SIGSEGV` em `CGColorTransformConvertColorComponents` ao alternar o status do cofre de credenciais.

### 4. 🎯 Injeção Segura de Senha e Permissões TCC
- **Detecção Real de Falhas**: A injeção agora detecta se a senha foi realmente digitada e avisa com animação vermelha caso falhe, eliminando o falso positivo do checkmark verde.
- **Limpeza de Modificadores de Teclado**: Eventos de digitação `CGEvent` agora têm suas flags limpas (`flags = []`) e intervalos de estabilização adicionados.
- **Assinatura Fixa**: Adicionada assinatura designada estável (`identifier "com.jonathan.glance"`), impedindo que o macOS revogue a permissão de Acessibilidade no TCC.

### 5. 👁️ Ícone da Barra de Menus Visível e Nítido
- Corrigida a invisibilidade do ícone na barra superior: o macOS 12 não carregava arquivos `.svg` avulsos pelo AppKit.
- Criado gerador de PNGs de alta resolução (`@1x` e `@2x`) e um desenhista vetorial nativo via CoreGraphics com `isTemplate = true`, garantindo que o logo apareça nítido em telas normais e Retina, com suporte dinâmico aos modos Claro e Escuro.

### 6. 🧹 Desinstalação Completa e Detecção Automática de Reinstalação Limpa
- **Desinstalação Sem Rastros 100% Integrada**: Adicionada a opção **"Uninstall Glance Completely..."** no menu da barra superior e na aba Sobre das preferências. Remove com um clique todos os dados biométricos, senhas do Chaveiro, configurações salvas, LaunchAgent e move o app para a Lixeira, sem precisar de scripts externos.
- **Detecção de Reinstalação de Fábrica**: O app monitora o identificador do bundle no disco. Se você excluir o app e reinstalar uma cópia no futuro, ele detecta a nova instalação e reinicia 100% como novo, abrindo o assistente inicial de Onboarding do zero.
- **Instalador DMG Limpo e Seguro**: A imagem de disco contém estritamente o `Glance.app` e o atalho para a pasta `Applications`.

---

## 🛠️ Instruções de Instalação e Permissões

### Pelo Instalador DMG:
1. Baixe e abra o **`Glance-macOS-Monterey.dmg`**.
2. Arraste o **Glance.app** para a pasta **Applications** (Aplicativos).
3. Abra o Glance pela pasta Aplicativos:
   - Na primeira vez, clique com o **botão direito (ou Control + clique)** sobre o Glance e selecione **Abrir** (Open).
   - Ou vá em **Preferências do Sistema** > **Segurança e Privacidade** > aba **Geral** e clique em **"Abrir Mesmo Assim"** (Open Anyway).

### Pelo Instalador PKG (Recomendado para instalação em 1 clique):
1. Baixe e abra o **`Glance-macOS-Monterey.pkg`**.
2. Siga o assistente do macOS. O instalador instala diretamente em `/Applications` e já libera as restrições automaticamente.

### Permissões e Uso:
1. Conceda as permissões solicitadas:
   - **Câmera**: para reconhecimento facial local (os frames nunca saem da memória).
   - **Acessibilidade**: para permitir que o Glance digite sua senha de forma automatizada na tela de login.
2. Siga o assistente no entalhe para cadastrar seu rosto e salvar a senha do Mac.
3. Pressione **⌃⌘L** a qualquer momento para bloquear e testar o desbloqueio facial!
