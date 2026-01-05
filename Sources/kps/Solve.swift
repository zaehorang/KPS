import ArgumentParser
import Foundation

struct Solve: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Git add, commit, push after solving"
    )
    
    @Argument(help: "Problem number, URL, or file path")
    var input: String
    
    @Flag(name: .shortAndLong, help: "BOJ (Baekjoon)")
    var boj = false
    
    @Flag(name: .shortAndLong, help: "Programmers")
    var programmers = false
    
    @Option(name: .long, help: "Commit message prefix (default: 'add')")
    var prefix: String = "add"
    
    @Flag(name: .shortAndLong, help: "Commit only, no push")
    var noPush = false
    
    func run() {
        // 입력 파싱
        guard let problemInput = ProblemInput(input) else {
            print("❌ Invalid input: \(input)")
            return
        }
        
        // Platform 결정 (플래그 우선)
        let platform: Platform
        if boj {
            platform = .boj
        } else if programmers {
            platform = .programmers
        } else {
            platform = problemInput.platform
        }
        
        let problemNumber = problemInput.number
        
        // Config 로드
        guard let config = Config.load() else {
            print("❌ Config not found. Run 'kps init' first.")
            return
        }
        
        guard let configPath = Config.findConfigPath() else {
            print("❌ Config file not found.")
            return
        }
        
        // 파일 경로 설정
        let projectRoot = configPath.deletingLastPathComponent().deletingLastPathComponent()
        var sourceDir = projectRoot.appendingPathComponent(config.sourceFolder)
        
        if let folderName = platform.folderName {
            sourceDir = sourceDir.appendingPathComponent(folderName)
        }
        
        let filePath = sourceDir.appendingPathComponent("\(problemNumber).swift")
        
        // 파일 존재 확인
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            print("❌ File not found: \(filePath.path)")
            return
        }
        
        // git add
        print("📦 Adding file...")
        guard runGit(["add", filePath.path], at: projectRoot) else {
            return
        }
        
        // git commit
        let platformName = platform == .none ? "" : "[\(platform.name)] "
        let commitMessage = "\(prefix): \(platformName)\(problemNumber) solve"
        print("💾 Committing: \(commitMessage)")
        guard runGit(["commit", "-m", commitMessage], at: projectRoot) else {
            return
        }
        
        // git push
        if !noPush {
            print("🚀 Pushing...")
            guard runGit(["push"], at: projectRoot) else {
                return
            }
        }
        
        print("✅ Done!")
    }
    
    func runGit(_ arguments: [String], at directory: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                print("❌ Git failed: \(output)")
                return false
            }
            return true
        } catch {
            print("❌ Git error: \(error)")
            return false
        }
    }
}
