//
//  CardType.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import Foundation

enum CardType: String, CaseIterable, Identifiable, Codable {
    case personal = "Personal"
    case business = "Business"
    case social = "Social"
    case event = "Event"
    case blank = "Custom Blank"   // <-- 5th type

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .business: return "Business"
        case .social: return "Social"
        case .event: return "Event"
        case .blank: return "Custom"
        }
    }
    
    var title: String {
        return displayName
    }

    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .business: return "briefcase.fill"
        case .social: return "sparkles"
        case .event: return "ticket.fill"
        case .blank: return "square.grid.2x2.fill"
        }
    }

    var emoji: String {
        switch self {
        case .personal: return "🌱"
        case .business: return "💼"
        case .social: return "✨"
        case .event: return "🎟️"
        case .blank: return "🧩"
        }
    }
}

