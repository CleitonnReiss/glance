//
//  RecognitionSettingsPage.swift
//  glance
//

import SwiftUI

struct RecognitionSettingsPage: View {
    @ObservedObject var coordinator: FaceUnlockCoordinator
    @ObservedObject var pocController: POCController
    @ObservedObject private var settings = GlanceSettings.shared

    @State private var isUnlocking = false
    @State private var sessionError: String?

    /// Read from `POCController`, not a local copy — same reasoning as
    /// `PasswordSettingsPage`.
    private var isSessionUnlocked: Bool { pocController.isSessionUnlocked }

    var body: some View {
        unlockedState
            .onAppear { pocController.refreshCredentialStatus() }
            .onChange(of: NotchOverlayController.shared.phase) { newPhase in
                guard newPhase == .closed else { return }
                pocController.refreshCredentialStatus()
            }
    }

    // MARK: - Unlocked

    private var unlockedState: some View {
        let lang = settings.appLanguage
        return VStack(alignment: .leading, spacing: 20) {
            SettingsGroup {
                SettingsOptionSliderRowContent(
                    title: L10n.string(.matchConfidenceTitle, lang: lang),
                    stepLabels: MatchConfidenceLevel.allCases.map(\.title),
                    index: matchConfidenceIndex,
                    stopCount: MatchConfidenceLevel.allCases.count
                )

                SettingsGroupDivider()

                SettingsOptionSliderRowContent(
                    title: L10n.string(.detectionDistanceTitle, lang: lang),
                    stepLabels: DetectionDistanceLevel.allCases.map(\.title),
                    index: detectionDistanceIndex,
                    stopCount: DetectionDistanceLevel.allCases.count
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingsSectionTitle(text: L10n.string(.livenessTitle, lang: lang))
                SettingsGroup {
                    SettingsRowContent(
                        title: L10n.string(.livenessToggleTitle, lang: lang),
                        subtitle: L10n.string(.livenessToggleSubtitle, lang: lang),
                        subtitleMaxWidth: SettingsMetrics.rowSubtitleMaxWidth
                    ) {
                        GlanceToggle(isOn: $settings.livenessChecksEnabled)
                    }
                    SettingsGroupDivider()
                    LivenessModePicker(
                        selection: $settings.livenessMode,
                        isEnabled: settings.livenessChecksEnabled
                    )
                }
            }
        }
    }

    // MARK: - Match confidence

    /// Nearest of the three snap points to whatever's stored, in case the
    /// value doesn't land exactly on one of the stops.
    private var matchConfidenceLevel: MatchConfidenceLevel {
        .nearest(to: coordinator.matchThreshold)
    }

    private var matchConfidenceIndex: Binding<Double> {
        Binding(
            get: { matchConfidenceLevel.sliderIndex },
            set: { coordinator.matchThreshold = MatchConfidenceLevel.from(sliderIndex: $0).threshold }
        )
    }

    // MARK: - Detection distance

    private var detectionDistanceLevel: DetectionDistanceLevel {
        .nearest(to: settings.minimumFaceWidth)
    }

    private var detectionDistanceIndex: Binding<Double> {
        Binding(
            get: { detectionDistanceLevel.sliderIndex },
            set: { settings.minimumFaceWidth = DetectionDistanceLevel.from(sliderIndex: $0).minimumFaceWidth }
        )
    }

    // MARK: - Actions

    private func unlock() {
        isUnlocking = true
        sessionError = nil
        Task {
            await pocController.unlockSession()
            sessionError = pocController.sessionError
            isUnlocking = false
        }
    }
}

/// The three selectable points on the "Match confidence" slider — named
/// rather than exposing the raw cosine-similarity threshold directly.
private enum MatchConfidenceLevel: Int, CaseIterable {
    case lessStrict, standard, moreStrict

    var title: String {
        switch self {
        case .lessStrict: return L10n.string(.confLessStrict)
        case .standard: return L10n.string(.confDefault)
        case .moreStrict: return L10n.string(.confMoreStrict)
        }
    }

    var threshold: Float {
        switch self {
        case .lessStrict: return 0.58
        case .standard: return 0.63
        case .moreStrict: return 0.68
        }
    }

    /// Position in `allCases` — same role as `AutoLockInterval.sliderIndex`.
    var sliderIndex: Double {
        Double(Self.allCases.firstIndex(of: self) ?? 0)
    }

    static func from(sliderIndex: Double) -> Self {
        let clamped = Int(sliderIndex.rounded())
        return allCases.indices.contains(clamped) ? allCases[clamped] : .standard
    }

    static func nearest(to threshold: Float) -> Self {
        allCases.min { abs($0.threshold - threshold) < abs($1.threshold - threshold) } ?? .standard
    }
}

/// The three selectable points on the "Detection distance" slider.
private enum DetectionDistanceLevel: Int, CaseIterable {
    case close, standard, far

    var title: String {
        switch self {
        case .close: return L10n.string(.distClose)
        case .standard: return L10n.string(.distDefault)
        case .far: return L10n.string(.distFar)
        }
    }

    var minimumFaceWidth: Float {
        switch self {
        case .close: return 0.23
        case .standard: return 0.19
        case .far: return 0.15
        }
    }

    var sliderIndex: Double {
        Double(Self.allCases.firstIndex(of: self) ?? 0)
    }

    static func from(sliderIndex: Double) -> Self {
        let clamped = Int(sliderIndex.rounded())
        return allCases.indices.contains(clamped) ? allCases[clamped] : .standard
    }

    static func nearest(to width: Float) -> Self {
        allCases.min { abs($0.minimumFaceWidth - width) < abs($1.minimumFaceWidth - width) } ?? .standard
    }
}
