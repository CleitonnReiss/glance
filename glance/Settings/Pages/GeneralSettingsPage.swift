//
//  GeneralSettingsPage.swift
//  glance
//

import OSLog
import SwiftUI

struct GeneralSettingsPage: View {
    @ObservedObject var coordinator: FaceUnlockCoordinator
    @ObservedObject private var settings = GlanceSettings.shared

    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?
    /// Refreshed on `didChangeScreenParametersNotification` so the picker
    /// reflects displays connecting/disconnecting while Settings is open.
    @State private var screens: [NSScreen] = NSScreen.screens
    /// Refreshed when the app regains focus, so granting the permission in
    /// System Settings clears the prompt below without a relaunch.
    @State private var inputMonitoring = SpaceKeyMonitor.inputMonitoringAccess
    @State private var previousTriggers: Set<UnlockTrigger> = GlanceSettings.shared.unlockTriggers

    private var needsInputMonitoring: Bool {
        settings.unlockTriggers.contains(.onSpace) && inputMonitoring != .granted
    }

    /// Dev-only: under Xcode the reading above is Xcode's permission, not
    /// glance's, so it's meaningless. See `SpaceKeyMonitor.isLaunchedByXcode`.
    private var hasInheritedXcodePermission: Bool {
        settings.unlockTriggers.contains(.onSpace) && SpaceKeyMonitor.isLaunchedByXcode
    }

    var body: some View {
        let lang = settings.appLanguage
        SettingsGroup {
            SettingsRowContent(title: L10n.string(.language, lang: lang)) {
                SettingsMenuPickerPill(label: settings.appLanguage.displayName) {
                    ForEach(AppLanguage.allCases) { item in
                        Button(item.displayName) {
                            settings.appLanguage = item
                        }
                    }
                }
            }
            SettingsGroupDivider()
            SettingsRowContent(title: L10n.string(.launchAtLoginTitle, lang: lang)) {
                GlanceToggle(isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { newValue in
                        launchAtLoginEnabled = newValue
                        do {
                            try LaunchAtLogin.setEnabled(newValue)
                            launchAtLoginError = nil
                        } catch {
                            launchAtLoginEnabled = !newValue
                            launchAtLoginError = error.localizedDescription
                        }
                    }
                ))
            }
            SettingsGroupDivider()
            SettingsRowContent(title: L10n.string(.enableFaceUnlockTitle, lang: lang)) {
                GlanceToggle(isOn: $coordinator.isEnabled)
            }
            SettingsGroupDivider()
            UnlockTriggerPicker(selection: $settings.unlockTriggers, isEnabled: coordinator.isEnabled)
            SettingsGroupDivider()
            displayPicker(lang: lang)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            inputMonitoring = SpaceKeyMonitor.inputMonitoringAccess
        }
        .onChange(of: settings.unlockTriggers) { newValue in
            let oldValue = previousTriggers
            previousTriggers = newValue
            // Only prompt on the transition into selecting "On space".
            SpaceKeyMonitor.log.info("unlockTriggers changed: old=\(String(describing: oldValue), privacy: .public) new=\(String(describing: newValue), privacy: .public) state=\(String(describing: inputMonitoring), privacy: .public)")
            if newValue.contains(.onSpace), !oldValue.contains(.onSpace), inputMonitoring != .granted {
                SpaceKeyMonitor.requestInputMonitoringAccess()
                // tccd flips notDetermined -> denied just after the call
                // returns, so re-read on the next beat rather than inline.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    inputMonitoring = SpaceKeyMonitor.inputMonitoringAccess
                }
            }
        }
        if let launchAtLoginError {
            SettingsCaption(text: launchAtLoginError)
        }
        if hasInheritedXcodePermission {
            SettingsCaption(text: "Running from Xcode — permission checks resolve against Xcode’s grants, not glance’s, so this reading is meaningless. Launch glance.app on its own to see the real state.")
        } else if needsInputMonitoring {
            inputMonitoringNotice(lang: lang)
        }

        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle(text: L10n.string(.behaviourTitle, lang: lang))
            SettingsGroup {
                SettingsRowContent(title: L10n.string(.retryOnHoverTitle, lang: lang)) {
                    GlanceToggle(isOn: $settings.retryOnHover)
                }
                SettingsGroupDivider()
                SettingsRowContent(title: L10n.string(.autoRetryTitle, lang: lang)) {
                    GlanceToggle(isOn: $settings.autoRetryOnce)
                }
                SettingsGroupDivider()
                SettingsRowContent(title: L10n.string(.hapticFeedbackTitle, lang: lang)) {
                    GlanceToggle(isOn: $settings.hapticFeedbackEnabled)
                }
                SettingsGroupDivider()
                SettingsSteppedSliderRowContent(
                    title: L10n.string(.faceDetectionDurationTitle, lang: lang),
                    valueLabel: "\(settings.faceDetectionSeconds)s",
                    index: Binding(
                        get: { Double(settings.faceDetectionSeconds - GlanceSettings.faceDetectionRange.lowerBound) },
                        set: { settings.faceDetectionSeconds = GlanceSettings.faceDetectionRange.lowerBound + Int($0.rounded()) }
                    ),
                    stopCount: GlanceSettings.faceDetectionRange.count
                )
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle(text: L10n.string(.animationTitle, lang: lang))
            SettingsGroup {
                SettingsRowContent(title: L10n.string(.showAnimationTitle, lang: lang)) {
                    GlanceToggle(isOn: $settings.showUnlockAnimation)
                }
                SettingsGroupDivider()
                UnlockAnimationPicker(
                    selection: $settings.unlockAnimationStyle,
                    isEnabled: settings.showUnlockAnimation
                )
            }
        }
    }

    /// Shown while "On space" is selected but Input Monitoring isn't granted.
    private func inputMonitoringNotice(lang: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsCaption(text: L10n.string(.inputMonitoringNotice, lang: lang))
            Button(L10n.string(.openAccessibilitySettings, lang: lang)) {
                // Covers the rare install with no Accessibility grant at all.
                SpaceKeyMonitor.requestInputMonitoringAccess()
                openSystemSettings(pane: "Privacy_Accessibility")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    inputMonitoring = SpaceKeyMonitor.inputMonitoringAccess
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(GlanceTheme.accent)
        }
    }

    private func openSystemSettings(pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func displayPicker(lang: AppLanguage) -> some View {
        SettingsRowContent(title: L10n.string(.displayOnTitle, lang: lang)) {
            SettingsMenuPickerPill(label: displayLabel(lang: lang)) {
                Button(L10n.string(.mainDisplay, lang: lang)) {
                    settings.preferredDisplayID = nil
                    settings.preferredDisplayName = nil
                }
                ForEach(screens.compactMap(NamedScreen.init), id: \.id) { screen in
                    Button(screen.name) {
                        settings.preferredDisplayID = screen.id
                        settings.preferredDisplayName = screen.name
                    }
                }
            }
        }
    }

    /// A connected screen with its stable ID already unwrapped, so the
    /// picker's `ForEach` doesn't need to filter/force-unwrap inline.
    private struct NamedScreen {
        let id: String
        let name: String

        init?(_ screen: NSScreen) {
            guard let id = screen.stableDisplayID else { return nil }
            self.id = id
            self.name = screen.localizedName
        }
    }

    private func displayLabel(lang: AppLanguage) -> String {
        guard let targetID = settings.preferredDisplayID else { return L10n.string(.mainDisplay, lang: lang) }
        if let connected = screens.first(where: { $0.stableDisplayID == targetID }) {
            return connected.localizedName
        }
        // Picked, but not currently connected — say so rather than showing
        // a bare ID or falling back to another display's name.
        guard let name = settings.preferredDisplayName else {
            return "\(L10n.string(.mainDisplay, lang: lang)) \(L10n.string(.displayDisconnected, lang: lang))"
        }
        return "\(name) \(L10n.string(.displayDisconnected, lang: lang))"
    }
}
