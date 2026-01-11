# KPS Architecture

> **문서 역할**: 이 문서는 KPS 프로젝트의 기술 아키텍처를 정의합니다.
> - **독자**: 개발자, 협업자, 기여자
> - **목적**: 기술 스택, 프로젝트 구조, 설계 원칙, 에러 처리 정책을 한 곳에서 관리
> - **관련 문서**: [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) - 명령어 스펙 및 빌드 가이드

---

## 1. 프로젝트 정의

> **KPS는 알고리즘 문제 풀이를 '정돈된 개발 기록'으로 남기게 해주는 CLI 도구입니다.**

문제 풀이에 집중하는 동안, 파일 구조와 Git 기록은 KPS가 책임집니다.

### 1.1 핵심 가치

KPS는 알고리즘 풀이를 **'기록 가능한 학습 자산'**으로 만듭니다.

- 면접에서 꺼내볼 수 있는 **정돈된 코드 히스토리**
- 포트폴리오로 보여줄 수 있는 **체계적인 풀이 기록**
- 성장 과정을 증명하는 **개발자 학습 로그**

### 1.2 스코프

KPS는 **Swift + Xcode 환경에 최적화된 도구**입니다. 이 조합에서 최고의 경험을 제공하는 것이 우선이며, 다른 언어 지원은 핵심 경험이 완성된 후 고려합니다.

**타겟 사용자:**
- 코딩 테스트를 준비하는 취업준비생
- 알고리즘 실력 향상을 원하는 현직 개발자
- Swift로 알고리즘을 공부하는 iOS 개발자
- 체계적인 문제 풀이 기록을 원하는 사람

---

## 2. 기술 스택

| 구성 요소 | 선택 | 이유 |
|-----------|------|------|
| 언어 | Swift 5.9+ | 타겟 사용자 환경과 일치 |
| CLI 프레임워크 | ArgumentParser | Apple 공식, 유지보수 안정성 |
| 파일 시스템 | Foundation | 별도 의존성 불필요 |
| JSON 처리 | Codable | 네이티브, 타입 안전성 |
| Git 연동 | Process (shell) | 외부 의존성 최소화 |
| 테스트 프레임워크 | Swift Testing | Swift 네이티브 테스트 지원 |
| 코드 스타일 | SwiftLint (SPM Plugin) | 자동화된 스타일 검증 |
| 패키지 관리 | SPM | Swift 표준 |

---

## 3. 프로젝트 구조

### 3.1 디렉토리 구조 (v2.0)

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
│       │   └── PlatformOption.swift    # OptionGroup
│       ├── Core/
│       │   ├── Config.swift
│       │   ├── ConfigKey.swift
│       │   ├── ConfigLocator.swift
│       │   ├── Platform.swift
│       │   ├── Problem.swift
│       │   ├── URLParser.swift
│       │   ├── Template.swift
│       │   ├── FileManager+KPS.swift
│       │   ├── GitExecutor.swift
│       │   └── KPSError.swift
│       └── Utils/
│           ├── Console.swift
│           └── DateFormatter+KPS.swift
├── Tests/
│   └── KPSTests/
│       ├── URLParserTests.swift
│       ├── ConfigTests.swift
│       ├── ConfigLocatorTests.swift
│       └── TemplateTests.swift
└── README.md
```

### 3.2 계층별 책임

#### Commands
- ArgumentParser 기반 명령어 구현
- 사용자 입력 검증 및 분기
- Core 계층 조율 (orchestration)

#### Core
- 비즈니스 로직
- 데이터 모델 (Config, Platform, Problem)
- 파일 시스템 및 Git 연동
- 에러 타입 정의

#### Utils
- 재사용 가능한 유틸리티
- Console 출력
- 날짜 포맷팅

---

## 4. 핵심 모델 설계

### 4.1 Config

**KPSConfig**
```swift
struct KPSConfig: Codable {
    var author: String
    var sourceFolder: String
    var projectName: String

    static let fileName = "config.json"
    static let directoryName = ".kps"

    func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url, options: .atomic)  // atomic write
    }

    static func load(from url: URL) throws -> KPSConfig {
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(KPSConfig.self, from: data)
        } catch {
            throw KPSError.configParseError  // JSON 디코딩 실패
        }
    }
}
```

**ConfigKey**
```swift
enum ConfigKey: String, CaseIterable {
    case author
    case sourceFolder
    case projectName

    var description: String {
        switch self {
        case .author: return "Author name for file headers"
        case .sourceFolder: return "Root folder for problem files"
        case .projectName: return "Xcode project name"
        }
    }
}
```

**ConfigLocator**
```swift
/// 프로젝트 루트 탐색 결과
struct ProjectRoot {
    let projectRoot: URL      // .kps 디렉토리가 존재하는 프로젝트 루트
    let configPath: URL       // projectRoot/.kps/config.json (계산된 경로)

    init(projectRoot: URL) {
        self.projectRoot = projectRoot
        self.configPath = projectRoot
            .appendingPathComponent(".kps")
            .appendingPathComponent("config.json")
    }
}

struct ConfigLocator {
    /// 현재 경로부터 상위로 .kps/config.json 탐색
    /// - Returns: Result<ProjectRoot, KPSError>
    static func locate(from startPath: URL = ...) -> Result<ProjectRoot, KPSError>
}
```

### 4.2 Platform & Problem

**Platform**
```swift
enum Platform: String {
    case boj
    case programmers

    var baseURL: String {
        switch self {
        case .boj: return "https://acmicpc.net/problem/"
        case .programmers: return "https://school.programmers.co.kr/learn/courses/30/lessons/"
        }
    }

    var folderName: String
    var displayName: String
}
```

**Problem**
```swift
struct Problem {
    let number: String
    let platform: Platform

    var url: String
    var fileName: String        // "1000.swift"
    var functionName: String    // "_1000"
}
```

### 4.3 PlatformOption

```swift
struct PlatformOption: OptionGroup {
    @Flag(name: .shortAndLong, help: "BOJ platform")
    var boj: Bool = false

    @Flag(name: .shortAndLong, help: "Programmers platform")
    var programmers: Bool = false

    /// 플랫폼 플래그 충돌 검증 후 반환
    func resolve() throws -> Platform?

    /// 플랫폼이 없으면 에러
    func requirePlatform() throws -> Platform
}
```

---

## 5. 주요 설계 원칙

### 5.1 URL 파싱 정책

- **입력 허용**: `programmers.co.kr`, `school.programmers.co.kr` 둘 다
- **출력 통일**: 항상 `school.programmers.co.kr`로 저장

### 5.2 입력 분기 (NewCommand)

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

**중요**: `looksLikeURL()`로 사전 체크하여 잘못된 URL은 `unsupportedURL` 에러로, 번호 입력 시 플랫폼 플래그 누락은 `platformRequired` 에러로 명확히 구분.

### 5.3 Git 명령 실행

- **working directory**: `projectRoot`로 고정
- **arguments**: 배열로 전달 (shell 문자열 금지)
- **`--` 사용**: 파일명 안전 처리

```swift
// 예시: git add -- <filePath>
Process.currentDirectoryURL = projectRoot
arguments = ["add", "--", filePath]
```

### 5.4 ConfigLocator 책임

- **파일 존재 및 경로 탐색만 담당**
- JSON 파싱은 `Config.load(from:)` 담당
- `.git` 발견 시 플래그만 설정, 탐색 계속 (모노레포 지원)

---

## 6. 에러 처리

### 6.1 에러 타입 전체 목록

```swift
enum KPSError: LocalizedError {
    // Config 관련
    case configNotFound
    case configNotFoundInGitRepo      // .git은 있지만 .kps 없음
    case configParseError             // JSON 디코딩 실패
    case configAlreadyExists

    // 입력 검증
    case unsupportedURL(String)
    case invalidProblemNumber
    case platformRequired
    case conflictingPlatformFlags     // -b와 -p 동시 사용
    case urlWithPlatformFlag          // URL + 플래그 동시 사용
    case invalidConfigKey(String, validKeys: [ConfigKey])

    // 파일 시스템
    case fileAlreadyExists(String)
    case fileNotFound(String)
    case permissionDenied             // 쓰기 권한 없음
    case fileIOError(String)          // generic fallback

    // Git 관련
    case gitNotAvailable              // git 설치 안 됨
    case notGitRepository             // git repo 아님
    case nothingToCommit              // 변경사항 없음
    case gitFailed(command: String, exitCode: Int32, message: String?)
    case gitPushFailed(message: String?)
}
```

### 6.2 NSError 매핑 정책

| NSError | KPSError |
|---------|----------|
| `NSFileWriteNoPermissionError` | permissionDenied |
| `NSFileReadNoPermissionError` | permissionDenied |
| 그 외 | fileIOError |

### 6.3 Console 출력 정책

| 레벨 | 아이콘 | 출력 대상 | 용도 |
|------|--------|-----------|------|
| success | ✅ | stdout | 완전 성공 |
| info | ✔ 📦 💾 🚀 🔗 💡 | stdout | 진행 상황, 안내 |
| warning | ⚠️ | **stderr** | push 실패 등 |
| error | ❌ | **stderr** | 모든 에러 |

**에러 메시지 형식:**
```
❌ {에러 타입}
   {상세 설명}
   {해결 힌트}
```

### 6.4 주요 에러 메시지

| 에러 | 메시지 |
|------|--------|
| configNotFound | `Config not found. Run 'kps init' first.` |
| configNotFoundInGitRepo | `Config not found in this git repository.`<br>`Run 'kps init' in your project root.` |
| configParseError | `Config file is corrupted.`<br>`Delete .kps/config.json and run 'kps init' again.` |
| unsupportedURL | `Unsupported URL: {url}`<br>`Supported: acmicpc.net, school.programmers.co.kr` |
| platformRequired | `Platform required. Use -b (BOJ) or -p (Programmers)` |
| gitNotAvailable | `Git is not installed or not in PATH.`<br>`Install: https://git-scm.com/downloads` |
| notGitRepository | `Not a git repository.`<br>`Run 'git init' first.` |
| nothingToCommit | `No changes to commit.`<br>`Did you save your solution file?` |
| gitPushFailed | `Commit succeeded, but push failed.`<br>`Possible causes:`<br>`  • No remote configured: run 'git remote -v'`<br>`  • Authentication issue: check your credentials or SSH key`<br>`To complete: run 'git push' manually` |

---

## 7. 파일 템플릿

### 7.1 변수 치환 로직

템플릿에서 다음 변수를 지원합니다:

| 변수 | 설명 | 예시 |
|------|------|------|
| `{number}` | 문제 번호 | "1000" |
| `{projectName}` | 프로젝트 이름 | "MyAlgorithm" |
| `{author}` | 작성자 이름 | "John Doe" |
| `{date}` | 생성 날짜 | "2026/1/11" |
| `{url}` | 문제 URL | "https://acmicpc.net/problem/1000" |

### 7.2 날짜 포맷 설정

- **Locale**: `Locale(identifier: "en_US_POSIX")` (날짜 파싱 일관성)
- **TimeZone**: `TimeZone.current` (로컬 타임존)
- **포맷**: `yyyy/M/d`

---

## 8. Exit Code 정책

| 상황 | Exit Code |
|------|-----------|
| 성공 (모든 단계 완료) | 0 |
| `--no-push` 성공 | 0 |
| 에러 (설정 없음, 파일 없음 등) | 1 |
| Git 실패 (add, commit) | 1 |
| **Git push 실패** | **1** |

> **중요**: Push 실패도 exit code 1로 처리합니다. "기록 완성"이 목표이므로 push 실패는 미완성 상태로 간주합니다.

---

## 참고

- **명령어 상세 스펙**: [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)
- **코드 스타일**: [SWIFT_STYLE_GUIDE.md](SWIFT_STYLE_GUIDE.md)
- **커밋 규칙**: [COMMIT_Convention.md](COMMIT_Convention.md)
