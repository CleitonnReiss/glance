import CoreML
import Foundation

let sourceURL = URL(fileURLWithPath: "glance/Models/ArcFace.mlpackage")
print("Compiling \(sourceURL.path)...")
do {
    let compiledURL = try MLModel.compileModel(at: sourceURL)
    print("Compiled to: \(compiledURL.path)")
    let destURL = URL(fileURLWithPath: "build/ArcFace.mlmodelc")
    try? FileManager.default.removeItem(at: destURL)
    try FileManager.default.createDirectory(at: URL(fileURLWithPath: "build"), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: compiledURL, to: destURL)
    print("Successfully saved to: \(destURL.path)")
} catch {
    print("Failed to compile model: \(error)")
    exit(1)
}
