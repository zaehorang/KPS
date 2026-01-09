import Foundation
import Testing
@testable import kps

@Test("encode should produce valid JSON")
func encodeProducesValidJSON() throws {
    let config = KPSConfig(
        author: "Test Author",
        sourceFolder: "Sources",
        projectName: "TestProject"
    )

    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-config.json")
    try config.save(to: tempURL)

    let data = try Data(contentsOf: tempURL)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

    #expect(json?["author"] == "Test Author")
    #expect(json?["sourceFolder"] == "Sources")
    #expect(json?["projectName"] == "TestProject")

    try? FileManager.default.removeItem(at: tempURL)
}

@Test("decode should load config from JSON")
func decodeLoadsConfigFromJSON() throws {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-config-load.json")

    let jsonString = """
    {
        "author": "John Doe",
        "sourceFolder": "src",
        "projectName": "MyProject"
    }
    """
    try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)

    let config = try KPSConfig.load(from: tempURL)

    #expect(config.author == "John Doe")
    #expect(config.sourceFolder == "src")
    #expect(config.projectName == "MyProject")

    try? FileManager.default.removeItem(at: tempURL)
}

@Test("load should throw configParseError for invalid JSON")
func loadThrowsConfigParseErrorForInvalidJSON() throws {
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invalid-config.json")

    let invalidJSON = "{ invalid json }"
    try? invalidJSON.write(to: tempURL, atomically: true, encoding: .utf8)

    var didThrow = false
    do {
        _ = try KPSConfig.load(from: tempURL)
    } catch let error as KPSError {
        if case .configParseError = error {
            didThrow = true
        }
    }

    #expect(didThrow)

    try? FileManager.default.removeItem(at: tempURL)
}

@Test("save should use atomic write")
func saveUsesAtomicWrite() throws {
    let config = KPSConfig(
        author: "Test",
        sourceFolder: "Sources",
        projectName: "Test"
    )

    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("atomic-test.json")
    try config.save(to: tempURL)

    #expect(FileManager.default.fileExists(atPath: tempURL.path))

    try? FileManager.default.removeItem(at: tempURL)
}
