import Foundation

/// Swift 파일 템플릿 생성 및 변수 치환
enum Template {
    /// Swift 문제 풀이 파일 템플릿
    /// 변수: {number}, {projectName}, {author}, {date}, {url}, {functionName}
    private static let swiftTemplate = """
    //
    // {number}.swift
    // {projectName}
    //
    // Created by {author} on {date}.
    // {url}
    //

    import Foundation

    func {functionName}() {
        // Your solution here
    }

    """

    /// 문제 풀이 파일 내용을 생성
    /// - Parameters:
    ///   - problem: 문제 정보 (플랫폼, 번호)
    ///   - config: 프로젝트 설정 (작성자, 프로젝트명)
    /// - Returns: 템플릿 변수가 치환된 Swift 파일 내용
    static func generate(for problem: Problem, config: KPSConfig) -> String {
        let date = DateFormatter.kpsDateFormatter.string(from: Date())

        return swiftTemplate
            .replacingOccurrences(of: "{number}", with: problem.number)
            .replacingOccurrences(of: "{projectName}", with: config.projectName)
            .replacingOccurrences(of: "{author}", with: config.author)
            .replacingOccurrences(of: "{date}", with: date)
            .replacingOccurrences(of: "{url}", with: problem.url)
            .replacingOccurrences(of: "{functionName}", with: problem.functionName)
    }
}
