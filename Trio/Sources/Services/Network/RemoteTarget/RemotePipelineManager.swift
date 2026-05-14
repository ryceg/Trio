import Combine
import CoreData
import Foundation
import Swinject

protocol RemotePipelineManaging: AnyObject {
    func register(target: any RemoteTargetWriter)
    func requestUpload(_ pipeline: UploadPipeline)
}

final class RemotePipelineManager: RemotePipelineManaging, Injectable {
    @Injected() private var reachabilityManager: ReachabilityManager!

    private(set) var targets: [any RemoteTargetWriter] = []
    private var subscriptions = Set<AnyCancellable>()

    private var pipelineSubjects: [UploadPipeline: PassthroughSubject<Void, Never>] = {
        var d: [UploadPipeline: PassthroughSubject<Void, Never>] = [:]
        UploadPipeline.allCases.forEach { d[$0] = PassthroughSubject<Void, Never>() }
        return d
    }()

    let pipelineQueue = DispatchQueue(label: "RemotePipelineManager.pipelines", qos: .utility)

    /// Real-time pipelines get a 2-second throttle; batched pipelines get 30 seconds.
    private let throttleIntervals: [UploadPipeline: TimeInterval] = [
        .glucose: 2, .manualGlucose: 2, .deviceStatus: 2,
        .carbs: 30, .pumpHistory: 30, .overrides: 30, .tempTargets: 30,
    ]

    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        injectServices(resolver)
    }

    func register(target: any RemoteTargetWriter) {
        targets.append(target)
    }

    func requestUpload(_ pipeline: UploadPipeline) {
        pipelineSubjects[pipeline]?.send(())
    }

    func start() {
        setupPipelineThrottles()
    }

    // MARK: - Private

    private func setupPipelineThrottles() {
        for pipeline in UploadPipeline.allCases {
            guard let subject = pipelineSubjects[pipeline],
                  let window = throttleIntervals[pipeline] else { continue }
            subject
                .receive(on: pipelineQueue)
                .throttle(for: .seconds(window), scheduler: pipelineQueue, latest: false)
                .sink { [weak self] in
                    guard let self else { return }
                    Task(priority: .utility) { await self.runPipeline(pipeline) }
                }
                .store(in: &subscriptions)
        }
    }

    func runPipeline(_ pipeline: UploadPipeline) async {
        guard reachabilityManager.isReachable else { return }
        for target in targets where target.isConfigured && target.isEnabled {
            do {
                try await dispatch(pipeline: pipeline, to: target)
            } catch {
                debug(.nightscout, "Pipeline \(pipeline) failed for \(target.id): \(error)")
            }
        }
    }

    private func dispatch(pipeline: UploadPipeline, to target: any RemoteTargetWriter) async throws {
        // The NightscoutTarget wrapper ignores the empty arrays and calls existing
        // BaseNightscoutManager methods directly (which query Core Data using isUploadedToNS flags).
        // Future targets like NocturneTarget will use the actual entity arrays.
        switch pipeline {
        case .glucose:
            try await target.upload(glucose: [])
        case .manualGlucose:
            try await target.upload(glucose: [])
        case .carbs:
            try await target.upload(carbs: [])
        case .pumpHistory:
            try await target.upload(pumpEvents: [])
        case .deviceStatus:
            try await target.upload(determinations: [])
        case .overrides:
            try await target.upload(overrides: [])
        case .tempTargets:
            try await target.upload(tempTargets: [])
        }
    }
}
