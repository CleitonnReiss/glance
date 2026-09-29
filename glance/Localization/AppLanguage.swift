//
//  AppLanguage.swift
//  glance
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case ptBR = "pt-BR"
    case en = "en"
    case es = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ptBR: return "Português (Brasil)"
        case .en: return "English"
        case .es: return "Español"
        }
    }

    /// Automatically detects user preference or defaults to pt-BR
    static var defaultLanguage: AppLanguage {
        for pref in Locale.preferredLanguages {
            let lower = pref.lowercased()
            if lower.hasPrefix("pt") { return .ptBR }
            if lower.hasPrefix("es") { return .es }
            if lower.hasPrefix("en") { return .en }
        }
        return .ptBR
    }

    private static let lock = NSLock()
    private static var _current: AppLanguage = {
        if let saved = UserDefaults.standard.string(forKey: "glance_app_language"),
           let lang = AppLanguage(rawValue: saved) {
            return lang
        }
        return AppLanguage.defaultLanguage
    }()

    static var current: AppLanguage {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock()
            _current = newValue
            lock.unlock()
            UserDefaults.standard.set(newValue.rawValue, forKey: "glance_app_language")
        }
    }
}
