//
//  Localization.swift
//  glance
//

import Foundation

enum L10nKey: String {
    // MARK: - Common Actions & Labels
    case next
    case back
    case continueBtn
    case save
    case confirm
    case saving
    case cancel
    case close
    case grant
    case granted
    case done
    case delete
    case remove
    case change
    case check
    case send
    case reset
    case uninstall
    case language

    // MARK: - Onboarding
    case introTitle
    case introSubtitle
    case permTitle
    case permAccessibilityTitle
    case permAccessibilityDetail
    case permCameraTitle
    case permCameraDetail
    case secNoticeTitle
    case secNoticeDetail
    case secNoticeDecline
    case secNoticeAccept
    case preSetupTitle
    case preSetupDetail
    case selectCameraTitle
    case selectCameraSubtitle
    case systemDefaultCamera
    case enrollFaceCaptured
    case enrollBringCloser
    case poseCenter
    case poseLeft
    case poseTopLeft
    case poseTop
    case poseTopRight
    case poseRight
    case poseBottomRight
    case poseBottom
    case poseBottomLeft
    case nameStepTitle
    case nameStepSubtitle
    case namePlaceholder
    case nameErrorEmpty
    case nameErrorDuplicate
    case passwordStepTitle
    case passwordStepSubtitle
    case passwordPlaceholder
    case passwordErrorEmpty
    case completeTitle

    // MARK: - Settings Tabs
    case tabGeneral
    case tabFace
    case tabPassword
    case tabCamera
    case tabRecognition
    case tabAbout
    case tabFaceLab

    // MARK: - General Settings
    case launchAtLoginTitle
    case enableFaceUnlockTitle
    case triggersTitle
    case triggersSubtitle
    case triggerOnWake
    case triggerOnLock
    case triggerOnSpace
    case displayOnTitle
    case mainDisplay
    case displayDisconnected
    case behaviourTitle
    case retryOnHoverTitle
    case autoRetryTitle
    case hapticFeedbackTitle
    case faceDetectionDurationTitle
    case animationTitle
    case showAnimationTitle
    case animationStyleTitle
    case animationStyleSubtitle
    case animationMinimal
    case animationOriginal
    case inputMonitoringNotice
    case openAccessibilitySettings

    // MARK: - Your Face Settings
    case sessionLocked
    case unlockSessionBtn
    case authenticatingBtn
    case authReasonViewFace
    case notEnrolledTitle
    case setupFaceUnlockBtn
    case deleteFacePrompt
    case deleteFaceMessage
    case faceLoadErrorTitle
    case faceLoadErrorDefault
    case faceLoadRecoveryNotice
    case faceEncryptedTitle
    case faceEncryptedDescription
    case identitiesTitle
    case addFaceHelp
    case noIdentitiesEnabledNotice
    case recaptureBtn
    case deleteFaceBtnHelp
    case qualityNotRecorded
    case qualityPercent
    case noSamplesCaptured
    case differentModelWarning

    // MARK: - Password Settings
    case noPasswordTitle
    case setPasswordBtn
    case passwordEncryptedTitle
    case autoLockTitle
    case autoLockNever
    case autoLock1Day
    case autoLockDays
    case vaultPillUnlocked
    case vaultPillLocked
    case changePasswordTitle
    case changePasswordBtn
    case removePasswordTitle
    case removePasswordBtn

    // MARK: - Camera Settings
    case cameraDefaultTitle
    case cameraBuiltInTitle
    case cameraExternalTitle
    case previewTitle
    case showPreviewBtn
    case refreshCamerasHelp

    // MARK: - Recognition Settings
    case matchConfidenceTitle
    case confLessStrict
    case confDefault
    case confMoreStrict
    case detectionDistanceTitle
    case distClose
    case distDefault
    case distFar
    case livenessTitle
    case livenessToggleTitle
    case livenessToggleSubtitle
    case livenessModeTitle
    case livenessModeSubtitle
    case livenessLight
    case livenessHeavy

    // MARK: - About Settings
    case checkUpdatesTitle
    case autoCheckUpdatesTitle
    case sendFeedbackTitle
    case resetConfigTitle
    case uninstallAppTitle

    // MARK: - Menu Bar
    case menuLockScreen
    case menuVaultUnlocked
    case menuVaultLocked
    case menuSettings
    case menuReset
    case menuUninstall
    case menuQuit

    // MARK: - AppResetter Alerts
    case alertUninstallTitle
    case alertUninstallMessage
    case alertUninstallBtn
    case alertResetTitle
    case alertResetMessage
    case alertResetBtn
}

enum L10n {
    private static let enDict: [L10nKey: String] = [
        .next: "Next",
        .back: "Back",
        .continueBtn: "Continue",
        .save: "Save",
        .confirm: "Confirm",
        .saving: "Saving…",
        .cancel: "Cancel",
        .close: "Close",
        .grant: "Grant",
        .granted: "Granted",
        .done: "Done",
        .delete: "Delete",
        .remove: "Remove",
        .change: "Change",
        .check: "Check",
        .send: "Send",
        .reset: "Reset",
        .uninstall: "Uninstall",
        .language: "Language",

        .introTitle: "Glance",
        .introSubtitle: "Face Unlock for Mac",
        .permTitle: "Permissions",
        .permAccessibilityTitle: "Accessibility",
        .permAccessibilityDetail: "Allow Glance to unlock your Mac",
        .permCameraTitle: "Camera",
        .permCameraDetail: "Allow Glance to recognize your face",
        .secNoticeTitle: "Glance is not as secure as Apple's FaceID or TouchID.",
        .secNoticeDetail: "It uses your Mac's standard webcam and is designed for convenience, not high-security authentication.",
        .secNoticeDecline: "No thanks",
        .secNoticeAccept: "I understand",
        .preSetupTitle: "Set up Face\nRecognition",
        .preSetupDetail: "Follow the directions\nshown on the screen",
        .selectCameraTitle: "Select camera",
        .selectCameraSubtitle: "Used for Face enrollment and for unlocking your Mac",
        .systemDefaultCamera: "System default",
        .enrollFaceCaptured: "Face captured",
        .enrollBringCloser: "Bring your face closer",
        .poseCenter: "Look straight at the camera",
        .poseLeft: "Turn your head slightly left",
        .poseTopLeft: "Turn your head to the top left",
        .poseTop: "Turn your head slightly up",
        .poseTopRight: "Turn your head to the top right",
        .poseRight: "Turn your head slightly right",
        .poseBottomRight: "Turn your head to the bottom right",
        .poseBottom: "Turn your head slightly down",
        .poseBottomLeft: "Turn your head to the bottom left",
        .nameStepTitle: "Name this face",
        .nameStepSubtitle: "Used to tell enrolled faces apart when more than one person is set up on this Mac.",
        .namePlaceholder: "Enter a name...",
        .nameErrorEmpty: "Enter a name.",
        .nameErrorDuplicate: "A face named \"%@\" is already enrolled.",
        .passwordStepTitle: "Enter your password",
        .passwordStepSubtitle: "Your password is required to unlock your Mac. It is encrypted and securely stored on your device. Glance works entirely offline, so your password never leaves your Mac.",
        .passwordPlaceholder: "Enter password...",
        .passwordErrorEmpty: "Enter a password.",
        .completeTitle: "You're all set",

        .tabGeneral: "General",
        .tabFace: "Face",
        .tabPassword: "Password",
        .tabCamera: "Camera",
        .tabRecognition: "Recognition",
        .tabAbout: "About",
        .tabFaceLab: "Face Lab",

        .launchAtLoginTitle: "Launch at login",
        .enableFaceUnlockTitle: "Enable Face Unlock",
        .triggersTitle: "Triggers",
        .triggersSubtitle: "Select multiple",
        .triggerOnWake: "On wake",
        .triggerOnLock: "On lock",
        .triggerOnSpace: "On space",
        .displayOnTitle: "Display on",
        .mainDisplay: "Main display",
        .displayDisconnected: "(disconnected)",
        .behaviourTitle: "Behaviour",
        .retryOnHoverTitle: "Retry on notch hover",
        .autoRetryTitle: "Auto retry once after failure",
        .hapticFeedbackTitle: "Haptic feedback",
        .faceDetectionDurationTitle: "Face detection duration",
        .animationTitle: "Animation",
        .showAnimationTitle: "Show animation",
        .animationStyleTitle: "Style",
        .animationStyleSubtitle: "The animation that appears when unlocking your Mac",
        .animationMinimal: "Minimal",
        .animationOriginal: "Original",
        .inputMonitoringNotice: "“On space” reads the keyboard directly to see the space key on the lock screen, which needs Accessibility — the same permission glance uses to type your password. Switch glance on under Privacy & Security → Accessibility, then quit and reopen glance.",
        .openAccessibilitySettings: "Open Accessibility settings",

        .sessionLocked: "Session locked",
        .unlockSessionBtn: "Unlock session",
        .authenticatingBtn: "Authenticating…",
        .authReasonViewFace: "Authenticate to view your enrolled face",
        .notEnrolledTitle: "Face enrollment",
        .setupFaceUnlockBtn: "Set up Face Unlock",
        .deleteFacePrompt: "Delete this enrolled face?",
        .deleteFaceMessage: "\"%@\" will stop being recognized until you enroll them again.",
        .faceLoadErrorTitle: "Enrolled faces couldn't be read",
        .faceLoadErrorDefault: "The stored data couldn't be decrypted with this session key.",
        .faceLoadRecoveryNotice: "Nothing has been deleted, and Glance will not overwrite it — enrolling is blocked until this resolves. Quit and reopen Glance to retry. If it keeps failing, the session key no longer matches this data: remove the stored password on the Password tab to clear both, then set up again.",
        .faceEncryptedTitle: "Face encrypted",
        .faceEncryptedDescription: "Enroll separate identities to use Glance with multiple people, accessories (ex. glasses), facial expressions, or new lighting environments. This improves recognition quality.",
        .identitiesTitle: "Identities",
        .addFaceHelp: "Enroll another face",
        .noIdentitiesEnabledNotice: "No identities are enabled — face unlock won't recognize anyone until you switch one back on.",
        .recaptureBtn: "Recapture",
        .deleteFaceBtnHelp: "Delete %@",
        .qualityNotRecorded: "Capture quality • not recorded",
        .qualityPercent: "Capture quality • %d%%",
        .noSamplesCaptured: "No samples captured",
        .differentModelWarning: "Captured with a different recognition model — recapture before this face can unlock your Mac.",

        .noPasswordTitle: "Set up a password",
        .setPasswordBtn: "Set password",
        .passwordEncryptedTitle: "Password encrypted",
        .autoLockTitle: "Auto lock session",
        .autoLockNever: "Never",
        .autoLock1Day: "1 day",
        .autoLockDays: "%d days",
        .vaultPillUnlocked: "Vault: Unlocked",
        .vaultPillLocked: "Vault: Locked",
        .changePasswordTitle: "Change password",
        .changePasswordBtn: "Change",
        .removePasswordTitle: "Remove password",
        .removePasswordBtn: "Remove",

        .cameraDefaultTitle: "Default",
        .cameraBuiltInTitle: "Built-in display",
        .cameraExternalTitle: "External display",
        .previewTitle: "Preview",
        .showPreviewBtn: "Show preview",
        .refreshCamerasHelp: "Refresh camera list",

        .matchConfidenceTitle: "Match confidence",
        .confLessStrict: "Less strict",
        .confDefault: "Default",
        .confMoreStrict: "More strict",
        .detectionDistanceTitle: "Detection distance",
        .distClose: "Close",
        .distDefault: "Default",
        .distFar: "Far",
        .livenessTitle: "Liveness",
        .livenessToggleTitle: "Liveness detection",
        .livenessToggleSubtitle: "Checks that you're a live person, not a photo. May increase unlock time.",
        .livenessModeTitle: "Strength",
        .livenessModeSubtitle: "Light includes basic protection. Heavy requires you to blink or slightly move your head.",
        .livenessLight: "Light",
        .livenessHeavy: "Heavy",

        .checkUpdatesTitle: "Check for Updates",
        .autoCheckUpdatesTitle: "Automatically check for updates",
        .sendFeedbackTitle: "Send Feedback",
        .resetConfigTitle: "Reset Configuration",
        .uninstallAppTitle: "Uninstall Glance",

        .menuLockScreen: "Lock Screen",
        .menuVaultUnlocked: "Credential Vault: Unlocked",
        .menuVaultLocked: "Credential Vault: Locked",
        .menuSettings: "Settings...",
        .menuReset: "Reset & Reconfigure...",
        .menuUninstall: "Uninstall Glance Completely...",
        .menuQuit: "Quit Glance",

        .alertUninstallTitle: "Uninstall Glance Completely?",
        .alertUninstallMessage: "This will remove all settings, enrolled face data, Keychain password, auto-start, and move Glance to your Mac's Trash.",
        .alertUninstallBtn: "Uninstall",
        .alertResetTitle: "Reset All Settings?",
        .alertResetMessage: "This will erase the current face enrollment, Keychain password, and preferences, allowing you to configure Glance again from scratch.",
        .alertResetBtn: "Reset and Configure"
    ]

    private static let ptBRDict: [L10nKey: String] = [
        .next: "Avançar",
        .back: "Voltar",
        .continueBtn: "Continuar",
        .save: "Salvar",
        .confirm: "Confirmar",
        .saving: "Salvando…",
        .cancel: "Cancelar",
        .close: "Fechar",
        .grant: "Conceder",
        .granted: "Concedido",
        .done: "Concluído",
        .delete: "Excluir",
        .remove: "Remover",
        .change: "Alterar",
        .check: "Verificar",
        .send: "Enviar",
        .reset: "Redefinir",
        .uninstall: "Desinstalar",
        .language: "Idioma",

        .introTitle: "Glance",
        .introSubtitle: "Desbloqueio Facial para Mac",
        .permTitle: "Permissões",
        .permAccessibilityTitle: "Acessibilidade",
        .permAccessibilityDetail: "Permita que o Glance desbloqueie seu Mac",
        .permCameraTitle: "Câmera",
        .permCameraDetail: "Permita que o Glance reconheça seu rosto",
        .secNoticeTitle: "O Glance não é tão seguro quanto o FaceID ou TouchID da Apple.",
        .secNoticeDetail: "Ele usa a webcam padrão do seu Mac e foi desenvolvido para conveniência, não para autenticação de alta segurança.",
        .secNoticeDecline: "Não, obrigado",
        .secNoticeAccept: "Entendi",
        .preSetupTitle: "Configurar Reconhecimento\nFacial",
        .preSetupDetail: "Siga as instruções\nexibidas na tela",
        .selectCameraTitle: "Selecionar câmera",
        .selectCameraSubtitle: "Usada para o cadastro facial e para desbloquear seu Mac",
        .systemDefaultCamera: "Padrão do sistema",
        .enrollFaceCaptured: "Rosto capturado",
        .enrollBringCloser: "Aproxime seu rosto",
        .poseCenter: "Olhe diretamente para a câmera",
        .poseLeft: "Vire a cabeça levemente para a esquerda",
        .poseTopLeft: "Vire a cabeça para cima e à esquerda",
        .poseTop: "Incline a cabeça levemente para cima",
        .poseTopRight: "Vire a cabeça para cima e à direita",
        .poseRight: "Vire a cabeça levemente para a direita",
        .poseBottomRight: "Vire a cabeça para baixo e à direita",
        .poseBottom: "Incline a cabeça levemente para baixo",
        .poseBottomLeft: "Vire a cabeça para baixo e à esquerda",
        .nameStepTitle: "Dê um nome a este rosto",
        .nameStepSubtitle: "Usado para diferenciar identidades quando mais de uma pessoa estiver cadastrada neste Mac.",
        .namePlaceholder: "Digite um nome...",
        .nameErrorEmpty: "Digite um nome.",
        .nameErrorDuplicate: "Já existe um rosto cadastrado com o nome \"%@\".",
        .passwordStepTitle: "Digite sua senha",
        .passwordStepSubtitle: "Sua senha é necessária para desbloquear o Mac. Ela é criptografada e armazenada com segurança no seu dispositivo. O Glance funciona 100% offline, de modo que sua senha nunca sai do seu Mac.",
        .passwordPlaceholder: "Digite a senha...",
        .passwordErrorEmpty: "Digite uma senha.",
        .completeTitle: "Tudo pronto!",

        .tabGeneral: "Geral",
        .tabFace: "Rosto",
        .tabPassword: "Senha",
        .tabCamera: "Câmera",
        .tabRecognition: "Reconhecimento",
        .tabAbout: "Sobre",
        .tabFaceLab: "Laboratório Facial",

        .launchAtLoginTitle: "Iniciar no login",
        .enableFaceUnlockTitle: "Ativar Desbloqueio Facial",
        .triggersTitle: "Gatilhos",
        .triggersSubtitle: "Selecione múltiplos",
        .triggerOnWake: "Ao despertar",
        .triggerOnLock: "Ao bloquear",
        .triggerOnSpace: "Na barra de espaço",
        .displayOnTitle: "Exibir em",
        .mainDisplay: "Monitor principal",
        .displayDisconnected: "(desconectado)",
        .behaviourTitle: "Comportamento",
        .retryOnHoverTitle: "Tentar novamente ao passar o mouse",
        .autoRetryTitle: "Tentar novamente após falha",
        .hapticFeedbackTitle: "Retorno tátil (Haptic)",
        .faceDetectionDurationTitle: "Duração da detecção facial",
        .animationTitle: "Animação",
        .showAnimationTitle: "Exibir animação",
        .animationStyleTitle: "Estilo",
        .animationStyleSubtitle: "A animação exibida ao desbloquear o Mac",
        .animationMinimal: "Mínimo",
        .animationOriginal: "Original",
        .inputMonitoringNotice: "A opção “Na barra de espaço” lê o teclado diretamente na tela de bloqueio, o que requer Acessibilidade — a mesma permissão usada para digitar a senha. Ative o Glance em Preferências do Sistema → Segurança e Privacidade → Acessibilidade, depois feche e reabra o aplicativo.",
        .openAccessibilitySettings: "Abrir ajustes de Acessibilidade",

        .sessionLocked: "Sessão bloqueada",
        .unlockSessionBtn: "Desbloquear sessão",
        .authenticatingBtn: "Autenticando…",
        .authReasonViewFace: "Autentique-se para gerenciar seus rostos cadastrados",
        .notEnrolledTitle: "Cadastro facial",
        .setupFaceUnlockBtn: "Configurar Desbloqueio Facial",
        .deleteFacePrompt: "Excluir este rosto cadastrado?",
        .deleteFaceMessage: "\"%@\" deixará de ser reconhecido até que você o cadastre novamente.",
        .faceLoadErrorTitle: "Não foi possível ler os rostos cadastrados",
        .faceLoadErrorDefault: "Os dados armazenados não puderam ser descriptografados com esta chave de sessão.",
        .faceLoadRecoveryNotice: "Nenhum arquivo foi apagado e o Glance não irá sobrescrevê-los — novos cadastros estão bloqueados até que isso se resolva. Feche e reabra o Glance para tentar novamente. Se persistir, remova a senha salva na aba Senha para reconfigurar.",
        .faceEncryptedTitle: "Rosto criptografado",
        .faceEncryptedDescription: "Cadastre identidades adicionais para usar o Glance com outras pessoas, acessórios (ex. óculos), diferentes expressões ou novas condições de iluminação. Isso melhora a qualidade do reconhecimento.",
        .identitiesTitle: "Identidades",
        .addFaceHelp: "Cadastrar outro rosto",
        .noIdentitiesEnabledNotice: "Nenhuma identidade ativada — o desbloqueio facial não reconhecerá ninguém até você reativar ao menos uma.",
        .recaptureBtn: "Recapturar",
        .deleteFaceBtnHelp: "Excluir %@",
        .qualityNotRecorded: "Qualidade da captura • não registrada",
        .qualityPercent: "Qualidade da captura • %d%%",
        .noSamplesCaptured: "Nenhuma amostra capturada",
        .differentModelWarning: "Capturado com outro modelo de reconhecimento — recapture antes que este rosto possa desbloquear seu Mac.",

        .noPasswordTitle: "Configurar uma senha",
        .setPasswordBtn: "Definir senha",
        .passwordEncryptedTitle: "Senha criptografada",
        .autoLockTitle: "Bloqueio automático da sessão",
        .autoLockNever: "Nunca",
        .autoLock1Day: "1 dia",
        .autoLockDays: "%d dias",
        .vaultPillUnlocked: "Cofre: Desbloqueado",
        .vaultPillLocked: "Cofre: Bloqueado",
        .changePasswordTitle: "Alterar senha",
        .changePasswordBtn: "Alterar",
        .removePasswordTitle: "Remover senha",
        .removePasswordBtn: "Remover",

        .cameraDefaultTitle: "Padrão",
        .cameraBuiltInTitle: "Tela integrada",
        .cameraExternalTitle: "Monitor externo",
        .previewTitle: "Pré-visualização",
        .showPreviewBtn: "Mostrar pré-visualização",
        .refreshCamerasHelp: "Atualizar lista de câmeras",

        .matchConfidenceTitle: "Confiança do reconhecimento",
        .confLessStrict: "Menos rigoroso",
        .confDefault: "Padrão",
        .confMoreStrict: "Mais rigoroso",
        .detectionDistanceTitle: "Distância de detecção",
        .distClose: "Perto",
        .distDefault: "Padrão",
        .distFar: "Longe",
        .livenessTitle: "Detecção de Vida (Liveness)",
        .livenessToggleTitle: "Detecção de presença real",
        .livenessToggleSubtitle: "Verifica se você é uma pessoa real e não uma foto. Pode aumentar levemente o tempo de desbloqueio.",
        .livenessModeTitle: "Intensidade",
        .livenessModeSubtitle: "Leve inclui proteção básica contra fotos. Avançado exige piscar os olhos ou mover levemente a cabeça.",
        .livenessLight: "Leve",
        .livenessHeavy: "Avançado",

        .checkUpdatesTitle: "Buscar Atualizações",
        .autoCheckUpdatesTitle: "Buscar atualizações automaticamente",
        .sendFeedbackTitle: "Enviar Feedback",
        .resetConfigTitle: "Redefinir Configuração",
        .uninstallAppTitle: "Desinstalar o Glance",

        .menuLockScreen: "Bloquear Tela",
        .menuVaultUnlocked: "Cofre de Credenciais: Desbloqueado",
        .menuVaultLocked: "Cofre de Credenciais: Bloqueado",
        .menuSettings: "Configurações...",
        .menuReset: "Redefinir e Reconfigurar...",
        .menuUninstall: "Desinstalar o Glance Completamente...",
        .menuQuit: "Encerrar o Glance",

        .alertUninstallTitle: "Desinstalar o Glance Completamente?",
        .alertUninstallMessage: "Isso removerá todas as configurações, os dados faciais cadastrados, a senha do Chaveiro, a inicialização automática e moverá o Glance para a Lixeira do seu Mac.",
        .alertUninstallBtn: "Desinstalar",
        .alertResetTitle: "Redefinir Todas as Configurações?",
        .alertResetMessage: "Isso apagará o cadastro facial atual, a senha do Chaveiro e as preferências, permitindo que você configure o Glance novamente do zero.",
        .alertResetBtn: "Redefinir e Configurar"
    ]

    private static let esDict: [L10nKey: String] = [
        .next: "Siguiente",
        .back: "Atrás",
        .continueBtn: "Continuar",
        .save: "Guardar",
        .confirm: "Confirmar",
        .saving: "Guardando…",
        .cancel: "Cancelar",
        .close: "Cerrar",
        .grant: "Conceder",
        .granted: "Concedido",
        .done: "Hecho",
        .delete: "Eliminar",
        .remove: "Quitar",
        .change: "Cambiar",
        .check: "Buscar",
        .send: "Enviar",
        .reset: "Restablecer",
        .uninstall: "Desinstalar",
        .language: "Idioma",

        .introTitle: "Glance",
        .introSubtitle: "Desbloqueo Facial para Mac",
        .permTitle: "Permisos",
        .permAccessibilityTitle: "Accesibilidad",
        .permAccessibilityDetail: "Permite que Glance desbloquee tu Mac",
        .permCameraTitle: "Cámara",
        .permCameraDetail: "Permite que Glance reconozca tu rostro",
        .secNoticeTitle: "Glance no es tan seguro como FaceID o TouchID de Apple.",
        .secNoticeDetail: "Utiliza la cámara web estándar de su Mac y está diseñado para conveniencia, no para autenticación de alta seguridad.",
        .secNoticeDecline: "No, gracias",
        .secNoticeAccept: "Entendido",
        .preSetupTitle: "Configurar Reconocimiento\nFacial",
        .preSetupDetail: "Siga las instrucciones\nmostradas en pantalla",
        .selectCameraTitle: "Seleccionar cámara",
        .selectCameraSubtitle: "Usada para el registro facial y para desbloquear su Mac",
        .systemDefaultCamera: "Predeterminada del sistema",
        .enrollFaceCaptured: "Rostro capturado",
        .enrollBringCloser: "Acerque su rostro",
        .poseCenter: "Mire directamente a la cámara",
        .poseLeft: "Gire la cabeza ligeramente a la izquierda",
        .poseTopLeft: "Gire la cabeza hacia arriba y a la izquierda",
        .poseTop: "Incline la cabeza ligeramente hacia arriba",
        .poseTopRight: "Gire la cabeza hacia arriba y a la derecha",
        .poseRight: "Gire la cabeza ligeramente a la derecha",
        .poseBottomRight: "Gire la cabeza hacia abajo y a la derecha",
        .poseBottom: "Incline la cabeza ligeramente hacia abajo",
        .poseBottomLeft: "Gire la cabeza hacia abajo y a la izquierda",
        .nameStepTitle: "Nombre este rostro",
        .nameStepSubtitle: "Se usa para diferenciar identidades cuando más de una persona está configurada en este Mac.",
        .namePlaceholder: "Ingrese un nombre...",
        .nameErrorEmpty: "Ingrese un nombre.",
        .nameErrorDuplicate: "Ya existe un rostro registrado con el nombre \"%@\".",
        .passwordStepTitle: "Ingrese su contraseña",
        .passwordStepSubtitle: "Su contraseña es necesaria para desbloquear su Mac. Está encriptada y almacenada de forma segura en su dispositivo. Glance funciona completamente sin conexión, por lo que su contraseña nunca sale de su Mac.",
        .passwordPlaceholder: "Ingrese la contraseña...",
        .passwordErrorEmpty: "Ingrese una contraseña.",
        .completeTitle: "¡Todo listo!",

        .tabGeneral: "General",
        .tabFace: "Rostro",
        .tabPassword: "Contraseña",
        .tabCamera: "Cámara",
        .tabRecognition: "Reconocimiento",
        .tabAbout: "Acerca de",
        .tabFaceLab: "Laboratorio Facial",

        .launchAtLoginTitle: "Iniciar al iniciar sesión",
        .enableFaceUnlockTitle: "Activar Desbloqueo Facial",
        .triggersTitle: "Activadores",
        .triggersSubtitle: "Seleccionar varios",
        .triggerOnWake: "Al reactivar",
        .triggerOnLock: "Al bloquear",
        .triggerOnSpace: "Con barra espaciadora",
        .displayOnTitle: "Mostrar en",
        .mainDisplay: "Pantalla principal",
        .displayDisconnected: "(desconectado)",
        .behaviourTitle: "Comportamiento",
        .retryOnHoverTitle: "Reintentar al pasar el cursor",
        .autoRetryTitle: "Reintentar tras error",
        .hapticFeedbackTitle: "Respuesta háptica",
        .faceDetectionDurationTitle: "Duración de detección facial",
        .animationTitle: "Animación",
        .showAnimationTitle: "Mostrar animación",
        .animationStyleTitle: "Estilo",
        .animationStyleSubtitle: "La animación mostrada al desbloquear su Mac",
        .animationMinimal: "Mínimo",
        .animationOriginal: "Original",
        .inputMonitoringNotice: "“Con barra espaciadora” lee el teclado en la pantalla de bloqueo, lo que requiere Accesibilidad — el mismo permiso que usa Glance para escribir su contraseña. Active Glance en Privacidad y Seguridad → Accesibilidad, luego cierre y vuelva a abrir Glance.",
        .openAccessibilitySettings: "Abrir ajustes de Accesibilidad",

        .sessionLocked: "Sesión bloqueada",
        .unlockSessionBtn: "Desbloquear sesión",
        .authenticatingBtn: "Autenticando…",
        .authReasonViewFace: "Autentíquese para ver sus rostros registrados",
        .notEnrolledTitle: "Registro facial",
        .setupFaceUnlockBtn: "Configurar Desbloqueo Facial",
        .deleteFacePrompt: "¿Eliminar este rostro registrado?",
        .deleteFaceMessage: "\"%@\" dejará de ser reconocido hasta que lo registre nuevamente.",
        .faceLoadErrorTitle: "No se pudieron leer los rostros registrados",
        .faceLoadErrorDefault: "Los datos guardados no se pudieron descifrar con esta clave de sesión.",
        .faceLoadRecoveryNotice: "No se ha eliminado nada y Glance no lo sobrescribirá. Cierre y vuelva a abrir Glance para reintentar. Si el error continúa, elimine la contraseña en la pestaña Contraseña para reconfigurar.",
        .faceEncryptedTitle: "Rostro encriptado",
        .faceEncryptedDescription: "Registre identidades separadas para usar Glance con varias personas, accesorios (ej. anteojos), diferentes expresiones o nueva iluminación. Esto mejora la calidad del reconocimiento.",
        .identitiesTitle: "Identidades",
        .addFaceHelp: "Registrar otro rostro",
        .noIdentitiesEnabledNotice: "No hay identidades activadas — el desbloqueo facial no reconocerá a nadie hasta que vuelva a activar al menos una.",
        .recaptureBtn: "Recapturar",
        .deleteFaceBtnHelp: "Eliminar %@",
        .qualityNotRecorded: "Calidad de captura • no registrada",
        .qualityPercent: "Calidad de captura • %d%%",
        .noSamplesCaptured: "Sin muestras capturadas",
        .differentModelWarning: "Capturado con un modelo de reconocimiento diferente — vuelva a capturarlo para desbloquear su Mac.",

        .noPasswordTitle: "Configurar una contraseña",
        .setPasswordBtn: "Establecer contraseña",
        .passwordEncryptedTitle: "Contraseña encriptada",
        .autoLockTitle: "Bloqueo automático de sesión",
        .autoLockNever: "Nunca",
        .autoLock1Day: "1 día",
        .autoLockDays: "%d días",
        .vaultPillUnlocked: "Cofre: Desbloqueado",
        .vaultPillLocked: "Cofre: Bloqueado",
        .changePasswordTitle: "Cambiar contraseña",
        .changePasswordBtn: "Cambiar",
        .removePasswordTitle: "Eliminar contraseña",
        .removePasswordBtn: "Eliminar",

        .cameraDefaultTitle: "Predeterminada",
        .cameraBuiltInTitle: "Pantalla integrada",
        .cameraExternalTitle: "Monitor externo",
        .previewTitle: "Vista previa",
        .showPreviewBtn: "Mostrar vista previa",
        .refreshCamerasHelp: "Actualizar lista de cámaras",

        .matchConfidenceTitle: "Confianza del reconocimiento",
        .confLessStrict: "Menos estricto",
        .confDefault: "Predeterminado",
        .confMoreStrict: "Más estricto",
        .detectionDistanceTitle: "Distancia de detección",
        .distClose: "Cerca",
        .distDefault: "Predeterminado",
        .distFar: "Lejos",
        .livenessTitle: "Detección de Vitalidad (Liveness)",
        .livenessToggleTitle: "Detección de presencia real",
        .livenessToggleSubtitle: "Verifica que seas una persona real y no una foto. Puede aumentar ligeramente el tiempo de desbloqueo.",
        .livenessModeTitle: "Intensidad",
        .livenessModeSubtitle: "Ligero incluye protección básica contra fotos. Avanzado requiere parpadear o mover ligeramente la cabeza.",
        .livenessLight: "Ligero",
        .livenessHeavy: "Avanzado",

        .checkUpdatesTitle: "Buscar Actualizaciones",
        .autoCheckUpdatesTitle: "Buscar actualizaciones automáticamente",
        .sendFeedbackTitle: "Enviar Comentarios",
        .resetConfigTitle: "Restablecer Configuración",
        .uninstallAppTitle: "Desinstalar Glance",

        .menuLockScreen: "Bloquear Pantalla",
        .menuVaultUnlocked: "Bóveda de Credenciales: Desbloqueada",
        .menuVaultLocked: "Bóveda de Credenciales: Bloqueada",
        .menuSettings: "Configuraciones...",
        .menuReset: "Restablecer y Reconfigurar...",
        .menuUninstall: "Desinstalar Glance Completamente...",
        .menuQuit: "Salir de Glance",

        .alertUninstallTitle: "¿Desinstalar Glance Completamente?",
        .alertUninstallMessage: "Esto eliminará todas las configuraciones, los datos faciales registrados, la contraseña del Llavero, el inicio automático y moverá Glance a la Papelera de su Mac.",
        .alertUninstallBtn: "Desinstalar",
        .alertResetTitle: "¿Restablecer Todas las Configuraciones?",
        .alertResetMessage: "Esto borrará el registro facial actual, la contraseña del Llavero y las preferencias, lo que le permitirá configurar Glance nuevamente desde cero.",
        .alertResetBtn: "Restablecer y Configurar"
    ]

    static func string(_ key: L10nKey, lang: AppLanguage = AppLanguage.current) -> String {
        switch lang {
        case .ptBR:
            return ptBRDict[key] ?? enDict[key] ?? key.rawValue
        case .es:
            return esDict[key] ?? enDict[key] ?? key.rawValue
        case .en:
            return enDict[key] ?? key.rawValue
        }
    }

    static func string(_ key: L10nKey, lang: AppLanguage = AppLanguage.current, _ args: CVarArg...) -> String {
        let format = string(key, lang: lang)
        return String(format: format, arguments: args)
    }
}
