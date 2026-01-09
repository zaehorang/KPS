import Foundation

/// KPS 전용 에러 타입
enum KPSError: LocalizedError, Equatable {
    case configNotFound
    case configNotFoundInGitRepo
    case configParseError(String)
    case configAlreadyExists
    case unsupportedURL
    case invalidProblemNumber
    case platformRequired
    case conflictingPlatformFlags
    case urlWithPlatformFlag
    case invalidConfigKey(String)
    case fileAlreadyExists(String)
    case fileNotFound(String)
    case gitNotAvailable
    case notGitRepository
    case nothingToCommit
    case gitFailed(String)
    case gitPushFailed(String)
    case permissionDenied(String)
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
        case .invalidProblemNumber:
            return "Invalid problem number. Problem number must be a positive integer."
        case .platformRequired:
            return "Platform not specified. Use -b for BOJ or -p for Programmers."
        case .conflictingPlatformFlags:
            return "Cannot use both -b and -p flags. Choose one platform."
        case .urlWithPlatformFlag:
            return "URL already specifies the platform. Do not use -b or -p flags with URL."
        case .invalidConfigKey(let key):
            return "Invalid config key: '\(key)'. Valid keys: author, sourceFolder, projectName"
        case .fileAlreadyExists(let path):
            return "File already exists: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .gitNotAvailable:
            return "Git is not installed or not in PATH. Install: https://git-scm.com/downloads"
        case .notGitRepository:
            return "Not a git repository. Run 'git init' first."
        case .nothingToCommit:
            return "No changes to commit. Did you save your solution file?"
        case .gitFailed(let stderr):
            return "Git command failed: \(stderr)"
        case .gitPushFailed(let stderr):
            return "Git push failed: \(stderr)"
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .fileIOError(let error):
            return "File I/O error: \(error.localizedDescription)"
        }
    }

    /// NSError를 KPSError로 매핑
    /// - NSFileWriteNoPermissionError → permissionDenied
    /// - NSFileReadNoPermissionError → permissionDenied
    /// - 기타 에러 → fileIOError
    static func from(_ nsError: NSError) -> KPSError {
        switch nsError.code {
        case NSFileWriteNoPermissionError, NSFileReadNoPermissionError:
            let path = nsError.userInfo[NSFilePathErrorKey] as? String ?? "unknown"
            return .permissionDenied(path)
        default:
            return .fileIOError(nsError)
        }
    }

    /// Swift Testing 호환성을 위한 커스텀 동등성 비교
    /// 주의: fileIOError 비교 시 중첩된 Error 값은 무시됨
    static func == (lhs: KPSError, rhs: KPSError) -> Bool {
        switch (lhs, rhs) {
        case (.configNotFound, .configNotFound),
             (.configNotFoundInGitRepo, .configNotFoundInGitRepo),
             (.configAlreadyExists, .configAlreadyExists),
             (.unsupportedURL, .unsupportedURL),
             (.invalidProblemNumber, .invalidProblemNumber),
             (.platformRequired, .platformRequired),
             (.conflictingPlatformFlags, .conflictingPlatformFlags),
             (.urlWithPlatformFlag, .urlWithPlatformFlag),
             (.gitNotAvailable, .gitNotAvailable),
             (.notGitRepository, .notGitRepository),
             (.nothingToCommit, .nothingToCommit):
            return true
        case (.configParseError(let lhsDetail), .configParseError(let rhsDetail)),
             (.invalidConfigKey(let lhsDetail), .invalidConfigKey(let rhsDetail)),
             (.fileAlreadyExists(let lhsDetail), .fileAlreadyExists(let rhsDetail)),
             (.fileNotFound(let lhsDetail), .fileNotFound(let rhsDetail)),
             (.gitFailed(let lhsDetail), .gitFailed(let rhsDetail)),
             (.gitPushFailed(let lhsDetail), .gitPushFailed(let rhsDetail)),
             (.permissionDenied(let lhsDetail), .permissionDenied(let rhsDetail)):
            return lhsDetail == rhsDetail
        case (.fileIOError, .fileIOError):
            return true
        default:
            return false
        }
    }
}
