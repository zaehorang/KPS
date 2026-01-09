import Foundation

/// Represents the root directory of a KPS project
struct ProjectRoot {
    let projectRoot: URL

    var configPath: URL {
        projectRoot.appendingPathComponent(".kps").appendingPathComponent("config.json")
    }
}

/// Locates KPS project root by searching for `.kps/config.json`
enum ConfigLocator {
    /// Searches upward from starting path to find KPS config
    /// - Returns: `Result` with `ProjectRoot` on success, or error indicating whether a git repo was found
    static func locate(from startingPath: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> Result<ProjectRoot, KPSError> {
        var currentPath = startingPath.standardizedFileURL
        var gitRepoDetected = false

        // Traverse upward until config is found or filesystem root is reached
        while currentPath.path != "/" {
            let kpsPath = currentPath.appendingPathComponent(".kps")
            let configPath = kpsPath.appendingPathComponent("config.json")

            if FileManager.default.fileExists(atPath: configPath.path) {
                return .success(ProjectRoot(projectRoot: currentPath))
            }

            // Track git repos for better error messages (monorepo support)
            let gitPath = currentPath.appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: gitPath.path) {
                gitRepoDetected = true
            }

            let parent = currentPath.deletingLastPathComponent().standardizedFileURL
            if parent.path == currentPath.path {
                break
            }
            currentPath = parent
        }

        // Differentiate error based on whether git repo was found
        if gitRepoDetected {
            return .failure(.configNotFoundInGitRepo)
        } else {
            return .failure(.configNotFound)
        }
    }
}
