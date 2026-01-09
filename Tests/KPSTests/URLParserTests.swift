import Testing
@testable import kps

// MARK: - BOJ Tests

@Test("parse should extract problem number from BOJ URL")
func parseExtractsProblemNumberFromBOJURL() throws {
    let url = "https://acmicpc.net/problem/1000"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

@Test("parse should handle WWW prefix for BOJ")
func parseHandlesWWWPrefixForBOJ() throws {
    let url = "https://www.acmicpc.net/problem/1000"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

@Test("parse should handle HTTP for BOJ")
func parseHandlesHTTPForBOJ() throws {
    let url = "http://acmicpc.net/problem/1000"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

@Test("parse should parse BOJ short URL")
func parsesBOJShortURL() throws {
    let url = "https://boj.kr/1000"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

// MARK: - Programmers Tests

@Test("parse should parse Programmers canonical URL")
func parsesProgrammersCanonicalURL() throws {
    let url = "https://school.programmers.co.kr/learn/courses/30/lessons/340207"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "340207")
    #expect(problem.platform == .programmers)
}

@Test("parse should parse Programmers legacy URL")
func parsesProgrammersLegacyURL() throws {
    let url = "https://programmers.co.kr/learn/courses/30/lessons/340207"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "340207")
    #expect(problem.platform == .programmers)
}

@Test("parse should handle WWW prefix for Programmers")
func parsesHandlesWWWPrefixForProgrammers() throws {
    let url = "https://www.programmers.co.kr/learn/courses/30/lessons/340207"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "340207")
    #expect(problem.platform == .programmers)
}

// MARK: - URL Normalization Tests

@Test("parse should ignore query string")
func parseIgnoresQueryString() throws {
    let url = "https://school.programmers.co.kr/learn/courses/30/lessons/340207?itm_content=detail"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "340207")
    #expect(problem.platform == .programmers)
}

@Test("parse should ignore fragment")
func parseIgnoresFragment() throws {
    let url = "https://acmicpc.net/problem/1000#section"

    let problem = try URLParser.parse(url)

    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

// MARK: - Error Tests

@Test("parse should throw unsupportedURL for unknown domain")
func parseThrowsUnsupportedURLForUnknownDomain() {
    let url = "https://leetcode.com/problems/two-sum"

    #expect(throws: KPSError.unsupportedURL) {
        try URLParser.parse(url)
    }
}

@Test("parse should throw unsupportedURL for invalid path")
func parseThrowsUnsupportedURLForInvalidPath() {
    let url = "https://acmicpc.net/submit/1000"

    #expect(throws: KPSError.unsupportedURL) {
        try URLParser.parse(url)
    }
}

@Test("parse should throw unsupportedURL for missing problem number")
func parseThrowsUnsupportedURLForMissingProblemNumber() {
    let url = "https://acmicpc.net/problem/"

    #expect(throws: KPSError.unsupportedURL) {
        try URLParser.parse(url)
    }
}
