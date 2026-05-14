import CoreData
import Foundation

extension UploadQueueEntry {
    enum Kind: String {
        case create
        case update
        case delete
    }

    var uploadKind: Kind {
        get { Kind(rawValue: kind ?? "create") ?? .create }
        set { kind = newValue.rawValue }
    }
}

extension NSPredicate {
    static func pendingQueueEntries(target: String, now: Date = Date()) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "target == %@", target),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "nextRetryAt == nil"),
                NSPredicate(format: "nextRetryAt <= %@", now as NSDate)
            ])
        ])
    }

    static func pendingQueueEntries(target: String, entityId: UUID) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "target == %@", target),
            NSPredicate(format: "entityId == %@", entityId as CVarArg)
        ])
    }
}
