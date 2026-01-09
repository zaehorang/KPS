import Foundation

/// KPS project configuration model
struct KPSConfig: Codable {
    var author: String
    var sourceFolder: String
    var projectName: String

    /// Saves config to JSON file with atomic write
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
