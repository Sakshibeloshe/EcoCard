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
        let request = NSFetchRequest<CDCard>(entityName: "CDCard")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try context.fetch(request)
            let models: [CardModel] = results.compactMap { cd in
                // Resolve type
                let type: CardType = CardType(rawValue: cd.typeRaw ?? "") ?? .personal

                // Resolve theme from themeHex (stored as rawValue)
                let theme: CardTheme = CardTheme(rawValue: cd.themeHex ?? "") ?? .pink

                return CardModel(
                    id: cd.id ?? UUID(),
                    type: type,
                    theme: theme,
                    fullName: cd.displayName ?? "",
                    title: cd.subtitle ?? "",
                    company: cd.org ?? "",
                    bio: cd.bio ?? "",
                    email: cd.email,
                    website: cd.website,
                    phone: cd.phone,
                    pronouns: cd.pronouns ?? "",
                    instagram: cd.instagram,
                    linkedIn: cd.linkedin,
                    github: cd.github,
                    portfolio: cd.portfolio,
                    isReceived: false,
                    isFavorite: cd.isFavorite,
                    note: cd.note ?? "",
                    folderId: cd.folderId,
                    eventName: cd.eventName,
                    intent: cd.intent
                )
            }

            let dummy = DummyData.cards(folders: folders).filter { !$0.isReceived }
            self.myCards = models + dummy
        } catch {
            print("Failed to fetch cards: \(error)")
        }
    }

    /// Saves a received card (from peer transfer) into the inbox.
    func importCard(_ payload: CardTransferPayload) {
        let card = CardModel(
            id: UUID(uuidString: payload.id) ?? UUID(),
            type: CardType(rawValue: payload.type) ?? .personal,
            theme: CardTheme(rawValue: payload.theme) ?? .sky,
            fullName: payload.displayName,
            title: payload.title,
            company: payload.company,
            bio: payload.bio,
            email: payload.email,
            website: payload.website,
            phone: payload.phone,
            pronouns: payload.pronouns,
            instagram: payload.instagram,
            linkedIn: payload.linkedIn,
            github: payload.github,
            portfolio: payload.portfolio,
            isReceived: true
        )
        inboxCards.insert(card, at: 0)
    }
}

