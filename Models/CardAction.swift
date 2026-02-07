import SwiftUI

enum CardActionType: String, Codable {
    case email
    case phone
    case website
    case linkedIn
    case instagram
    case github
    case portfolio
    case message
}

struct CardAction: Identifiable {
    let id = UUID()
    let type: CardActionType
    let label: String
    let value: String
    let systemIcon: String
    
    var url: URL? {
        switch type {
        case .email:
            return URL(string: "mailto:\(value)")
        case .phone:
            return URL(string: "tel:\(value)")
        case .website, .portfolio:
            return URL(string: value.hasPrefix("http") ? value : "https://\(value)")
        case .linkedIn:
            return URL(string: value.hasPrefix("http") ? value : "https://\(value)")
        case .instagram:
            // fallback to web
            return URL(string: value.hasPrefix("http") ? value : "https://instagram.com/\(value)")
        case .github:
            return URL(string: value.hasPrefix("http") ? value : "https://github.com/\(value)")
        case .message:
            return nil
        }
    }
}
