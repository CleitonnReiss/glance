//
//  YourFaceSettingsPage.swift
//  glance
//
//  The multi-identity Your Face page. Every enrolled person gets a card:
//  name, an enable switch, per-sample capture-quality ticks, and
//  Recapture/Delete.
//

import SwiftUI

struct YourFaceSettingsPage: View {
    let environment: AppEnvironment
    @ObservedObject private var store = FaceEnrollmentStore.shared
    @ObservedObject private var settings = GlanceSettings.shared

    @State private var sessionError: String?
    @State private var isUnlocking = false
    @State private var identityPendingDeletion: FaceIdentity?
    /// Surfaced when an encrypted write fails (realistically: the session
    /// lapsed between rendering and tapping). The store rolls back on
    /// failure, so the control snaps back on its own — this explains why.
    @State private var writeError: String?

    /// Locked takes priority over enrollment status: `FaceIdentity` data is
    /// encrypted under the session key, so whether anyone is enrolled is
    /// unknown until the session is unlocked.
    private enum PageStateKind: Equatable {
        case locked
        case unreadable
        case notEnrolled
        case enrolled
    }

    private var stateKind: PageStateKind {
        if store.isLocked { return .locked }
        // Ahead of `.notEnrolled` — a failed decrypt looks like an empty
        // store, and offering "Set up Face Unlock" there would destroy the data.
        if store.loadFailure != nil { return .unreadable }
        return store.identities.isEmpty ? .notEnrolled : .enrolled
    }

    /// The notch hosts one flow at a time, so a second Add/Recapture would
    /// swap the content out from under a capture already in progress.
    private var enrollmentFlowIsRunning: Bool {
        NotchOverlayController.shared.phase == .onboarding
    }

    var body: some View {
        let lang = settings.appLanguage
        ZStack(alignment: .top) {
            lockedState(lang: lang)
                .opacity(stateKind == .locked ? 1 : 0)
                .allowsHitTesting(stateKind == .locked)
                .accessibilityHidden(stateKind != .locked)

            unreadableState(lang: lang)
                .opacity(stateKind == .unreadable ? 1 : 0)
                .allowsHitTesting(stateKind == .unreadable)
                .accessibilityHidden(stateKind != .unreadable)

            notEnrolledState(lang: lang)
                .opacity(stateKind == .notEnrolled ? 1 : 0)
                .allowsHitTesting(stateKind == .notEnrolled)
                .accessibilityHidden(stateKind != .notEnrolled)

            enrolledState(lang: lang)
                .opacity(stateKind == .enrolled ? 1 : 0)
                .allowsHitTesting(stateKind == .enrolled)
                .accessibilityHidden(stateKind != .enrolled)
        }
        .animation(SettingsMetrics.stateTransitionAnimation, value: stateKind)
        .onAppear { store.reloadIfUnlocked() }
        // The enrollment flow runs in the notch, outside this view's
        // hierarchy, so nothing else prompts a re-check once it closes.
        .onChange(of: NotchOverlayController.shared.phase) { newPhase in
            guard newPhase == .closed else { return }
            store.reloadIfUnlocked()
        }
        .confirmationDialog(
            L10n.string(.deleteFacePrompt, lang: lang),
            isPresented: Binding(
                get: { identityPendingDeletion != nil },
                set: { if !$0 { identityPendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: identityPendingDeletion
        ) { identity in
            Button(L10n.string(.delete, lang: lang), role: .destructive) { delete(identity) }
            Button(L10n.string(.cancel, lang: lang), role: .cancel) { identityPendingDeletion = nil }
        } message: { identity in
            Text(L10n.string(.deleteFaceMessage, lang: lang, identity.name))
        }
    }

    // MARK: - Locked

    private func lockedState(lang: AppLanguage) -> some View {
        SettingsEmptyStateView(
            icon: "lock.fill",
            message: L10n.string(.sessionLocked, lang: lang),
            buttonTitle: isUnlocking ? L10n.string(.authenticatingBtn, lang: lang) : L10n.string(.unlockSessionBtn, lang: lang),
            isButtonEnabled: !isUnlocking,
            caption: sessionError,
            action: unlock
        )
    }

    // MARK: - Unreadable

    /// Session open but the encrypted store didn't decrypt. Deliberately
    /// offers no enroll or delete action, since a write here would replace
    /// faces still on disk.
    private func unreadableState(lang: AppLanguage) -> some View {
        VStack(spacing: SettingsMetrics.emptyStateSpacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: SettingsMetrics.emptyStateIconSize, weight: .regular))
                .foregroundStyle(SettingsMetrics.qualityFairColor)

            Text(L10n.string(.faceLoadErrorTitle, lang: lang))
                .font(SettingsMetrics.rowFont)
                .foregroundStyle(SettingsMetrics.textSecondary)

            SettingsCaption(text: store.loadFailure ?? L10n.string(.faceLoadErrorDefault, lang: lang))
                .multilineTextAlignment(.center)

            SettingsCaption(text: L10n.string(.faceLoadRecoveryNotice, lang: lang))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: SettingsMetrics.emptyStateMinHeight)
    }

    // MARK: - Not enrolled

    private func notEnrolledState(lang: AppLanguage) -> some View {
        SettingsEmptyStateView(
            icon: "faceid",
            message: L10n.string(.notEnrolledTitle, lang: lang),
            buttonTitle: L10n.string(.setupFaceUnlockBtn, lang: lang),
            isButtonEnabled: !enrollmentFlowIsRunning,
            action: { OnboardingController.startEnrollmentOnly() }
        )
    }

    // MARK: - Enrolled

    private func enrolledState(lang: AppLanguage) -> some View {
        VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
            faceEncryptedCard(lang: lang)
            identitiesHeader(lang: lang)
            .padding(.bottom, -8)

            ForEach(store.identities) { identity in
                IdentityCard(
                    identity: identity,
                    isStale: identity.isStale(comparedTo: environment.faceLabController.pipeline.embedder),
                    canStartFlow: !enrollmentFlowIsRunning,
                    isEnabled: enabledBinding(for: identity),
                    recapture: { OnboardingController.startRecapture(of: identity) },
                    delete: { identityPendingDeletion = identity }
                )
            }

            if !store.identities.isEmpty && store.activeIdentities.isEmpty {
                SettingsCaption(text: L10n.string(.noIdentitiesEnabledNotice, lang: lang))
            }

            if let writeError {
                SettingsCaption(text: writeError)
            }
        }
    }

    /// Mirrors the Password page's "Password encrypted" row — both refer to
    /// the same session key.
    private func faceEncryptedCard(lang: AppLanguage) -> some View {
        SettingsGroup {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(L10n.string(.faceEncryptedTitle, lang: lang))
                        .font(SettingsMetrics.rowFont)
                        .foregroundStyle(SettingsMetrics.textPrimary)
                    Spacer(minLength: 8)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsMetrics.textSecondary)
                }

                Text(L10n.string(.faceEncryptedDescription, lang: lang))
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsMetrics.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
            .padding(.vertical, 12)
        }
    }

    private func identitiesHeader(lang: AppLanguage) -> some View {
        HStack(spacing: 0) {
            SettingsSectionTitle(text: L10n.string(.identitiesTitle, lang: lang))

            Button {
                OnboardingController.startAddIdentity()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SettingsMetrics.textTertiary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(enrollmentFlowIsRunning)
            .opacity(enrollmentFlowIsRunning ? 0.4 : 1)
            .help(L10n.string(.addFaceHelp, lang: lang))
            .padding(.trailing, SettingsMetrics.sectionTitleHorizontalInset)
            .padding(.top, SettingsMetrics.sectionTitleVerticalPadding)
        }
    }

    // MARK: - Actions

    /// Reads through to the store so the switch reflects a rolled-back
    /// write instead of the value the user just tapped.
    private func enabledBinding(for identity: FaceIdentity) -> Binding<Bool> {
        Binding(
            get: { store.identities.first { $0.id == identity.id }?.isEnabled ?? true },
            set: { newValue in
                do {
                    try store.setEnabled(newValue, for: identity.id)
                    writeError = nil
                } catch {
                    writeError = error.localizedDescription
                }
            }
        )
    }

    private func delete(_ identity: FaceIdentity) {
        do {
            try store.delete(identity)
            writeError = nil
        } catch {
            writeError = error.localizedDescription
        }
        identityPendingDeletion = nil
    }

    private func unlock() {
        isUnlocking = true
        sessionError = nil
        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try SecureCredentialManager.unlockSession(reason: L10n.string(.authReasonViewFace))
                }.value
                store.reloadIfUnlocked()
            } catch {
                sessionError = error.localizedDescription
            }
            isUnlocking = false
        }
    }
}

// MARK: - Identity card

/// One enrolled person: name pill and switch on the first line, quality
/// read-out and actions on the second. Built from `SettingsGroup` and the
/// shared row tokens so it matches every other settings page.
private struct IdentityCard: View {
    let identity: FaceIdentity
    let isStale: Bool
    let canStartFlow: Bool
    @Binding var isEnabled: Bool
    let recapture: () -> Void
    let delete: () -> Void

    private var poorCount: Int {
        identity.samples.filter { $0.qualityTier == .poor }.count
    }

    private var ratedCount: Int {
        identity.samples.filter { $0.qualityTier != .unrated }.count
    }

    /// Share of samples that *aren't* in the red band, e.g. 3 low out of 18
    /// samples is 15/18 good → 83%.
    private var qualityPercentage: Int {
        let total = identity.samples.count
        guard total > 0 else { return 0 }
        return Int((Double(total - poorCount) / Double(total) * 100).rounded())
    }

    /// An enrollment saved before per-sample quality existed reports "not
    /// recorded" rather than a misleading 100%.
    private var qualityCaption: String {
        if identity.samples.isEmpty { return L10n.string(.noSamplesCaptured) }
        if ratedCount == 0 { return L10n.string(.qualityNotRecorded) }
        return L10n.string(.qualityPercent, qualityPercentage)
    }

    var body: some View {
        let lang = GlanceSettings.shared.appLanguage
        SettingsGroup {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    namePill
                    .padding(.leading, -2)
                    Spacer(minLength: 8)
                    GlanceToggle(isOn: $isEnabled)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(qualityCaption)
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsMetrics.textTertiary)

                    HStack(alignment: .center, spacing: 8) {
                        QualityTickStrip(samples: identity.samples)
                        .padding(.leading, 2)
                        Spacer(minLength: 12)
                        PillActionButton(title: L10n.string(.recaptureBtn, lang: lang), action: recapture)
                            .disabled(!canStartFlow)
                            .opacity(canStartFlow ? 1 : 0.4)
                        PillIconButton(systemImage: "trash", action: delete)
                            .help(L10n.string(.deleteFaceBtnHelp, lang: lang, identity.name))
                    }
                }
                // Dimmed rather than hidden while switched off: the person
                // is still enrolled, just not being matched against.
                .opacity(isEnabled ? 1 : 0.45)

                if isStale {
                    Text(L10n.string(.differentModelWarning, lang: lang))
                        .font(.system(size: 11))
                        .foregroundStyle(SettingsMetrics.qualityFairColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
            .padding(.vertical, 12)
        }
    }

    private var namePill: some View {
        Text(identity.name)
            .font(SettingsMetrics.rowFont)
            .foregroundStyle(SettingsMetrics.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(SettingsMetrics.neutralButtonFill)
            .overlay(
                Capsule().strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
            )
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.45)
    }
}

/// One tick per stored sample, colored by its band. Reads left-to-right in
/// capture order (not sorted by score) so a run of red points at the pose
/// that actually went badly.
private struct QualityTickStrip: View {
    let samples: [FaceSample]

    var body: some View {
        HStack(spacing: SettingsMetrics.qualityTickSpacing) {
            ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                Capsule()
                    .fill(color(for: sample.qualityTier))
                    // maxWidth, not fixed, so more samples than a guided
                    // enrollment's 18 compress instead of overflowing.
                    .frame(maxWidth: SettingsMetrics.qualityTickWidth)
            }
        }
        .frame(width: stripWidth, height: SettingsMetrics.qualityTickHeight, alignment: .leading)
        .accessibilityElement()
        .accessibilityLabel("Capture quality for \(samples.count) samples")
    }

    /// Fixed rather than flexible: this strip shares a row with a `Spacer`
    /// and two buttons, and a `maxWidth` frame would negotiate against them
    /// for the slack instead of just sizing to its ticks.
    private var stripWidth: CGFloat {
        let tick = SettingsMetrics.qualityTickWidth
        let gap = SettingsMetrics.qualityTickSpacing
        let natural = CGFloat(samples.count) * (tick + gap) - gap
        return min(max(natural, 0), SettingsMetrics.qualityStripMaxWidth)
    }

    private func color(for tier: FaceSample.QualityTier) -> Color {
        switch tier {
        case .poor: return SettingsMetrics.qualityPoorColor
        case .fair: return SettingsMetrics.qualityFairColor
        case .good: return SettingsMetrics.qualityGoodColor
        case .unrated: return SettingsMetrics.qualityUnratedColor
        }
    }
}

/// Neutral capsule button matching the card's inner pills. Deliberately not
/// `SettingsPrimaryButton`: this sits next to a destructive action and
/// shouldn't read as the accent CTA.
private struct PillActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SettingsMetrics.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(SettingsMetrics.neutralButtonFill)
                .overlay(
                    Capsule().strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The circular icon twin of `PillActionButton`, for the delete control.
private struct PillIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundStyle(SettingsMetrics.textPrimary)
                .frame(width: 28, height: 28)
                .background(SettingsMetrics.neutralButtonFill)
                .overlay(
                    Circle().strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
