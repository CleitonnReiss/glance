//
//  SessionLockButton.swift
//  glance
//
//  The header's trailing pill: shows whether the Settings session is
//  unlocked, and doubles as its on/off switch — unlocks while locked, locks
//  while unlocked.
//

import SwiftUI

struct SessionLockButton: View {
    @ObservedObject var pocController: POCController

    @ObservedObject private var settings = GlanceSettings.shared
    @State private var isUnlocking = false

    var body: some View {
        Button(action: toggleSession) {
            HStack(spacing: 7) {
                Image(systemName: pocController.isSessionUnlocked ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 12))

                Text(label)
                    .font(SettingsMetrics.headerButtonFont)
            }
            .foregroundStyle(SettingsMetrics.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: SettingsMetrics.headerButtonHeight)
            .background(Capsule().fill(SettingsMetrics.rowColor))
            .overlay(
                Capsule()
                    .strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // Only disabled mid-authentication — a tap then would double up the
        // Touch ID prompt or race the unresolved lock.
        .disabled(isUnlocking)
        .animation(SettingsMetrics.stateTransitionAnimation, value: pocController.isSessionUnlocked)
        .animation(SettingsMetrics.stateTransitionAnimation, value: isUnlocking)
        .onAppear {
            SecureCredentialManager.tryRestoreSession()
            pocController.refreshCredentialStatus()
        }
        // Some unlock paths call SecureCredentialManager directly rather
        // than through this pocController, so this doesn't update
        // reactively on its own — refresh after the notch closes, same as
        // every gated page.
        .onChange(of: NotchOverlayController.shared.phase) { newPhase in
            guard newPhase == .closed else { return }
            SecureCredentialManager.tryRestoreSession()
            pocController.refreshCredentialStatus()
        }
    }

    private var label: String {
        let lang = settings.appLanguage
        if pocController.isSessionUnlocked {
            return L10n.string(.vaultPillUnlocked, lang: lang)
        }
        return isUnlocking ? L10n.string(.authenticatingBtn, lang: lang) : L10n.string(.vaultPillLocked, lang: lang)
    }

    private func toggleSession() {
        if pocController.isSessionUnlocked {
            pocController.lockSession()
            return
        }
        isUnlocking = true
        Task {
            await pocController.unlockSession()
            isUnlocking = false
        }
    }
}
