import Foundation

enum Platform: String, Codable {
    case boj
    case programmers
    case none
    
    var name: String {
        switch self {
        case .boj:
            return "BOJ"
        case .programmers:
            return "Programmers"
        case .none:
            return ""
        }
    }
    
    var folderName: String? {
        switch self {
        case .boj:
            return "BOJ"
        case .programmers:
            return "Programmers"
        case .none:
            return nil
        }
    }
    
    func problemURL(_ number: String) -> String? {
        switch self {
        case .boj:
            return "https://acmicpc.net/problem/\(number)"
        case .programmers:
            return "https://school.programmers.co.kr/learn/courses/30/lessons/\(number)"
        case .none:
            return nil
        }
    }
}
