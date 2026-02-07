import Foundation
import UIKit

struct FieldDefinition: Identifiable, Hashable {
    let id = UUID()

    let key: String              // "linkedin"
    let label: String            // "LinkedIn"
    let placeholder: String      // "linkedin.com/in/..."
    let kind: FieldKind
    let required: Bool
    let keyboard: KeyboardType
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FieldDefinition, rhs: FieldDefinition) -> Bool {
        lhs.id == rhs.id
    }

    enum KeyboardType {
        case normal
        case email
        case phone
        case url
    }
}
