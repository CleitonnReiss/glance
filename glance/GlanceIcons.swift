//
//  GlanceIcons.swift
//  glance
//
//  Provides native vector drawing and PNG asset resolution for Glance icons
//  (MenuBarIcon and YourFaceIcon) ensuring full compatibility with macOS Monterey (12.x+).
//

import AppKit
import SwiftUI

enum GlanceIcons {
    /// Loads the MenuBarIcon from resources or falls back to programmatic vector rendering.
    static func menuBarIcon() -> NSImage {
        if let image = NSImage(named: "MenuBarIcon") ?? Bundle.main.image(forResource: "MenuBarIcon") {
            image.isTemplate = true
            return image
        }
        return createVectorIcon(size: CGSize(width: 18, height: 18))
    }

    /// Loads the YourFaceIcon from resources or falls back to programmatic vector rendering.
    static func yourFaceIcon(size: CGFloat = 18) -> NSImage {
        if let image = NSImage(named: "YourFaceIcon") ?? Bundle.main.image(forResource: "YourFaceIcon") {
            image.isTemplate = true
            return image
        }
        return createVectorIcon(size: CGSize(width: size, height: size))
    }

    /// Programmatic vector drawing handler for Glance's mark (face in brackets).
    /// Resolution-independent; renders crisp lines on Retina (2x) and standard (1x) displays.
    static func createVectorIcon(size: CGSize) -> NSImage {
        let img = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            defer { context.restoreGState() }

            let padding: CGFloat = 1.0
            let drawWidth = rect.width - (padding * 2)
            let drawHeight = rect.height - (padding * 2)
            let fitScale = min(drawWidth / 181.0, drawHeight / 174.0)
            let renderedW = 181.0 * fitScale
            let renderedH = 174.0 * fitScale
            let offsetX = padding + (drawWidth - renderedW) / 2.0
            let offsetY = padding + (drawHeight - renderedH) / 2.0

            context.translateBy(x: offsetX, y: rect.height - offsetY)
            context.scaleBy(x: fitScale, y: -fitScale)

            context.setStrokeColor(NSColor.black.cgColor)
            context.setLineWidth(14)
            context.setLineCap(.round)
            context.setLineJoin(.round)

            // 1. Smile
            let smile = CGMutablePath()
            smile.move(to: CGPoint(x: 50.0027, y: 117.938))
            smile.addCurve(to: CGPoint(x: 134.326, y: 117.938),
                           control1: CGPoint(x: 66.6591, y: 139.354),
                           control2: CGPoint(x: 117.149, y: 139.354))
            context.addPath(smile)
            context.strokePath()

            // 2. Nose
            let nose = CGMutablePath()
            nose.move(to: CGPoint(x: 96.8489, y: 47))
            nose.addLine(to: CGPoint(x: 80.7874, y: 95.1846))
            nose.addLine(to: CGPoint(x: 96.8489, y: 95.1846))
            context.addPath(nose)
            context.strokePath()

            // 3. Left Eye
            let leftEye = CGMutablePath()
            leftEye.move(to: CGPoint(x: 52.6797, y: 47))
            leftEye.addLine(to: CGPoint(x: 52.6797, y: 68.6513))
            context.addPath(leftEye)
            context.strokePath()

            // 4. Right Eye
            let rightEye = CGMutablePath()
            rightEye.move(to: CGPoint(x: 131.649, y: 47))
            rightEye.addLine(to: CGPoint(x: 131.649, y: 68.6513))
            context.addPath(rightEye)
            context.strokePath()

            // 5. Bottom-Left Bracket
            let blBracket = CGMutablePath()
            blBracket.move(to: CGPoint(x: 6.00001, y: 134))
            blBracket.addCurve(to: CGPoint(x: 6.00001, y: 140.182),
                               control1: CGPoint(x: 6.00001, y: 135.545),
                               control2: CGPoint(x: 6.00001, y: 139.299))
            blBracket.addCurve(to: CGPoint(x: 30.7292, y: 168),
                               control1: CGPoint(x: 6.00001, y: 155.636),
                               control2: CGPoint(x: 18.3646, y: 168))
            blBracket.addCurve(to: CGPoint(x: 40.0027, y: 168),
                               control1: CGPoint(x: 33.8204, y: 168),
                               control2: CGPoint(x: 36.9115, y: 168))
            context.addPath(blBracket)
            context.strokePath()

            // 6. Bottom-Right Bracket
            let brBracket = CGMutablePath()
            brBracket.move(to: CGPoint(x: 175.005, y: 134))
            brBracket.addCurve(to: CGPoint(x: 175.005, y: 140.182),
                               control1: CGPoint(x: 175.005, y: 135.545),
                               control2: CGPoint(x: 175.005, y: 139.299))
            brBracket.addCurve(to: CGPoint(x: 150.276, y: 168),
                               control1: CGPoint(x: 175.005, y: 155.636),
                               control2: CGPoint(x: 162.641, y: 168))
            brBracket.addCurve(to: CGPoint(x: 141.003, y: 168),
                               control1: CGPoint(x: 147.185, y: 168),
                               control2: CGPoint(x: 144.094, y: 168))
            context.addPath(brBracket)
            context.strokePath()

            // 7. Top-Left Bracket
            let tlBracket = CGMutablePath()
            tlBracket.move(to: CGPoint(x: 6.00001, y: 40))
            tlBracket.addCurve(to: CGPoint(x: 6.00001, y: 33.8182),
                               control1: CGPoint(x: 6.00001, y: 38.4545),
                               control2: CGPoint(x: 6.00001, y: 34.7008))
            tlBracket.addCurve(to: CGPoint(x: 30.7292, y: 6),
                               control1: CGPoint(x: 6.00001, y: 18.3636),
                               control2: CGPoint(x: 18.3646, y: 6))
            tlBracket.addCurve(to: CGPoint(x: 40.0027, y: 6),
                               control1: CGPoint(x: 33.8204, y: 6),
                               control2: CGPoint(x: 36.9115, y: 6))
            context.addPath(tlBracket)
            context.strokePath()

            // 8. Top-Right Bracket
            let trBracket = CGMutablePath()
            trBracket.move(to: CGPoint(x: 175.005, y: 40))
            trBracket.addCurve(to: CGPoint(x: 175.005, y: 33.8182),
                               control1: CGPoint(x: 175.005, y: 38.4545),
                               control2: CGPoint(x: 175.005, y: 34.7008))
            trBracket.addCurve(to: CGPoint(x: 150.276, y: 6),
                               control1: CGPoint(x: 175.005, y: 18.3636),
                               control2: CGPoint(x: 162.641, y: 6))
            trBracket.addCurve(to: CGPoint(x: 141.003, y: 6),
                               control1: CGPoint(x: 147.185, y: 6),
                               control2: CGPoint(x: 144.094, y: 6))
            context.addPath(trBracket)
            context.strokePath()

            return true
        }
        img.isTemplate = true
        return img
    }
}
