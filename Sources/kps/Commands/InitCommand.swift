import ArgumentParser
import Foundation

/// KPS 프로젝트 초기화 명령
/// 현재 디렉토리에 .kps 디렉토리와 설정 파일을 생성
struct InitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "현재 디렉토리를 KPS 프로젝트로 초기화"
    )

    @Option(name: .shortAndLong, help: "작성자 이름")
    var author: String

    @Option(name: .shortAndLong, help: "소스 코드 폴더 이름 (기본값: Sources)")
    var source: String = "Sources"

    @Flag(name: .long, help: "기존 설정을 덮어쓰기")
    var force = false

    func run() throws {
        let fileManager = FileManager.default
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        // 현재 디렉토리 이름을 프로젝트 이름으로 사용
        let projectName = currentDirectory.lastPathComponent

        // .kps 디렉토리 경로
        let kpsDirectory = currentDirectory.appendingPathComponent(".kps")
        let configPath = kpsDirectory.appendingPathComponent("config.json")

        // 기존 설정 확인
        if fileManager.fileExists(atPath: configPath.path) && !force {
            throw KPSError.config(.alreadyExists)
        }

        // .kps 디렉토리 생성
        do {
            try fileManager.createDirectory(
                at: kpsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch let error as NSError {
            throw KPSError.from(error)
        }

        // 설정 생성 및 저장
        let config = KPSConfig(
            author: author,
            sourceFolder: source,
            projectName: projectName
        )

        try config.save(to: configPath)

        // 성공 메시지
        Console.success("KPS initialized!")
        Console.info("Project: \(projectName)")
        Console.info("Author: \(author)")
        Console.info("Source folder: \(source)")
        Console.info("Config saved to: .kps/config.json", icon: "💾")
    }
}
