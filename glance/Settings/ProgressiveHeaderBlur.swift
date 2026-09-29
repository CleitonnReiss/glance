//
//  ProgressiveHeaderBlur.swift
//  glance
//
//  A backdrop blur behind the header whose strength fades from strongest at
//  the window's top edge to none by the bottom of the blur zone, so
//  scrolled rows sharpen up as they pass underneath rather than cutting
//  from blurred to crisp at a hard line.
//
//  SwiftUI's native `scrollEdgeEffectStyle(.soft, for: .top)` (macOS 26) is
//  the system version of exactly this, but it needs macOS 26 — this
//  window's deployment target is 15.0, and the header here is a custom
//  overlay rather than a real toolbar/safe-area inset for that system
//  effect to attach to. So this fakes it manually: each `Material` (weakest
//  to strongest) is masked to fade out over a shorter distance than the
//  last, so only a thin band right at the top ever stacks every layer —
//  the same layered-mask trick most manual "progressive blur" implementations
//  use, since `.blur(radius:)` itself has no per-pixel-varying radius.
//

import SwiftUI

struct ProgressiveHeaderBlur: View {
    var height: CGFloat

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: SettingsMetrics.windowTintColor.opacity(0.85), location: 0),
                .init(color: SettingsMetrics.windowTintColor.opacity(0), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
