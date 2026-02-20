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
    var pronouns: String?
    var photo: String? // Optional photo URL or base64
    
    // Additional fields for themes
    var locationCity: String?
    var officeLocation: String?
    var linkedin: String?
    var instagram: String?
    var github: String?
    var portfolio: String?
    var snapchat: String?
    var spotify: String?
    var whatsapp: String?
    var eventBadge: String?
    var skillsTags: String?
    var emojiTags: String?
    var nickname: String?
    
    // Inbox features
    var isReceived: Bool
    var isFavorite: Bool
    var note: String
    var tags: [String]
    var folderId: UUID?
    var eventName: String?
    var intent: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: CardType,
        theme: CardTheme,
        fullName: String,
        createdAt: Date = Date(),
        title: String = "",
        company: String = "",
        bio: String = "",
        email: String? = nil,
        website: String? = nil,
        phone: String? = nil,
        pronouns: String? = nil,
        photo: String? = nil,
        locationCity: String? = nil,
        officeLocation: String? = nil,
        linkedin: String? = nil,
        instagram: String? = nil,
        github: String? = nil,
        portfolio: String? = nil,
        snapchat: String? = nil,
        spotify: String? = nil,
        whatsapp: String? = nil,
        eventBadge: String? = nil,
        skillsTags: String? = nil,
        emojiTags: String? = nil,
        nickname: String? = nil,
        isReceived: Bool = false,
        isFavorite: Bool = false,
        note: String = "",
        tags: [String] = [],
        folderId: UUID? = nil,
        eventName: String? = nil,
        intent: String? = nil
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
        self.photo = photo
        self.locationCity = locationCity
        self.officeLocation = officeLocation
        self.linkedin = linkedin
        self.instagram = instagram
        self.github = github
        self.portfolio = portfolio
        self.snapchat = snapchat
        self.spotify = spotify
        self.whatsapp = whatsapp
        self.eventBadge = eventBadge
        self.skillsTags = skillsTags
        self.emojiTags = emojiTags
        self.nickname = nickname
        self.isReceived = isReceived
        self.isFavorite = isFavorite
        self.note = note
        self.tags = tags
        self.folderId = folderId
        self.eventName = eventName
        self.intent = intent
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    var uiColor: Color {
        theme.color
    }
    
    var org: String? {
        if let event = eventName, !event.isEmpty { return event }
        if !company.isEmpty { return company }
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
        if let linkedin, !linkedin.isEmpty {
            actions.append(CardAction(type: .linkedIn, label: "LinkedIn", value: linkedin, systemIcon: "link"))
        }
        if let instagram, !instagram.isEmpty {
            actions.append(CardAction(type: .instagram, label: "Instagram", value: instagram, systemIcon: "camera.fill"))
        }
        if let github, !github.isEmpty {
            actions.append(CardAction(type: .github, label: "GitHub", value: github, systemIcon: "chevron.left.slash.chevron.right"))
        }
        if let portfolio, !portfolio.isEmpty {
            actions.append(CardAction(type: .website, label: "Portfolio", value: portfolio, systemIcon: "sparkles"))
        }
        if let whatsapp, !whatsapp.isEmpty {
            actions.append(CardAction(type: .whatsapp, label: "WhatsApp", value: whatsapp, systemIcon: "phone.bubble.left.fill"))
        }
        if let snapchat, !snapchat.isEmpty {
            actions.append(CardAction(type: .snapchat, label: "Snapchat", value: snapchat, systemIcon: "bell.fill"))
        }
        if let spotify, !spotify.isEmpty {
            actions.append(CardAction(type: .spotify, label: "Spotify", value: spotify, systemIcon: "music.note"))
        }

        return actions
    }

    /// Decide what goes on the front card.
    func primaryAction() -> CardAction? {
        let actions = availableActions()
        switch type {
        case .personal:
            // Instagram > WhatsApp > Phone
            return actions.first(where: { $0.type == .instagram })
                ?? actions.first(where: { $0.type == .whatsapp })
                ?? actions.first(where: { $0.type == .phone })
                ?? actions.first

        case .business:
            // LinkedIn > Email > Website
            return actions.first(where: { $0.type == .linkedIn })
                ?? actions.first(where: { $0.type == .email })
                ?? actions.first(where: { $0.type == .website })
                ?? actions.first

        case .social:
            // Instagram > Snapchat > Spotify
            return actions.first(where: { $0.type == .instagram })
                ?? actions.first(where: { $0.type == .snapchat })
                ?? actions.first(where: { $0.type == .spotify })
                ?? actions.first

        case .event:
            // LinkedIn > GitHub > Email
            return actions.first(where: { $0.type == .linkedIn })
                ?? actions.first(where: { $0.type == .github })
                ?? actions.first(where: { $0.type == .email })
                ?? actions.first

        case .blank:
            // Custom = first available
            return actions.first
        }
    }

    func secondaryAction() -> CardAction? {
        guard let primary = primaryAction() else { return nil }
        let actions = availableActions()
        return actions.first(where: { $0.type != primary.type })
    }
}

