//
//  AboutSettingsPage.swift
//  glance
//

import SwiftUI
import AppKit

struct AboutSettingsPage: View {
    @ObservedObject var updater: UpdaterController
    let environment: AppEnvironment

    /// Secret-tap state for revealing the Debug/Face Lab sidebar section —
    /// see `AppEnvironment.isDebugSectionRevealed`. A pause over a second
    /// resets the count, so this requires 5 *consecutive* taps.
    @State private var iconTapCount = 0
    @State private var lastTapDate: Date?
    private let requiredTapCount = 5
    private let tapResetInterval: TimeInterval = 1.0

    private func versionString(lang: AppLanguage) -> String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let prefix: String
        switch lang {
        case .ptBR: prefix = "Versão"
        case .es: prefix = "Versión"
        case .en: prefix = "Version"
        }
        return "\(prefix) \(short)"
    }

    var body: some View {
        let lang = GlanceSettings.shared.appLanguage
        VStack(spacing: 2) {
            Image("appicon")
                .resizable()
                .frame(width: 80, height: 80)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
                .onTapGesture(perform: handleIconTap)

            Text("Glance")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SettingsMetrics.textPrimary)

            Text(versionString(lang: lang))
                .font(.system(size: 12))
                .foregroundStyle(SettingsMetrics.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)

        SettingsGroup {
            SettingsActionRowContent(
                title: L10n.string(.sendFeedbackTitle, lang: lang),
                buttonTitle: L10n.string(.send, lang: lang)
            ) {
                if let url = URL(string: "https://tryglance.app/feedback") {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        SettingsGroup {
            SettingsActionRowContent(
                title: L10n.string(.resetConfigTitle, lang: lang),
                buttonTitle: L10n.string(.reset, lang: lang)
            ) {
                AppResetter.promptResetAndReconfigure {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.presentOnboardingGate()
                    }
                }
            }

            SettingsGroupDivider()

            SettingsActionRowContent(
                title: L10n.string(.uninstallAppTitle, lang: lang),
                buttonTitle: L10n.string(.uninstall, lang: lang)
            ) {
                AppResetter.promptUninstall()
            }
        }
    }

    private func handleIconTap() {
        let now = Date()
        if let lastTapDate, now.timeIntervalSince(lastTapDate) > tapResetInterval {
            iconTapCount = 0
        }
        lastTapDate = now
        iconTapCount += 1
        guard iconTapCount >= requiredTapCount else { return }
        iconTapCount = 0
        environment.isDebugSectionRevealed = true
    }
}
