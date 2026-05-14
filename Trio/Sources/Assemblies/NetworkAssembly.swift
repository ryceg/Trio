import Foundation
import Swinject

final class NetworkAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ReachabilityManager.self) { _ in
            NetworkReachabilityManager()!
        }

        container.register(NightscoutManager.self) { r in BaseNightscoutManager(resolver: r) }
        container.register(TidepoolManager.self) { r in BaseTidepoolManager(resolver: r) }

        container.register(RemotePipelineManaging.self) { r in
            let manager = RemotePipelineManager(resolver: r)
            if let nightscoutManager = r.resolve(NightscoutManager.self) as? BaseNightscoutManager {
                let nightscoutTarget = NightscoutTarget(manager: nightscoutManager)
                manager.register(target: nightscoutTarget)
            }
            return manager
        }
    }
}
