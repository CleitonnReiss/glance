//
//  NotchShape.swift
//  glance
//
//  The notch silhouette. Inverted (concave) top corners flare the panel into the
//  menu bar; the flare has no standard-shape equivalent so it's a hand-built quad
//  curve, while the bottom corners use Apple's real `.continuous` curve (see
//  `ContinuousCorner`) for pixel parity with system UI. Body is inset by `topRadius`
//  per side for the flare (see `NotchGeometry.flareAllowance`).
//
//  `style` is fixed per screen, so deliberately excluded from `animatableData` —
//  only the radii interpolate.
//

import SwiftUI

struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat
    var style: NotchPanelStyle = .notch

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        switch style {
        case .notch: return notchPath(in: rect)
        case .pill: return pillPath(in: rect)
        }
    }

    private func notchPath(in rect: CGRect) -> Path {
        // Clamp so a small closed size can't produce self-intersecting
        // curves when the radii exceed half the available width/height.
        let top = max(0, min(topRadius, rect.width / 2))
        let bottom = max(0, min(bottomRadius, min(rect.width / 2 - top, rect.height)))

        var path = Path()

        // Top-left: flare outward to meet the screen edge.
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + top, y: rect.minY + top),
            control: CGPoint(x: rect.minX + top, y: rect.minY)
        )

        // Bottom corners quad-curve approximation
        path.addLine(to: CGPoint(x: rect.minX + top, y: rect.maxY - bottom))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + top + bottom, y: rect.maxY),
            control: CGPoint(x: rect.minX + top, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - top - bottom, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - top, y: rect.maxY - bottom),
            control: CGPoint(x: rect.maxX - top, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY + top))

        // Top-right flare.
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - top, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }

    private func pillPath(in rect: CGRect) -> Path {
        let limit = min(rect.width, rect.height) / 2
        let top = max(0, min(topRadius, limit))
        let bottom = max(0, min(bottomRadius, limit))

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - top, y: rect.minY + top), radius: top, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottom))
        path.addArc(center: CGPoint(x: rect.maxX - bottom, y: rect.maxY - bottom), radius: bottom, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottom, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottom, y: rect.maxY - bottom), radius: bottom, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + top))
        path.addArc(center: CGPoint(x: rect.minX + top, y: rect.minY + top), radius: top, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct NotchShape_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NotchShape(topRadius: 16, bottomRadius: 65)
                .frame(width: 380, height: 260)
                .padding(20)
                .previewDisplayName("Notch")

            NotchShape(topRadius: 8, bottomRadius: 12)
                .frame(width: 200, height: 32)
                .padding(20)
                .previewDisplayName("Notch — closed")

            NotchShape(topRadius: 16, bottomRadius: 16, style: .pill)
                .frame(width: NotchGeometry.pillClosedSize.width, height: NotchGeometry.pillClosedSize.height)
                .padding(20)
                .previewDisplayName("Pill — collapsed")

            NotchShape(
                topRadius: NotchGeometry.pillOpenCornerRadius,
                bottomRadius: NotchGeometry.pillOpenCornerRadius,
                style: .pill
            )
            .frame(width: 380, height: 220)
            .padding(20)
            .previewDisplayName("Pill — expanded")
        }
    }
}

