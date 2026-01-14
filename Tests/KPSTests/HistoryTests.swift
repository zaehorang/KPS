import Foundation
import Testing
@testable import kps

// MARK: - Test Helpers

/// 임시 파일 생성 헬퍼
private func withTempFile(extension fileExtension: String = "json", _ block: (URL) throws -> Void) rethrows {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(fileExtension)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try block(tempURL)
}

// MARK: - Encoding/Decoding Tests

@Test("History encode should produce valid JSON")
func historyEncodesToJSON() throws {
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "Sources/BOJ/1000.swift",
        timestamp: Date()
    )
    let history = KPSHistory(entries: [entry])

    try withTempFile { tempURL in
        try history.save(to: tempURL)

        let data = try Data(contentsOf: tempURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect((json?["entries"] as? [[String: Any]])?.count == 1)
    }
}

@Test("History load should restore from JSON")
func historyLoadsFromJSON() throws {
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "Sources/BOJ/1000.swift",
        timestamp: Date()
    )
    let original = KPSHistory(entries: [entry])

    try withTempFile { tempURL in
        try original.save(to: tempURL)
        let loaded = try KPSHistory.load(from: tempURL)

        #expect(loaded.entries.count == 1)
        #expect(loaded.entries[0].problemNumber == "1000")
        #expect(loaded.entries[0].platform == .boj)
        #expect(loaded.entries[0].filePath == "Sources/BOJ/1000.swift")
    }
}

@Test("History decode should handle ISO8601 date format")
func historyDecodesISO8601Dates() throws {
    let jsonString = """
    {
      "entries": [
        {
          "problemNumber": "1000",
          "platform": "boj",
          "filePath": "Sources/BOJ/1000.swift",
          "timestamp": "2026-01-13T04:00:00Z"
        }
      ]
    }
    """

    try withTempFile { tempURL in
        try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
        let history = try KPSHistory.load(from: tempURL)

        #expect(history.entries.count == 1)
        #expect(history.entries[0].problemNumber == "1000")
    }
}

// MARK: - Most Recent Tests

@Test("History mostRecent should return last entry")
func historyMostRecentReturnsLastEntry() {
    let entry1 = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "a.swift",
        timestamp: Date()
    )
    let entry2 = HistoryEntry(
        problemNumber: "1001",
        platform: .boj,
        filePath: "b.swift",
        timestamp: Date()
    )
    let history = KPSHistory(entries: [entry1, entry2])

    #expect(history.mostRecent()?.problemNumber == "1001")
}

@Test("History mostRecent should return nil for empty")
func historyMostRecentReturnsNilWhenEmpty() {
    let history = KPSHistory()
    #expect(history.mostRecent() == nil)
}

// MARK: - Add Entry Tests

@Test("History addEntry should append to array")
func historyAddEntryAppends() {
    var history = KPSHistory()
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "a.swift",
        timestamp: Date()
    )

    history.addEntry(entry)

    #expect(history.entries.count == 1)
    #expect(history.entries[0].problemNumber == "1000")
}

@Test("History addEntry should preserve order")
func historyAddEntryPreservesOrder() {
    var history = KPSHistory()
    let entry1 = HistoryEntry(problemNumber: "1000", platform: .boj, filePath: "a.swift", timestamp: Date())
    let entry2 = HistoryEntry(problemNumber: "1001", platform: .boj, filePath: "b.swift", timestamp: Date())

    history.addEntry(entry1)
    history.addEntry(entry2)

    #expect(history.entries.count == 2)
    #expect(history.entries[0].problemNumber == "1000")
    #expect(history.entries[1].problemNumber == "1001")
}

// MARK: - File I/O Tests

@Test("History save should use atomic write")
func historySavesAtomically() throws {
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "Sources/BOJ/1000.swift",
        timestamp: Date()
    )
    let history = KPSHistory(entries: [entry])

    try withTempFile { tempURL in
        try history.save(to: tempURL)

        // File should exist and be readable
        #expect(FileManager.default.fileExists(atPath: tempURL.path))

        let data = try Data(contentsOf: tempURL)
        #expect(data.count > 0)
    }
}

@Test("History save should produce pretty-printed JSON")
func historySavesPrettyPrintedJSON() throws {
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "Sources/BOJ/1000.swift",
        timestamp: Date()
    )
    let history = KPSHistory(entries: [entry])

    try withTempFile { tempURL in
        try history.save(to: tempURL)

        let content = try String(contentsOf: tempURL)
        // Pretty-printed JSON should have newlines
        #expect(content.contains("\n"))
        // Should be sorted keys
        #expect(content.range(of: "entries") != nil)
    }
}

@Test("History load should throw on invalid JSON")
func historyLoadThrowsOnInvalidJSON() throws {
    let invalidJSON = "{ invalid json }"

    try withTempFile { tempURL in
        try invalidJSON.write(to: tempURL, atomically: true, encoding: .utf8)

        #expect(throws: KPSError.self) {
            _ = try KPSHistory.load(from: tempURL)
        }
    }
}

@Test("History load should throw on missing file")
func historyLoadThrowsOnMissingFile() {
    let nonExistentURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")

    #expect(throws: KPSError.self) {
        _ = try KPSHistory.load(from: nonExistentURL)
    }
}

// MARK: - Solved Field Tests

@Test("HistoryEntry should encode solved field")
func historyEntryEncodesSolvedField() throws {
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "Sources/BOJ/1000.swift",
        timestamp: Date(),
        solved: true
    )

    try withTempFile { tempURL in
        let history = KPSHistory(entries: [entry])
        try history.save(to: tempURL)

        let data = try Data(contentsOf: tempURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let entries = json?["entries"] as? [[String: Any]]

        #expect(entries?.first?["solved"] as? Bool == true)
    }
}

@Test("HistoryEntry should default solved to false")
func historyEntryDefaultsSolvedToFalse() {
    let entry = HistoryEntry(
        problemNumber: "1000",
        platform: .boj,
        filePath: "Sources/BOJ/1000.swift",
        timestamp: Date()
    )

    #expect(entry.solved == false)
}

@Test("History should decode entries without solved field")
func historyDecodesEntriesWithoutSolvedField() throws {
    let jsonString = """
    {
      "entries": [
        {
          "problemNumber": "1000",
          "platform": "boj",
          "filePath": "Sources/BOJ/1000.swift",
          "timestamp": "2026-01-13T12:00:00Z"
        }
      ]
    }
    """

    try withTempFile { tempURL in
        try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
        let history = try KPSHistory.load(from: tempURL)

        #expect(history.entries.count == 1)
        #expect(history.entries[0].solved == false)
    }
}

@Test("markAsSolved should update solved status")
func markAsSolvedUpdatesStatus() {
    var history = KPSHistory(entries: [
        HistoryEntry(
            problemNumber: "1000",
            platform: .boj,
            filePath: "Sources/BOJ/1000.swift",
            timestamp: Date()
        ),
        HistoryEntry(
            problemNumber: "1001",
            platform: .boj,
            filePath: "Sources/BOJ/1001.swift",
            timestamp: Date()
        )
    ])

    #expect(history.entries[0].solved == false)
    #expect(history.entries[1].solved == false)

    history.markAsSolved(problemNumber: "1000", platform: .boj)

    #expect(history.entries[0].solved == true)
    #expect(history.entries[1].solved == false)
}

@Test("markAsSolved should do nothing for non-existent problem")
func markAsSolvedHandlesNonExistent() {
    var history = KPSHistory(entries: [
        HistoryEntry(
            problemNumber: "1000",
            platform: .boj,
            filePath: "Sources/BOJ/1000.swift",
            timestamp: Date()
        )
    ])

    // 존재하지 않는 문제 번호로 markAsSolved 호출
    history.markAsSolved(problemNumber: "9999", platform: .boj)

    // 아무 변화 없어야 함
    #expect(history.entries[0].solved == false)
}
