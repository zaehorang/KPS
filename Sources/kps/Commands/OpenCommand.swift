import ArgumentParser
import Foundation

/// 문제 파일을 시스템 기본 에디터로 열기
/// - 인자 없음: 최근 생성/수정한 파일 열기
/// - 번호 + 플랫폼: 특정 문제 파일 열기
struct OpenCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "open",
        abstract: "문제 파일 열기"
    )

    @Argument(help: "문제 번호 (생략 시 최근 파일 열기)")
    var number: String?

    @OptionGroup var platformOption: PlatformOption

    func run() throws {
        let (projectRoot, config) = try loadProjectConfig()

        let fileToOpen: URL
        if let number = number {
            // Specific file mode
            fileToOpen = try openSpecificFile(
                number: number,
                config: config,
                projectRoot: projectRoot
            )
        } else {
            // Recent file mode
            fileToOpen = try openRecentFile(
                config: config,
                projectRoot: projectRoot
            )
        }

        // Open with xed (Xcode project + file) or system default editor
        try executeOpenCommand(fileToOpen, projectRoot: projectRoot, config: config)

        // Success message
        Console.success("Opened: \(fileToOpen.path)")
    }

    // MARK: - Helpers

    /// 프로젝트 설정 로드
    /// - Returns: (projectRoot, config) 튜플
    /// - Throws: 설정 탐색/로드 실패 시 에러
    private func loadProjectConfig() throws -> (ProjectRoot, KPSConfig) {
        let projectRoot = try ConfigLocator.locate().get()
        let config = try KPSConfig.load(from: projectRoot.configPath)
        return (projectRoot, config)
    }

    /// 특정 문제 파일 열기 (번호 + 플랫폼 모드)
    /// - Parameters:
    ///   - number: 문제 번호
    ///   - config: 프로젝트 설정
    ///   - projectRoot: 프로젝트 루트
    /// - Returns: 열 파일 경로
    /// - Throws: 플랫폼 미지정 또는 파일 없음 에러
    private func openSpecificFile(
        number: String,
        config: KPSConfig,
        projectRoot: ProjectRoot
    ) throws -> URL {
        // 플랫폼 플래그 필수
        let platform = try platformOption.requirePlatform()

        // 하위 폴더 포함 파일 찾기
        let filePath = try findProblemFile(
            number: number,
            platform: platform,
            projectRoot: projectRoot.projectRoot,
            config: config
        )

        return filePath
    }

    /// 플랫폼 폴더 내에서 문제 파일 찾기 (하위 폴더 포함)
    /// - Parameters:
    ///   - number: 문제 번호
    ///   - platform: 플랫폼
    ///   - projectRoot: 프로젝트 루트
    ///   - config: 프로젝트 설정
    /// - Returns: 찾은 파일 경로
    /// - Throws: 플랫폼 폴더 없음, 파일 없음 에러
    /// - Note: 중복 파일 발견 시 첫 번째 파일 사용
    private func findProblemFile(
        number: String,
        platform: Platform,
        projectRoot: URL,
        config: KPSConfig
    ) throws -> URL {
        let platformDir = projectRoot
            .appendingPathComponent(config.sourceFolder)
            .appendingPathComponent(platform.folderName)

        let fileName = "\(number).swift"

        // 플랫폼 폴더 존재 확인
        guard FileManager.default.fileExists(atPath: platformDir.path) else {
            throw KPSError.file(.notFound(platformDir.path))
        }

        // 하위 폴더 포함 재귀 탐색
        guard let paths = FileManager.default.subpaths(atPath: platformDir.path) else {
            throw KPSError.file(.notFound(fileName))
        }

        // 파일명 매칭
        let matches = paths.filter { $0.hasSuffix(fileName) }

        guard !matches.isEmpty else {
            throw KPSError.file(.notFound(fileName))
        }

        // 중복 발견 시 경고 출력
        if matches.count > 1 {
            Console.warning("Multiple files found for \(number):")
            matches.forEach { Console.warning("  • \($0)") }
            Console.info("Using first match: \(matches[0])")
        }

        // 첫 번째 매칭 파일 사용
        let relativePath = matches[0]
        return platformDir.appendingPathComponent(relativePath)
    }

    /// 최근 파일 열기 (히스토리 기반)
    /// - Parameters:
    ///   - config: 프로젝트 설정
    ///   - projectRoot: 프로젝트 루트
    /// - Returns: 열 파일 경로
    /// - Throws: 히스토리 없음 또는 파일 삭제됨 에러
    private func openRecentFile(
        config: KPSConfig,
        projectRoot: ProjectRoot
    ) throws -> URL {
        let historyPath = projectRoot.projectRoot
            .appendingPathComponent(".kps")
            .appendingPathComponent("history.json")

        // 히스토리 파일 존재 확인
        guard FileManager.default.fileExists(atPath: historyPath.path) else {
            throw KPSError.history(.noRecentFile)
        }

        // 히스토리 로드
        let history = try KPSHistory.load(from: historyPath)

        // 가장 최근 항목 가져오기
        guard let recent = history.mostRecent() else {
            throw KPSError.history(.noRecentFile)
        }

        // 절대 경로 생성
        let filePath = projectRoot.projectRoot.appendingPathComponent(recent.filePath)

        // 파일이 여전히 존재하는지 확인 (삭제되었을 수 있음)
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            throw KPSError.history(.fileDeleted(filePath.path))
        }

        return filePath
    }

    /// 파일을 Xcode 프로젝트 또는 기본 에디터로 열기
    /// - Parameters:
    ///   - filePath: 열 파일 경로
    ///   - projectRoot: 프로젝트 루트
    ///   - config: 프로젝트 설정
    /// - Throws: 프로세스 실행 에러
    private func executeOpenCommand(
        _ filePath: URL,
        projectRoot: ProjectRoot,
        config: KPSConfig
    ) throws {
        // Xcode 프로젝트 경로 확인
        if let xcodeProj = config.xcodeProjectPath {
            let projectPath = projectRoot.projectRoot.appendingPathComponent(xcodeProj)

            // 프로젝트 파일 존재 확인
            guard FileManager.default.fileExists(atPath: projectPath.path) else {
                Console.warning("Xcode project not found: \(xcodeProj)")
                Console.info("Falling back to default editor...")
                try openWithSystemDefault(filePath: filePath)
                return
            }

            // xed 명령으로 프로젝트와 파일 함께 열기
            try openWithXed(projectPath: projectPath, filePath: filePath)
        } else {
            // Fallback: 파일만 기본 에디터로 열기
            try openWithSystemDefault(filePath: filePath)
        }
    }

    /// xed 명령으로 Xcode 프로젝트와 파일 열기
    /// - Parameters:
    ///   - projectPath: Xcode 프로젝트 경로
    ///   - filePath: 활성화할 파일 경로
    /// - Throws: xed 실행 실패 시 에러, command not found 시 fallback
    /// - Note: -p 플래그를 사용하여 프로젝트 컨텍스트 내에서 파일을 엽니다
    private func openWithXed(projectPath: URL, filePath: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["xed", "-p", projectPath.path, filePath.path]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"

            // xed 실패 시 fallback
            if errorMessage.contains("xed: command not found") || errorMessage.contains("not found") {
                Console.warning("xed not available. Install Xcode Command Line Tools.")
                Console.info("Falling back to default editor...")
                try openWithSystemDefault(filePath: filePath)
                return
            } else {
                throw KPSError.open(.commandFailed(errorMessage))
            }
        }
    }

    /// Fallback: 시스템 기본 에디터로 열기
    /// - Parameter filePath: 열 파일 경로
    /// - Throws: open 실행 실패 시 에러
    private func openWithSystemDefault(filePath: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["open", filePath.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw KPSError.open(.commandFailed("Failed to open file"))
        }
    }
}
