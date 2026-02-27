import Foundation

enum DummyData {

    static let folders: [FolderModel] = [
        .init(id: UUID(uuidString: "A1B2C3D4-0001-0001-0001-000000000001")!, name: "Hackathon"),
        .init(id: UUID(uuidString: "A1B2C3D4-0002-0002-0002-000000000002")!, name: "College"),
        .init(id: UUID(uuidString: "A1B2C3D4-0003-0003-0003-000000000003")!, name: "Design"),
    ]

    static func cards(folders: [FolderModel]) -> [CardModel] {
        let hackathonId = folders.first(where: { $0.name == "Hackathon" })?.id
        let collegeId   = folders.first(where: { $0.name == "College" })?.id
        let designId    = folders.first(where: { $0.name == "Design" })?.id

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

            // Hackathon folder
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
                tags: ["Hackathon"],
                folderId: hackathonId,
                eventName: "Architecture Week"
            ),

            CardModel(
                type: .event,
                theme: .pink,
                fullName: "Arjun Mehta",
                title: "iOS Developer",
                company: "AppForge",
                email: "arjun@appforge.io",
                linkedin: "linkedin.com/in/arjunmehta",
                github: "github.com/arjunmehta",
                isReceived: true,
                tags: ["Hackathon"],
                folderId: hackathonId,
                eventName: "Buildathon 2025",
                intent: "Looking for co-founder"
            ),

            // Design folder
            CardModel(
                type: .social,
                theme: .pink,
                fullName: "Elena Rossi",
                bio: "Sustainable design • coffee • cities",
                pronouns: "SHE/HER",
                instagram: "instagram.com/elenarossi",
                portfolio: "elenarossi.design",
                isReceived: true,
                tags: ["Design"],
                folderId: designId
            ),

            CardModel(
                type: .business,
                theme: .lime,
                fullName: "Marco Silva",
                title: "UX Lead",
                company: "Pixel & Co.",
                email: "marco@pixelco.io",
                website: "pixelco.io",
                linkedin: "linkedin.com/in/marcosilva",
                isReceived: true,
                tags: ["Design"],
                folderId: designId,
                intent: "Open to freelance"
            ),

            // College folder
            CardModel(
                type: .personal,
                theme: .lime,
                fullName: "Priya Nair",
                bio: "CS @ BITS Pilani | Coder + dreamer",
                pronouns: "SHE/HER",
                instagram: "instagram.com/priya.codes",
                github: "github.com/priyanair",
                isReceived: true,
                tags: ["College"],
                folderId: collegeId
            ),
        ]
    }
}
