//
//  OnboardingNotchView.swift
//  glance
//
//  Routes `controller.step` to its screen and applies the scroll-with-blur transition
//  between them: Next travels upward, Back is the mirror, travelling downward.
//

import SwiftUI

@MainActor
struct OnboardingNotchView: View {
    @ObservedObject var controller: OnboardingController

    var body: some View {
        ZStack {
            switch controller.step {
            case .intro:
                IntroStepView(controller: controller)
            case .permissions:
                PermissionsStepView(controller: controller)
            case .securityNotice:
                SecurityNoticeStepView(controller: controller)
            case .preSetup:
                PreSetupStepView(controller: controller)
            case .selectCamera:
                SelectCameraStepView(controller: controller)
            case .enroll:
                EnrollStepView(controller: controller)
            case .name:
                NameStepView(controller: controller)
            case .password:
                PasswordStepView(controller: controller)
            case .complete:
                CompleteStepView()
            }
        }
        .id(controller.step)
        .frame(width: controller.panelSize.width, height: controller.panelSize.height)
        .transition(stepTransition)
    }

    private var stepTransition: AnyTransition {
        let travel = controller.panelSize.height
        let insertionOffset: CGFloat = controller.navDirection == .forward ? travel : -travel
        let removalOffset: CGFloat = controller.navDirection == .forward ? -travel : travel
        return .asymmetric(
            insertion: .modifier(
                active: OffsetOpacity(offset: insertionOffset, opacity: 0),
                identity: OffsetOpacity(offset: 0, opacity: 1)
            ),
            removal: .modifier(
                active: OffsetOpacity(offset: removalOffset, opacity: 0),
                identity: OffsetOpacity(offset: 0, opacity: 1)
            )
        )
    }
}

/// Backing modifier for the step transition — offsets and fades smoothly
/// without triggering CoreGraphics vImageConverter crashes on Monterey.
private struct OffsetOpacity: ViewModifier {
    let offset: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
    }
}
