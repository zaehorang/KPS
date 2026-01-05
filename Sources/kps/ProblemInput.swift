import Foundation

struct ProblemInput {
    let number: String
    let platform: Platform
    
    init?(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // BOJ URL: acmicpc.net/problem/12852
        if trimmed.contains("acmicpc.net/problem/") {
            let components = trimmed.components(separatedBy: "/problem/")
            if let last = components.last {
                let number = last.components(separatedBy: "/").first ?? last
                if number.allSatisfy({ $0.isNumber }) && !number.isEmpty {
                    self.number = number
                    self.platform = .boj
                    return
                }
            }
        }
        
        // Programmers URL: programmers.co.kr/.../lessons/389630
        if trimmed.contains("programmers.co.kr") && trimmed.contains("/lessons/") {
            let components = trimmed.components(separatedBy: "/lessons/")
            if let last = components.last {
                // ?language=swift 같은 쿼리 제거
                let number = last.components(separatedBy: "?").first ?? last
                if number.allSatisfy({ $0.isNumber }) && !number.isEmpty {
                    self.number = number
                    self.platform = .programmers
                    return
                }
            }
        }
        
        // 순수 숫자
        if trimmed.allSatisfy({ $0.isNumber }) && !trimmed.isEmpty {
            self.number = trimmed
            self.platform = .none
            return
        }
        
        return nil
    }
}
