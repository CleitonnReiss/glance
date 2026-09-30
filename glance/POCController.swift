//
//  POCController.swift
//  glance
//
//  Orchestration for credential storage: wires SecureCredentialManager to
//  KeystrokeInjector and exposes session/password status for Settings.
//

import Foundation
import Combine

@MainActor
final class POCController: ObservableObject {
    @Published var accessibilityGranted: Bool = KeystrokeInjector.isAccessibilityTrusted()

    @Published var hasStoredPassword: Bool = SecureCredentialManager.hasStoredPassword()
    @Published var isSessionUnlocked: Bool = SecureCredentialManager.isSessionUnlocked
    @Published var sessionError: String? = nil

    /// Bound to the setup SecureField. Cleared immediately after a successful save.
    @Published var passwordInput: String = ""

    @Published var statusMessage: String = "Idle"

    init() {
        NotificationCenter.default.addObserver(
            forName: .secureCredentialSessionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCredentialStatus()
            }
        }
    }

    func refreshAccessibilityStatus() {
        accessibilityGranted = KeystrokeInjector.isAccessibilityTrusted()
    }

    func requestAccessibility() {
        KeystrokeInjector.promptForAccessibility()
    }

    func refreshCredentialStatus() {
        hasStoredPassword = SecureCredentialManager.hasStoredPassword()
        isSessionUnlocked = SecureCredentialManager.isSessionUnlocked
    }

    // MARK: - Session (Touch ID gate)

    /// Must succeed before `savePassword()` or `injectStoredPassword()` will do anything.
    func unlockSession() async {
        sessionError = nil
        do {
            try await Task.detached(priority: .userInitiated) {
                try SecureCredentialManager.unlockSession(reason: "Authenticate to set up or use glance")
            }.value
            isSessionUnlocked = true
        } catch {
            isSessionUnlocked = false
            sessionError = error.localizedDescription
        }
    }

    func lockSession() {
        SecureCredentialManager.lockSession()
        refreshCredentialStatus()
    }

    // MARK: - Setup flow

    /// Encrypts and stores `passwordInput`. Requires the session to already
    /// be unlocked (Touch ID happens in `unlockSession()`, not here).
    func savePassword() async {
        guard !passwordInput.isEmpty else {
            statusMessage = "Enter a password first."
            return
        }
        let plaintext = passwordInput
        passwordInput = ""

        do {
            try await Task.detached(priority: .userInitiated) {
                guard var bytes = plaintext.data(using: .utf8) else {
                    throw SecureCredentialError.emptyPassword
                }
                defer { bytes.resetBytes(in: 0..<bytes.count) }
                try SecureCredentialManager.savePassword(bytes)
            }.value
            statusMessage = "Password saved and encrypted."
            hasStoredPassword = true
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Injection

    /// Reads + decrypts + injects the stored password, zeroing the plaintext
    /// buffer before returning. When `requireAuthoritativeLock` is true (the
    /// auto-trigger path), refuses to inject unless the CGSession dictionary
    /// confirms the screen is actually locked.
    @discardableResult
    func injectStoredPassword(requireAuthoritativeLock: Bool = false) async -> Bool {
        guard KeystrokeInjector.isAccessibilityTrusted() else {
            statusMessage = "Accessibility permission required — open System Settings → Security & Privacy → Accessibility and enable Glance."
            print("Glance: [injectStoredPassword] FAILED: Accessibility not granted (AXIsProcessTrusted is false)")
            return false
        }
        guard SecureCredentialManager.isSessionUnlocked else {
            statusMessage = "Session locked — unlock in Glance menu first."
            print("Glance: [injectStoredPassword] FAILED: Credential session is locked")
            return false
        }

        if requireAuthoritativeLock {
            guard LockMonitor.isScreenActuallyLocked() else {
                statusMessage = "Skipped: CGSession reports screen is not actually locked."
                print("Glance: [injectStoredPassword] SKIPPED: Screen is not reported locked by CGSession")
                return false
            }
        }

        statusMessage = "Injecting…"
        print("Glance: [injectStoredPassword] Starting password injection...")
        do {
            try await Task.detached(priority: .userInitiated) {
                var bytes = try SecureCredentialManager.readPassword()
                defer { bytes.resetBytes(in: 0..<bytes.count) }
                try KeystrokeInjector.typeAndReturn(bytes)
            }.value
            statusMessage = "Injected stored password + Return at \(Date().formatted(date: .omitted, time: .standard))"
            print("Glance: [injectStoredPassword] SUCCESS: Injected password + Return successfully")
            return true
        } catch {
            statusMessage = "Injection failed: \(error.localizedDescription)"
            print("Glance: [injectStoredPassword] FAILED with error: \(error.localizedDescription)")
            return false
        }
    }
}
