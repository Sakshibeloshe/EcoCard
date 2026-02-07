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
        theme: CardTheme = .pink
    ) throws {

        let card = CDCard(context: context)
        card.id = UUID()
        card.type = type
        card.createdAt = Date()
        card.updatedAt = Date()
        card.themeHex = theme.rawValue // Store theme

        // Photo
        if let photo {
            card.photoData = photo.jpegData(compressionQuality: 0.85)
        }

        // Core fields mapping
        // Logic: prioritize explicit keys if present, otherwise fallback
        card.displayName = values["fullName"] ?? values["displayName"] ?? values["title"] ?? "Untitled"

        card.subtitle = values["title"] ?? values["roleAtEvent"] ?? values["description"]
        card.org = values["company"] ?? values["eventName"]
        card.bio = values["bio"]

        // Save all other fields dynamically
        let definitions = FieldCatalog.fields(for: type)

        for (index, def) in definitions.enumerated() {
            let v = values[def.key, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
            if v.isEmpty { continue }

            // Skip core fields already stored above to avoid duplication in 'fields' relationship if we only want dynamic ones there.
            // However, the prompt implies "Save all other fields dynamically".
            // Let's exclude the ones we mapped to CDCard properties directly to keep it clean, OR store everything in CDCardField as well?
            // The prompt said:
            // // Skip core fields already stored above
            // if ["fullName","displayName","title","company","eventName","bio"].contains(def.key) { continue }
            
            if ["fullName", "displayName", "title", "company", "eventName", "bio", "roleAtEvent"].contains(def.key) {
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
