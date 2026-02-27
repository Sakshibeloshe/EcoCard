import SwiftUI
import Foundation

enum DummyData {

    static let folders: [FolderModel] = [
        .init(id: UUID(uuidString: "A1B2C3D4-0002-0002-0002-000000000002")!, name: "College", color: .softRose),
    ]

    static func cards(folders: [FolderModel]) -> [CardModel] {
        let collegeId   = folders.first(where: { $0.name == "College" })?.id

        return [
            // ── MY CARDS (isReceived: false) ──────────────────────────────
            CardModel(
                type: .business,
                theme: .pink,
                fullName: "Emily Parker",
                title: "Product Designer",
                company: "Studio Linear",
                bio: "I love design + travel",
                email: "emily@linear.studio",
                website: "linear.studio",
                pronouns: "SHE/HER",
                linkedin: "linkedin.com/in/emilyparker"
            ),

            CardModel(
                type: .personal,
                theme: .lime,
                fullName: "Emily Parker",
                bio: "I love design + travel",
                pronouns: "SHE/HER",
                instagram: "instagram.com/emilyparker"
            ),

            // ── INBOX CARDS (isReceived: true) ────────────────────────────

            // College folder (Exactly 2 cards)
            CardModel(
                type: .personal,
                theme: .lime,
                fullName: "Priya Nair",
                bio: "CS @ BITS Pilani | Coder + dreamer. Building the future of AI.",
                pronouns: "SHE/HER",
                instagram: "instagram.com/priya.codes",
                github: "github.com/priyanair",
                isReceived: true,
                isFavorite: true,
                tags: ["College"],
                folderId: collegeId
            ),

            CardModel(
                type: .business,
                theme: .pink,
                fullName: "Alex Thompson",
                title: "Software Engineer",
                company: "TechNova",
                bio: "Full stack dev with a passion for Swift and open source.",
                email: "alex@technova.io",
                linkedin: "linkedin.com/in/alexthompson",
                isReceived: true,
                tags: ["College"],
                folderId: collegeId
            ),

            // Main Inbox (3 unique cards)
            CardModel(
                type: .business,
                theme: .lime,
                fullName: "Sarah Jenkins",
                title: "Lead Architect",
                company: "Buildflow",
                email: "sarah@buildflow.co",
                website: "buildflow.co",
                linkedin: "linkedin.com/in/sarahjenkins",
                isReceived: true,
                isFavorite: true,
                note: "Met at architecture week",
                tags: ["Work"],
                eventName: "Architecture Week"
            ),
            
            CardModel(
                type: .event,
                theme: .pink,
                fullName: "Arjun Mehta",
                title: "iOS Developer",
                company: "AppForge",
                bio: "Building cool stuff for the world. Love hackathons.",
                email: "arjun@appforge.io",
                linkedin: "linkedin.com/in/arjunmehta",
                github: "github.com/arjunmehta",
                isReceived: true,
                tags: ["Hackathon"],
                eventName: "Buildathon 2025",
                intent: "Looking for co-founder"
            ),

            CardModel(
                type: .social,
                theme: .pink,
                fullName: "Sophie Laurent",
                bio: "Travel Blogger | Foodie. Exploring the streets of Paris.",
                instagram: "instagram.com/sophie.travels",
                isReceived: true,
                isFavorite: true,
                note: "Really cool travel tips!"
            )
        ]
    }
}
