import ArgumentParser
import Foundation

/// 문제 풀이 완료 후 커밋 및 푸시 명령
/// Git add, commit, push를 자동으로 수행
struct SolveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "solve",
        abstract: "문제 풀이 커밋 및 푸시"
    )

    @Argument(help: "문제 번호")
    var number: String

    @OptionGroup var platformOption: PlatformOption

    @Flag(name: .long, help: "푸시하지 않고 커밋만 수행")
    var noPush = false

    @Option(name: .shortAndLong, help: "커밋 메시지 (기본값: solve: [Platform] {number})")
    var message: String?

    func run() throws {
        // 1. 문제 및 설정 로드
        let (problem, projectRoot, config) = try loadProblemContext()

        // 2. 파일 존재 확인
        let filePath = try validateProblemFile(problem: problem, config: config, projectRoot: projectRoot)

        // 3. Git 커밋
        let commitHash = try performGitCommit(problem: problem, filePath: filePath, projectRoot: projectRoot.projectRoot)

        // 4. Git 푸시 (옵션)
        try performGitPush(projectRoot: projectRoot.projectRoot, commitHash: commitHash)
    }

    /// 문제 정보와 프로젝트 설정 로드
    /// - Returns: (problem, projectRoot, config) 튜플
    /// - Throws: 플랫폼 결정, 설정 탐색/로드 실패 시 에러
    private func loadProblemContext() throws -> (Problem, ProjectRoot, KPSConfig) {
        let platform = try platformOption.requirePlatform()
        let problem = Problem(platform: platform, number: number)
        let projectRoot = try ConfigLocator.locate().get()
        let config = try KPSConfig.load(from: projectRoot.configPath)

        return (problem, projectRoot, config)
    }

    /// 문제 파일 경로 계산 및 존재 확인
    /// - Parameters:
    ///   - problem: 문제 정보
    ///   - config: 프로젝트 설정
    ///   - projectRoot: 프로젝트 루트
    /// - Returns: 검증된 파일 경로
    /// - Throws: 파일이 존재하지 않으면 KPSError.file(.notFound)
    private func validateProblemFile(
        problem: Problem,
        config: KPSConfig,
        projectRoot: ProjectRoot
    ) throws -> URL {
        let filePath = problem.filePath(projectRoot: projectRoot.projectRoot, config: config)

        guard FileManager.default.fileExists(atPath: filePath.path) else {
            throw KPSError.file(.notFound(filePath.path))
        }

        return filePath
    }

    /// Git add 및 commit 수행
    /// - Parameters:
    ///   - problem: 문제 정보 (커밋 메시지 생성용)
    ///   - filePath: 커밋할 파일 경로
    ///   - projectRoot: Git 저장소 루트
    /// - Returns: 생성된 커밋 해시
    /// - Throws: Git 명령 실패 시 에러
    private func performGitCommit(
        problem: Problem,
        filePath: URL,
        projectRoot: URL
    ) throws -> String {
        // Git preflight check
        try GitExecutor.checkPreflight(at: projectRoot)

        // Git add
        Console.info("Adding file to git...", icon: "📦")
        try GitExecutor.add(file: filePath, at: projectRoot)

        // Git commit
        let commitMessage = message ?? generateCommitMessage(for: problem)
        Console.info("Committing changes...", icon: "💾")
        let hash = try GitExecutor.commit(message: commitMessage, at: projectRoot)
        Console.info("Commit: \(hash)")

        return hash
    }

    /// Git push 수행 (--no-push 플래그에 따라)
    /// - Parameters:
    ///   - projectRoot: Git 저장소 루트
    ///   - commitHash: 커밋 해시 (로그용)
    /// - Throws: Push 실패 시 에러 (사용자 친화적 메시지 출력 후)
    private func performGitPush(projectRoot: URL, commitHash: String) throws {
        if noPush {
            Console.success("Done! (push skipped)")
            return
        }

        do {
            Console.info("Pushing to remote...", icon: "🚀")
            try GitExecutor.push(at: projectRoot)
            Console.success("Done!")
        } catch {
            displayPushErrorGuidance()
            throw error
        }
    }

    /// Push 실패 시 사용자 안내 메시지 출력
    private func displayPushErrorGuidance() {
        Console.warning("Commit succeeded, but push failed.")
        Console.warning("Possible causes:")
        Console.warning("  • No remote configured: run 'git remote -v'")
        Console.warning("  • Authentication issue: check your credentials or SSH key")
        Console.warning("To complete: run 'git push' manually")
    }

    /// 기본 커밋 메시지 생성
    /// - Parameter problem: 문제 정보
    /// - Returns: 형식: "solve: [Platform] {number}"
    private func generateCommitMessage(for problem: Problem) -> String {
        let platformName = problem.platform == .boj ? "BOJ" : "Programmers"
        return "solve: [\(platformName)] \(problem.number)"
    }
}
