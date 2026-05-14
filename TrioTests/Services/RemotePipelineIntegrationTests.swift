import CoreData
import Foundation
import Swinject
import Testing

@testable import Trio

@Suite("RemotePipeline Integration Tests", .serialized) struct RemotePipelineIntegrationTests: Injectable {
    let resolver: Resolver
    var coreDataStack: CoreDataStack!
    var testContext: NSManagedObjectContext!

    init() async throws {
        coreDataStack = try await CoreDataStack.createForTests()
        testContext = coreDataStack.newTaskContext()

        let assembler = Assembler([
            StorageAssembly(),
            ServiceAssembly(),
            APSAssembly(),
            NetworkAssembly(),
            UIAssembly(),
            SecurityAssembly(),
            TestAssembly(testContext: testContext)
        ])

        resolver = assembler.resolver
        injectServices(resolver)
    }

    // MARK: - DI Resolution

    @Test("RemotePipelineManaging is resolvable from the DI container") func testResolvable() {
        let manager = resolver.resolve(RemotePipelineManaging.self)
        #expect(manager != nil)
    }

    @Test("Resolved manager has at least one target registered") func testHasTargets() {
        let manager = resolver.resolve(RemotePipelineManaging.self)
        let concrete = manager as? RemotePipelineManager
        #expect(concrete != nil)
        #expect((concrete?.registeredTargetCount ?? 0) >= 1)
    }

    // MARK: - Core Data Entity Persistence

    @Test("UploadQueueEntry can be created and persisted") func testUploadQueueEntryPersistence() async throws {
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
            predicate: NSPredicate(format: "entityId == %@", entityId as CVarArg),
            key: "createdAt",
            ascending: true
        ) as? [UploadQueueEntry]

        #expect(results?.count == 1)
        #expect(results?.first?.target == "nightscout")
        #expect(results?.first?.pipeline == UploadPipeline.glucose.rawValue)
        #expect(results?.first?.uploadKind == .create)
    }

    @Test("UploadState can be created and persisted") func testUploadStatePersistence() async throws {
        let entityId = UUID()

        try await testContext.perform {
            let state = UploadState(context: testContext)
            state.target = "nightscout"
            state.entityType = "glucose"
            state.entityId = entityId
            state.uploadedAt = Date()
            try testContext.save()
        }

        let results = try await coreDataStack.fetchEntitiesAsync(
            ofType: UploadState.self,
            onContext: testContext,
            predicate: NSPredicate.isUploaded(target: "nightscout", entityType: "glucose", entityId: entityId),
            key: "uploadedAt",
            ascending: true
        ) as? [UploadState]

        #expect(results?.count == 1)
        #expect(results?.first?.target == "nightscout")
        #expect(results?.first?.entityType == "glucose")
        #expect(results?.first?.entityId == entityId)
    }
}
