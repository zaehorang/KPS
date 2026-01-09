import Foundation

/// Parses problem solving platform URLs (BOJ, Programmers)
enum URLParser {
    /// Parses URL string and extracts platform and problem number
    /// - Throws: `KPSError.unsupportedURL` for invalid or unsupported URLs
    static func parse(_ urlString: String) throws -> Problem {
        guard let url = URL(string: urlString),
              let host = url.host else {
            throw KPSError.unsupportedURL
        }

        // Remove "www." prefix for normalization
        let normalizedHost = host.replacingOccurrences(of: "www.", with: "")
        let path = url.path

        if normalizedHost == "acmicpc.net" {
            return try parseBOJ(path: path)
        } else if normalizedHost == "boj.kr" {
            return try parseBOJShort(path: path)
        } else if normalizedHost == "school.programmers.co.kr" || normalizedHost == "programmers.co.kr" {
            return try parseProgrammers(path: path)
        } else {
            throw KPSError.unsupportedURL
        }
    }

    /// Parses BOJ URL path (format: /problem/{number})
    /// - Parameter path: URL path component
    /// - Returns: Parsed Problem instance
    /// - Throws: KPSError.unsupportedURL if path format is invalid
    private static func parseBOJ(path: String) throws -> Problem {
        let components = path.split(separator: "/")

        guard components.count == 2,
              components[0] == "problem",
              !components[1].isEmpty else {
            throw KPSError.unsupportedURL
        }

        return Problem(platform: .boj, number: String(components[1]))
    }

    /// Parses BOJ short URL path (format: /{number})
    /// - Parameter path: URL path component
    /// - Returns: Parsed Problem instance
    /// - Throws: KPSError.unsupportedURL if path format is invalid
    private static func parseBOJShort(path: String) throws -> Problem {
        let components = path.split(separator: "/")

        guard components.count == 1,
              !components[0].isEmpty else {
            throw KPSError.unsupportedURL
        }

        return Problem(platform: .boj, number: String(components[0]))
    }

    /// Parses Programmers URL path (format: /learn/courses/30/lessons/{number})
    /// - Parameter path: URL path component
    /// - Returns: Parsed Problem instance
    /// - Throws: KPSError.unsupportedURL if path format is invalid
    private static func parseProgrammers(path: String) throws -> Problem {
        let components = path.split(separator: "/")

        // Course ID "30" represents the coding test practice course
        guard components.count >= 4,
              components[0] == "learn",
              components[1] == "courses",
              components[2] == "30",
              components[3] == "lessons",
              components.count >= 5,
              !components[4].isEmpty else {
            throw KPSError.unsupportedURL
        }

        return Problem(platform: .programmers, number: String(components[4]))
    }
}
