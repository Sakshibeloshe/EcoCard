import SwiftUI
import CoreData

final class CardRepository {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createCard(
        type: CardType,
        values: [String: String],
        photo: UIImage?,
        theme: CardTheme = .pink,
        usesProfileName: Bool = true,
        usesProfileTitle: Bool = true,
        usesProfileCompany: Bool = true,
        usesProfilePhoto: Bool = true
    ) throws {

        let card = CDCard(context: context)
        card.id = UUID()
        card.type = type
        card.createdAt = Date()
        card.updatedAt = Date()
        card.themeHex = theme.rawValue
        card.isReceived = false
        card.isFavorite = false
        
        card.usesProfileName = usesProfileName
        card.usesProfileTitle = usesProfileTitle
        card.usesProfileCompany = usesProfileCompany
        card.usesProfilePhoto = usesProfilePhoto

        // Photo
        if let photo {
            card.photoData = photo.jpegData(compressionQuality: 0.85)
        }

        // Core fields mapping
        card.displayName = values["fullName"] ?? values["nickname"] ?? values["displayName"] ?? values["title"] ?? "Untitled"
        card.subtitle = values["title"] ?? values["eventBadge"] ?? values["roleAtEvent"] ?? values["description"]
        card.org = values["company"] ?? values["eventName"]
        card.bio = values["bio"]

        // Save all other fields dynamically
        let definitions = FieldCatalog.fields(for: type)

        for (index, def) in definitions.enumerated() {
            let v = values[def.key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
            if v.isEmpty { continue }

            if ["fullName", "nickname", "displayName", "title", "company", "eventBadge", "eventName", "bio", "roleAtEvent"].contains(def.key) {
                continue
            }

            let f = CDCardField(context: context)
            f.id = UUID()
            f.key = def.key
            f.label = def.label
            f.value = v
            f.kindRaw = def.kind.rawValue
            f.orderIndex = Int16(index)
            f.card = card
        }

        try context.save()
    }
}
