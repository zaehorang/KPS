import Testing
import Foundation
@testable import kps

/// Template 변수 치환 및 날짜 포맷 테스트
@Suite("Template Tests")
struct TemplateTests {
    /// BOJ 문제에 대한 템플릿 변수 치환 테스트
    @Test("generate should substitute all variables for BOJ problem")
    func generateSubstitutesVariablesForBOJ() throws {
        // Given
        let problem = Problem(platform: .boj, number: "1000")
        let config = KPSConfig(
            author: "Test Author",
            sourceFolder: "Sources",
            projectName: "TestProject"
        )

        // When
        let content = Template.generate(for: problem, config: config)

        // Then
        #expect(content.contains("1000.swift"))
        #expect(content.contains("TestProject"))
        #expect(content.contains("Test Author"))
        #expect(content.contains("https://acmicpc.net/problem/1000"))
        #expect(content.contains("func solve1000()"))
    }

    /// Programmers 문제에 대한 템플릿 변수 치환 테스트
    @Test("generate should substitute all variables for Programmers problem")
    func generateSubstitutesVariablesForProgrammers() throws {
        // Given
        let problem = Problem(platform: .programmers, number: "340207")
        let config = KPSConfig(
            author: "Test Author",
            sourceFolder: "Sources",
            projectName: "TestProject"
        )

        // When
        let content = Template.generate(for: problem, config: config)

        // Then
        #expect(content.contains("340207.swift"))
        #expect(content.contains("TestProject"))
        #expect(content.contains("Test Author"))
        #expect(content.contains("https://school.programmers.co.kr/learn/courses/30/lessons/340207"))
        #expect(content.contains("func solution340207()"))
    }

    /// Programmers URL이 school.programmers.co.kr로 정규화되는지 확인
    @Test("generate should use canonical Programmers URL (school.programmers.co.kr)")
    func generateUsesCanonicalProgrammersURL() throws {
        // Given
        let problem = Problem(platform: .programmers, number: "340207")
        let config = KPSConfig(
            author: "Test",
            sourceFolder: "Sources",
            projectName: "Test"
        )

        // When
        let content = Template.generate(for: problem, config: config)

        // Then - school 서브도메인이 포함되어야 함
        #expect(content.contains("school.programmers.co.kr"))
    }

    /// 날짜 포맷 테스트 (yyyy/M/d 형식)
    @Test("generate should format date as yyyy/M/d")
    func generateFormatsDateCorrectly() throws {
        // Given
        let problem = Problem(platform: .boj, number: "1000")
        let config = KPSConfig(
            author: "Test",
            sourceFolder: "Sources",
            projectName: "Test"
        )

        // When
        let content = Template.generate(for: problem, config: config)

        // Then - 날짜 형식이 yyyy/M/d인지 확인 (예: 2026/1/10)
        let datePattern = #/\d{4}/\d{1,2}/\d{1,2}/#
        #expect(content.contains(datePattern))
    }

    /// 함수명 생성 테스트 (BOJ)
    @Test("generate should create correct function name for BOJ")
    func generateCreatesCorrectFunctionNameForBOJ() throws {
        // Given
        let problem = Problem(platform: .boj, number: "12345")
        let config = KPSConfig(
            author: "Test",
            sourceFolder: "Sources",
            projectName: "Test"
        )

        // When
        let content = Template.generate(for: problem, config: config)

        // Then
        #expect(content.contains("func solve12345()"))
    }

    /// 함수명 생성 테스트 (Programmers)
    @Test("generate should create correct function name for Programmers")
    func generateCreatesCorrectFunctionNameForProgrammers() throws {
        // Given
        let problem = Problem(platform: .programmers, number: "12345")
        let config = KPSConfig(
            author: "Test",
            sourceFolder: "Sources",
            projectName: "Test"
        )

        // When
        let content = Template.generate(for: problem, config: config)

        // Then
        #expect(content.contains("func solution12345()"))
    }
}
