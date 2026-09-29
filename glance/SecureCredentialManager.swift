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

        // If the user explicitly locked the vault, respect their decision until manual unlock
        if UserDefaults.standard.bool(forKey: manuallyLockedKey) {
            return
        }

        // Verify that credentials exist on disk
        guard KeychainManager.exists(account: sessionKeyAccount) && KeychainManager.exists(account: passwordBlobAccount) else {
            return
        }

        // Check if session has expired based on auto-lock duration
        let lastTimestamp = UserDefaults.standard.double(forKey: lastActivityTimestampKey)
        if lastTimestamp > 0 {
            let lastDate = Date(timeIntervalSince1970: lastTimestamp)
            let days = UserDefaults.standard.object(forKey: "GlanceSettings.autoLockIntervalDays") as? Int ?? 7
            let idleLimit: TimeInterval = Double(days) * 24 * 3600
            if Date().timeIntervalSince(lastDate) >= idleLimit {
                return
            }
        }

        do {
            let data = try KeychainManager.read(account: sessionKeyAccount)
            setCachedKey(SymmetricKey(data: data))
            print("Glance: [SecureCredentialManager] Session key restored successfully from Keychain on startup")
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

    /// Prompts Touch ID and unwraps the session key, creating it Touch-ID-gated on first run. Caches only after a real gated
    /// read-back succeeds — `SecItemAdd` alone returns success even if the user hit Cancel on the auth UI, and bridging
    /// `LAContext.evaluatePolicy` synchronously via a semaphore deadlocks the thread pool and crashes the process.
    /// Must succeed before `savePassword`/`readPassword`. Blocking; call from a background task.
    nonisolated static func unlockSession(reason: String) throws {
        if cachedKey() != nil { return }

        // User is actively unlocking the session; clear any manual lock state
        UserDefaults.standard.set(false, forKey: manuallyLockedKey)
        UserDefaults.standard.synchronize()

        // The existence check, not the read, decides whether a key gets created (load-bearing): a cancelled Touch ID prompt on
        // a user-presence item reports `errSecItemNotFound`, indistinguishable from no key — deciding on the read's error would
        // mint a fresh key (destroying the one that decrypts existing data) on every mis-tap.
        if KeychainManager.exists(account: sessionKeyAccount) {
            let context = LAContext()
            context.localizedReason = reason
            let data = try KeychainManager.read(account: sessionKeyAccount, context: context)
            setCachedKey(SymmetricKey(data: data))
            return
        }

        // No key at all, but minting one is still destructive if data is already encrypted under a previous key (e.g. a
        // re-signed dev build) — refuse rather than silently render it unreadable forever.
        guard !hasSessionEncryptedData else {
            throw SecureCredentialError.sessionKeyUnavailable
        }

        let key = SymmetricKey(size: .bits256)
        let access = try KeychainManager.makeUserPresenceAccessControl()
        try KeychainManager.save(
            account: sessionKeyAccount,
            data: key.withUnsafeBytes { Data($0) },
            accessControl: access
        )

        // Read back through the gated path rather than trusting the write — only a real read proves authentication happened.
        let readBackContext = LAContext()
        readBackContext.localizedReason = reason
        let data = try KeychainManager.read(account: sessionKeyAccount, context: readBackContext)
        setCachedKey(SymmetricKey(data: data))
    }

    /// Checked without needing the key itself, so this stays answerable precisely when the key can't be read.
    nonisolated static var hasSessionEncryptedData: Bool {
        KeychainManager.exists(account: passwordBlobAccount) || SecureFaceStore.exists
    }

    /// Clears the cached session key and records that the user manually locked the vault.
    nonisolated static func lockSession() {
        UserDefaults.standard.set(true, forKey: manuallyLockedKey)
        UserDefaults.standard.synchronize()
        setCachedKey(nil)
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
