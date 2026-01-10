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
        // 1. 입력이 URL인지 문제 번호인지 판단
        let problem: Problem
        if looksLikeURL(input) {
            // URL 형태인 경우: 플래그가 있으면 에러
            if platformOption.boj || platformOption.programmers {
                throw KPSError.platform(.urlWithPlatformFlag)
            }
            // URL 파싱 (에러를 삼키지 않음)
            problem = try URLParser.parse(input)
        } else {
            // 문제 번호 형태인 경우: 플래그로 플랫폼 결정
            let platform = try platformOption.requirePlatform()
            problem = Problem(platform: platform, number: input)
        }

        // 2. 프로젝트 루트 찾기
        let projectRoot = try ConfigLocator.locate().get()

        // 3. 설정 로드
        let config = try KPSConfig.load(from: projectRoot.configPath)

        // 4. 파일 경로 계산
        let sourceDir = projectRoot.projectRoot
            .appendingPathComponent(config.sourceFolder)
            .appendingPathComponent(problem.platform.folderName)
        let filePath = sourceDir.appendingPathComponent(problem.fileName)

        // 5. 파일이 이미 존재하는지 확인
        let fileManager = FileManager.default
        try fileManager.ensureFileDoesNotExist(at: filePath)

        // 6. 디렉토리 생성
        try fileManager.createDirectoryIfNeeded(at: sourceDir)

        // 7. 템플릿 생성 및 파일 작성
        let content = Template.generate(for: problem, config: config)
        try fileManager.writeFile(content: content, to: filePath)

        // 8. 성공 메시지 및 안내
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
