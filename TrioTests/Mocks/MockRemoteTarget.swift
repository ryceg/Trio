import Foundation
@testable import Trio

final class MockRemoteTarget: RemoteTargetWriter, @unchecked Sendable {
    let id: String
    var isConfigured: Bool = true
    var isEnabled: Bool = true

    var uploadGlucoseCallCount = 0
    var uploadCarbsCallCount = 0
    var uploadPumpEventsCallCount = 0
    var uploadDeterminationsCallCount = 0
    var uploadOverridesCallCount = 0
    var uploadOverrideRunsCallCount = 0
    var uploadTempTargetsCallCount = 0
    var uploadTempTargetRunsCallCount = 0
    var uploadProfilesCallCount = 0
    var deleteGlucoseCallCount = 0
    var deleteTreatmentCallCount = 0

    var shouldThrow: Error?

    init(id: String = "mock") {
        self.id = id
    }

    func upload(glucose: [GlucoseStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadGlucoseCallCount += 1
    }

    func upload(carbs: [CarbEntryStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadCarbsCallCount += 1
    }

    func upload(pumpEvents: [PumpEventStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadPumpEventsCallCount += 1
    }

    func upload(determinations: [OrefDetermination]) async throws {
        if let error = shouldThrow { throw error }
        uploadDeterminationsCallCount += 1
    }

    func upload(overrides: [OverrideStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadOverridesCallCount += 1
    }

    func upload(overrideRuns: [OverrideRunStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadOverrideRunsCallCount += 1
    }

    func upload(tempTargets: [TempTargetStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadTempTargetsCallCount += 1
    }

    func upload(tempTargetRuns: [TempTargetRunStored]) async throws {
        if let error = shouldThrow { throw error }
        uploadTempTargetRunsCallCount += 1
    }

    func upload(profiles: NightscoutProfileStore) async throws {
        if let error = shouldThrow { throw error }
        uploadProfilesCallCount += 1
    }

    func delete(glucoseId: String) async throws {
        if let error = shouldThrow { throw error }
        deleteGlucoseCallCount += 1
    }

    func delete(treatmentId: String) async throws {
        if let error = shouldThrow { throw error }
        deleteTreatmentCallCount += 1
    }
}
