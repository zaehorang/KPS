# KPS (Korean Problem Solving) - Agent Guidelines

## 프로젝트 개요

KPS는 알고리즘 문제 풀이를 정돈된 개발 기록으로 남기게 해주는 Swift CLI 도구입니다.

**핵심 명령어:**
- `kps init` - 프로젝트 초기화
- `kps new` - 문제 파일 생성
- `kps solve` - Git commit & push
- `kps config` - 설정 관리

**지원 플랫폼:**
- BOJ (acmicpc.net, boj.kr)
- Programmers (school.programmers.co.kr, programmers.co.kr)

## 기술 스택

| 구성 요소 | 선택 |
|-----------|------|
| 언어 | Swift 5.9+ |
| CLI 프레임워크 | ArgumentParser |
| 테스트 프레임워크 | Swift Testing |
| 패키지 관리 | SPM |
| Git 연동 | Process (shell) |

## 프로젝트 구조

```
KPS/
├── Package.swift
├── Sources/
│   └── KPS/
│       ├── main.swift
│       ├── Commands/
│       │   ├── InitCommand.swift
│       │   ├── NewCommand.swift
│       │   ├── SolveCommand.swift
│       │   ├── ConfigCommand.swift
│       │   └── PlatformOption.swift
│       ├── Core/
│       │   ├── KPSError.swift
│       │   ├── Config.swift
│       │   ├── ConfigKey.swift
│       │   ├── ConfigLocator.swift
│       │   ├── Platform.swift
│       │   ├── Problem.swift
│       │   ├── URLParser.swift
│       │   ├── Template.swift
│       │   ├── FileManager+KPS.swift
│       │   └── GitExecutor.swift
│       └── Utils/
│           ├── Console.swift
│           └── DateFormatter+KPS.swift
└── Tests/
    └── KPSTests/
        ├── URLParserTests.swift
        ├── ConfigTests.swift
        ├── ConfigLocatorTests.swift
        └── TemplateTests.swift
```

## 코딩 컨벤션

### Swift 스타일
- Swift API Design Guidelines 준수
- `guard let` 적극 활용 (early return)
- `Result` 타입으로 에러 전파 (ConfigLocator)
- `throws`로 에러 전파 (Commands, Parsers)

### 네이밍
- 파일: `PascalCase.swift`
- 타입: `PascalCase`
- 함수/변수: `camelCase`
- 상수: `camelCase` (Swift 컨벤션)

### 에러 처리
```swift
// 모든 에러는 KPSError로 통일
enum KPSError: LocalizedError {
    case configNotFound
    // ...
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Config not found. Run 'kps init' first."
        // ...
        }
    }
}
```

### Console 출력
```swift
// stdout: success, info
// stderr: warning, error
Console.success("Done!")           // ✅
Console.info("File created")       // ✔
Console.warning("Push failed")     // ⚠️ (stderr)
Console.error("Config not found")  // ❌ (stderr)
```

## 문서화 규칙

### 주석 작성 원칙
- 복잡한 로직에는 설명 주석 필수
- Public API에는 Swift 문서화 주석 (`///`) 필수
- 자명한 코드에는 주석 불필요 (코드 자체가 문서)
- 간결하게 작성 (필요한 내용만)

### Swift 문서화 주석 스타일
```swift
/// Brief one-line summary
///
/// Additional details if needed
/// - Parameter name: Parameter description
/// - Returns: Return value description
/// - Throws: Error conditions
func example(name: String) throws -> Result
```

### 주석이 필요한 경우
1. **복잡한 알고리즘**: 디렉토리 순회, URL 파싱 등
2. **비자명한 설계 결정**: POSIX locale 사용, atomic write 사용
3. **Public API**: 외부에서 호출하는 타입과 메서드
4. **특수한 에러 처리**: 에러 타입 변환, 특수한 비교 로직
5. **매직 넘버/문자열**: 하드코딩된 값의 이유

### 주석이 불필요한 경우
- 자명한 Getter/Setter
- 단순한 변수 선언
- 이름만으로 충분히 설명되는 함수

### 예시

**좋은 예:**
```swift
/// Parses BOJ URL path (format: /problem/{number})
private static func parseBOJ(path: String) throws -> Problem {
    // Course ID "30" represents the coding test practice course
    guard components[2] == "30" else { ... }
}
```

**나쁜 예:**
```swift
/// Returns the author name
var author: String  // 불필요한 주석
```

## 주요 설계 원칙

### 1. URL 파싱 정책
- **입력 허용**: `programmers.co.kr`, `school.programmers.co.kr` 둘 다
- **출력 통일**: 항상 `school.programmers.co.kr`로 저장

### 2. 입력 분기 (NewCommand)
```swift
// try? 사용 금지 - 에러 삼킴 방지
if looksLikeURL(input) {
    let problem = try URLParser.parse(input)  // 에러 그대로 전파
    // ...
} else {
    let platform = try platformOption.requirePlatform()
    // ...
}
```

### 3. Git 명령 실행
- working directory: `projectRoot`로 고정
- arguments: 배열로 전달 (shell 문자열 금지)
- `--` 사용: 파일명 안전 처리

### 4. ConfigLocator 책임
- 파일 존재 및 경로 탐색만 담당
- JSON 파싱은 `Config.load(from:)` 담당

## 테스트 전략

### 단위 테스트 필수
- `URLParserTests` - URL 파싱 로직
- `ConfigTests` - JSON 인코딩/디코딩
- `ConfigLocatorTests` - 경로 탐색
- `TemplateTests` - 변수 치환

### Smoke Test (수동)
```bash
kps init -a "Test" -s "Sources"
kps new 1000 -b
kps solve 1000 -b --no-push
```

## 개발 방법론

### TDD 사이클
```
Red → Green → Refactor
```

1. **Red**: 실패하는 테스트 먼저 작성
2. **Green**: 테스트 통과하는 최소한의 코드 구현
3. **Refactor**: 테스트 통과 상태에서 구조 개선

### Tidy First 원칙

변경을 두 가지로 분리:
- **구조적 변경**: 동작 변경 없이 코드 정리 (리네이밍, 메서드 추출, 코드 이동)
- **동작 변경**: 실제 기능 추가/수정

**규칙:**
- 구조적 변경과 동작 변경을 같은 커밋에 섞지 않기
- 둘 다 필요하면 구조적 변경 먼저
- 구조적 변경 전후로 테스트 실행하여 동작 보존 확인

### 커밋 규칙

**커밋 타이밍:**
- 하루 분량 TODO 완료 시 사용자 검사 요청
- 사용자 승인 후 커밋 진행
- 커밋 메시지는 작업 내용만 포함 (Claude 관련 내용 제외)

커밋 조건:
- [ ] 모든 테스트 통과
- [ ] 컴파일러/린터 경고 해결
- [ ] 단일 논리적 작업 단위

커밋 메시지 형식:
```bash
# 기능 추가
feat: add BOJ URL parsing
feat: add Config JSON encoding/decoding

# 테스트 추가
test: add URLParser tests

# 구조적 변경
refactor: extract URLParser from NewCommand
```

### 작업 워크플로우

"go" 명령 시:
1. TODO에서 다음 미완료 항목 찾기
2. 해당 기능의 실패하는 테스트 작성 (TDD Red)
3. 테스트 통과하는 최소 코드 구현 (TDD Green)
4. 테스트 통과 확인
5. 필요시 구조 개선 (Refactor)
6. **복잡한 로직이나 Public API에 문서화 주석 추가**
7. **하루 분량 완료 시 사용자에게 검사 요청**
8. **사용자 승인 시 커밋 메시지 제안 → 사용자 검토 → 커밋 진행**
9. TODO 항목 체크 `- [x]`

### 테스트 작성 가이드 (Swift Testing)

```swift
import Testing
@testable import kps

// 테스트 함수에 @Test 속성 사용
@Test("parse should extract problem number from BOJ URL")
func parseExtractsProblemNumberFromBOJURL() throws {
    // Given
    let url = "https://acmicpc.net/problem/1000"

    // When
    let problem = try URLParser.parse(url)

    // Then
    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

// 에러 테스트
@Test("parse should throw unsupportedURL for unknown domain")
func parseThrowsUnsupportedURLForUnknownDomain() {
    let url = "https://leetcode.com/problems/two-sum"

    #expect(throws: KPSError.unsupportedURL) {
        try URLParser.parse(url)
    }
}

// 테스트 스위트 그룹화 (선택 사항)
@Suite("URL Parser Tests")
struct URLParserTests {
    @Test("BOJ URL parsing")
    func bojURLParsing() throws { }

    @Test("Programmers URL parsing")
    func programmersURLParsing() throws { }
}
```

### 리팩토링 가이드

- 테스트 통과 상태(Green)에서만 리팩토링
- 한 번에 하나의 리팩토링만
- 각 리팩토링 후 테스트 실행
- 우선순위: 중복 제거 > 명확성 개선

## 빌드 & 실행

```bash
# 빌드
swift build

# 테스트
swift test

# 릴리즈 빌드
swift build -c release

# 실행
.build/debug/kps --help
```

## 참고 문서

프로젝트 루트의 다음 문서 참조:
- `KPS_PRD.md` - 요구사항 정의
- `KPS_Development_Plan.md` - 설계 상세
- `KPS_TODO.md` - 개발 체크리스트

## 작업 요청 시 참고

1. TODO의 Week/Day 단위로 작업 요청
2. 새 파일 생성 시 프로젝트 구조 확인
3. 에러 타입 추가 시 `KPSError.swift`에 통합
4. 테스트 작성 시 기존 테스트 패턴 따르기
