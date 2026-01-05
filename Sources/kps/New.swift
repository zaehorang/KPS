import ArgumentParser
import Foundation

struct New: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create new problem file"
    )
    
    @Argument(help: "Problem number or URL")
    var input: String
    
    @Flag(name: .shortAndLong, help: "BOJ (Baekjoon)")
    var boj = false
    
    @Flag(name: .shortAndLong, help: "Programmers")
    var programmers = false
    
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
        
        // 경로 설정
        let projectRoot = configPath.deletingLastPathComponent().deletingLastPathComponent()
        var sourceDir = projectRoot.appendingPathComponent(config.sourceFolder)
        
        // 플랫폼별 폴더 추가
        if let folderName = platform.folderName {
            sourceDir = sourceDir.appendingPathComponent(folderName)
        }
        
        let filePath = sourceDir.appendingPathComponent("\(problemNumber).swift")
        
        // 중복 확인
        if FileManager.default.fileExists(atPath: filePath.path) {
            print("⚠️  \(problemNumber).swift already exists.")
            return
        }
        
        // 디렉토리 생성
        do {
            try FileManager.default.createDirectory(
                at: sourceDir,
                withIntermediateDirectories: true
            )
        } catch {
            print("❌ Failed to create directory: \(error)")
            return
        }
        
        // 파일 생성
        let content = generateTemplate(config: config, platform: platform, problemNumber: problemNumber)
        
        do {
            try content.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Created: \(filePath.path)")
            if let url = platform.problemURL(problemNumber) {
                print("🔗 \(url)")
            }
        } catch {
            print("❌ Failed to create file: \(error)")
        }
    }
    
    func generateTemplate(config: Config, platform: Platform, problemNumber: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M/d"
        let dateString = dateFormatter.string(from: Date())
        
        var lines = [
            "//",
            "//  \(problemNumber).swift",
            "//  \(config.projectName)",
            "//",
            "//  Created by \(config.author) on \(dateString)."
        ]
        
        if let url = platform.problemURL(problemNumber) {
            lines.append("//  \(url)")
        }
        
        lines.append("//")
        lines.append("")
        lines.append("func _\(problemNumber)() {")
        lines.append("    ")
        lines.append("}")
        
        return lines.joined(separator: "\n")
    }
}
