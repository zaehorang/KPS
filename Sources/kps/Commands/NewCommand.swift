import ArgumentParser
import Foundation

/// 문제 풀이 파일 생성 명령
/// URL 또는 문제 번호 + 플랫폼 플래그로 파일을 생성
struct NewCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "문제 풀이 파일 생성"
    )

    @Argument(help: "문제 URL 또는 문제 번호")
    var input: String

    @OptionGroup var platformOption: PlatformOption

    func run() throws {
        // 1. 입력 파싱 (URL 또는 문제 번호)
        let problem = try parseInput()

        // 2. 프로젝트 설정 로드
        let (projectRoot, config) = try loadProjectConfig()

        // 3. 파일 경로 계산 및 검증
        let filePath = try prepareFilePath(for: problem, config: config, projectRoot: projectRoot)

        // 4. 파일 생성
        try createProblemFile(problem: problem, config: config, at: filePath)

        // 5. 성공 메시지 출력
        displaySuccessMessage(for: problem, at: filePath)
    }

    /// 입력 문자열을 파싱하여 Problem 객체 생성
    /// - Returns: 파싱된 Problem 인스턴스
    /// - Throws: URL/플랫폼 검증 실패 시 에러
    private func parseInput() throws -> Problem {
        if looksLikeURL(input) {
            // URL 형태인 경우: 플래그가 있으면 에러
            if platformOption.boj || platformOption.programmers {
                throw KPSError.platform(.urlWithPlatformFlag)
            }
            return try URLParser.parse(input)
        } else {
            // 문제 번호 형태인 경우: 플래그로 플랫폼 결정
            let platform = try platformOption.requirePlatform()
            return Problem(platform: platform, number: input)
        }
    }

    /// 프로젝트 루트와 설정 로드
    /// - Returns: (projectRoot, config) 튜플
    /// - Throws: 설정 탐색/로드 실패 시 에러
    private func loadProjectConfig() throws -> (ProjectRoot, KPSConfig) {
        let projectRoot = try ConfigLocator.locate().get()
        let config = try KPSConfig.load(from: projectRoot.configPath)
        return (projectRoot, config)
    }

    /// 파일 경로 계산 및 존재 확인
    /// - Parameters:
    ///   - problem: 문제 정보
    ///   - config: 프로젝트 설정
    ///   - projectRoot: 프로젝트 루트
    /// - Returns: 생성할 파일의 경로
    /// - Throws: 파일이 이미 존재하면 에러
    private func prepareFilePath(
        for problem: Problem,
        config: KPSConfig,
        projectRoot: ProjectRoot
    ) throws -> URL {
        let filePath = problem.filePath(projectRoot: projectRoot.projectRoot, config: config)

        let fileManager = FileManager.default
        try fileManager.ensureFileDoesNotExist(at: filePath)

        return filePath
    }

    /// 디렉토리 생성 및 템플릿 파일 작성
    /// - Parameters:
    ///   - problem: 문제 정보
    ///   - config: 프로젝트 설정
    ///   - filePath: 생성할 파일 경로
    /// - Throws: 디렉토리 생성 또는 파일 쓰기 실패 시 에러
    private func createProblemFile(
        problem: Problem,
        config: KPSConfig,
        at filePath: URL
    ) throws {
        let fileManager = FileManager.default

        // 디렉토리 생성
        let sourceDir = filePath.deletingLastPathComponent()
        try fileManager.createDirectoryIfNeeded(at: sourceDir)

        // 템플릿 생성 및 파일 작성
        let content = Template.generate(for: problem, config: config)
        try fileManager.writeFile(content: content, to: filePath)
    }

    /// 파일 생성 성공 메시지 및 다음 행동 가이드 출력
    /// - Parameters:
    ///   - problem: 생성된 문제 정보
    ///   - filePath: 파일 경로
    private func displaySuccessMessage(for problem: Problem, at filePath: URL) {
        Console.success("File created!")
        Console.info("File: \(filePath.path)", icon: "📦")
        Console.info("URL: \(problem.url)", icon: "🔗")

        // 다음 행동 가이드
        let platformFlag = problem.platform == .boj ? "-b" : "-p"
        Console.info("Next: solve with 'kps solve \(problem.number) \(platformFlag)'", icon: "💡")
    }

    /// 문자열이 URL 형태인지 판단
    /// - Parameter string: 검사할 문자열
    /// - Returns: http(s):// 또는 www.로 시작하면 true
    private func looksLikeURL(_ string: String) -> Bool {
        string.hasPrefix("http://") ||
        string.hasPrefix("https://") ||
        string.hasPrefix("www.")
    }
}
