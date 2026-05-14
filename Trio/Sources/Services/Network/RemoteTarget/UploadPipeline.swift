import Foundation

/// Data pipelines that the RemotePipelineManager routes to registered targets.
public enum UploadPipeline: String, CaseIterable, Sendable {
    case glucose
    case manualGlucose
    case carbs
    case pumpHistory
    case overrides
    case tempTargets
    case deviceStatus
}
