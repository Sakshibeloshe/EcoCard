import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import SwiftUI

/// Generates a QR code `UIImage` from a `CardModel`.
///
/// Encoding format: the card is JSON-encoded then base64url-encoded.
/// The string is prefixed with `ecocard://` so the scanner can
/// distinguish it from other QR codes.
enum QRCodeGenerator {

    static let scheme = "ecocard://"

    // MARK: - Generate

    /// Returns a `UIImage` of the QR code, or `nil` on failure.
    static func generate(from card: CardModel, size: CGFloat = 300) -> UIImage? {
        guard let payload = encode(card) else { return nil }
        return generateQR(from: payload, size: size)
    }

    /// Encodes a `CardModel` to a deep-link string safe for a QR code.
    static func encode(_ card: CardModel) -> String? {
        guard let data = try? JSONEncoder().encode(card) else { return nil }
        let b64 = data.base64EncodedString()
        return scheme + b64
    }

    /// Decodes a QR code string back into a `CardModel`.
    static func decode(_ string: String) -> CardModel? {
        guard string.hasPrefix(scheme) else { return nil }
        let b64 = String(string.dropFirst(scheme.count))
        guard let data = Data(base64Encoded: b64),
              var card = try? JSONDecoder().decode(CardModel.self, from: data)
        else { return nil }
        card.isReceived = true
        return card
    }

    // MARK: - Private

    private static func generateQR(from string: String, size: CGFloat) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.correctionLevel = "M"
        guard let data = string.data(using: .isoLatin1) else { return nil }
        filter.setValue(data, forKey: "inputMessage")

        guard let ciImage = filter.outputImage else { return nil }

        // Scale up so the QR code is crisp at the requested size
        let scaleX = size / ciImage.extent.width
        let scaleY = size / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
