//
//  AppStore.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI
import CoreData

final class AppStore: ObservableObject {

    @Published var folders: [FolderModel] = []
    @Published var myCards: [CardModel] = []
    @Published var inboxCards: [CardModel] = []

    init() {
        folders = DummyData.folders
        let all = DummyData.cards(folders: folders)
        myCards = all.filter { !$0.isReceived }
        inboxCards = all.filter { $0.isReceived }
    }

    func addMyCard(_ card: CardModel) {
        myCards.insert(card, at: 0)
    }

    func toggleFavorite(_ card: CardModel) {
        if let i = inboxCards.firstIndex(where: {$0.id == card.id}) {
            inboxCards[i].isFavorite.toggle()
        }
    }

    func assignFolder(cardId: UUID, folderId: UUID?) {
        if let i = inboxCards.firstIndex(where: {$0.id == cardId}) {
            inboxCards[i].folderId = folderId
        }
    }

    func createFolder(name: String) {
        guard !folders.contains(where: { $0.name == name }) else { return }
        let newFolder = FolderModel(id: UUID(), name: name)
        folders.append(newFolder)
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        // Optional: remove folder assignment from cards
        for i in 0..<inboxCards.count {
            if inboxCards[i].folderId == id {
                inboxCards[i].folderId = nil
            }
        }
        for i in 0..<myCards.count {
            if myCards[i].folderId == id {
                myCards[i].folderId = nil
            }
        }
    }
    
    func fetchMyCards() {
        let context = PersistenceController.shared.container.viewContext
        // Build a typed fetch request explicitly using the entity name to avoid generic mismatch
        let request = NSFetchRequest<CDCard>(entityName: "CDCard")
        // Sort by createdAt descending
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            let models: [CardModel] = results.compactMap { card in
                let id = card.value(forKey: "id") as? UUID ?? UUID()
                let createdAt = card.value(forKey: "createdAt") as? Date ?? Date()
                let isFavorite = (card.value(forKey: "isFavorite") as? Bool) ?? false
                let folderId = card.value(forKey: "folderId") as? UUID

                // Decode CardType
                let type: CardType
                if let raw = card.value(forKey: "typeRaw") as? String, let value = CardType(rawValue: raw) {
                    type = value
                } else if let first = CardType.allCases.first {
                    type = first
                } else {
                    fatalError("CardType has no cases to default to")
                }

                // Decode CardTheme (fallback to .pink)
                let theme: CardTheme
                if let raw = card.value(forKey: "theme") as? String, let value = CardTheme(rawValue: raw) {
                    theme = value
                } else if let first = CardTheme.allCases.first {
                    theme = first
                } else {
                    fatalError("CardTheme has no cases to default to")
                }

                let fullName = card.value(forKey: "displayName") as? String ?? ""
                let title = card.value(forKey: "subtitle") as? String ?? ""
                let company = card.value(forKey: "org") as? String ?? ""
                let bio = card.value(forKey: "bio") as? String ?? ""

                // Optional contact/socials if present in flat storage (these may be nil in Core Data)
                let email = card.value(forKey: "email") as? String
                let website = card.value(forKey: "website") as? String
                let phone = card.value(forKey: "phone") as? String
                let pronouns = card.value(forKey: "pronouns") as? String ?? ""
                let instagram = card.value(forKey: "instagram") as? String
                let linkedIn = card.value(forKey: "linkedin") as? String
                let github = card.value(forKey: "github") as? String
                let portfolio = card.value(forKey: "portfolio") as? String
                let note = card.value(forKey: "note") as? String ?? ""
                let tags = card.value(forKey: "tags") as? [String] ?? []
                let eventName = card.value(forKey: "eventName") as? String
                let intent = card.value(forKey: "intent") as? String

                return CardModel(
                    id: id,
                    type: type,
                    theme: theme,
                    fullName: fullName,
                    title: title,
                    company: company,
                    bio: bio,
                    email: email,
                    website: website,
                    phone: phone,
                    pronouns: pronouns,
                    instagram: instagram,
                    linkedIn: linkedIn,
                    github: github,
                    portfolio: portfolio,
                    isReceived: false,
                    isFavorite: isFavorite,
                    note: note,
                    tags: tags,
                    folderId: folderId,
                    eventName: eventName,
                    intent: intent
                )
            }

            let dummy = DummyData.cards(folders: folders).filter { !$0.isReceived }
            self.myCards = models + dummy
        } catch {
            print("Failed to fetch cards: \(error)")
        }
    }
}

