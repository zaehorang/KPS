import ArgumentParser
import Foundation

/// 설정 조회 및 수정 명령
/// - 인자 0개: 전체 설정 조회
/// - 인자 1개: 특정 키 값 조회
/// - 인자 2개: 키-값 수정
struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "설정 조회 및 수정"
    )

    @Argument(help: "설정 키 (선택 사항)")
    var key: String?

    @Argument(help: "설정 값 (선택 사항)")
    var value: String?

    func run() throws {
        // 1. 프로젝트 루트 찾기
        let projectRoot = try ConfigLocator.locate().get()

        // 2. 설정 로드
        let config = try KPSConfig.load(from: projectRoot.configPath)

        // 3. 인자 개수에 따른 분기
        switch (key, value) {
        case (nil, nil):
            // 전체 조회
            displayAllConfig(config)

        case let (key?, nil):
            // 특정 값 조회
            try displayConfigValue(for: key, in: config)

        case let (key?, value?):
            // 값 수정
            try updateConfigValue(key: key, value: value, at: projectRoot.configPath)

        case (nil, .some):
            // 불가능한 경우 (값만 있고 키가 없음)
            fatalError("ArgumentParser should prevent this case")
        }
    }

    /// 전체 설정 출력
    private func displayAllConfig(_ config: KPSConfig) {
        Console.info("author: \(config.author)")
        Console.info("sourceFolder: \(config.sourceFolder)")
        Console.info("projectName: \(config.projectName)")
        if let xcodeProj = config.xcodeProjectPath {
            Console.info("xcodeProjectPath: \(xcodeProj)")
        }
    }

    /// 특정 키의 값 출력
    private func displayConfigValue(for key: String, in config: KPSConfig) throws {
        let configKey = try ConfigKey.from(key)
        let value = config.value(for: configKey)
        print(value)
    }

    /// 설정 값 수정
    private func updateConfigValue(key: String, value: String, at configPath: URL) throws {
        // 키 검증
        let configKey = try ConfigKey.from(key)

        // 기존 설정 로드
        var config = try KPSConfig.load(from: configPath)

        // 값 업데이트
        config.setValue(value, for: configKey)

        // 저장
        try config.save(to: configPath)

        // 성공 메시지
        Console.success("Config updated!")
        Console.info("\(configKey.rawValue): \(value)")
    }
}
