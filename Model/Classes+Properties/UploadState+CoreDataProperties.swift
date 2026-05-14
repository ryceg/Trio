import CoreData
import Foundation

public extension UploadState {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UploadState> {
        NSFetchRequest<UploadState>(entityName: "UploadState")
    }

    @NSManaged var target: String?
    @NSManaged var entityType: String?
    @NSManaged var entityId: UUID?
    @NSManaged var uploadedAt: Date?
}
