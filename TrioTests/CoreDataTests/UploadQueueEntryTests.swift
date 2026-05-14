import CoreData
import Foundation
import Swinject
import Testing

@testable import Trio

@Suite("UploadQueueEntry Tests", .serialized) struct UploadQueueEntryTests {
    let coreDataStack: CoreDataStack
    let testContext: NSManagedObjectContext

    init() async throws {
        coreDataStack = try await CoreDataStack.createForTests()
        testContext = coreDataStack.newTaskContext()
    }

    // MARK: - Entity Creation

    @Test("Create and fetch queue entry") func testCreateAndFetch() async throws {
        let entityId = UUID()

        try await testContext.perform {
            let entry = UploadQueueEntry(context: testContext)
            entry.id = UUID()
            entry.target = "nightscout"
            entry.pipeline = UploadPipeline.glucose.rawValue
            entry.uploadKind = .create
            entry.entityId = entityId
            entry.createdAt = Date()
            try testContext.save()
        }

        let results = try await coreDataStack.fetchEntitiesAsync(
            ofType: UploadQueueEntry.self,
            onContext: testContext,
            predicate: NSPredicate(format: "target == %@", "nightscout"),
            key: "createdAt",
            ascending: true
        ) as? [UploadQueueEntry]

        #expect(results?.count == 1)
        #expect(results?.first?.entityId == entityId)
        #expect(results?.first?.uploadKind == .create)
    }

    // MARK: - Pending Predicate

    @Test("Pending predicate excludes future nextRetryAt") func testPendingPredicateExcludesFuture() async throws {
        try await testContext.perform {
            // Entry ready now (nil nextRetryAt)
            let ready = UploadQueueEntry(context: testContext)
            ready.id = UUID()
            ready.target = "nightscout"
            ready.pipeline = UploadPipeline.glucose.rawValue
            ready.uploadKind = .create
            ready.entityId = UUID()
            ready.createdAt = Date()

            // Entry with future retry
            let futureRetry = UploadQueueEntry(context: testContext)
            futureRetry.id = UUID()
            futureRetry.target = "nightscout"
            futureRetry.pipeline = UploadPipeline.glucose.rawValue
            futureRetry.uploadKind = .create
            futureRetry.entityId = UUID()
            futureRetry.createdAt = Date()
            futureRetry.nextRetryAt = Date().addingTimeInterval(3600)

            // Entry with past retry (should be included)
            let pastRetry = UploadQueueEntry(context: testContext)
            pastRetry.id = UUID()
            pastRetry.target = "nightscout"
            pastRetry.pipeline = UploadPipeline.glucose.rawValue
            pastRetry.uploadKind = .create
            pastRetry.entityId = UUID()
            pastRetry.createdAt = Date()
            pastRetry.nextRetryAt = Date().addingTimeInterval(-60)

            try testContext.save()
        }

        let predicate = NSPredicate.pendingQueueEntries(target: "nightscout")
        let results = try await coreDataStack.fetchEntitiesAsync(
            ofType: UploadQueueEntry.self,
            onContext: testContext,
            predicate: predicate,
            key: "createdAt",
            ascending: true
        ) as? [UploadQueueEntry]

        // Should include the ready entry and the past-retry entry, but not the future-retry entry
        #expect(results?.count == 2)
    }

    // MARK: - Entity ID Predicate

    @Test("Entity ID predicate matches target and entityId") func testEntityIdPredicate() async throws {
        let sharedEntityId = UUID()

        try await testContext.perform {
            // Same entityId, correct target
            let match = UploadQueueEntry(context: testContext)
            match.id = UUID()
            match.target = "nightscout"
            match.pipeline = UploadPipeline.glucose.rawValue
            match.uploadKind = .create
            match.entityId = sharedEntityId
            match.createdAt = Date()

            // Same entityId, different target
            let wrongTarget = UploadQueueEntry(context: testContext)
            wrongTarget.id = UUID()
            wrongTarget.target = "nocturne"
            wrongTarget.pipeline = UploadPipeline.glucose.rawValue
            wrongTarget.uploadKind = .create
            wrongTarget.entityId = sharedEntityId
            wrongTarget.createdAt = Date()

            // Different entityId, correct target
            let wrongEntity = UploadQueueEntry(context: testContext)
            wrongEntity.id = UUID()
            wrongEntity.target = "nightscout"
            wrongEntity.pipeline = UploadPipeline.glucose.rawValue
            wrongEntity.uploadKind = .create
            wrongEntity.entityId = UUID()
            wrongEntity.createdAt = Date()

            try testContext.save()
        }

        let predicate = NSPredicate.pendingQueueEntries(target: "nightscout", entityId: sharedEntityId)
        let results = try await coreDataStack.fetchEntitiesAsync(
            ofType: UploadQueueEntry.self,
            onContext: testContext,
            predicate: predicate,
            key: "createdAt",
            ascending: true
        ) as? [UploadQueueEntry]

        #expect(results?.count == 1)
        #expect(results?.first?.target == "nightscout")
        #expect(results?.first?.entityId == sharedEntityId)
    }

    // MARK: - Kind Accessor

    @Test("uploadKind accessor round-trips correctly") func testUploadKindAccessor() async throws {
        try await testContext.perform {
            let entry = UploadQueueEntry(context: testContext)
            entry.id = UUID()
            entry.target = "test"
            entry.pipeline = UploadPipeline.glucose.rawValue
            entry.createdAt = Date()

            entry.uploadKind = .create
            #expect(entry.kind == "create")
            #expect(entry.uploadKind == .create)

            entry.uploadKind = .update
            #expect(entry.kind == "update")
            #expect(entry.uploadKind == .update)

            entry.uploadKind = .delete
            #expect(entry.kind == "delete")
            #expect(entry.uploadKind == .delete)
        }
    }
}
