import ArgumentParser
import Foundation

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "View or update config"
    )
    
    @Flag(name: .shortAndLong, help: "Show all config values")
    var list = false
    
    @Argument(help: "Config key (author, project, source)")
    var key: String?
    
    @Argument(help: "New value")
    var value: String?
    
    func run() {
        guard let configPath = Config.findConfigPath() else {
            print("❌ Config not found. Run 'kps init' first.")
            return
        }
        
        guard var config = Config.load() else {
            print("❌ Failed to load config.")
            return
        }
        
        // --list: 설정 전체 출력
        if list {
            print("📋 Current config:")
            print("   author: \(config.author)")
            print("   project: \(config.projectName)")
            print("   source: \(config.sourceFolder)")
            return
        }
        
        // key만 있으면: 해당 값 출력
        // key + value 있으면: 값 업데이트
        guard let key = key else {
            print("Usage: kps config --list")
            print("       kps config <key>")
            print("       kps config <key> <value>")
            return
        }
        
        if let value = value {
            // 값 업데이트
            switch key {
            case "author":
                config.author = value
            case "project":
                config.projectName = value
            case "source":
                config.sourceFolder = value
            default:
                print("❌ Unknown key: \(key)")
                print("   Available keys: author, project, source")
                return
            }
            
            do {
                let directory = configPath.deletingLastPathComponent()
                try Config.save(config, at: directory)
                print("✅ Updated \(key) = \(value)")
            } catch {
                print("❌ Failed to save config: \(error)")
            }
        } else {
            // 값 출력
            switch key {
            case "author":
                print(config.author)
            case "project":
                print(config.projectName)
            case "source":
                print(config.sourceFolder)
            default:
                print("❌ Unknown key: \(key)")
                print("   Available keys: author, project, source")
            }
        }
    }
}
