import Foundation
import Testing
@testable import kps

@Test("locate should find config in current directory")
func locateFindsConfigInCurrentDirectory() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let kpsDir = tempDir.appendingPathComponent(".kps")
    try FileManager.default.createDirectory(at: kpsDir, withIntermediateDirectories: true)

    let configPath = kpsDir.appendingPathComponent("config.json")
    try "{}".write(to: configPath, atomically: true, encoding: .utf8)

    let result = ConfigLocator.locate(from: tempDir)

    guard case .success(let projectRoot) = result else {
        Issue.record("Expected success, got failure")
        return
    }

    #expect(projectRoot.projectRoot.standardizedFileURL == tempDir.standardizedFileURL)
    #expect(projectRoot.configPath.lastPathComponent == "config.json")
    #expect(projectRoot.configPath.deletingLastPathComponent().lastPathComponent == ".kps")
}

@Test("locate should find config in parent directory")
func locateFindsConfigInParentDirectory() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let kpsDir = tempDir.appendingPathComponent(".kps")
    try FileManager.default.createDirectory(at: kpsDir, withIntermediateDirectories: true)

    let configPath = kpsDir.appendingPathComponent("config.json")
    try "{}".write(to: configPath, atomically: true, encoding: .utf8)

    let subDir = tempDir.appendingPathComponent("subdir")
    try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

    let result = ConfigLocator.locate(from: subDir)

    guard case .success(let projectRoot) = result else {
        Issue.record("Expected success, got failure")
        return
    }

    #expect(projectRoot.projectRoot.standardizedFileURL == tempDir.standardizedFileURL)
}

@Test("locate should return configNotFound when no config")
func locateReturnsConfigNotFoundWhenNoConfig() {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempDir) }
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let result = ConfigLocator.locate(from: tempDir)

    guard case .failure(let error) = result else {
        Issue.record("Expected failure, got success")
        return
    }

    guard case KPSError.configNotFound = error else {
        Issue.record("Expected configNotFound, got \(error)")
        return
    }
}

@Test("locate should return configNotFoundInGitRepo when only git exists")
func locateReturnsConfigNotFoundInGitRepoWhenOnlyGitExists() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let gitDir = tempDir.appendingPathComponent(".git")
    try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)

    let result = ConfigLocator.locate(from: tempDir)

    guard case .failure(let error) = result else {
        Issue.record("Expected failure, got success")
        return
    }

    guard case KPSError.configNotFoundInGitRepo = error else {
        Issue.record("Expected configNotFoundInGitRepo, got \(error)")
        return
    }
}

@Test("locate should support monorepo with parent git and child KPS")
func locateSupportsMonorepoWithParentGitAndChildKPS() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let gitDir = tempDir.appendingPathComponent(".git")
    try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)

    let subProject = tempDir.appendingPathComponent("project")
    let kpsDir = subProject.appendingPathComponent(".kps")
    try FileManager.default.createDirectory(at: kpsDir, withIntermediateDirectories: true)

    let configPath = kpsDir.appendingPathComponent("config.json")
    try "{}".write(to: configPath, atomically: true, encoding: .utf8)

    let result = ConfigLocator.locate(from: subProject)

    guard case .success(let projectRoot) = result else {
        Issue.record("Expected success, got failure")
        return
    }

    #expect(projectRoot.projectRoot.standardizedFileURL == subProject.standardizedFileURL)
}

@Test("projectRoot should have correct structure")
func projectRootHasCorrectStructure() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let kpsDir = tempDir.appendingPathComponent(".kps")
    try FileManager.default.createDirectory(at: kpsDir, withIntermediateDirectories: true)

    let configPath = kpsDir.appendingPathComponent("config.json")
    try "{}".write(to: configPath, atomically: true, encoding: .utf8)

    let result = ConfigLocator.locate(from: tempDir)

    guard case .success(let projectRoot) = result else {
        Issue.record("Expected success")
        return
    }

    #expect(projectRoot.configPath.lastPathComponent == "config.json")
    #expect(projectRoot.configPath.deletingLastPathComponent().lastPathComponent == ".kps")
    #expect(
        projectRoot.configPath.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL ==
        projectRoot.projectRoot.standardizedFileURL
    )
}
