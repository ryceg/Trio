import CoreData
import Foundation
import Swinject
import Testing

@testable import Trio

@Suite("RemotePipelineManager Tests", .serialized) struct RemotePipelineManagerTests: Injectable {
    @Injected() var reachabilityManager: ReachabilityManager!
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

    // MARK: - Registration

    @Test("Register adds target to targets array") func testRegisterTarget() {
        let manager = RemotePipelineManager(resolver: resolver)
        let target = MockRemoteTarget(id: "test-target")

        manager.register(target: target)

        #expect(manager.targets.count == 1)
        #expect(manager.targets.first?.id == "test-target")
    }

    @Test("Register multiple targets preserves order") func testRegisterMultipleTargets() {
        let manager = RemotePipelineManager(resolver: resolver)
        let target1 = MockRemoteTarget(id: "first")
        let target2 = MockRemoteTarget(id: "second")

        manager.register(target: target1)
        manager.register(target: target2)

        #expect(manager.targets.count == 2)
        #expect(manager.targets[0].id == "first")
        #expect(manager.targets[1].id == "second")
    }

    // MARK: - Pipeline Dispatch

    @Test("runPipeline dispatches to configured and enabled targets") func testRunPipelineDispatches() async {
        let manager = RemotePipelineManager(resolver: resolver)
        let target = MockRemoteTarget(id: "active")
        target.isConfigured = true
        target.isEnabled = true
        manager.register(target: target)

        await manager.runPipeline(.glucose)

        #expect(target.uploadGlucoseCallCount == 1)
    }

    @Test("runPipeline skips unconfigured targets") func testSkipsUnconfigured() async {
        let manager = RemotePipelineManager(resolver: resolver)
        let target = MockRemoteTarget(id: "unconfigured")
        target.isConfigured = false
        target.isEnabled = true
        manager.register(target: target)

        await manager.runPipeline(.glucose)

        #expect(target.uploadGlucoseCallCount == 0)
    }

    @Test("runPipeline skips disabled targets") func testSkipsDisabled() async {
        let manager = RemotePipelineManager(resolver: resolver)
        let target = MockRemoteTarget(id: "disabled")
        target.isConfigured = true
        target.isEnabled = false
        manager.register(target: target)

        await manager.runPipeline(.glucose)

        #expect(target.uploadGlucoseCallCount == 0)
    }

    @Test("runPipeline dispatches each pipeline to the correct method") func testPipelineRouting() async {
        let manager = RemotePipelineManager(resolver: resolver)
        let target = MockRemoteTarget(id: "routing")
        manager.register(target: target)

        await manager.runPipeline(.carbs)
        #expect(target.uploadCarbsCallCount == 1)
        #expect(target.uploadGlucoseCallCount == 0)

        await manager.runPipeline(.pumpHistory)
        #expect(target.uploadPumpEventsCallCount == 1)

        await manager.runPipeline(.deviceStatus)
        #expect(target.uploadDeterminationsCallCount == 1)

        await manager.runPipeline(.overrides)
        #expect(target.uploadOverridesCallCount == 1)

        await manager.runPipeline(.tempTargets)
        #expect(target.uploadTempTargetsCallCount == 1)
    }

    @Test("runPipeline continues to next target on error") func testContinuesOnError() async {
        let manager = RemotePipelineManager(resolver: resolver)

        let failingTarget = MockRemoteTarget(id: "failing")
        failingTarget.shouldThrow = NSError(domain: "test", code: 500)

        let healthyTarget = MockRemoteTarget(id: "healthy")

        manager.register(target: failingTarget)
        manager.register(target: healthyTarget)

        await manager.runPipeline(.glucose)

        // The failing target threw, but the healthy target should still have been called
        #expect(healthyTarget.uploadGlucoseCallCount == 1)
    }
}
