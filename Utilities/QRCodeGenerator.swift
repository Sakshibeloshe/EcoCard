import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Generates a QR code `UIImage` from a `CardModel`.
///
/// **Swift 6 threading:**  All methods are `nonisolated` — they are safe
/// to call from any actor, including `Task.detached`.
/// `CIContext`, `CIFilter`, `CGImage`, and `UIImage(cgImage:)` are all
/// documented as safe to use off the main thread by Apple.
///
/// Encoding format: the card is JSON-encoded then base64-encoded and
/// prefixed with `ecocard://` so the scanner can identify it.
enum QRCodeGenerator {

    static let scheme = "ecocard://"

    // MARK: - Public API

    /// Returns a pixel-perfect QR code `UIImage`, or `nil` on failure.
    /// Safe to call from any thread / actor.
    nonisolated static func generate(from card: CardModel, size: CGFloat = 300) -> UIImage? {
        guard let payload = encode(card) else { return nil }
        return makeQRImage(from: payload, size: size)
    }

    /// Encodes a `CardModel` into the `ecocard://` deep-link string.
    nonisolated static func encode(_ card: CardModel) -> String? {
        guard let data = try? JSONEncoder().encode(card) else { return nil }
        return scheme + data.base64EncodedString()
    }

    /// Decodes a scanned QR string back into a `CardModel`.
    /// Returns `nil` if the string doesn't start with `ecocard://`.
    nonisolated static func decode(_ string: String) -> CardModel? {
        guard string.hasPrefix(scheme) else { return nil }
        let b64 = String(string.dropFirst(scheme.count))
        guard
            let data = Data(base64Encoded: b64),
            var card = try? JSONDecoder().decode(CardModel.self, from: data)
        else { return nil }
        card.isReceived = true
        return card
    }

    // MARK: - Private

    private static func makeQRImage(from string: String, size: CGFloat) -> UIImage? {
        // CIContext is thread-safe; create per-call to avoid shared state.
        let ciContext = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.correctionLevel = "M"

        guard let inputData = string.data(using: .isoLatin1) else { return nil }
        filter.setValue(inputData, forKey: "inputMessage")

        guard let ciImage = filter.outputImage else { return nil }

        // Scale the raw QR (usually ~41 × 41 pts) to the requested size
        let scaleX = size / ciImage.extent.width
        let scaleY = size / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = ciContext.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
