import ArgumentParser

/// BOJ와 Programmers 플랫폼 선택을 위한 옵션 그룹
/// -b/--boj 또는 -p/--programmers 플래그로 플랫폼을 지정할 수 있음
struct PlatformOption: ParsableArguments {
    @Flag(name: .shortAndLong, help: "BOJ 플랫폼 선택")
    var boj = false

    @Flag(name: .shortAndLong, help: "Programmers 플랫폼 선택")
    var programmers = false

    /// 플래그를 Platform으로 해석
    /// - Returns: Platform (boj, programmers) 또는 nil (플래그 없음)
    /// - Throws: 두 플래그가 모두 설정된 경우 KPSError.platform(.conflictingFlags)
    func resolve() throws -> Platform? {
        if boj && programmers {
            throw KPSError.platform(.conflictingFlags)
        }
        if boj {
            return .boj
        }
        if programmers {
            return .programmers
        }
        return nil
    }

    /// Platform을 반환하거나 없으면 에러
    /// - Returns: Platform (boj, programmers)
    /// - Throws: 플래그가 없는 경우 KPSError.platform(.platformRequired)
    func requirePlatform() throws -> Platform {
        guard let platform = try resolve() else {
            throw KPSError.platform(.platformRequired)
        }
        return platform
    }
}
