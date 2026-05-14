import Foundation

struct UploadError: Error {
    let category: Category
    let underlying: Error?

    enum Category {
        case transient
        case rateLimited(retryAfter: TimeInterval?)
        case terminal
    }

    static func transient(_ error: Error) -> UploadError {
        UploadError(category: .transient, underlying: error)
    }

    static func rateLimited(retryAfter: TimeInterval? = nil) -> UploadError {
        UploadError(category: .rateLimited(retryAfter: retryAfter), underlying: nil)
    }

    static func terminal(_ error: Error) -> UploadError {
        UploadError(category: .terminal, underlying: error)
    }

    static func fromHTTPStatus(_ statusCode: Int, error: Error? = nil) -> UploadError {
        switch statusCode {
        case 401, 403, 404:
            return .terminal(error ?? NSError(domain: "UploadError", code: statusCode))
        case 429:
            return .rateLimited()
        default:
            return .transient(error ?? NSError(domain: "UploadError", code: statusCode))
        }
    }
}
