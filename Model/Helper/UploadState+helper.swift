import CoreData
import Foundation

extension NSPredicate {
    static func isUploaded(target: String, entityType: String, entityId: UUID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "target == %@", target),
            NSPredicate(format: "entityType == %@", entityType),
            NSPredicate(format: "entityId == %@", entityId as CVarArg)
        ])
    }

    static func uploadedEntities(target: String, entityType: String) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "target == %@", target),
            NSPredicate(format: "entityType == %@", entityType)
        ])
    }
}
