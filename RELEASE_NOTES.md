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

### 6. 🧹 Desinstalação Sem Rastros e Auto-Limpeza ao Mover para a Lixeira
- **Auto-Limpeza Imediata ao Mover para a Lixeira**: O Glance monitora o ciclo de vida do seu próprio bundle no disco. Caso você arraste o `Glance.app` para a Lixeira (`~/.Trash`) ou o delete da pasta Aplicativos, ele detecta a remoção em tempo real e purga imediatamente todos os arquivos faciais em Application Support, credenciais do Chaveiro, LaunchAgent e preferências do UserDefaults, deixando o macOS 100% limpo sem arquivos órfãos.
- **Desinstalação 100% Integrada**: Adicionada também a opção **"Uninstall Glance Completely..."** no menu da barra superior e na aba Sobre das preferências. Remove com um clique todos os dados biométricos e move o app para a Lixeira.
- **Detecção de Reinstalação de Fábrica**: Se você excluir o app e reinstalar uma cópia no futuro, ele detecta a nova instalação e reinicia 100% como novo, abrindo o assistente inicial de Onboarding do zero.
- **Instalador DMG Limpo e Seguro**: A imagem de disco contém estritamente o `Glance.app` e o atalho para a pasta `Applications`.

### 7. 🛡️ Estabilidade no Onboarding e Persistência Imediata de Dados
- **Correção do Crash ao Confirmar Senha (`EXC_BAD_ACCESS` / `vImageConverter`)**: Eliminada a falha de desalocamento em `QuartzCore`/`CoreGraphics` ao concluir o assistente de configuração. A transição agora utiliza `OffsetOpacity` nativa, dispensando filtros de rasterização de desfoque conflitantes com o campo seguro de senha no macOS 12 Monterey.
- **Sincronização Imediata no Disco**: A gravação de conclusão do Onboarding e de chave de sessão é persistida instantaneamente com `defaults.synchronize()`, garantindo que o app nunca perca o estado de configuração nem reabra pedindo onboarding novamente após a configuração inicial.

### 8. 📦 Correção de Permissões no Instalador PKG (Equiparação 100% com DMG)
- **Desbloqueio dos Pesos do Modelo ArcFace**: Corrigidas as permissões restritivas (`40700` para `40755`) no diretório `ArcFace.mlmodelc/weights/` que bloqueavam a leitura de `weight.bin` por usuários não-root, destravando completamente o cadastro facial no PKG.
- **Propriedade Correta do Bundle (`$CONSOLE_USER:staff`)**: O script `postinstall` agora detecta o usuário ativo do console e atribui a titularidade do `/Applications/Glance.app` diretamente a ele. Com isso, tanto a opção de desinstalação integrada do app quanto o ato de arrastar para a Lixeira do Finder funcionam sem pedir senha de administrador, exatamente como no DMG.

### 9. 🌐 Internacionalização Completa (Português do Brasil, English, Español)
- **Seletor de Idiomas em Tempo Real**: Adicionado menu de seleção de idiomas na primeira linha da aba **Geral** das Configurações, com troca instantânea e reatividade em tempo real em todas as telas sem necessidade de reiniciar o aplicativo.
- **Tradução de 100% da Interface**:
  - Todo o fluxo de Onboarding (Boas-vindas, Permissões, Aviso de Segurança, Seleção de Câmera, as 9 poses de orientação da cabeça e telas de Nome/Senha/Conclusão).
  - Todas as abas de Preferências (Geral, Seu Rosto, Senha, Câmera, Reconhecimento e Sobre).
  - Ícone e itens da barra de status superior (menu do sistema).
  - Caixas de diálogo de confirmação (redefinição de fábrica e desinstalação completa).
- **Detecção Inteligente do Sistema**: O aplicativo seleciona automaticamente o Português do Brasil para usuários com macOS em português ou caso nenhuma preferência tenha sido definida.

### 10. 🌍 Seletor de Idioma (Globo) na Tela Inicial e Layout Responsivo Aprimorado
- **Botão de Globo na Primeira Tela de Boas-vindas**: Adicionado botão de globo com menu dropdown elegante ao lado do botão de iniciar/avançar no Onboarding, permitindo escolher o idioma desejado (Português, Inglês ou Espanhol) antes mesmo de iniciar a configuração.
- **Ajuste Proporcional do Layout para Textos Traduzidos**:
  - Ampliada a largura do painel (`panelWidth` de 380 para 400px) e altura de cada etapa, eliminando cortes em textos mais longos característicos do Português e Espanhol.
  - Tipografia ajustada (`title` 21pt, legendas 11.5pt) com suporte a escalonamento adaptativo (`minimumScaleFactor` de 0.75 a 0.85).
  - Botões com largura flexível e auto-ajuste de espaçamento, impedindo que textos como "Não, obrigado", "Entendi" ou "Concedido" quebrem ou fiquem espremidos.
  - Janela de configurações ampliada para 520px com limites de largura de legendas expandidos para 280px.

---

## 🛠️ Instruções de Instalação e Permissões

### ⚡ Instalação Rápida em 1 Clique (Terminal — Sem bloqueio do Gatekeeper):
Basta colar no Terminal do Mac:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cleitonnreiss/glance/main/install.sh)"
```

### Pelo Instalador DMG:
1. Baixe o **`Glance-macOS-Monterey.dmg`**.
2. **Como abrir no macOS**: Como este é um projeto open-source comunitário (sem anuidade de desenvolvedor pago da Apple), o Gatekeeper avisa *"desenvolvedor não identificado"*.
   - Basta clicar com o **botão direito (ou segurar Control e clicar)** no arquivo `.dmg` e selecionar **"Abrir"**.
   - Na janela de confirmação que surgir, clique em **"Abrir"**.
   *(Ou acesse **Preferências do Sistema > Segurança e Privacidade > Geral** e clique em **"Abrir Mesmo Assim"**).*
3. Arraste o **Glance.app** para a pasta **Applications** (Aplicativos).
4. Abra o Glance pela pasta Aplicativos.

### Pelo Instalador PKG:
1. Baixe o **`Glance-macOS-Monterey.pkg`**.
2. Clique com o botão direito -> **Abrir** -> **Abrir**. O instalador instala diretamente em `/Applications`.

### Permissões e Uso:
1. Conceda as permissões solicitadas:
   - **Câmera**: para reconhecimento facial local (os frames nunca saem da memória).
   - **Acessibilidade**: para permitir que o Glance digite sua senha de forma automatizada na tela de login.
2. Siga o assistente no entalhe para cadastrar seu rosto e salvar a senha do Mac.
3. Pressione **⌃⌘L** a qualquer momento para bloquear e testar o desbloqueio facial!
