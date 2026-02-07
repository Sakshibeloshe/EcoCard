import Foundation

struct FieldCatalog {

    static func fields(for type: CardType) -> [FieldDefinition] {

        switch type {

        case .personal:
            return [
                .init(key: "fullName", label: "Full Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "bio", label: "Bio", placeholder: "A short line about you", kind: .text, required: false, keyboard: .normal),
                .init(key: "phone", label: "Phone", placeholder: "+91 ...", kind: .phone, required: false, keyboard: .phone),
                .init(key: "email", label: "Email", placeholder: "name@email.com", kind: .email, required: false, keyboard: .email),
                .init(key: "instagram", label: "Instagram", placeholder: "@username", kind: .handle, required: false, keyboard: .normal)
            ]

        case .business:
            return [
                .init(key: "fullName", label: "Full Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "title", label: "Role / Title", placeholder: "iOS Developer", kind: .text, required: true, keyboard: .normal),
                .init(key: "company", label: "Company / Org", placeholder: "EcoCard Inc.", kind: .text, required: true, keyboard: .normal),

                .init(key: "email", label: "Work Email", placeholder: "you@company.com", kind: .email, required: false, keyboard: .email),
                .init(key: "linkedin", label: "LinkedIn", placeholder: "linkedin.com/in/...", kind: .url, required: false, keyboard: .url),
                .init(key: "github", label: "GitHub", placeholder: "github.com/...", kind: .url, required: false, keyboard: .url),
                .init(key: "website", label: "Website / Portfolio", placeholder: "yourdomain.com", kind: .url, required: false, keyboard: .url),

                .init(key: "intent", label: "Intent", placeholder: "Looking for...", kind: .picker, required: false, keyboard: .normal)
            ]

        case .social:
            return [
                .init(key: "displayName", label: "Display Name", placeholder: "Riya / @riya", kind: .text, required: true, keyboard: .normal),
                .init(key: "bio", label: "Bio", placeholder: "What are you about?", kind: .text, required: false, keyboard: .normal),

                .init(key: "instagram", label: "Instagram", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "tiktok", label: "TikTok", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "snapchat", label: "Snapchat", placeholder: "@username", kind: .handle, required: false, keyboard: .normal),
                .init(key: "spotify", label: "Spotify", placeholder: "Profile link", kind: .url, required: false, keyboard: .url)
            ]

        case .event:
            return [
                .init(key: "fullName", label: "Full Name", placeholder: "Your name", kind: .text, required: true, keyboard: .normal),
                .init(key: "eventName", label: "Event Name", placeholder: "Hackathon 2026", kind: .text, required: true, keyboard: .normal),
                .init(key: "roleAtEvent", label: "Role", placeholder: "Attendee / Speaker", kind: .text, required: false, keyboard: .normal),
                .init(key: "intent", label: "Intent", placeholder: "Looking for teammates", kind: .picker, required: false, keyboard: .normal),
                .init(key: "linkedin", label: "LinkedIn", placeholder: "linkedin.com/in/...", kind: .url, required: false, keyboard: .url),
                .init(key: "email", label: "Email", placeholder: "name@email.com", kind: .email, required: false, keyboard: .email)
            ]

        case .blank:
            return [
                .init(key: "title", label: "Card Title", placeholder: "My custom card", kind: .text, required: true, keyboard: .normal),
                .init(key: "bio", label: "Description", placeholder: "What is this card for?", kind: .text, required: false, keyboard: .normal),
                .init(key: "link1", label: "Link", placeholder: "any link", kind: .url, required: false, keyboard: .url)
            ]
        }
    }

    static let intents = [
        "Open to internships",
        "Looking for collaborators",
        "Hiring",
        "Open to freelance",
        "Networking",
        "Seeking mentorship"
    ]
}
