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
        // 1. 경로 계산
        let (kpsDirectory, configPath, projectName) = try calculatePaths()

        // 2. 기존 설정 확인
        try checkExistingConfig(at: configPath)

        // 3. 디렉토리 생성
        try createKPSDirectory(at: kpsDirectory)

        // 4. 설정 생성 및 저장
        try createAndSaveConfig(projectName: projectName, to: configPath)

        // 5. 성공 메시지
        displaySuccessMessage(projectName: projectName)
    }

    /// .kps 디렉토리와 config.json 경로 계산
    /// - Returns: (kpsDirectory, configPath, projectName) 튜플
    private func calculatePaths() throws -> (URL, URL, String) {
        let fileManager = FileManager.default
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let projectName = currentDirectory.lastPathComponent
        let kpsDirectory = currentDirectory.appendingPathComponent(".kps")
        let configPath = kpsDirectory.appendingPathComponent("config.json")

        return (kpsDirectory, configPath, projectName)
    }

    /// 기존 설정 파일이 있는지 확인
    /// - Parameter configPath: 설정 파일 경로
    /// - Throws: force 플래그 없이 기존 설정이 있으면 KPSError.config(.alreadyExists)
    private func checkExistingConfig(at configPath: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: configPath.path) && !force {
            throw KPSError.config(.alreadyExists)
        }
    }

    /// .kps 디렉토리 생성
    /// - Parameter kpsDirectory: 생성할 디렉토리 경로
    /// - Throws: 권한 오류 등 파일 시스템 에러
    private func createKPSDirectory(at kpsDirectory: URL) throws {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(
                at: kpsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch let error as NSError {
            throw KPSError.from(error)
        }
    }

    /// 설정 객체 생성 및 저장
    /// - Parameters:
    ///   - projectName: 프로젝트 이름
    ///   - configPath: 저장할 경로
    /// - Throws: 저장 실패 시 에러
    private func createAndSaveConfig(projectName: String, to configPath: URL) throws {
        let config = KPSConfig(
            author: author,
            sourceFolder: source,
            projectName: projectName
        )
        try config.save(to: configPath)
    }

    /// 초기화 성공 메시지 출력
    /// - Parameter projectName: 프로젝트 이름
    private func displaySuccessMessage(projectName: String) {
        Console.success("KPS initialized!")
        Console.info("Project: \(projectName)")
        Console.info("Author: \(author)")
        Console.info("Source folder: \(source)")
        Console.info("Config saved to: .kps/config.json", icon: "💾")
    }
}
