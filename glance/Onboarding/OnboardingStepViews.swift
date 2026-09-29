//
//  OnboardingStepViews.swift
//  glance
//
//  The screens of the notch-hosted onboarding flow. Each fills whatever panel size
//  OnboardingController reports for its step — sizing itself is the notch window's job.
//

import SwiftUI
import AppKit

// MARK: - 1. Intro

/// Globe button in the initial screen to switch language before starting configuration.
struct LanguageGlobeButton: View {
    @ObservedObject private var settings = GlanceSettings.shared

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button(action: {
                    settings.appLanguage = lang
                }) {
                    if settings.appLanguage == lang {
                        Label(lang.displayName, systemImage: "checkmark")
                    } else {
                        Text(lang.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(GlanceTheme.textPrimary)
            .frame(width: 48, height: OnboardingMetrics.pillButtonHeight)
            .background(GlanceTheme.surface)
            .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .accessibilityLabel("Language / Idioma")
    }
}

struct IntroStepView: View {
    let controller: OnboardingController
    @ObservedObject private var settings = GlanceSettings.shared

    var body: some View {
        let lang = settings.appLanguage
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string(.introTitle, lang: lang))
                    .font(GlanceTheme.Font.title)
                    .foregroundStyle(GlanceTheme.textPrimary)
                Text(L10n.string(.introSubtitle, lang: lang))
                    .font(GlanceTheme.Font.button)
                    .foregroundStyle(GlanceTheme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    PillButton(title: L10n.string(.next, lang: lang)) {
                        controller.advance()
                    }
                    LanguageGlobeButton()
                }
            }
            .padding(.leading, 4)
            Spacer(minLength: 4)
            GlanceLogoView()
                .frame(width: 106, height: 106)
                .padding(.top, 4)
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
        .onAppear {
            controller.playIntroSweepIfNeeded()
        }
    }
}

private struct GlanceLogoView: View {
    var body: some View {
        // Video already bakes in its own white rounded-card background — no extra chrome needed.
        LoopingVideoView(resourceName: "logoanimation")
    }
}

// MARK: - 2. Permissions

struct PermissionsStepView: View {
    @ObservedObject var controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string(.permTitle))
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            // Spacer(minLength: 0)

            PermissionRow(
                title: L10n.string(.permAccessibilityTitle),
                detail: L10n.string(.permAccessibilityDetail),
                granted: controller.accessibilityGranted
            ) { controller.grantAccessibility() }

            PermissionRow(
                title: L10n.string(.permCameraTitle),
                detail: L10n.string(.permCameraDetail),
                granted: controller.cameraPermission == .granted
            ) { controller.grantCamera() }

            // Spacer(minLength: 0)

            HStack(spacing: 10) {
                PillButton(title: L10n.string(.back), style: .secondary) {
                    controller.back()
                }
                PillButton(title: L10n.string(.next), isEnabled: controller.bothPermissionsGranted) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 3. Security notice

struct SecurityNoticeStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.top, 4)
                .padding(.leading, 4)

            Text(L10n.string(.secNoticeTitle))
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)

            Text(L10n.string(.secNoticeDetail))
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)
                .padding(.bottom, 6)

            HStack(spacing: 10) {
                if controller.isPostUpdateNotice {
                    // Declining isn't a real option here — see `declinePostUpdateNotice()`.
                    PillButton(title: L10n.string(.secNoticeDecline), style: .secondary) {
                        controller.declinePostUpdateNotice()
                    }
                } else {
                    PillButton(title: L10n.string(.back), style: .secondary) {
                        controller.back()
                    }
                }
                PillButton(title: L10n.string(.secNoticeAccept), isDefault: true) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 4. Pre set-up

struct PreSetupStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.string(.preSetupTitle))
                        .font(GlanceTheme.Font.title)
                        .foregroundStyle(GlanceTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)

                    Text(L10n.string(.preSetupDetail))
                        .font(GlanceTheme.Font.button)
                        .foregroundStyle(GlanceTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.85)
                }
                .padding(.top, 6)
                .padding(.leading, 4)
                Spacer(minLength: 0)
                UnlockGlyphView()
                    .frame(width: 120, height: 120)
            }
            Spacer(minLength: 4)

            HStack(spacing: 10) {
                PillButton(title: L10n.string(.back), style: .secondary) {
                    controller.back()
                }
                PillButton(title: L10n.string(.next)) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

private struct UnlockGlyphView: View {
    var body: some View {
        LoopingVideoView(resourceName: "idleanimation")
    }
}

// MARK: - 5. Select camera

struct SelectCameraStepView: View {
    @ObservedObject var controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(.selectCameraTitle))
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)
                .padding(.top, 4)

            Text(L10n.string(.selectCameraSubtitle))
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            CameraSelectionPill(
                label: controller.cameraSelectionLabel,
                devices: controller.cameraDevices
            ) { id in
                controller.selectCamera(id: id)
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                PillButton(title: L10n.string(.back), style: .secondary) {
                    controller.back()
                }
                PillButton(title: L10n.string(.next)) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
        .onAppear {
            controller.refreshCameraDevices()
            controller.applyDisplayPinForCameraSelection()
        }
    }
}

// MARK: - 6-8. Guided enrollment (camera + tick ring + camera-complete)

struct EnrollStepView: View {
    @ObservedObject var controller: OnboardingController
    @Environment(\.notchPanelStyle) private var style

    var body: some View {
        VStack(spacing: 0) {
            cameraCluster
                .padding(.top, cameraTopPadding)
            Spacer(minLength: 8)
            instructionLabel
                .padding(.horizontal, OnboardingMetrics.enrollInstructionHorizontalPadding)
                .padding(.bottom, OnboardingMetrics.enrollInstructionBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            if showsCloseButton {
                EnrollmentCloseButton {
                    controller.back()
                }
                .padding(OnboardingMetrics.enrollCloseButtonEdgePadding)
            }
        }
        .background(GlanceTheme.panel)
    }

    private var showsCloseButton: Bool {
        !controller.enrollmentComplete && !controller.showCheckmark
    }

    private var cameraTopPadding: CGFloat {
        style == .pill
            ? OnboardingMetrics.enrollCameraTopPaddingPill
            : OnboardingMetrics.enrollCameraTopPaddingNotch
    }

    private var cameraCluster: some View {
        ZStack {
            EnrollmentRingView(controller: controller)

            CameraPreviewView(session: controller.camera.session, faces: [])
                .frame(
                    width: OnboardingMetrics.cameraCircleDiameter,
                    height: OnboardingMetrics.cameraCircleDiameter
                )
                .clipShape(Circle())
                .opacity(controller.cameraPreviewVisible ? 1 : 0)
                .animation(
                    .easeInOut(duration: OnboardingMetrics.previewFadeOut),
                    value: controller.cameraPreviewVisible
                )
                .overlay {
                    if controller.isTooFar && controller.cameraPreviewVisible && !controller.showCheckmark {
                        EnrollmentTooFarChevron()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: controller.isTooFar)

            if controller.showCheckmark {
                AnimatedCheckmark(color: GlanceTheme.accent, lineWidth: 8)
                    .frame(width: 70, height: 59)
                    .transition(.opacity)
                    .padding(.top, 4)
            }
        }
        .frame(
            width: OnboardingMetrics.enrollCameraClusterDiameter,
            height: OnboardingMetrics.enrollCameraClusterDiameter
        )
    }

    private var instructionLabel: some View {
        Text(controller.enrollmentInstruction)
            .font(GlanceTheme.Font.instruction)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .id(controller.enrollmentInstruction)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: controller.enrollmentInstruction)
            .opacity(controller.guideVisible ? 1 : 0)
            .animation(
                .easeInOut(
                    duration: controller.guideVisible
                        ? OnboardingMetrics.enrollInstructionFadeIn
                        : OnboardingMetrics.enrollInstructionFadeOut
                ),
                value: controller.guideVisible
            )
    }
}

private struct EnrollmentCloseButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.8))
                .frame(
                    width: OnboardingMetrics.enrollCloseButtonSize,
                    height: OnboardingMetrics.enrollCloseButtonSize
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(L10n.string(.close))
    }
}

private struct EnrollmentTooFarChevron: View {
    var body: some View {
        Image(systemName: "chevron.up.2")
            .font(.system(size: OnboardingMetrics.enrollTooFarChevronSize, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
            .accessibilityHidden(true)
    }
}

// MARK: - 9. Name

/// Asks who was just captured — for a recapture, pre-filled with the existing name so
/// this doubles as rename.
struct NameStepView: View {
    @ObservedObject var controller: OnboardingController

    private var trimmedName: String {
        controller.pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(.nameStepTitle))
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)

            Text(L10n.string(.nameStepSubtitle))
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            PillTextField(placeholder: L10n.string(.namePlaceholder), text: $controller.pendingName, autofocus: true) {
                controller.confirmName()
            }

            if let error = controller.nameError {
                Text(error)
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.statusDenied)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                PillButton(title: L10n.string(.back), style: .secondary) {
                    controller.back()
                }
                PillButton(title: controller.nameStepPrimaryTitle, isEnabled: !trimmedName.isEmpty, isDefault: true) {
                    controller.confirmName()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 10. Password

struct PasswordStepView: View {
    @ObservedObject var controller: OnboardingController

    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string(.passwordStepTitle))
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)

            Text(L10n.string(.passwordStepSubtitle))
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            PillSecureField(placeholder: L10n.string(.passwordPlaceholder), text: $password, autofocus: true) {
                guard !password.isEmpty, !controller.isSavingPassword else { return }
                Task { _ = await controller.finish(password: password) }
            }

            if let error = controller.passwordError {
                Text(error)
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.statusDenied)
            }

            // Spacer(minLength: 0)

            HStack(spacing: 10) {
                PillButton(title: L10n.string(.back), style: .secondary) {
                    controller.back()
                }
                PillButton(
                    title: controller.isSavingPassword ? L10n.string(.saving) : L10n.string(.confirm),
                    isEnabled: !password.isEmpty && !controller.isSavingPassword,
                    isDefault: true
                ) {
                    Task { _ = await controller.finish(password: password) }
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 11. Complete

struct CompleteStepView: View {
    var body: some View {
        HStack(spacing: 12) {
            Text(L10n.string(.completeTitle))
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
            Spacer(minLength: 4)
            AnimatedCheckmark(color: .white, lineWidth: 5)
                .frame(width: 20, height: 15)
        }
        .onboardingContentHorizontalPadding()
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(GlanceTheme.panel)
    }
}
