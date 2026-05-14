import CoreData
import Foundation

public extension UploadQueueEntry {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UploadQueueEntry> {
        NSFetchRequest<UploadQueueEntry>(entityName: "UploadQueueEntry")
    }

    @NSManaged var id: UUID?
    @NSManaged var target: String?
    @NSManaged var pipeline: String?
    @NSManaged var kind: String?
    @NSManaged var payload: Data?
    @NSManaged var entityId: UUID?
    @NSManaged var createdAt: Date?
    @NSManaged var retryCount: Int16
    @NSManaged var nextRetryAt: Date?
}
