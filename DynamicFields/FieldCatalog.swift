import Foundation

struct FieldCatalog {

    static func fields(for type: CardType) -> [FieldDefinition] {
        switch type {
        case .personal:
            return [
                .init(key: "fullName", label: "Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "pronouns", label: "Pronouns", placeholder: "She/Her", kind: .text, required: false, keyboard: .normal),
                .init(key: "phone", label: "Phone", placeholder: "+1 ...", kind: .phone, required: true, keyboard: .phone),
                .init(key: "email", label: "Email", placeholder: "name@email.com", kind: .email, required: false, keyboard: .email),
                .init(key: "instagram", label: "Instagram", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "whatsapp", label: "WhatsApp", placeholder: "Phone number", kind: .phone, required: false, keyboard: .phone),
                .init(key: "snapchat", label: "Snapchat", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "bio", label: "Short Bio", placeholder: "I love design + travel", kind: .text, required: false, keyboard: .normal),
                .init(key: "locationCity", label: "Location (City)", placeholder: "San Francisco", kind: .text, required: false, keyboard: .normal),
                .init(key: "intent", label: "Intent", placeholder: "Open to meet people", kind: .picker, required: false, keyboard: .normal)
            ]

        case .business:
            return [
                .init(key: "fullName", label: "Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "company", label: "Company", placeholder: "EcoCard Inc.", kind: .text, required: true, keyboard: .normal),
                .init(key: "title", label: "Job Title", placeholder: "Product Designer", kind: .text, required: true, keyboard: .normal),
                .init(key: "email", label: "Email", placeholder: "you@company.com", kind: .email, required: true, keyboard: .email),
                .init(key: "phone", label: "Phone", placeholder: "+1 ...", kind: .phone, required: true, keyboard: .phone),
                .init(key: "website", label: "Website", placeholder: "yourdomain.com", kind: .url, required: false, keyboard: .url),
                .init(key: "linkedin", label: "LinkedIn", placeholder: "linkedin.com/in/...", kind: .url, required: false, keyboard: .url),
                .init(key: "officeLocation", label: "Office Location", placeholder: "123 Business St, NY", kind: .text, required: false, keyboard: .normal),
                .init(key: "intent", label: "Intent", placeholder: "Looking for...", kind: .picker, required: false, keyboard: .normal)
            ]

        case .social:
            return [
                .init(key: "nickname", label: "Display Name / Nickname", placeholder: "Riya / @riya", kind: .text, required: true, keyboard: .normal),
                .init(key: "instagram", label: "Instagram", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "snapchat", label: "Snapchat", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "spotify", label: "Spotify", placeholder: "Profile link", kind: .url, required: false, keyboard: .url),
                .init(key: "whatsapp", label: "WhatsApp", placeholder: "Phone number", kind: .phone, required: false, keyboard: .phone),
                .init(key: "bio", label: "Vibe Bio", placeholder: "What are you about?", kind: .text, required: false, keyboard: .normal),
                .init(key: "emojiTags", label: "Emoji Tags", placeholder: "🎨 ✈️ 🍕", kind: .text, required: false, keyboard: .normal),
                .init(key: "intent", label: "Intent", placeholder: "What's the vibe?", kind: .text, required: false, keyboard: .normal)
            ]

        case .event:
            return [
                .init(key: "fullName", label: "Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "eventBadge", label: "Event Badge", placeholder: "WWDC Student / Attendee", kind: .text, required: true, keyboard: .normal),
                .init(key: "skillsTags", label: "Skills Tags", placeholder: "Swift, ML, UIKit", kind: .text, required: false, keyboard: .normal),
                .init(key: "linkedin", label: "LinkedIn", placeholder: "linkedin.com/in/...", kind: .url, required: false, keyboard: .url),
                .init(key: "github", label: "GitHub", placeholder: "github.com/...", kind: .url, required: false, keyboard: .url),
                .init(key: "bio", label: "About Me", placeholder: "Working on ML apps...", kind: .text, required: false, keyboard: .normal),
                .init(key: "intent", label: "Intent", placeholder: "Looking for teammates", kind: .picker, required: false, keyboard: .normal)
            ]

        case .blank:
            return [
                .init(key: "fullName", label: "Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "title", label: "Section Title", placeholder: "My Project", kind: .text, required: false, keyboard: .normal),
                .init(key: "bio", label: "Text Block", placeholder: "Description here...", kind: .text, required: false, keyboard: .normal),
                .init(key: "website", label: "Icon + Text Link", placeholder: "yourlink.com", kind: .url, required: false, keyboard: .url),
                .init(key: "instagram", label: "Social Handle", placeholder: "@username", kind: .handle, required: false, keyboard: .normal)
            ]
        }
    }

    static func intents(for type: CardType) -> [String] {
        switch type {
        case .personal:
            return ["Open to meet new people", "Collaborate", "Connect"]
        case .business:
            return ["Open to internships", "Open to freelance work", "Hiring", "Looking for collaboration"]
        case .event:
            return ["Looking for team members", "Open to ideas", "Seeking partners"]
        default:
            return []
        }
    }
}

