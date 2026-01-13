import Foundation
import Testing
@testable import kps

// MARK: - Test Helpers

/// 자동 정리 기능이 있는 임시 파일 URL 생성
private func withTempFile(extension fileExtension: String = "json", _ block: (URL) throws -> Void) rethrows {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(fileExtension)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try block(tempURL)
}

// MARK: - Tests

@Test("encode should produce valid JSON")
func encodeProducesValidJSON() throws {
    let config = KPSConfig(
        author: "Test Author",
        sourceFolder: "Sources",
        projectName: "TestProject"
    )

    try withTempFile { tempURL in
        try config.save(to: tempURL)

        let data = try Data(contentsOf: tempURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        #expect(json?["author"] == "Test Author")
        #expect(json?["sourceFolder"] == "Sources")
        #expect(json?["projectName"] == "TestProject")
    }
}

@Test("decode should load config from JSON")
func decodeLoadsConfigFromJSON() throws {
    try withTempFile { tempURL in
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
    }
}

@Test("load should throw configParseError for invalid JSON")
func loadThrowsConfigParseErrorForInvalidJSON() throws {
    try withTempFile { tempURL in
        let invalidJSON = "{ invalid json }"
        try invalidJSON.write(to: tempURL, atomically: true, encoding: .utf8)

        var didThrow = false
        do {
            _ = try KPSConfig.load(from: tempURL)
        } catch let error as KPSError {
            if case .config(.parseError) = error {
                didThrow = true
            }
        }

        #expect(didThrow)
    }
}

@Test("save should use atomic write")
func saveUsesAtomicWrite() throws {
    let config = KPSConfig(
        author: "Test",
        sourceFolder: "Sources",
        projectName: "Test"
    )

    try withTempFile { tempURL in
        try config.save(to: tempURL)
        #expect(FileManager.default.fileExists(atPath: tempURL.path))
    }
}

@Test("Config encode should include xcodeProjectPath when present")
func configEncodesXcodeProjectPath() throws {
    let config = KPSConfig(
        author: "Test",
        sourceFolder: "Sources",
        projectName: "TestProject",
        xcodeProjectPath: "TestProject.xcodeproj"
    )

    try withTempFile { tempURL in
        try config.save(to: tempURL)

        let data = try Data(contentsOf: tempURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        #expect(json?["xcodeProjectPath"] == "TestProject.xcodeproj")
    }
}

@Test("Config decode should handle missing xcodeProjectPath")
func configDecodesMissingXcodeProjectPath() throws {
    let jsonString = """
    {
      "author": "Test",
      "projectName": "TestProject",
      "sourceFolder": "Sources"
    }
    """

    try withTempFile { tempURL in
        try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
        let config = try KPSConfig.load(from: tempURL)

        #expect(config.xcodeProjectPath == nil)
    }
}
