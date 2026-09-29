# Adaptação do Glance para macOS Monterey (12.0+)

Este documento detalha todas as mudanças arquiteturais, técnicas e correções implementadas para tornar o **[Glance](https://github.com/jonnyoo/glance)** totalmente compatível com o **macOS Monterey (12.0+)** em processadores **Intel (`x86_64`)** e **Apple Silicon (`arm64`)**.

Originalmente, o projeto exigia **macOS 15 (Sequoia)** devido ao uso intensivo do framework `Observation` (`@Observable`), APIs SwiftUI do macOS 14/15, especificação moderna do Core ML (v8) e subsistemas de autenticação recentes.

---

## 📋 Sumário das Modificações

1. [Migração do Observation Framework para Combine (`ObservableObject`)](#1-migração-do-observation-framework-para-combine)
2. [Retrocompatibilidade de SwiftUI e AppKit](#2-retrocompatibilidade-de-swiftui-e-appkit)
3. [Substituição de Concorrência e Clocks Modernos](#3-substituição-de-concorrência-e-clocks-modernos)
4. [Mapeamento de Câmeras e Dispositivos AVFoundation](#4-mapeamento-de-câmeras-e-dispositivos-avfoundation)
5. [Inicialização Automática no Login (LaunchAgent)](#5-inicialização-automática-no-login-launchagent)
6. [Conversão e Otimização do Modelo ArcFace Core ML](#6-conversão-e-otimização-do-modelo-arcface-core-ml)
7. [Correções Críticas no Keychain (Builds Ad-hoc e macOS 12)](#7-correções-críticas-no-keychain)
8. [Correção de Reatividade no Redimensionamento da Janela (NotchOverlay)](#8-correção-de-reatividade-no-redimensionamento-da-janela)
9. [Prevenção de Crash em Espaços de Cores Dinâmicos](#9-prevenção-de-crash-em-espaços-de-cores-dinâmicos)
10. [Bloqueio Real de Tela do macOS (`Lock Screen`)](#10-bloqueio-real-de-tela-do-macos-lock-screen)
11. [Injeção Confiável de Senha e Preservação de Acessibilidade no TCC](#11-injeção-confiável-de-senha-e-preservação-de-acessibilidade-no-tcc)
12. [Compatibilidade do Ícone da Barra de Menus e Assets SVG](#12-compatibilidade-do-ícone-da-barra-de-menus-e-assets-svg)
13. [Desinstalação Completa e Detecção de Reinstalação Limpa](#13-desinstalação-completa-e-detecção-de-reinstalação-limpa)
14. [Scripts de Compilação e Geração de Instaladores](#14-scripts-de-compilação-e-geração-de-instaladores)

---

## 1. Migração do Observation Framework para Combine

### Contexto
No macOS 14+ (Swift 5.9+), a Apple introduziu as macros `@Observable` e o property wrapper `@Bindable`. No macOS 12 (Monterey), essas APIs não existem no runtime do sistema.

### O que foi alterado
Todas as classes de estado e modelos reativos foram convertidos para a conformidade com `ObservableObject`:
- `@Observable` foi substituído por `: ObservableObject`.
- Propriedades mutáveis observadas receberam o decorador `@Published`.
- Nas Views do SwiftUI:
  - `@Bindable var controller: ...` foi substituído por `@ObservedObject var controller: ...`.
  - Passagem de bindings atualizada para `$controller.property`.

### Arquivos modificados:
- `glance/AppEnvironment.swift`
- `glance/CameraManager.swift`
- `glance/FaceUnlockCoordinator.swift`
- `glance/FaceLabController.swift`
- `glance/FaceEnrollmentStore.swift`
- `glance/Settings/GlanceSettings.swift`
- `glance/Onboarding/OnboardingController.swift`
- `glance/NotchOverlay/NotchOverlayController.swift`
- `glance/Updater/UpdaterController.swift`
- `glance/LockMonitor.swift`
- Todas as Views correspondentes em `glance/Settings/Pages/` e `glance/Onboarding/`.

---

## 2. Retrocompatibilidade de SwiftUI e AppKit

### Formas Customizadas (`UnevenRoundedRectangle`)
- **Problema**: O componente `UnevenRoundedRectangle` (usado para desenhar o entalhe curvado com raios diferentes no topo e na base) só foi introduzido no macOS 14.
- **Solução**: Implementamos uma `Shape` geométrica nativa equivalente em [`glance/NotchOverlay/NotchShape.swift`](glance/NotchOverlay/NotchShape.swift) utilizando `Path`, `addArc` e `addCurve`, preservando 100% da curvatura original do notch.

### Gráficos do FaceLab (`Charts` Framework)
- **Problema**: O framework Apple `Charts` (`import Charts`, `Chart`, `LineMark`, `RuleMark`) requer macOS 13+.
- **Solução**: Criamos um substituto leve e direto via SwiftUI Canvas/Path (`CalibrationChartView`) dentro de [`glance/FaceLabView.swift`](glance/FaceLabView.swift), eliminando a dependência do framework `Charts` sem perder a visualização de calibração de scores faciais.

### Efeitos de Símbolo e Animações Não Suportadas
- **Problema**: Modificadores `.symbolEffect(.pulse)`, `.contentTransition(.numericText())` e `.menuStyle(.button)` exigem macOS 14+.
- **Solução**: Substituídos por animações nativas com `.opacity` / `.animation` e uso de `BorderlessButtonMenuStyle()`.

### Custom Environment Values
- **Problema**: Macro `@Entry` em `EnvironmentValues` (macOS 15+).
- **Solução**: Convertido para o padrão canônico do SwiftUI: struct adotando `EnvironmentKey` + extensão em `EnvironmentValues`.

---

## 3. Substituição de Concorrência e Clocks Modernos

- **`ContinuousClock` e `Duration`** (macOS 13+):
  - Substituídos pelo uso de `TimeInterval` (`Double`), `ProcessInfo.processInfo.systemUptime` para medição monotônica de alta precisão e `Task.sleep(nanoseconds:)` para esperas assíncronas.
- **`MainActor.assumeIsolated`** (macOS 14+):
  - Substituído por `if Thread.isMainThread { ... } else { DispatchQueue.main.sync { ... } }` seguro e compatível com macOS 12.

---

## 4. Mapeamento de Câmeras e Dispositivos AVFoundation

- **Problema**: Constantes como `AVCaptureDevice.DeviceType.external` e `.continuityCamera` requerem macOS 14+.
- **Solução** em [`glance/CameraDeviceCatalog.swift`](glance/CameraDeviceCatalog.swift):
  - Tipos de dispositivos mapeados para `.builtInWideAngleCamera` e `.externalUnknown`.

---

## 5. Inicialização Automática no Login (LaunchAgent)

- **Problema**: `SMAppService.mainApp` é exclusivo do macOS 13 Ventura ou superior.
- **Solução** em [`glance/LaunchAtLogin.swift`](glance/LaunchAtLogin.swift):
  - Implementado fallback automático para criação e gerenciamento do arquivo LaunchAgent do usuário em `~/Library/LaunchAgents/com.jonathan.glance.plist`.
  - Permite que a opção "Launch at Login" funcione perfeitamente no macOS 12 sem erros de compilação ou execução.

---

## 6. Conversão e Otimização do Modelo ArcFace Core ML

- **Problema**: O arquivo original `ArcFace.mlpackage` foi gerado para a especificação do Core ML v8 (macOS 14+), recusando-se a carregar no macOS 12 com erro de incompatibilidade de especificação.
- **Solução**:
  1. Desenvolvemos o script de conversão [`tools/convert_arcface.py`](tools/convert_arcface.py) utilizando `coremltools` definindo explicitamente `minimum_deployment_target = coremltools.target.iOS15` (equivalente ao macOS 12 Monterey, spec version 6).
  2. Geramos a saída com precisão FP32 mantendo dimensões fixas `(1, 3, 112, 112)` e vetor de saída `(1, 512)`.
  3. A validação matemática comprovou similaridade de cosseno de **0.999845** com o modelo original (acima do limiar de paridade exigido de > 0.999).
  4. Adicionamos script de pré-compilação em tempo de build ([`tools/compile_model.swift`](tools/compile_model.swift)), incluindo `ArcFace.mlmodelc` diretamente no bundle do app para inicialização instantânea sem compilação no primeiro lançamento.

---

## 7. Correções Críticas no Keychain

- **Problema**:
  - O Glance original grava segredos com `SecAccessControlCreateWithFlags(..., .userPresence, ...)`.
  - No macOS, o Keychain exige um Developer Team ID oficial validado nos entitlements (`keychain-access-groups`) para aplicar políticas de Access Control biométricas.
  - Em builds de desenvolvimento, builds ad-hoc (`codesign --sign -`) ou forks independentes sem conta paga Apple Developer, a chamada `SecItemAdd` falha com `errSecMissingEntitlement` (`-34018`), impedindo o salvamento da senha.
- **Solução** em [`glance/KeychainManager.swift`](glance/KeychainManager.swift):
  - Adicionado fallback transparente: caso a gravação com Access Control falhe com `-34018`, a chave é gravada com `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
  - Leitura e remoção atualizadas para lidar com ambos os cenários de forma limpa.

---

## 8. Correção de Reatividade no Redimensionamento da Janela

- **Problema**:
  - No fluxo de Onboarding, ao trocar de etapa (por exemplo, de instruções para gravação da face), a janela do entalhe não atualizava seu tamanho até que o mouse fosse movido para fora e para dentro da tela.
  - Isso ocorria porque `NotchOverlayView` observava `NotchOverlayController`, enquanto a propriedade `step` mudava no `OnboardingController` filho, sem propagação de notificações para o SwiftUI no macOS 12.
- **Solução** em [`glance/NotchOverlay/NotchOverlayController.swift`](glance/NotchOverlay/NotchOverlayController.swift) e [`glance/NotchOverlay/NotchOverlayView.swift`](glance/NotchOverlay/NotchOverlayView.swift):
  - Configurada inscrição reativa em `obController.$step.dropFirst()` emitindo `self.objectWillChange.send()`.
  - Adicionada animação explícita `.animation(expansionAnimation(entering: true), value: currentSize)`.

---

## 9. Prevenção de Crash em Espaços de Cores Dinâmicos

- **Problema**:
  - Ao alternar o estado do cofre para "Session Locked", a View redesenhava com `SettingsMetrics.adaptiveColor`. No macOS 12, instâncias de `NSColor(name: nil)` misturando cores monocromáticas (`NSColor(white:...)`) com sRGB causavam falha de segmentação (`SIGSEGV` em `CGColorTransformConvertColorComponents`).
- **Solução** em [`glance/Settings/SettingsMetrics.swift`](glance/Settings/SettingsMetrics.swift):
  - Padronizadas as cores de modo escuro e claro para `.usingColorSpace(.sRGB)` antes do retorno no provider dinâmico.

---

## 10. Bloqueio Real de Tela do macOS (`Lock Screen`)

- **Problema**: O botão do menu "Session Unlocked" apenas trancava o cofre de chaves local, gerando confusão nos usuários que esperavam bloquear a tela do computador para testar o Glance.
- **Solução** em [`glance/glanceApp.swift`](glance/glanceApp.swift):
  - Adicionada a função nativa `lockMacScreen()`, que utiliza a chamada de sistema `SACLockScreenImmediate()` do `login.framework` privativo do macOS.
  - Adicionado novo item de menu **"Lock Screen" (⌃⌘L)**.
  - Renomeado o indicador do cofre para **"Credential Vault: Unlocked / Locked"**.

---

## 11. Injeção Confiável de Senha e Preservação de Acessibilidade no TCC

- **Problema 1 (Falso Positivo)**: `injectStoredPassword()` retornava `Void` e ignorava exceções ou ausência de permissão. Mesmo se nenhuma senha fosse digitada, o coordenador exibia o check verde de sucesso.
- **Problema 2 (TCC Revogando Acessibilidade)**: No macOS Monterey, cada build ad-hoc (`codesign -s -`) altera o hash do binário (`cdhash`). O subsistema de segurança (TCC) revogava a autorização com código `-67050 (errSecCSStaticCodeChanged)`.
- **Problema 3 (Flags de Teclado no CGEvent)**: O `KeystrokeInjector` não limpava as flags dos eventos de teclado (`keyDown.flags = []`), transmitindo acidentalmente modificadores (como Command) durante a digitação da senha.
- **Soluções Aplicadas**:
  - Em [`glance/POCController.swift`](glance/POCController.swift): `injectStoredPassword` agora retorna `Bool` e registra logs de depuração.
  - Em [`glance/FaceUnlockCoordinator.swift`](glance/FaceUnlockCoordinator.swift): Adicionado estado `.injectionFailed`; se a injeção falhar, a animação exibe falha vermelha (`finish(success: false)`).
  - Em [`glance/KeystrokeInjector.swift`](glance/KeystrokeInjector.swift): Inclusão de `flags = []` explícitas e intervalos de estabilização (40ms e 60ms).
  - Em [`build_app.sh`](build_app.sh): Configurado `-r='designated => identifier "com.jonathan.glance"'` no `codesign`, garantindo uma assinatura designada estável que não perde a permissão de Acessibilidade no TCC entre atualizações.

---

## 12. Compatibilidade do Ícone da Barra de Menus e Assets SVG

- **Problema**:
  - No macOS 14/15, `NSImage` e SwiftUI possuem suporte automático a arquivos `.svg` do catálogo de assets.
  - No **macOS 12 Monterey**, o AppKit **não** carrega imagens `.svg` diretamente via `NSImage(named:)` ou `NSImage(contentsOfFile:)`.
  - Como resultado, a chamada `NSImage(named: "MenuBarIcon")` retornava `nil`. O macOS alocava o espaço de 22px na barra de menus, mas o botão ficava **completamente invisível** (embora clicável). O mesmo acontecia com o ícone `YourFaceIcon` na barra de abas das preferências.
- **Solução Implementada**:
  1. Criado o script [`tools/generate_icons.swift`](tools/generate_icons.swift) integrado ao build, que rasteriza o vetor exato do Glance em arquivos PNG com canal alfa real (`MenuBarIcon.png`, `MenuBarIcon@2x.png`, `YourFaceIcon.png`, `YourFaceIcon@2x.png`).
  2. Criado o módulo [`glance/GlanceIcons.swift`](glance/GlanceIcons.swift), que fornece o renderizador vetorial nativo via `NSImage(size:flipped:drawingHandler:)`. Ele desenha os caminhos bézier do logo em CoreGraphics com `isTemplate = true`.
  3. Atualizado o [`glance/glanceApp.swift`](glance/glanceApp.swift) e [`glance/Settings/SettingsTabBar.swift`](glance/Settings/SettingsTabBar.swift) para carregar o asset PNG com fallback vetorial direto. O ícone passa a ser exibido com total nitidez e adaptação dinâmica aos modos claro e escuro.

---

## 13. Desinstalação Completa e Detecção de Reinstalação Limpa

- **Problema**:
  - No macOS, quando um usuário move um `.app` para a Lixeira, o sistema operacional **não** remove as preferências (`UserDefaults`), dados biométricos em `~/Library/Application Support/glance`, senhas e chaves salvas no Chaveiro (`Keychain`), nem o `LaunchAgent`.
  - Como consequência, ao excluir o Glance e reinstalá-lo mais tarde, o app encontrava dados residuais e considerava o onboarding como concluído, deixando de exibir o assistente inicial e podendo até entrar em estados inconsistentes com o Chaveiro.
- **Solução Implementada**:
  1. **Módulo [`glance/AppResetter.swift`](glance/AppResetter.swift)**:
     - Adiciona a função `resetAllUserData()`, que limpa atomicamente o Chaveiro (`sessionKey`, `encryptedPassword`), apaga a pasta `~/Library/Application Support/glance`, remove o LaunchAgent, limpa caches e reseta o `UserDefaults`.
     - Adiciona a ação `promptUninstall()`: exibe confirmação nativa, remove todos os dados residuais do Mac, move o aplicativo para a Lixeira do macOS (`NSWorkspace.shared.recycle`) e encerra o processo.
     - Adiciona a ação `promptResetAndReconfigure()`: limpa os dados e reabre imediatamente a janela de Onboarding inicial para reconfiguração do zero sem precisar deletar o app.
  2. **Detecção Automática de Nova Instalação (`verifyInstallationIntegrity`)**:
     - Monitora a assinatura de arquivo no disco (Inode e data de criação `birthtime` do bundle em `/Applications/Glance.app`).
     - Se o usuário excluir o app para a Lixeira manualmente e depois baixar/instalar uma nova cópia, o Glance detecta a mudança de Inode na inicialização, limpa automaticamente qualquer sobra antiga e inicia 100% como novo, apresentando o Onboarding original de fábrica.
  3. **Interface Integrada de Usuário**:
     - Menu da Barra Superior: Adicionados os itens **"Reset & Reconfigure..."** e **"Uninstall Glance Completely..."**.
     - Tela Sobre (Settings > About): Adicionados botões de ação dedicados para Redefinir Configuração e Desinstalar.
     - Ao clicar em "Uninstall", o app apaga todas as chaves e dados biométricos e move o próprio executável para a Lixeira, mantendo a pasta do instalador limpa sem scripts adicionais.

---

## 15. Correção de Crash no Encerramento do Onboarding (CoreGraphics vImageConverter)

### Problema
Ao finalizar o cadastro inicial (após o escaneamento facial e ao clicar em "Confirm" na tela de digitação de senha), o aplicativo encerrava abruptamente com erro `EXC_BAD_ACCESS (SIGSEGV)` em `CoreFoundation` / `CoreGraphics`:
```text
Exception Type: EXC_BAD_ACCESS (SIGSEGV)
Thread 0 Crashed:
0  CoreFoundation: CFRelease + 15
1  CoreGraphics: CGvImageConverterDeallocate + 22
2  libcache.dylib: _entry_evict + 41
...
19 QuartzCore: CA::Render::create_image_by_rendering
20 QuartzCore: CA::Render::copy_image
25 QuartzCore: CA::Transaction::commit
```
Ao reabrir o app, o estado de conclusão do onboarding não estava salvo, forçando o usuário a refazer todo o fluxo.

### Causa Raiz
1. **Renderização de Blur em Camadas AppKit/SwiftUI**: A transição entre os passos do assistente (`OnboardingNotchView.swift`) aplicava um modificador `.blur(radius: 12)`. No macOS 12 Monterey (especialmente em Macs Intel), rasterizar views contendo `NSViewRepresentable` / `NSSecureTextField` com desfoque durante animações forçava o `QuartzCore` a alocar e evictar conversores de espaço de cor na cache (`CGvImageConverterCache`), provocando um desalocamento ilegal (`CFRelease` em ponteiro inválido).
2. **Persistência Assíncrona do UserDefaults**: A propriedade `hasCompletedOnboarding` gravava no `UserDefaults` sem chamada imediata a `synchronize()`. Com o crash instantâneo no loop de renderização da animação, a gravação em disco era perdida.

### Solução Aplicada
- Em `OnboardingNotchView.swift`, substituímos o modificador de transição com desfoque por `OffsetOpacity`, que combina deslocamento vertical suave e fade de opacidade nativo sem disparar conversões de rasterização `vImageConverter`.
- Em `NotchOverlayView.swift`, removemos o `.blur(radius: 40)` no colapso do painel, mantendo fade e escala suaves.
- Em `GlanceSettings.swift`, adicionamos `defaults.synchronize()` imediato nas propriedades `hasCompletedOnboarding`, `onboardingResumeStep` e `hasAcknowledgedSecurityNotice`.
- Em `OnboardingController.swift`, garantimos que o foco do campo de texto seja liberado antes da transição final e que a abertura da janela de preferências ocorra após a conclusão do fechamento do entalhe.

---

## 16. Scripts de Compilação e Geração de Instaladores

Foram incluídos scripts prontos e independentes na raiz do projeto:

### Compilar o Aplicativo
```bash
./build_app.sh
```
Compila os arquivos Swift para `x86_64-apple-macos12.0` com otimização completa (`-O -whole-module-optimization`), embute o Sparkle framework, compila o modelo Core ML, gera o `Info.plist`, cria o `AppIcon.icns` e assina com designated requirement estável. O binário final é gerado em `build/Glance.app`.

### Gerar os Instaladores (.dmg, .pkg e .zip)
```bash
./create_installer.sh
```
Gera na pasta `dist/`:
- **`Glance-macOS-Monterey.dmg`**: Imagem de disco limpa contendo exclusivamente o `Glance.app` e o atalho para `/Applications`.
- **`Glance-macOS-Monterey.pkg`**: Instalador interativo nativo do macOS para instalação automatizada em `/Applications`.
- **`Glance-macOS-Monterey.zip`**: Pacote compactado do aplicativo pronto para distribuição em GitHub Releases.

---

## 🚀 Como Executar seu Fork

1. Clone o repositório modificado.
2. Execute `./create_installer.sh` para compilar o app e produzir os instaladores.
3. Instale o app em `/Applications/Glance.app`.
4. Conceda as permissões de **Câmera** e **Acessibilidade** em *Preferências do Sistema > Segurança e Privacidade*.
5. Inicie o Glance e realize a configuração inicial!
