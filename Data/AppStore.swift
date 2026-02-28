import SwiftUI
import CoreData
import Combine

@MainActor
final class AppStore: ObservableObject {

    @Published var folders: [FolderModel] = []
    @Published var myCards: [CardModel] = []
    @Published var inboxCards: [CardModel] = []
    @Published var activeTab: Tab = .myCards  // Feature 4: programmatic tab switching
    
    private var cancellables = Set<AnyCancellable>()
    private let profile = ProfileStore.shared

    init() {
        folders = DummyData.folders
        fetchMyCards()
        setupProfileObserver()
        refreshProfileSync()
    }

    private func setupProfileObserver() {
        // Observe ProfileStore changes to trigger sync
        profile.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    // Small delay to let @AppStorage values update
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    self?.refreshProfileSync()
                }
            }
            .store(in: &cancellables)
    }

    func refreshProfileSync() {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<CDCard>(entityName: "CDCard")
        request.predicate = NSPredicate(format: "isReceived == NO")
        
        do {
            let results = try context.fetch(request)
            var madeChanges = false
            
            for card in results {
                if card.usesProfileName {
                    if card.displayName != profile.fullName {
                        card.displayName = profile.fullName
                        madeChanges = true
                    }
                }
                if card.usesProfileTitle {
                    if card.subtitle != profile.title {
                        card.subtitle = profile.title
                        madeChanges = true
                    }
                }
                if card.usesProfileCompany {
                    if card.org != profile.company {
                        card.org = profile.company
                        madeChanges = true
                    }
                }
                if card.usesProfilePhoto {
                    let profilePhotoData = Data(base64Encoded: profile.photo.replacingOccurrences(of: "data:image/jpeg;base64,", with: ""))
                    if card.photoData != profilePhotoData {
                        card.photoData = profilePhotoData
                        madeChanges = true
                    }
                }
            }
            
            if madeChanges {
                try context.save()
                fetchMyCards()
            }
        } catch {
            print("[AppStore] Profile Sync Error: \(error)")
        }
    }

    func addMyCard(_ card: CardModel) {
        saveCard(card, isReceived: false)
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
        
        // Cycle through colors for variety
        let colors: [Color] = [.skyBlue, .softRose, .freshLime, .lavenderPurple, .softTerracotta]
        let color = colors[folders.count % colors.count]
        
        let newFolder = FolderModel(id: UUID(), name: trimmed, color: color)
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
        saveCard(card, isReceived: true)
    }

    private func saveCard(_ card: CardModel, isReceived: Bool) {
        let context = PersistenceController.shared.container.viewContext

        let cdCard = CDCard(context: context)
        cdCard.id = card.id
        cdCard.type = card.type
        cdCard.themeHex = card.theme.rawValue
        cdCard.createdAt = card.createdAt
        cdCard.updatedAt = Date()
        cdCard.displayName = card.fullName
        cdCard.subtitle = card.title.isEmpty ? nil : card.title
        cdCard.org = card.company.isEmpty ? nil : card.company
        cdCard.bio = card.bio.isEmpty ? nil : card.bio
        cdCard.isReceived = isReceived
        cdCard.isFavorite = card.isFavorite
        cdCard.note = card.note
        cdCard.tagsRaw = card.tags.joined(separator: ",")
        
        // Handle Photo
        if let photoString = card.photo {
            let base64 = photoString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            cdCard.photoData = Data(base64Encoded: base64)
        } else {
            cdCard.photoData = nil
        }

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
            saved.isReceived = isReceived
            
            if isReceived {
                inboxCards.insert(saved, at: 0)
                // Feature 4: Auto-switch to inbox
                withAnimation(.easeInOut(duration: 0.22)) {
                    activeTab = .inbox
                }
            } else {
                myCards.insert(saved, at: 0)
            }
            
            print("[AppStore] 💾 Card saved: \(card.fullName) (isReceived: \(isReceived))")
        } catch {
            print("[AppStore] ❌ Failed to save card: \(error)")
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

            let dummyData = DummyData.cards(folders: folders)
            
            self.myCards = dbMyCards.isEmpty ? dummyData.filter { !$0.isReceived } : dbMyCards
            self.inboxCards = dbInboxCards.isEmpty ? dummyData.filter { $0.isReceived } : dbInboxCards
            
        } catch {
            print("Failed to fetch cards: \(error)")
        }
    }
}
