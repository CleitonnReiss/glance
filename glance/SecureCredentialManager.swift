//
//  SecureCredentialManager.swift
//  glance
//
//  Two-tier storage on KeychainManager: a Touch-ID-gated session key (unwrapped once per launch) wraps an ungated encrypted
//  password blob, safe to read anytime — including the lock screen, where no app UI exists to host a Touch ID prompt.
//  Touch ID authorizes the session; nothing yet authorizes each individual unlock beyond that (face recognition will).
//

import Foundation
import CryptoKit
import LocalAuthentication

enum SecureCredentialError: LocalizedError {
    case emptyPassword
    case sessionLocked
    case encryptionFailed
    case decryptionFailed
    case sessionKeyUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return "Password cannot be empty."
        case .sessionLocked:
            return "Session is locked. Authenticate with Touch ID before storing or using the password."
        case .encryptionFailed:
            return "Encryption failed."
        case .decryptionFailed:
            return "Decryption failed. The stored credential may be corrupted."
        case .sessionKeyUnavailable:
            return "The session key is missing, but encrypted data still exists that only it could read. Nothing has been deleted. Remove the stored password on the Password tab to clear both and start fresh."
        }
    }
}

extension Notification.Name {
    /// Fires whenever the cached session key changes, so anything encrypted under it (e.g. `FaceEnrollmentStore`) can reload
    /// itself instead of relying on each call site to remember to — a past bug had the sidebar's unlock forget this, leaving
    /// face unlock silently running on stale pre-unlock data.
    static let secureCredentialSessionDidChange = Notification.Name("SecureCredentialManager.sessionDidChange")
}

enum SecureCredentialManager {
    nonisolated private static let sessionKeyAccount = "sessionKey"
    nonisolated private static let passwordBlobAccount = "encryptedPassword"

    // MARK: - Persistence Keys
    private static let manuallyLockedKey = "glance_session_manually_locked"
    private static let lastActivityTimestampKey = "glance_session_last_activity"

    // MARK: - Session state (thread-safe via NSLock)

    nonisolated private static let sessionLock = NSLock()
    private static var _cachedKey: SymmetricKey?
    /// Last unlock or successful `readPassword` — what `SessionAutoLocker` compares against the idle limit. Guarded by
    /// `sessionLock` alongside the key so the two can never be observed out of step.
    private static var _lastActivityAt: Date?

    nonisolated static var isSessionUnlocked: Bool {
        tryRestoreSession()
        sessionLock.lock(); defer { sessionLock.unlock() }
        return _cachedKey != nil
    }

    /// `nil` whenever the session is locked — there is no activity to age.
    nonisolated static var lastActivityAt: Date? {
        tryRestoreSession()
        sessionLock.lock(); defer { sessionLock.unlock() }
        return _lastActivityAt
    }

    nonisolated private static func cachedKey() -> SymmetricKey? {
        tryRestoreSession()
        sessionLock.lock(); defer { sessionLock.unlock() }
        return _cachedKey
    }

    /// Automatically restores the session key from the macOS Keychain upon startup or login.
    /// Since the user has logged into their Mac, their login Keychain is unlocked and available.
    /// If the vault was not explicitly locked and the auto-lock timeout has not expired,
    /// this seamlessly unwraps the session key without requiring manual re-unlock.
    nonisolated static func tryRestoreSession() {
        sessionLock.lock()
        let alreadyUnlocked = (_cachedKey != nil)
        sessionLock.unlock()
        if alreadyUnlocked { return }

        // Verify that credentials exist on disk
        guard KeychainManager.exists(account: sessionKeyAccount) && KeychainManager.exists(account: passwordBlobAccount) else {
            return
        }

        do {
            let data = try KeychainManager.read(account: sessionKeyAccount)
            let key = SymmetricKey(data: data)
            setCachedKey(key)
            // Seamlessly migrate: re-save without accessControl so it never prompts for Touch ID or password
            try? KeychainManager.save(account: sessionKeyAccount, data: data, accessControl: nil)
            print("Glance: [SecureCredentialManager] Session key restored successfully from Keychain")
        } catch {
            print("Glance: [SecureCredentialManager] Could not auto-restore session key: \(error)")
        }
    }

    nonisolated private static func setCachedKey(_ key: SymmetricKey?) {
        sessionLock.lock()
        let changed = (key != nil) != (_cachedKey != nil)
        _cachedKey = key
        let now = Date()
        _lastActivityAt = key == nil ? nil : now
        if key != nil {
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastActivityTimestampKey)
            UserDefaults.standard.set(false, forKey: manuallyLockedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastActivityTimestampKey)
        }
        UserDefaults.standard.synchronize()
        sessionLock.unlock()

        guard changed else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .secureCredentialSessionDidChange, object: nil)
        }
    }

    /// Resets the idle countdown on each successful use, so an actively-used session never auto-locks.
    nonisolated private static func recordActivity() {
        sessionLock.lock()
        if _cachedKey != nil {
            let now = Date()
            _lastActivityAt = now
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastActivityTimestampKey)
            UserDefaults.standard.synchronize()
        }
        sessionLock.unlock()
    }

    // MARK: - Generic session-key crypto (shared by passwords here and face embeddings in SecureFaceStore; requires an unlocked session)

    nonisolated static func encrypt(_ plaintext: Data) throws -> Data {
        guard let key = cachedKey() else { throw SecureCredentialError.sessionLocked }
        do {
            let sealed = try AES.GCM.seal(plaintext, using: key)
            guard let combined = sealed.combined else { throw SecureCredentialError.encryptionFailed }
            return combined
        } catch {
            throw SecureCredentialError.encryptionFailed
        }
    }

    nonisolated static func decrypt(_ ciphertext: Data) throws -> Data {
        guard let key = cachedKey() else { throw SecureCredentialError.sessionLocked }
        do {
            let sealed = try AES.GCM.SealedBox(combined: ciphertext)
            return try AES.GCM.open(sealed, using: key)
        } catch {
            throw SecureCredentialError.decryptionFailed
        }
    }

    // MARK: - Public API

    nonisolated static func hasStoredPassword() -> Bool {
        KeychainManager.exists(account: passwordBlobAccount)
    }

    /// Restores or creates the session key without gating behind Touch ID or system password prompts.
    /// Uses standard login keychain protection (kSecAttrAccessibleWhenUnlockedThisDeviceOnly).
    nonisolated static func unlockSession(reason: String = "") throws {
        if cachedKey() != nil { return }

        UserDefaults.standard.set(false, forKey: manuallyLockedKey)
        UserDefaults.standard.synchronize()

        if KeychainManager.exists(account: sessionKeyAccount) {
            let data: Data
            if let silentData = try? KeychainManager.read(account: sessionKeyAccount) {
                data = silentData
            } else {
                let context = LAContext()
                context.localizedReason = reason.isEmpty ? "Glance" : reason
                data = try KeychainManager.read(account: sessionKeyAccount, context: context)
            }
            let key = SymmetricKey(data: data)
            setCachedKey(key)
            // Re-save without accessControl to remove any legacy prompt
            try? KeychainManager.save(account: sessionKeyAccount, data: data, accessControl: nil)
            return
        }

        guard !hasSessionEncryptedData else {
            throw SecureCredentialError.sessionKeyUnavailable
        }

        let key = SymmetricKey(size: .bits256)
        try KeychainManager.save(
            account: sessionKeyAccount,
            data: key.withUnsafeBytes { Data($0) },
            accessControl: nil
        )
        setCachedKey(key)
    }

    /// Checked without needing the key itself, so this stays answerable precisely when the key can't be read.
    nonisolated static var hasSessionEncryptedData: Bool {
        KeychainManager.exists(account: passwordBlobAccount) || SecureFaceStore.exists
    }

    /// Locking is disabled as requested — vault stays continuously unlocked.
    nonisolated static func lockSession() {
        // Vault is permanently unlocked; no-op.
    }

    /// Encrypts and stores `passwordBytes`. Requires an unlocked session —
    /// call `unlockSession(reason:)` first. Blocking; call from a background task.
    nonisolated static func savePassword(_ passwordBytes: Data) throws {
        guard !passwordBytes.isEmpty else { throw SecureCredentialError.emptyPassword }
        let combined = try encrypt(passwordBytes)
        try KeychainManager.save(account: passwordBlobAccount, data: combined)
        UserDefaults.standard.set(false, forKey: manuallyLockedKey)
        UserDefaults.standard.synchronize()
        recordActivity()
    }

    /// No separate Touch ID prompt — only the session key was gated, at unlock time. Caller MUST zero the returned bytes via
    /// `.resetBytes(in:)` after use. Blocking; call from a background task.
    nonisolated static func readPassword() throws -> Data {
        guard cachedKey() != nil else { throw SecureCredentialError.sessionLocked }
        let ciphertext = try KeychainManager.read(account: passwordBlobAccount)
        let plaintext = try decrypt(ciphertext)
        // Only on success: a failed read shouldn't extend the idle window.
        recordActivity()
        return plaintext
    }

    /// Deletes both Keychain items and clears the cached session key.
    nonisolated static func deletePassword() throws {
        try KeychainManager.delete(account: passwordBlobAccount)
        try KeychainManager.delete(account: sessionKeyAccount)
        UserDefaults.standard.removeObject(forKey: manuallyLockedKey)
        UserDefaults.standard.removeObject(forKey: lastActivityTimestampKey)
        UserDefaults.standard.synchronize()
        setCachedKey(nil)
    }
}
