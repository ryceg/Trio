import Combine
import CoreData
import Foundation

extension RemotePipelineManager {
    /// Call once from `start()`. Hooks up:
    /// 1) Core Data change triggers -> requests per upload pipeline
    /// 2) Glucose storage updates -> request glucose pipeline
    func wireSubscribers() {
        wireCoreDataSubscribers()
        wireGlucoseStorageSubscriber()
    }

    /// Maps Core Data entity changes into upload pipeline requests. We rely on
    /// per-pipeline throttle so rapid changes don't spam remote targets.
    private func wireCoreDataSubscribers() {
        let publisher = coreDataPublisher()

        publisher
            .filteredByEntityName("OrefDetermination")
            .sink { [weak self] _ in self?.requestUpload(.deviceStatus) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("OverrideStored")
            .sink { [weak self] _ in self?.requestUpload(.overrides) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("OverrideRunStored")
            .sink { [weak self] _ in self?.requestUpload(.overrides) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("TempTargetStored")
            .sink { [weak self] _ in self?.requestUpload(.tempTargets) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("TempTargetRunStored")
            .sink { [weak self] _ in self?.requestUpload(.tempTargets) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("PumpEventStored")
            .sink { [weak self] _ in self?.requestUpload(.pumpHistory) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("CarbEntryStored")
            .sink { [weak self] _ in self?.requestUpload(.carbs) }
            .store(in: &subscriptions)

        publisher
            .filteredByEntityName("GlucoseStored")
            .sink { [weak self] _ in
                self?.requestUpload(.glucose)
                self?.requestUpload(.manualGlucose)
            }
            .store(in: &subscriptions)
    }

    /// Glucose storage updates -> request glucose pipeline
    private func wireGlucoseStorageSubscriber() {
        glucoseStorage.updatePublisher
            .receive(on: pipelineQueue)
            .sink { [weak self] _ in
                self?.requestUpload(.glucose)
            }
            .store(in: &subscriptions)
    }

    private func coreDataPublisher() -> AnyPublisher<Set<NSManagedObjectID>, Never> {
        changedObjectsOnManagedObjectContextDidSavePublisher()
            .receive(on: pipelineQueue)
            .share()
            .eraseToAnyPublisher()
    }
}
