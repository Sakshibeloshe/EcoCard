import Foundation
import CoreData
import UIKit

// MARK: - Core Data Entities

@objc(CDCard)
public class CDCard: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var typeRaw: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var themeHex: String?
    @NSManaged public var photoData: Data?
    
    // Core fields
    @NSManaged public var displayName: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var org: String?
    @NSManaged public var bio: String?
    
    // Inbox & State fields
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isReceived: Bool
    @NSManaged public var folderId: UUID?
    @NSManaged public var note: String?
    @NSManaged public var tagsRaw: String? // Comma-separated tags
    
    @NSManaged public var fields: NSSet?
}

@objc(CDCardField)
public class CDCardField: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var key: String?
    @NSManaged public var label: String?
    @NSManaged public var value: String?
    @NSManaged public var kindRaw: String?
    @NSManaged public var orderIndex: Int16
    
    @NSManaged public var card: CDCard?
}

// MARK: - Generated Accessors for fields
extension CDCard {
    @objc(addFieldsObject:)
    @NSManaged public func addToFields(_ value: CDCardField)

    @objc(removeFieldsObject:)
    @NSManaged public func removeFromFields(_ value: CDCardField)

    @objc(addFields:)
    @NSManaged public func addToFields(_ values: NSSet)

    @objc(removeFields:)
    @NSManaged public func removeFromFields(_ values: NSSet)
}

// MARK: - Helper Extensions

extension CDCard {
    var type: CardType {
        get { CardType(rawValue: typeRaw ?? "") ?? .personal }
        set { typeRaw = newValue.rawValue }
    }
    
    var tags: [String] {
        get { tagsRaw?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { tagsRaw = newValue.joined(separator: ",") }
    }
}

extension CDCardField {
    var kind: FieldKind {
        get { FieldKind(rawValue: kindRaw ?? "") ?? .text }
        set { kindRaw = newValue.rawValue }
    }
}

extension CDCard {
    func toModel() -> CardModel {
        // Convert NSSet fields to Dictionary for easy lookup
        var fieldMap: [String: String] = [:]
        if let fields = self.fields as? Set<CDCardField> {
            for f in fields {
                if let key = f.key, let value = f.value {
                    fieldMap[key] = value
                }
            }
        }
        
        // Resolve Theme
        var theme: CardTheme = .pink
        if let hex = self.themeHex, let mappedTheme = CardTheme(rawValue: hex) {
            theme = mappedTheme
        }
        
        return CardModel(
            id: self.id ?? UUID(),
            type: self.type,
            theme: theme,
            fullName: self.displayName ?? "",
            createdAt: self.createdAt ?? Date(),
            title: self.subtitle ?? "",
            company: self.org ?? "",
            bio: self.bio ?? "",
            email: fieldMap["email"],
            website: fieldMap["website"],
            phone: fieldMap["phone"],
            pronouns: fieldMap["pronouns"] ?? "",
            photo: self.photoData != nil ? "data:image/jpeg;base64," + self.photoData!.base64EncodedString() : nil,
            locationCity: fieldMap["locationCity"],
            officeLocation: fieldMap["officeLocation"],
            linkedin: fieldMap["linkedin"],
            instagram: fieldMap["instagram"],
            github: fieldMap["github"],
            portfolio: fieldMap["portfolio"],
            snapchat: fieldMap["snapchat"],
            spotify: fieldMap["spotify"],
            whatsapp: fieldMap["whatsapp"],
            eventBadge: fieldMap["eventBadge"],
            skillsTags: fieldMap["skillsTags"],
            emojiTags: fieldMap["emojiTags"],
            nickname: fieldMap["nickname"],
            isReceived: self.isReceived,
            isFavorite: self.isFavorite,
            note: self.note ?? "",
            tags: self.tags,
            folderId: self.folderId,
            eventName: self.org, // org stores eventName for event cards
            intent: fieldMap["intent"]
            
        )
    }
}

// MARK: - Programmatic Model Definition

extension NSManagedObjectModel {
    nonisolated(unsafe) static let programmaticModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        
        // CDCard Entity
        let cardEntity = NSEntityDescription()
        cardEntity.name = "CDCard"
        cardEntity.managedObjectClassName = NSStringFromClass(CDCard.self)
        
        // CDCard Attributes
        let cardId = NSAttributeDescription()
        cardId.name = "id"
        cardId.attributeType = .UUIDAttributeType
        
        let cardTypeRaw = NSAttributeDescription()
        cardTypeRaw.name = "typeRaw"
        cardTypeRaw.attributeType = .stringAttributeType
        
        let cardCreatedAt = NSAttributeDescription()
        cardCreatedAt.name = "createdAt"
        cardCreatedAt.attributeType = .dateAttributeType

        let cardUpdatedAt = NSAttributeDescription()
        cardUpdatedAt.name = "updatedAt"
        cardUpdatedAt.attributeType = .dateAttributeType
        
        let cardThemeHex = NSAttributeDescription()
        cardThemeHex.name = "themeHex"
        cardThemeHex.attributeType = .stringAttributeType
        
        let cardPhotoData = NSAttributeDescription()
        cardPhotoData.name = "photoData"
        cardPhotoData.attributeType = .binaryDataAttributeType
        
        let cardDisplayName = NSAttributeDescription()
        cardDisplayName.name = "displayName"
        cardDisplayName.attributeType = .stringAttributeType
        
        let cardSubtitle = NSAttributeDescription()
        cardSubtitle.name = "subtitle"
        cardSubtitle.attributeType = .stringAttributeType
        
        let cardOrg = NSAttributeDescription()
        cardOrg.name = "org"
        cardOrg.attributeType = .stringAttributeType
        
        let cardBio = NSAttributeDescription()
        cardBio.name = "bio"
        cardBio.attributeType = .stringAttributeType
        
        let cardIsFavorite = NSAttributeDescription()
        cardIsFavorite.name = "isFavorite"
        cardIsFavorite.attributeType = .booleanAttributeType
        cardIsFavorite.defaultValue = false
        
        let cardIsReceived = NSAttributeDescription()
        cardIsReceived.name = "isReceived"
        cardIsReceived.attributeType = .booleanAttributeType
        cardIsReceived.defaultValue = false
        
        let cardFolderId = NSAttributeDescription()
        cardFolderId.name = "folderId"
        cardFolderId.attributeType = .UUIDAttributeType
        
        let cardNote = NSAttributeDescription()
        cardNote.name = "note"
        cardNote.attributeType = .stringAttributeType
        
        let cardTagsRaw = NSAttributeDescription()
        cardTagsRaw.name = "tagsRaw"
        cardTagsRaw.attributeType = .stringAttributeType
        
        cardEntity.properties = [
            cardId, cardTypeRaw, cardCreatedAt, cardUpdatedAt,
            cardThemeHex, cardPhotoData, cardDisplayName,
            cardSubtitle, cardOrg, cardBio, 
            cardIsFavorite, cardIsReceived, cardFolderId, cardNote, cardTagsRaw
        ]
        
        // CDCardField Entity
        let fieldEntity = NSEntityDescription()
        fieldEntity.name = "CDCardField"
        fieldEntity.managedObjectClassName = NSStringFromClass(CDCardField.self)
        
        // CDCardField Attributes
        let fieldId = NSAttributeDescription()
        fieldId.name = "id"
        fieldId.attributeType = .UUIDAttributeType
        
        let fieldKey = NSAttributeDescription()
        fieldKey.name = "key"
        fieldKey.attributeType = .stringAttributeType
        
        let fieldLabel = NSAttributeDescription()
        fieldLabel.name = "label"
        fieldLabel.attributeType = .stringAttributeType
        
        let fieldValue = NSAttributeDescription()
        fieldValue.name = "value"
        fieldValue.attributeType = .stringAttributeType

        let fieldKindRaw = NSAttributeDescription()
        fieldKindRaw.name = "kindRaw"
        fieldKindRaw.attributeType = .stringAttributeType
        
        let fieldOrderIndex = NSAttributeDescription()
        fieldOrderIndex.name = "orderIndex"
        fieldOrderIndex.attributeType = .integer16AttributeType

        fieldEntity.properties = [
            fieldId, fieldKey, fieldLabel, fieldValue,
            fieldKindRaw, fieldOrderIndex
        ]
        
        // Relationships
        let fieldsRelation = NSRelationshipDescription()
        fieldsRelation.name = "fields"
        fieldsRelation.destinationEntity = fieldEntity
        fieldsRelation.minCount = 0
        fieldsRelation.maxCount = 0 // unlimited
        fieldsRelation.deleteRule = .cascadeDeleteRule
        
        let cardRelation = NSRelationshipDescription()
        cardRelation.name = "card"
        cardRelation.destinationEntity = cardEntity
        cardRelation.minCount = 0
        cardRelation.maxCount = 1
        cardRelation.deleteRule = .nullifyDeleteRule
        
        fieldsRelation.inverseRelationship = cardRelation
        cardRelation.inverseRelationship = fieldsRelation
        
        cardEntity.properties.append(fieldsRelation)
        fieldEntity.properties.append(cardRelation)
        
        model.entities = [cardEntity, fieldEntity]
        return model
    }()
}
