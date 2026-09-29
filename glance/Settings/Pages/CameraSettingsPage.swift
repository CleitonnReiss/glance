//
//  CameraSettingsPage.swift
//  glance
//

import SwiftUI

struct CameraSettingsPage: View {
    @ObservedObject var pocController: POCController
    @State private var devices: [CameraDevice] = CameraDeviceCatalog.availableDevices()
    @ObservedObject private var settings = GlanceSettings.shared
    @State private var previewCamera = CameraManager()
    @State private var isPreviewShown = false

    @State private var isUnlocking = false
    @State private var sessionError: String?

    private var isSessionUnlocked: Bool { pocController.isSessionUnlocked }

    var body: some View {
        ZStack(alignment: .top) {
            lockedState
                .opacity(isSessionUnlocked ? 0 : 1)
                .allowsHitTesting(!isSessionUnlocked)
                .accessibilityHidden(isSessionUnlocked)

            unlockedState
                .opacity(isSessionUnlocked ? 1 : 0)
                .allowsHitTesting(isSessionUnlocked)
                .accessibilityHidden(!isSessionUnlocked)
        }
        .animation(SettingsMetrics.stateTransitionAnimation, value: isSessionUnlocked)
        // Gated on isSessionUnlocked so the header's refresh icon doesn't
        // show while this page is displaying the locked prompt.
        .preference(
            key: HeaderTrailingActionKey.self,
            value: isSessionUnlocked ? HeaderAction(perform: refreshDevices) : nil
        )
        .onAppear { pocController.refreshCredentialStatus() }
        .onChange(of: isSessionUnlocked) { unlocked in
            guard !unlocked else { return }
            hidePreview()
        }
        .onDisappear { hidePreview() }
        // Password/name/enrollment flows run in the notch, outside this
        // window, so nothing else prompts a re-check once one closes.
        .onChange(of: NotchOverlayController.shared.phase) { newPhase in
            guard newPhase == .closed else { return }
            pocController.refreshCredentialStatus()
        }
    }

    // MARK: - Locked

    private var lockedState: some View {
        let lang = settings.appLanguage
        return SettingsEmptyStateView(
            icon: "lock.fill",
            message: L10n.string(.sessionLocked, lang: lang),
            buttonTitle: isUnlocking ? L10n.string(.authenticatingBtn, lang: lang) : L10n.string(.unlockSessionBtn, lang: lang),
            isButtonEnabled: !isUnlocking,
            caption: sessionError,
            action: unlock
        )
    }

    // MARK: - Unlocked

    private var unlockedState: some View {
        let lang = settings.appLanguage
        return VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
            SettingsGroup {
                cameraPicker(title: L10n.string(.cameraDefaultTitle, lang: lang), selection: $settings.defaultCameraID, lang: lang)
                SettingsGroupDivider()
                cameraPicker(title: L10n.string(.cameraBuiltInTitle, lang: lang), selection: $settings.builtInDisplayCameraID, lang: lang)
                SettingsGroupDivider()
                cameraPicker(title: L10n.string(.cameraExternalTitle, lang: lang), selection: $settings.externalDisplayCameraID, lang: lang)
            }

            SettingsSectionTitle(text: L10n.string(.previewTitle, lang: lang))
            .padding(.bottom, -4)
            previewArea(lang: lang)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.rowRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsMetrics.rowRadius)
                        .strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                )

            if isPreviewShown, let error = previewCamera.errorMessage {
                SettingsCaption(text: error)
            }
        }
        .onChange(of: settings.defaultCameraID) { _ in restartPreview() }
        .onChange(of: settings.builtInDisplayCameraID) { _ in restartPreview() }
        .onChange(of: settings.externalDisplayCameraID) { _ in restartPreview() }
    }

    /// Live feed, or a placeholder until "Show preview" is tapped — opening
    /// this page alone should never request camera access.
    @ViewBuilder
    private func previewArea(lang: AppLanguage) -> some View {
        if isPreviewShown {
            CameraPreviewView(session: previewCamera.session, faces: [])
        } else {
            ZStack {
                SettingsMetrics.rowColor
                SettingsPrimaryButton(title: L10n.string(.showPreviewBtn, lang: lang), action: showPreview)
            }
        }
    }

    private func showPreview() {
        isPreviewShown = true
        Task { await previewCamera.start() }
    }

    private func hidePreview() {
        guard isPreviewShown else { return }
        previewCamera.stop()
        isPreviewShown = false
    }

    /// `CameraManager` only re-resolves its device on `start()`, so restart
    /// it to reflect a new pick. No-op while hidden — picking a camera must
    /// not be what quietly turns it on.
    private func restartPreview() {
        guard isPreviewShown else { return }
        previewCamera.stop()
        Task { await previewCamera.start() }
    }

    private func cameraPicker(title: String, selection: Binding<String?>, lang: AppLanguage) -> some View {
        SettingsRowContent(title: title) {
            SettingsMenuPickerPill(label: cameraLabel(for: selection.wrappedValue, lang: lang)) {
                Button(L10n.string(.systemDefaultCamera, lang: lang)) { selection.wrappedValue = nil }
                ForEach(devices) { device in
                    Button(device.name) { selection.wrappedValue = device.id }
                }
            }
        }
    }

    /// Fired by the header's refresh icon (see `HeaderTrailingActionKey`).
    private func refreshDevices() {
        devices = CameraDeviceCatalog.availableDevices()
    }

    private func cameraLabel(for id: String?, lang: AppLanguage) -> String {
        guard let id, let device = devices.first(where: { $0.id == id }) else {
            return L10n.string(.systemDefaultCamera, lang: lang)
        }
        return device.name
    }

    // MARK: - Actions

    private func unlock() {
        isUnlocking = true
        sessionError = nil
        Task {
            await pocController.unlockSession()
            sessionError = pocController.sessionError
            isUnlocking = false
        }
    }
}
