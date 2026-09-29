//
//  LaunchAtLogin.swift
//  glance
//
//  Thin wrapper around SMAppService.mainApp. Not persisted via GlanceSettings — SMAppService's own status is already the source of truth.
//

import Foundation
import ServiceManagement

enum LaunchAtLogin {
    private static var launchAgentURL: URL {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.jonnyo.glance"
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent("\(bundleID).plist")
    }

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return FileManager.default.fileExists(atPath: launchAgentURL.path)
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if enabled {
                guard SMAppService.mainApp.status != .enabled else { return }
                try SMAppService.mainApp.register()
            } else {
                guard SMAppService.mainApp.status == .enabled else { return }
                try SMAppService.mainApp.unregister()
            }
        } else {
            let fileManager = FileManager.default
            let url = launchAgentURL
            if enabled {
                let launchAgentsDir = url.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: launchAgentsDir.path) {
                    try fileManager.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
                }
                let bundlePath = Bundle.main.bundlePath
                let bundleID = Bundle.main.bundleIdentifier ?? "com.jonnyo.glance"
                let dict: [String: Any] = [
                    "Label": bundleID,
                    "ProgramArguments": ["/usr/bin/open", "-a", bundlePath],
                    "RunAtLoad": true
                ]
                let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
                try data.write(to: url)
            } else {
                if fileManager.fileExists(atPath: url.path) {
                    try fileManager.removeItem(at: url)
                }
            }
        }
    }
}
