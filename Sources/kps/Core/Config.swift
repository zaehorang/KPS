import Foundation

/// KPS project configuration model
struct KPSConfig: Codable {
    var author: String
    var sourceFolder: String
    var projectName: String

    /// Saves config to JSON file with atomic write
    /// - Parameter url: File URL where config will be saved
    /// - Throws: KPSError.fileIOError on encoding or write failure
    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(self)
            // Atomic write ensures all-or-nothing behavior
            try data.write(to: url, options: .atomic)
        } catch let error as EncodingError {
            throw KPSError.fileIOError(error)
        } catch {
            throw KPSError.fileIOError(error)
        }
    }

    /// Loads config from JSON file
    /// - Parameter url: File URL to read config from
    /// - Returns: Parsed KPSConfig instance
    /// - Throws: KPSError.configParseError on decode failure, KPSError.fileIOError on read failure
    static func load(from url: URL) throws -> KPSConfig {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(KPSConfig.self, from: data)
        } catch let error as DecodingError {
            // Convert DecodingError to configParseError for better error messages
            throw KPSError.configParseError(error.localizedDescription)
        } catch {
            throw KPSError.fileIOError(error)
        }
    }
}
