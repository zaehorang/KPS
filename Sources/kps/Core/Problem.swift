import Foundation

/// 특정 플랫폼의 문제를 나타냄
struct Problem {
    let platform: Platform
    let number: String

    var url: String {
        platform.baseURL + number
    }

    var fileName: String {
        "\(number).swift"
    }

    /// 문제 풀이 함수 이름
    /// - BOJ: solve{number}
    /// - Programmers: solution{number}
    var functionName: String {
        switch platform {
        case .boj:
            return "solve\(number)"
        case .programmers:
            return "solution\(number)"
        }
    }

    /// 파일의 전체 경로 계산
    /// - Parameters:
    ///   - projectRoot: 프로젝트 루트 디렉토리
    ///   - config: 프로젝트 설정 (sourceFolder 정보 포함)
    /// - Returns: 문제 파일의 전체 경로
    func filePath(projectRoot: URL, config: KPSConfig) -> URL {
        projectRoot
            .appendingPathComponent(config.sourceFolder)
            .appendingPathComponent(platform.folderName)
            .appendingPathComponent(fileName)
    }

    /// 파일이 위치할 소스 디렉토리 경로
    /// - Parameters:
    ///   - projectRoot: 프로젝트 루트 디렉토리
    ///   - config: 프로젝트 설정 (sourceFolder 정보 포함)
    /// - Returns: 플랫폼별 소스 디렉토리 경로
    func sourceDirectory(projectRoot: URL, config: KPSConfig) -> URL {
        projectRoot
            .appendingPathComponent(config.sourceFolder)
            .appendingPathComponent(platform.folderName)
    }
}
