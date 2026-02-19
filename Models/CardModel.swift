import Foundation
import SwiftUI

struct CardModel: Identifiable, Hashable, Codable {
    let id: UUID
    var type: CardType
    var theme: CardTheme

    // Core fields
    var fullName: String
    var title: String
    var company: String
    var bio: String
    var email: String?
    var website: String?
    var phone: String?
    var pronouns: String
    var photo: String? // Optional photo URL or base64
    
    // Socials (Optionals)
    var instagram: String?
    var linkedIn: String?
    var github: String?
    var portfolio: String?

    // Inbox features
    var isReceived: Bool
    var isFavorite: Bool
    var note: String
    var tags: [String]
    var folderId: UUID?
    var eventName: String?
    var intent: String? // New field

    init(
        id: UUID = UUID(),
        type: CardType,
        theme: CardTheme,
        fullName: String,
        title: String = "",
        company: String = "",
        bio: String = "",
        email: String? = nil,
        website: String? = nil,
        phone: String? = nil,
        pronouns: String = "",
        instagram: String? = nil,
        linkedIn: String? = nil,
        github: String? = nil,
        portfolio: String? = nil,
        isReceived: Bool = false,
        isFavorite: Bool = false,
        note: String = "",
        tags: [String] = [],
        folderId: UUID? = nil,
        eventName: String? = nil,
        intent: String? = nil,
        photo: String? = nil
    ) {
        self.id = id
        self.type = type
        self.theme = theme
        self.fullName = fullName
        self.title = title
        self.company = company
        self.bio = bio
        self.email = email
        self.website = website
        self.phone = phone
        self.pronouns = pronouns
        self.instagram = instagram
        self.linkedIn = linkedIn
        self.github = github
        self.portfolio = portfolio
        self.isReceived = isReceived
        self.isFavorite = isFavorite
        self.note = note
        self.tags = tags
        self.folderId = folderId
        self.eventName = eventName
        self.intent = intent
        self.photo = photo
    }
    
    // MARK: - Computed Properties
    
    var uiColor: Color {
        theme.color
    }
    
    var org: String? {
        if !company.isEmpty { return company }
        if let event = eventName, !event.isEmpty { return event }
        return nil
    }
    
    var subtitle: String? {
        if !title.isEmpty { return title }
        return nil
    }
}

extension CardModel {

    /// Returns actions that exist on the card.
    func availableActions() -> [CardAction] {
        var actions: [CardAction] = []

        if let email, !email.isEmpty {
            actions.append(CardAction(type: .email, label: "Email", value: email, systemIcon: "envelope.fill"))
        }
        if let phone, !phone.isEmpty {
            actions.append(CardAction(type: .phone, label: "Call", value: phone, systemIcon: "phone.fill"))
        }
        if let website, !website.isEmpty {
            actions.append(CardAction(type: .website, label: "Website", value: website, systemIcon: "safari.fill"))
        }
        if let linkedIn, !linkedIn.isEmpty {
            actions.append(CardAction(type: .linkedIn, label: "LinkedIn", value: linkedIn, systemIcon: "link"))
        }
        if let instagram, !instagram.isEmpty {
            actions.append(CardAction(type: .instagram, label: "Instagram", value: instagram, systemIcon: "camera.fill"))
        }
        if let github, !github.isEmpty {
            actions.append(CardAction(type: .github, label: "GitHub", value: github, systemIcon: "chevron.left.slash.chevron.right"))
        }
        if let portfolio, !portfolio.isEmpty {
            actions.append(CardAction(type: .portfolio, label: "Portfolio", value: portfolio, systemIcon: "sparkles"))
        }

        return actions
    }

    /// Decide what goes on the front card.
    func primaryAction() -> CardAction? {
        switch type {
        case .personal:
            // Most personal cards want phone/message
            return availableActions().first(where: { $0.type == .phone })
                ?? availableActions().first(where: { $0.type == .email })

        case .business:
            // Business = LinkedIn > Email > Website
            return availableActions().first(where: { $0.type == .linkedIn })
                ?? availableActions().first(where: { $0.type == .email })
                ?? availableActions().first(where: { $0.type == .website })

        case .social:
            // Social = Instagram > Website
            return availableActions().first(where: { $0.type == .instagram })
                ?? availableActions().first(where: { $0.type == .website })

        case .event:
            // Event = Email > LinkedIn
            return availableActions().first(where: { $0.type == .email })
                ?? availableActions().first(where: { $0.type == .linkedIn })

        case .blank:
            // Custom = first available
            return availableActions().first
        }
    }

    func secondaryAction() -> CardAction? {
        guard let primary = primaryAction() else { return nil }
        let actions = availableActions()
        return actions.first(where: { $0.type != primary.type })
    }

    /// Converts this card into a lightweight payload for peer-to-peer transfer.
    func toPayload() -> CardTransferPayload {
        CardTransferPayload(
            id: id.uuidString,
            type: type.rawValue,
            theme: theme.rawValue,
            displayName: fullName,
            title: title,
            company: company,
            bio: bio,
            email: email,
            phone: phone,
            website: website,
            pronouns: pronouns,
            instagram: instagram,
            linkedIn: linkedIn,
            github: github,
            portfolio: portfolio
        )
    }
}
