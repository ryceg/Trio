import CoreData
import Foundation

// MARK: - Base Protocol

/// A remote destination that Trio can interact with (Nightscout, Nocturne, etc.)
protocol RemoteTarget: AnyObject, Sendable {
    var id: String { get }
    var isConfigured: Bool { get }
    var isEnabled: Bool { get }
}

// MARK: - Writer Protocol

/// A remote target that can receive uploaded data from Trio.
protocol RemoteTargetWriter: RemoteTarget {
    func upload(glucose: [GlucoseStored]) async throws
    func upload(carbs: [CarbEntryStored]) async throws
    func upload(pumpEvents: [PumpEventStored]) async throws
    func upload(determinations: [OrefDetermination]) async throws
    func upload(overrides: [OverrideStored]) async throws
    func upload(overrideRuns: [OverrideRunStored]) async throws
    func upload(tempTargets: [TempTargetStored]) async throws
    func upload(tempTargetRuns: [TempTargetRunStored]) async throws
    func upload(profiles: NightscoutProfileStore) async throws

    func delete(glucoseId: String) async throws
    func delete(treatmentId: String) async throws
}

// MARK: - Reader Protocol (future)

/// A remote target that can provide data to Trio. Placeholder for bidirectional sync.
protocol RemoteTargetReader: RemoteTarget {}
