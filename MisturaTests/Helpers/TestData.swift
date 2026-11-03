import UIKit
@testable import Mistura

enum TestError: Error {
    case any
}

func makeImage(color: UIColor = .systemOrange) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: format).image { context in
        color.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    }
}

func captureError<Value>(from operation: () async throws -> Value) async -> Error? {
    do {
        _ = try await operation()
        return nil
    } catch {
        return error
    }
}
