import ArgumentParser
import Foundation

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create config file"
    )
    
    @Option(name: .shortAndLong, help: "Author name")
    var author: String?
    
    @Option(name: .shortAndLong, help: "Project name")
    var project: String?
    
    @Option(name: .shortAndLong, help: "Source folder name")
    var source: String?
    
    func run() {
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        let configPath = currentDir.appendingPathComponent(Config.fileName)
        if FileManager.default.fileExists(atPath: configPath.path) {
            print("⚠️  \(Config.fileName) already exists.")
            return
        }
        
        // 기본값 설정
        let folderName = currentDir.lastPathComponent
        let authorName = author ?? "KPS"
        let projectName = project ?? folderName
        let sourceFolder = source ?? folderName
        
        let config = Config(
            author: authorName,
            projectName: projectName,
            sourceFolder: sourceFolder
        )
        
        do {
            try Config.save(config, at: currentDir)
            print("✅ Config created!")
            print("   File: \(configPath.path)")
            print("   Author: \(authorName)")
            print("   Project: \(projectName)")
            print("   Source folder: \(sourceFolder)")
        } catch {
            print("❌ Failed to save config: \(error)")
        }
    }
}
