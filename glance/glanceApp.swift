//
//  glanceApp.swift
//  glance
//
//  Created by Jonathan Zhou on 2026-07-21.
//

import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    convenience init(environment: AppEnvironment) {
        let rootView = SettingsWindowView(environment: environment)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Glance Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.hasShadow = true

        let toolbar = NSToolbar(identifier: "GlanceSettingsToolbar")
        window.toolbar = toolbar
        window.toolbarStyle = .unified

        let target = SettingsMetrics.windowSize
        window.setContentSize(target)
        window.minSize = target
        window.maxSize = target
        window.center()
        self.init(window: window)
    }
}

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static var sharedDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        sharedDelegate = delegate
        app.delegate = delegate
        app.run()
    }
    /// Owns the long-lived controllers so every Settings page and the menu bar's session row share the same instances instead of
    /// each spinning up its own camera/lock-monitor (see AppEnvironment.swift). Lives here rather than as `@State` because
    /// `@NSApplicationDelegateAdaptor` constructs this delegate before the scene body runs, so it's always safe to read.
    let environment = AppEnvironment()

    /// Kept alive for the app's lifetime — a local variable would vanish (and the icon with it) once `applicationDidFinishLaunching` returns.
    private var statusItem: NSStatusItem?
    private var lockScreenMenuItem: NSMenuItem?
    private var sessionMenuItem: NSMenuItem?
    private var settingsMenuItem: NSMenuItem?
    private var resetMenuItem: NSMenuItem?
    private var uninstallMenuItem: NSMenuItem?
    private var quitMenuItem: NSMenuItem?
    private var settingsWindowController: SettingsWindowController?

    /// Guards `environment.updater.start()` against running twice — reachable from two call sites, and Sparkle doesn't promise
    /// starting an already-started `SPUUpdater` is a safe no-op.
    private var hasStartedUpdater = false

    /// Accessory before the Dock binds this launch to a persistent tile — starting `.regular` made the pinned icon bounce and
    /// get replaced by a Recents tile the moment the Dock icon was later hidden/shown.
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Glance: applicationWillFinishLaunching")
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Glance: applicationDidFinishLaunching")
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = GlanceIcons.menuBarIcon()
        icon.size = NSSize(width: 18, height: 18)
        item.button?.image = icon

        let menu = NSMenu()
        // Refreshes menu items right before the menu displays — see `menuNeedsUpdate` below.
        menu.delegate = self

        let lang = GlanceSettings.shared.appLanguage

        let lockScreenItem = NSMenuItem(title: L10n.string(.menuLockScreen, lang: lang), action: #selector(lockMacScreen), keyEquivalent: "l")
        lockScreenItem.keyEquivalentModifierMask = [.command, .control]
        lockScreenItem.target = self
        lockScreenItem.image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: nil)
        menu.addItem(lockScreenItem)
        lockScreenMenuItem = lockScreenItem

        menu.addItem(NSMenuItem.separator())

        let sessionItem = NSMenuItem(title: "", action: #selector(toggleSession), keyEquivalent: "")
        sessionItem.target = self
        menu.addItem(sessionItem)
        sessionMenuItem = sessionItem

        let settingsItem = NSMenuItem(title: L10n.string(.menuSettings, lang: lang), action: #selector(openSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        menu.addItem(settingsItem)
        settingsMenuItem = settingsItem

        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: L10n.string(.menuReset, lang: lang), action: #selector(promptReset), keyEquivalent: "")
        resetItem.target = self
        resetItem.image = NSImage(systemSymbolName: "arrow.counterclockwise", accessibilityDescription: nil)
        menu.addItem(resetItem)
        resetMenuItem = resetItem

        let uninstallItem = NSMenuItem(title: L10n.string(.menuUninstall, lang: lang), action: #selector(promptUninstall), keyEquivalent: "")
        uninstallItem.target = self
        uninstallItem.image = NSImage(systemSymbolName: "trash.fill", accessibilityDescription: nil)
        menu.addItem(uninstallItem)
        uninstallMenuItem = uninstallItem

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L10n.string(.menuQuit, lang: lang), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        menu.addItem(quitItem)
        quitMenuItem = quitItem

        item.menu = menu
        statusItem = item

        updateSessionMenuItem(lang: lang)

        // SwiftUI can flip the app back to `.regular` while installing scenes even with `.suppressed`; re-assert accessory.
        NSApp.setActivationPolicy(.accessory)

        // `object: nil` deliberately — the Settings window may not exist yet (SwiftUI creates scene content lazily), and this
        // still matches it by identity in the handler below once it does close.
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification, object: nil
        )

        // Verify installation integrity: if the app was reinstalled or replaced on disk,
        // automatically reset stale state so it begins cleanly with onboarding.
        AppResetter.verifyInstallationIntegrity()
        AppResetter.startBundleLifecycleMonitor()

        // Automatically restore session if valid so face unlock is immediately armed
        SecureCredentialManager.tryRestoreSession()
        environment.pocController.refreshCredentialStatus()
        updateSessionMenuItem()

        NotificationCenter.default.addObserver(
            forName: .secureCredentialSessionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.environment.pocController.refreshCredentialStatus()
                self?.updateSessionMenuItem()
            }
        }

        // Deferred until onboarding is done — Sparkle's own "Check for updates automatically?" consent alert fires the moment
        // it starts on a fresh install, and starting unconditionally here used to pop it mid-onboarding.
        if GlanceSettings.shared.hasCompletedOnboarding {
            if GlanceSettings.shared.hasAcknowledgedSecurityNotice {
                startUpdaterIfNeeded()
            } else {
                presentPostUpdateSecurityNotice()
            }
        } else {
            presentOnboardingGate()
        }
    }

    /// First-run gate: onboarding lives entirely in the notch, so this stays accessory. Called once at launch if onboarding
    /// isn't done, and again from `revealSettingsWindow()` if the user reaches Settings mid-flow. Closing any main window here
    /// is defense in depth against SwiftUI's `.suppressed` scene timing not being guaranteed.
    func presentOnboardingGate() {
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
        NSApp.setActivationPolicy(.accessory)
        OnboardingController.startFlow(
            resumingAt: GlanceSettings.shared.onboardingResumeStep,
            onFirstRunComplete: { [weak self] in
                // First time Settings should appear, which also brings the Dock icon back.
                self?.revealSettingsWindow()
                self?.startUpdaterIfNeeded()
            }
        )
    }

    /// One-time catch-up for users who completed onboarding before the security-notice step
    /// existed — same accessory/window-closing treatment as `presentOnboardingGate()`, but
    /// resumes straight into the updater afterward instead of revealing Settings, since setup
    /// itself is already done.
    private func presentPostUpdateSecurityNotice() {
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
        NSApp.setActivationPolicy(.accessory)
        // Reachable repeatedly — every gated menu action re-enters here while unacknowledged.
        // A fresh `startPostUpdateNotice()` would just replace the one already on screen.
        guard NotchOverlayController.shared.phase != .onboarding else { return }
        OnboardingController.startPostUpdateNotice { [weak self] in
            self?.startUpdaterIfNeeded()
        }
    }

    /// Reachable from launch (onboarding already done) or from first-run completion — `hasStartedUpdater` collapses both into "exactly once."
    private func startUpdaterIfNeeded() {
        guard !hasStartedUpdater else { return }
        hasStartedUpdater = true
        environment.updater.start()
    }

    /// Hides the Dock icon once no `canBecomeMain` window is left (`revealSettingsWindow()` brings it back) — excludes non-main
    /// windows like the lock-screen notch overlay, and backs off while Sparkle's update window is showing.
    @objc private func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow.canBecomeMain else { return }
        guard !environment.updater.isPresentingUpdateUI else { return }
        let stillOpen = NSApp.windows.contains { $0 !== closingWindow && $0.canBecomeMain && $0.isVisible }
        guard !stillOpen else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    /// Fires right before the menu opens — refreshes all items with current language and state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        let lang = GlanceSettings.shared.appLanguage
        lockScreenMenuItem?.title = L10n.string(.menuLockScreen, lang: lang)
        settingsMenuItem?.title = L10n.string(.menuSettings, lang: lang)
        resetMenuItem?.title = L10n.string(.menuReset, lang: lang)
        uninstallMenuItem?.title = L10n.string(.menuUninstall, lang: lang)
        quitMenuItem?.title = L10n.string(.menuQuit, lang: lang)
        updateSessionMenuItem(lang: lang)
    }

    @objc private func lockMacScreen() {
        typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
        if let lib = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            if let sym = dlsym(lib, "SACLockScreenImmediate") {
                let lock = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
                lock()
            }
            dlclose(lib)
        }
    }

    private func updateSessionMenuItem(lang: AppLanguage = AppLanguage.current) {
        guard let sessionMenuItem else { return }
        let isUnlocked = environment.pocController.isSessionUnlocked
        sessionMenuItem.title = isUnlocked
            ? L10n.string(.menuVaultUnlocked, lang: lang)
            : L10n.string(.menuVaultLocked, lang: lang)
        sessionMenuItem.image = NSImage(
            systemSymbolName: isUnlocked ? "key.fill" : "lock.fill",
            accessibilityDescription: nil
        )
    }

    /// Locking is immediate; unlocking prompts Touch ID, so this can't be a plain synchronous action for that branch.
    @objc private func toggleSession() {
        guard !isBlockedByPostUpdateNotice else {
            presentPostUpdateSecurityNotice()
            return
        }
        if environment.pocController.isSessionUnlocked {
            environment.pocController.lockSession()
        } else {
            Task { await environment.pocController.unlockSession() }
        }
    }

    /// Keeps the process alive after the window closes so it can still react to the screen locking (e.g. for face unlock).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// A Dock click must not create the Settings window — that produced a duplicate Recents icon. If already open, the default
    /// reopen behavior just brings it forward.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return flag
    }

    /// Menu bar "Settings" — the only user-facing way to open the window after onboarding.
    @objc private func openSettingsWindow() {
        revealSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    /// True whenever an updated user hasn't acknowledged the post-update security notice yet.
    /// Checked by every menu-bar action that would otherwise let them use the app — Settings,
    /// locking/unlocking — before the notice has been seen.
    private var isBlockedByPostUpdateNotice: Bool {
        GlanceSettings.shared.hasCompletedOnboarding && !GlanceSettings.shared.hasAcknowledgedSecurityNotice
    }

    /// Restores the Dock icon before bringing the window forward — doing it after the window is already key can leave the icon
    /// out of sync. During onboarding this only ensures the notch flow is up; it doesn't open Settings or show a Dock icon.
    private func revealSettingsWindow() {
        if isBlockedByPostUpdateNotice {
            presentPostUpdateSecurityNotice()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        guard GlanceSettings.shared.hasCompletedOnboarding else {
            // Re-present rather than restart: a fresh startFlow() would throw away the in-session step already navigated to,
            // since it only knows the last step written to disk.
            if NotchOverlayController.shared.phase != .onboarding {
                presentOnboardingGate()
            }
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        NSApp.setActivationPolicy(.regular)
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(environment: environment)
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func promptReset() {
        AppResetter.promptResetAndReconfigure { [weak self] in
            DispatchQueue.main.async {
                self?.settingsWindowController?.close()
                self?.settingsWindowController = nil
                self?.presentOnboardingGate()
            }
        }
    }

    @objc private func promptUninstall() {
        AppResetter.promptUninstall()
    }
}

