//
//  AppStore.swift
//  BeforeUSayIt
//
//  Created by SDC-USER on 06/02/26.
//
import SwiftUI
import CoreData

@MainActor
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
            let allModels = results.map { $0.toModel() }
            
            // Separate into types
            let dbMyCards = allModels.filter { !$0.isReceived }
            let dbInboxCards = allModels.filter { $0.isReceived }
            
            // Filter out dummy data that might be duplicates if needed, 
            // but for now let's just combine with existing dummy data logic if intended
            let dummy = DummyData.cards(folders: folders)
            let dummyMyCards = dummy.filter { !$0.isReceived }
            let dummyInboxCards = dummy.filter { $0.isReceived }
            
            self.myCards = dbMyCards + dummyMyCards
            self.inboxCards = dbInboxCards + dummyInboxCards
        } catch {
            print("Failed to fetch cards: \(error)")
        }
    }
}
