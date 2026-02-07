//
//  DummyData.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import Foundation

enum DummyData {

    static let folders: [FolderModel] = [
        .init(id: UUID(), name: "Hackathon"),
        .init(id: UUID(), name: "College"),
        .init(id: UUID(), name: "Startup"),
        .init(id: UUID(), name: "Design")
    ]

    static func cards(folders: [FolderModel]) -> [CardModel] {
        let hackathon = folders.first(where: {$0.name == "Hackathon"})?.id

        return [
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
                linkedIn: "linkedin.com/in/emilyparker"
            ),

            CardModel(
                type: .personal,
                theme: .lime,
                fullName: "Emily Parker",
                bio: "I love design + travel",
                pronouns: "SHE/HER",
                instagram: "instagram.com/emilyparker"
            ),

            CardModel(
                type: .business,
                theme: .lime,
                fullName: "Sarah Jenkins",
                title: "Lead Architect",
                company: "Buildflow",
                email: "sarah@buildflow.co",
                website: "buildflow.co",
                isReceived: true,
                isFavorite: true,
                note: "Met at architecture week",
                tags: ["Startup", "Design"],
                folderId: hackathon,
                eventName: "Architecture Week"
            ),

            CardModel(
                type: .social,
                theme: .pink,
                fullName: "Elena Rossi",
                bio: "Sustainable design • coffee • cities",
                pronouns: "SHE/HER",
                instagram: "instagram.com/elenarossi",
                isReceived: true,
                tags: ["College"]
            )
        ]
    }
}

