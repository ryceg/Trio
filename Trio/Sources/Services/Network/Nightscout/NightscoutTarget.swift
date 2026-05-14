import CoreData
import Foundation

/// Thin adapter wrapping `BaseNightscoutManager` as a `RemoteTargetWriter`.
///
/// All upload methods delegate to the existing `BaseNightscoutManager` methods,
/// which query Core Data internally to find un-uploaded records. The entity
/// arrays passed by the pipeline are intentionally ignored.
final class NightscoutTarget: RemoteTargetWriter {
    let id = "nightscout"

    private weak var manager: BaseNightscoutManager?

    init(manager: BaseNightscoutManager) {
        self.manager = manager
    }

    var isConfigured: Bool {
        manager?.isNightscoutConfigured ?? false
    }

    var isEnabled: Bool {
        isConfigured
    }

    // MARK: - Uploads

    func upload(glucose: [GlucoseStored]) async throws {
        await manager?.uploadGlucose()
    }

    func upload(carbs: [CarbEntryStored]) async throws {
        await manager?.uploadCarbs()
    }

    func upload(pumpEvents: [PumpEventStored]) async throws {
        await manager?.uploadPumpHistory()
    }

    func upload(determinations: [OrefDetermination]) async throws {
        try await manager?.uploadDeviceStatus()
    }

    func upload(overrides: [OverrideStored]) async throws {
        await manager?.uploadOverrides()
    }

    func upload(overrideRuns: [OverrideRunStored]) async throws {
        await manager?.uploadOverrides()
    }

    func upload(tempTargets: [TempTargetStored]) async throws {
        await manager?.uploadTempTargets()
    }

    func upload(tempTargetRuns: [TempTargetRunStored]) async throws {
        await manager?.uploadTempTargets()
    }

    func upload(profiles: NightscoutProfileStore) async throws {
        try await manager?.uploadProfiles()
    }

    // MARK: - Deletes

    func delete(glucoseId: String) async throws {
        await manager?.deleteManualGlucose(withID: glucoseId)
    }

    func delete(treatmentId: String) async throws {
        await manager?.deleteInsulin(withID: treatmentId)
    }
}
