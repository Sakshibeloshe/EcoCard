import SwiftUI
import CoreData

@MainActor
final class AppStore: ObservableObject {

    @Published var folders: [FolderModel] = []
    @Published var myCards: [CardModel] = []
    @Published var inboxCards: [CardModel] = []
    @Published var activeTab: Tab = .myCards  // Feature 4: programmatic tab switching

    init() {
        folders = DummyData.folders
    }

    func addMyCard(_ card: CardModel) {
        myCards.insert(card, at: 0)
    }

    func toggleFavorite(_ card: CardModel) {
        if let i = inboxCards.firstIndex(where: {$0.id == card.id}) {
            inboxCards[i].isFavorite.toggle()
        }
    }

    func toggleFavoriteMyCard(_ card: CardModel) {
        if let i = myCards.firstIndex(where: { $0.id == card.id }) {
            myCards[i].isFavorite.toggle()
        }
    }

    func deleteCard(_ card: CardModel) {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<CDCard>(entityName: "CDCard")
        request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)

        do {
            if let result = try context.fetch(request).first {
                context.delete(result)
                try context.save()
            }
        } catch {
            print("Failed to delete card: \(error)")
        }

        myCards.removeAll { $0.id == card.id }
        inboxCards.removeAll { $0.id == card.id }
    }

    func assignFolder(cardId: UUID, folderId: UUID?) {
        if let i = inboxCards.firstIndex(where: {$0.id == cardId}) {
            inboxCards[i].folderId = folderId
        }
    }

    func removeCardFromFolder(cardId: UUID) {
        assignFolder(cardId: cardId, folderId: nil)
    }

    func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !folders.contains(where: { $0.name == trimmed }) else { return }
        let newFolder = FolderModel(id: UUID(), name: trimmed)
        folders.append(newFolder)
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
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

    // MARK: - Peer Transfer

    func saveInboxCard(_ card: CardModel) {
        let context = PersistenceController.shared.container.viewContext

        let cdCard = CDCard(context: context)
        cdCard.id = card.id
        cdCard.type = card.type
        cdCard.themeHex = card.theme.rawValue
        cdCard.createdAt = Date()
        cdCard.updatedAt = Date()
        cdCard.displayName = card.fullName
        cdCard.subtitle = card.title.isEmpty ? nil : card.title
        cdCard.org = card.company.isEmpty ? nil : card.company
        cdCard.bio = card.bio.isEmpty ? nil : card.bio
        cdCard.isReceived = true
        cdCard.isFavorite = false
        cdCard.note = ""
        cdCard.tagsRaw = ""

        let fieldPairs: [(String, String?)] = [
            ("email",          card.email),
            ("phone",          card.phone),
            ("website",        card.website),
            ("pronouns",       card.pronouns),
            ("locationCity",   card.locationCity),
            ("officeLocation", card.officeLocation),
            ("linkedin",       card.linkedin),
            ("instagram",      card.instagram),
            ("github",         card.github),
            ("portfolio",      card.portfolio),
            ("snapchat",       card.snapchat),
            ("spotify",        card.spotify),
            ("whatsapp",       card.whatsapp),
            ("eventBadge",     card.eventBadge),
            ("skillsTags",     card.skillsTags),
            ("emojiTags",      card.emojiTags),
            ("nickname",       card.nickname),
            ("intent",         card.intent),
        ]

        for (idx, (key, value)) in fieldPairs.enumerated() {
            guard let value, !value.isEmpty else { continue }
            let field = CDCardField(context: context)
            field.id = UUID()
            field.key = key
            field.label = key.capitalized
            field.value = value
            field.kindRaw = "text"
            field.orderIndex = Int16(idx)
            field.card = cdCard
        }

        do {
            try context.save()
            var saved = card
            saved.isReceived = true
            inboxCards.insert(saved, at: 0)
            // Feature 4: Auto-switch to inbox
            withAnimation(.easeInOut(duration: 0.22)) {
                activeTab = .inbox
            }
            print("[AppStore] 💾 Inbox card saved: \(card.fullName)")
        } catch {
            print("[AppStore] ❌ Failed to save inbox card: \(error)")
        }
    }

    func saveInboxCardIfNew(_ card: CardModel) {
        if inboxCards.contains(where: { $0.id == card.id }) { return }

        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<CDCard>(entityName: "CDCard")
        request.predicate = NSPredicate(format: "id == %@", card.id as CVarArg)

        do {
            let count = try context.count(for: request)
            if count > 0 { return }
        } catch {
            print("[AppStore] ❌ Check error: \(error)")
        }

        saveInboxCard(card)
    }

    func fetchMyCards() {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<CDCard>(entityName: "CDCard")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let results = try context.fetch(request)
            let allModels = results.map { $0.toModel() }

            let dbMyCards = allModels.filter { !$0.isReceived }
            let dbInboxCards = allModels.filter { $0.isReceived }

            if allModels.isEmpty {
                let dummy = DummyData.cards(folders: folders)
                self.myCards = dummy.filter { !$0.isReceived }
                self.inboxCards = dummy.filter { $0.isReceived }
            } else {
                self.myCards = dbMyCards
                self.inboxCards = dbInboxCards
            }
        } catch {
            print("Failed to fetch cards: \(error)")
        }
    }
}
