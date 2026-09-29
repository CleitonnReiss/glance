import AppKit

func renderIcon(targetSize: CGSize, strokeWidth: CGFloat, scale: CGFloat) -> Data? {
    let pixelWidth = Int(targetSize.width * scale)
    let pixelHeight = Int(targetSize.height * scale)
    
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        return nil
    }
    
    context.scaleBy(x: scale, y: scale)
    
    // Center the 181x174 shape within targetSize with a small padding
    let padding: CGFloat = 1.0
    let drawWidth = targetSize.width - (padding * 2)
    let drawHeight = targetSize.height - (padding * 2)
    
    let scaleX = drawWidth / 181.0
    let scaleY = drawHeight / 174.0
    let fitScale = min(scaleX, scaleY)
    
    let renderedW = 181.0 * fitScale
    let renderedH = 174.0 * fitScale
    let offsetX = padding + (drawWidth - renderedW) / 2.0
    let offsetY = padding + (drawHeight - renderedH) / 2.0
    
    context.translateBy(x: offsetX, y: targetSize.height - offsetY)
    context.scaleBy(x: fitScale, y: -fitScale)
    
    context.setStrokeColor(NSColor.black.cgColor)
    context.setLineWidth(strokeWidth)
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

    guard let cgImage = context.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    return rep.representation(using: .png, properties: [:])
}

let args = CommandLine.arguments
let outputDir = args.count > 1 ? args[1] : "glance/Resources"

// 1. MenuBarIcon (18x18, 36x36)
if let data1x = renderIcon(targetSize: CGSize(width: 18, height: 18), strokeWidth: 14, scale: 1.0) {
    try? data1x.write(to: URL(fileURLWithPath: "\(outputDir)/MenuBarIcon.png"))
}
if let data2x = renderIcon(targetSize: CGSize(width: 18, height: 18), strokeWidth: 14, scale: 2.0) {
    try? data2x.write(to: URL(fileURLWithPath: "\(outputDir)/MenuBarIcon@2x.png"))
}

// 2. YourFaceIcon (20x19, 40x38)
if let dataFace1x = renderIcon(targetSize: CGSize(width: 20, height: 19), strokeWidth: 14, scale: 1.0) {
    try? dataFace1x.write(to: URL(fileURLWithPath: "\(outputDir)/YourFaceIcon.png"))
}
if let dataFace2x = renderIcon(targetSize: CGSize(width: 20, height: 19), strokeWidth: 14, scale: 2.0) {
    try? dataFace2x.write(to: URL(fileURLWithPath: "\(outputDir)/YourFaceIcon@2x.png"))
}

print("Icon assets successfully generated at: \(outputDir)")
