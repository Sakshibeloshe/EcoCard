import Foundation

/// Lightweight Codable representation of a CardModel used for peer-to-peer transfer.
struct CardTransferPayload: Codable {
    let id: String
    let type: String        // CardType.rawValue
    let theme: String       // CardTheme.rawValue
    let displayName: String
    let title: String
    let company: String
    let bio: String
    let email: String?
    let phone: String?
    let website: String?
    let pronouns: String
    let instagram: String?
    let linkedIn: String?
    let github: String?
    let portfolio: String?
}
