import Foundation

/// KPS-specific errors
enum KPSError: LocalizedError, Equatable {
    case configNotFound
    case configNotFoundInGitRepo
    case configParseError(String)
    case configAlreadyExists
    case unsupportedURL
    case fileIOError(Error)

    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Config not found. Run 'kps init' first."
        case .configNotFoundInGitRepo:
            return "Config not found in git repository. Run 'kps init' to initialize KPS in this repository."
        case .configParseError(let detail):
            return "Failed to parse config.json: \(detail)"
        case .configAlreadyExists:
            return "Config already exists. Use --force to overwrite."
        case .unsupportedURL:
            return "Unsupported URL. Supported: acmicpc.net, boj.kr, school.programmers.co.kr"
        case .fileIOError(let error):
            return "File I/O error: \(error.localizedDescription)"
        }
    }

    /// Custom equality for Swift Testing compatibility
    /// Note: fileIOError comparison ignores nested Error value
    static func == (lhs: KPSError, rhs: KPSError) -> Bool {
        switch (lhs, rhs) {
        case (.configNotFound, .configNotFound),
             (.configNotFoundInGitRepo, .configNotFoundInGitRepo),
             (.configAlreadyExists, .configAlreadyExists),
             (.unsupportedURL, .unsupportedURL):
            return true
        case (.configParseError(let lhsDetail), .configParseError(let rhsDetail)):
            return lhsDetail == rhsDetail
        case (.fileIOError, .fileIOError):
            return true
        default:
            return false
        }
    }
}
