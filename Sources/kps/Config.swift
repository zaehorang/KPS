import Foundation

struct Config: Codable {
    var author: String
    var projectName: String
    var sourceFolder: String
    
    static let folderName = ".kps"
    static let fileName = "config.json"
    
    static func findConfigPath() -> URL? {
        var currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        while currentDir.path != "/" {
            let configPath = currentDir
                .appendingPathComponent(folderName)
                .appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: configPath.path) {
                return configPath
            }
            currentDir = currentDir.deletingLastPathComponent()
        }
        
        return nil
    }
    
    static func load() -> Config? {
        guard let configPath = findConfigPath(),
              let data = try? Data(contentsOf: configPath) else {
            return nil
        }
        return try? JSONDecoder().decode(Config.self, from: data)
    }
    
    static func save(_ config: Config, at directory: URL) throws {
        let kpsFolder = directory.appendingPathComponent(folderName)
        let configPath = kpsFolder.appendingPathComponent(fileName)
        
        // .kps 폴더 생성
        try FileManager.default.createDirectory(
            at: kpsFolder,
            withIntermediateDirectories: true
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: configPath)
    }
}
