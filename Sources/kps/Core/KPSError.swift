import Foundation

/// 카테고리별로 구성된 KPS 전용 에러 타입
enum KPSError: LocalizedError, Equatable {
    case config(Config)
    case git(Git)
    case file(File)
    case platform(Platform)
    case history(History)
    case open(Open)

    // MARK: - Config Errors

    enum Config: Equatable {
        case notFound
        case notFoundInGitRepo
        case parseError(String)
        case alreadyExists
        case invalidKey(String)

        var localizedDescription: String {
            switch self {
            case .notFound:
                return "Config not found. Run 'kps init' first."
            case .notFoundInGitRepo:
                return "Config not found in git repository. Run 'kps init' to initialize KPS in this repository."
            case .parseError(let detail):
                return "Failed to parse config.json: \(detail)"
            case .alreadyExists:
                return "Config already exists. Use --force to overwrite."
            case .invalidKey(let key):
                return "Invalid config key: '\(key)'. Valid keys: author, sourceFolder, projectName"
            }
        }
    }

    // MARK: - Git Errors

    enum Git: Equatable {
        case notAvailable
        case notRepository
        case nothingToCommit
        case failed(String)
        case pushFailed(String)

        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "Git is not installed or not in PATH. Install: https://git-scm.com/downloads"
            case .notRepository:
                return "Not a git repository. Run 'git init' first."
            case .nothingToCommit:
                return "No changes to commit. Did you save your solution file?"
            case .failed(let stderr):
                return "Git command failed: \(stderr)"
            case .pushFailed(let stderr):
                return "Git push failed: \(stderr)"
            }
        }
    }

    // MARK: - File Errors

    enum File: Equatable {
        case alreadyExists(String)
        case notFound(String)
        case multipleFound([String])
        case permissionDenied(String)
        case ioError(Error)

        var localizedDescription: String {
            switch self {
            case .alreadyExists(let path):
                return "File already exists: \(path)"
            case .notFound(let path):
                return "File not found: \(path)"
            case .multipleFound(let paths):
                let fileList = paths.map { "  • \($0)" }.joined(separator: "\n")
                return """
                Multiple files found:
                \(fileList)

                Please remove or move duplicate files so only one remains.
                """
            case .permissionDenied(let path):
                return "Permission denied: \(path)"
            case .ioError(let error):
                return "File I/O error: \(error.localizedDescription)"
            }
        }

        /// Swift Testing 호환성을 위한 커스텀 동등성 비교
        /// 참고: ioError 비교 시 중첩된 Error 값은 무시됨
        static func == (lhs: File, rhs: File) -> Bool {
            switch (lhs, rhs) {
            case (.alreadyExists(let lPath), .alreadyExists(let rPath)),
                 (.notFound(let lPath), .notFound(let rPath)),
                 (.permissionDenied(let lPath), .permissionDenied(let rPath)):
                return lPath == rPath
            case (.multipleFound(let lPaths), .multipleFound(let rPaths)):
                return lPaths == rPaths
            case (.ioError, .ioError):
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Platform Errors

    enum Platform: Equatable {
        case unsupportedURL
        case invalidProblemNumber
        case platformRequired
        case conflictingFlags
        case urlWithPlatformFlag

        var localizedDescription: String {
            switch self {
            case .unsupportedURL:
                return "Unsupported URL. Supported: acmicpc.net, boj.kr, school.programmers.co.kr"
            case .invalidProblemNumber:
                return "Invalid problem number. Problem number must be a positive integer."
            case .platformRequired:
                return "Platform not specified. Use -b for BOJ or -p for Programmers."
            case .conflictingFlags:
                return "Cannot use both -b and -p flags. Choose one platform."
            case .urlWithPlatformFlag:
                return "URL already specifies the platform. Do not use -b or -p flags with URL."
            }
        }
    }

    // MARK: - History Errors

    enum History: Equatable {
        case noRecentFile
        case fileDeleted(String)

        var localizedDescription: String {
            switch self {
            case .noRecentFile:
                return "No recent file found. Use 'kps new' to create a problem file first."
            case .fileDeleted(let path):
                return "Recent file no longer exists: \(path)"
            }
        }
    }

    // MARK: - Open Errors

    enum Open: Equatable {
        case commandFailed(String)

        var localizedDescription: String {
            switch self {
            case .commandFailed(let message):
                return "Failed to open file: \(message)"
            }
        }
    }

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        case .config(let error):
            return error.localizedDescription
        case .git(let error):
            return error.localizedDescription
        case .file(let error):
            return error.localizedDescription
        case .platform(let error):
            return error.localizedDescription
        case .history(let error):
            return error.localizedDescription
        case .open(let error):
            return error.localizedDescription
        }
    }

    // MARK: - Utility Methods

    /// NSError를 KPSError로 매핑
    /// - NSFileWriteNoPermissionError → file(.permissionDenied)
    /// - NSFileReadNoPermissionError → file(.permissionDenied)
    /// - 기타 에러 → file(.ioError)
    static func from(_ nsError: NSError) -> KPSError {
        switch nsError.code {
        case NSFileWriteNoPermissionError, NSFileReadNoPermissionError:
            let path = nsError.userInfo[NSFilePathErrorKey] as? String ?? "unknown"
            return .file(.permissionDenied(path))
        default:
            return .file(.ioError(nsError))
        }
    }
}
