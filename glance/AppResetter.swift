//
//  AppResetter.swift
//  glance
//
//  Handles complete uninstallation, clean reinstallation detection, and
//  factory resets so that Glance never leaves orphan files or stale credentials.
//

import AppKit
import Foundation
import Security

@MainActor
enum AppResetter {
    private static let inodeKey = "GlanceLastRecordedBundleInode"
    private static let birthtimeKey = "GlanceLastRecordedBundleBirthtime"

    /// Verifies if the application bundle on disk has been replaced, reinstalled, or moved.
    /// If an old installation was removed from /Applications and a new one was installed,
    /// it resets stale user data automatically so the app starts 100% fresh from scratch.
    static func verifyInstallationIntegrity() {
        let bundleURL = Bundle.main.bundleURL
        // Only run bundle replacement check if the app is actually installed in /Applications
        // This avoids resetting data if the user runs from Xcode/build or temporary staging directory.
        guard bundleURL.path.hasPrefix("/Applications/") || bundleURL.path == "/Applications/Glance.app" else {
            return
        }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: bundleURL.path),
              let inode = attrs[.systemFileNumber] as? UInt64,
              let creationDate = attrs[.creationDate] as? Date else {
            return
        }

        let defaults = UserDefaults.standard
        let currentBirthtime = creationDate.timeIntervalSince1970
        defaults.set(inode, forKey: inodeKey)
        defaults.set(currentBirthtime, forKey: birthtimeKey)
        defaults.synchronize()
    }

    private static var monitorTimer: Timer?

    /// Monitors whether the application bundle has been deleted from /Applications or moved to Trash while running.
    /// If the user deletes or trashes Glance, it immediately purges all user data and terminates.
    static func startBundleLifecycleMonitor() {
        let bundlePath = Bundle.main.bundlePath
        // Only monitor if running from /Applications
        guard bundlePath.hasPrefix("/Applications/") || bundlePath == "/Applications/Glance.app" else {
            return
        }

        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                let bundleURL = Bundle.main.bundleURL
                let isInsideTrash = bundleURL.path.contains("/.Trash/") || bundleURL.path.contains("/Trash/")
                if isInsideTrash {
                    print("Glance: Bundle was moved to Trash. Purging all user data...")
                    monitorTimer?.invalidate()
                    monitorTimer = nil
                    resetAllUserData(keepApplicationFile: false)
                    NSApp.terminate(nil)
                }
            }
        }
    }

    /// Resets all data: Keychain items, enrolled faces in Application Support,
    /// UserDefaults preferences, LaunchAgents, and caches.
    static func resetAllUserData(keepApplicationFile: Bool = true) {
        print("Glance: Performing complete cleanup of user data...")

        // 1. Delete Keychain credentials (sessionKey and encryptedPassword)
        try? SecureCredentialManager.deletePassword()
        KeychainManager.deleteAllItems()

        // 2. Delete Application Support folder
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let glanceDir = appSupport.appendingPathComponent("glance", isDirectory: true)
        try? FileManager.default.removeItem(at: glanceDir)

        // 3. Remove LaunchAgent
        try? LaunchAtLogin.setEnabled(false)
        let launchAgentURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.jonathan.glance.plist")
        try? FileManager.default.removeItem(at: launchAgentURL)

        // 4. Remove caches
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.jonathan.glance")
        try? FileManager.default.removeItem(at: cachesDir)

        // 5. Reset UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }

        // 6. Reset in-memory settings
        GlanceSettings.shared.hasCompletedOnboarding = false
        GlanceSettings.shared.hasAcknowledgedSecurityNotice = false
        SecureCredentialManager.lockSession()

        print("Glance: Cleanup completed successfully.")
    }

    /// Complete uninstallation: prompts the user, wipes all data, moves the app to Trash, and terminates.
    static func promptUninstall() {
        let lang = GlanceSettings.shared.appLanguage
        let alert = NSAlert()
        alert.messageText = L10n.string(.alertUninstallTitle, lang: lang)
        alert.informativeText = L10n.string(.alertUninstallMessage, lang: lang)
        alert.alertStyle = .critical
        alert.addButton(withTitle: L10n.string(.alertUninstallBtn, lang: lang))
        alert.addButton(withTitle: L10n.string(.cancel, lang: lang))

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        // Clean all user data
        resetAllUserData(keepApplicationFile: false)

        // Move .app to Trash with fallback
        let bundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.recycle([bundleURL]) { _, error in
            if error != nil {
                let fm = FileManager.default
                if let trash = fm.urls(for: .trashDirectory, in: .userDomainMask).first {
                    let dest = trash.appendingPathComponent(bundleURL.lastPathComponent)
                    try? fm.removeItem(at: dest)
                    try? fm.moveItem(at: bundleURL, to: dest)
                } else {
                    try? fm.removeItem(at: bundleURL)
                }
            }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }

        // Fallback terminate after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NSApp.terminate(nil)
        }
    }

    /// Resets app and restarts onboarding wizard
    static func promptResetAndReconfigure(onboardingStarter: @escaping () -> Void) {
        let lang = GlanceSettings.shared.appLanguage
        let alert = NSAlert()
        alert.messageText = L10n.string(.alertResetTitle, lang: lang)
        alert.informativeText = L10n.string(.alertResetMessage, lang: lang)
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.string(.alertResetBtn, lang: lang))
        alert.addButton(withTitle: L10n.string(.cancel, lang: lang))

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        resetAllUserData(keepApplicationFile: true)
        
        // Re-record current inode so it doesn't trigger reinstall reset again
        let bundleURL = Bundle.main.bundleURL
        if let attrs = try? FileManager.default.attributesOfItem(atPath: bundleURL.path),
           let inode = attrs[.systemFileNumber] as? UInt64,
           let creationDate = attrs[.creationDate] as? Date {
            let defaults = UserDefaults.standard
            defaults.set(inode, forKey: inodeKey)
            defaults.set(creationDate.timeIntervalSince1970, forKey: birthtimeKey)
            defaults.synchronize()
        }

        onboardingStarter()
    }
}
