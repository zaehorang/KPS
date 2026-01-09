# KPS 개발 계획서 v2

## 1. 기술 스택

| 구성 요소 | 선택 | 이유 |
|-----------|------|------|
| 언어 | Swift 5.9+ | 타겟 사용자 환경과 일치 |
| CLI 프레임워크 | ArgumentParser | Apple 공식, 유지보수 안정성 |
| 파일 시스템 | Foundation | 별도 의존성 불필요 |
| JSON 처리 | Codable | 네이티브, 타입 안전성 |
| Git 연동 | Process (shell) | 외부 의존성 최소화 |
| 패키지 관리 | SPM | Swift 표준 |

## 2. 프로젝트 구조

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
│       │   └── PlatformOption.swift    # 추가: OptionGroup
│       ├── Core/
│       │   ├── Config.swift
│       │   ├── ConfigKey.swift
│       │   ├── ConfigLocator.swift      # 추가
│       │   ├── Platform.swift
│       │   ├── URLParser.swift
│       │   ├── Template.swift
│       │   ├── FileManager+KPS.swift
│       │   └── GitExecutor.swift
│       └── Utils/
│           ├── Console.swift
│           └── DateFormatter.swift
├── Tests/
│   └── KPSTests/
│       ├── URLParserTests.swift
│       ├── ConfigTests.swift
│       ├── ConfigLocatorTests.swift     # 추가
│       └── TemplateTests.swift
└── README.md
```

**v1 대비 변경사항**
- Services 계층 제거 → Core로 통합
- ConfigKey enum 추가
- **ConfigLocator 추가** (하위 폴더에서 프로젝트 루트 탐색)
- **PlatformOption 추가** (플랫폼 플래그 검증 로직 재사용)
- CommandTests 제거 (smoke test로 대체)

## 3. 핵심 모델 설계

### 3.1 Config

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

### 3.2 ConfigLocator (신규)

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

/// ConfigLocator 책임 범위
/// - 파일 존재 및 경로 탐색만 담당
/// - JSON 파싱/형식 오류는 Config.load(from:) 단계에서 처리
struct ConfigLocator {
    /// 현재 경로부터 상위로 .kps/config.json 탐색
    static func locate(from startPath: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> Result<ProjectRoot, KPSError> {
        var current = startPath.standardizedFileURL
        var gitRepoDetected = false
        
        while current.path != "/" {
            // .kps/config.json 발견
            let configPath = current
                .appendingPathComponent(".kps")
                .appendingPathComponent("config.json")
            
            if FileManager.default.fileExists(atPath: configPath.path) {
                return .success(ProjectRoot(projectRoot: current))
            }
            
            // .git 발견 시 플래그만 설정, 탐색 계속 (모노레포 지원)
            let gitPath = current.appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: gitPath.path) {
                gitRepoDetected = true
            }
            
            current = current.deletingLastPathComponent()
        }
        
        // 최종 실패 시 에러 분기
        if gitRepoDetected {
            return .failure(.configNotFoundInGitRepo)
        } else {
            return .failure(.configNotFound)
        }
    }
}
```

### 3.3 Platform

```swift
enum Platform: String, Codable, CaseIterable {
    case boj = "BOJ"
    case programmers = "Programmers"
    
    var baseURL: String {
        switch self {
        case .boj: return "https://acmicpc.net/problem/"
        case .programmers: return "https://school.programmers.co.kr/learn/courses/30/lessons/"
        }
    }
    
    var folderName: String { rawValue }
}
```

### 3.4 Problem

```swift
struct Problem {
    let platform: Platform
    let number: String
    
    var url: String {
        platform.baseURL + number
    }
    
    var fileName: String {
        "\(number).swift"
    }
    
    var functionName: String {
        "_\(number)"
    }
}
```

### 3.5 PlatformOption (OptionGroup)

`new`와 `solve` 명령어에서 플랫폼 플래그(-b/-p) 처리 로직이 동일하므로, `OptionGroup`으로 분리하여 재사용한다.

```swift
struct PlatformOption: ParsableArguments {
    @Flag(name: .shortAndLong, help: "BOJ (acmicpc.net)")
    var boj: Bool = false
    
    @Flag(name: .shortAndLong, help: "Programmers")
    var programmers: Bool = false
    
    /// 플래그 검증 및 Platform 반환
    /// - Returns: 선택된 Platform (플래그가 없으면 nil)
    /// - Throws: conflictingPlatformFlags (둘 다 선택된 경우)
    func resolve() throws -> Platform? {
        switch (boj, programmers) {
        case (true, true):
            throw KPSError.conflictingPlatformFlags
        case (true, false):
            return .boj
        case (false, true):
            return .programmers
        case (false, false):
            return nil
        }
    }
    
    /// 플래그 필수인 경우 (solve 명령어)
    /// - Returns: 선택된 Platform
    /// - Throws: platformRequired (플래그 없음), conflictingPlatformFlags (둘 다)
    func requirePlatform() throws -> Platform {
        guard let platform = try resolve() else {
            throw KPSError.platformRequired
        }
        return platform
    }
}
```

**사용 예시**

```swift
// NewCommand.swift
struct NewCommand: ParsableCommand {
    @Argument(help: "Problem URL or number")
    var input: String
    
    @OptionGroup var platformOption: PlatformOption
    
    func run() throws {
        // 1단계: URL 형태인지 판단 (scheme + host 존재)
        if looksLikeURL(input) {
            // URL이면 파싱 시도, 에러는 그대로 전파 (try? 사용 금지)
            let problem = try URLParser.parse(input)
            
            // URL인데 플래그도 있으면 에러
            if try platformOption.resolve() != nil {
                throw KPSError.urlWithPlatformFlag
            }
            // URL에서 추출한 platform 사용
            try createFile(for: problem)
        } else {
            // 번호인 경우: 플래그 필수
            let platform = try platformOption.requirePlatform()
            let problem = Problem(platform: platform, number: input)
            try createFile(for: problem)
        }
    }
    
    /// URL 형태인지 판단 (에러 삼킴 방지를 위해 파싱 전 사전 체크)
    private func looksLikeURL(_ input: String) -> Bool {
        guard let url = URL(string: input),
              let scheme = url.scheme,
              url.host != nil else {
            return false
        }
        return ["http", "https"].contains(scheme.lowercased())
    }
}

// SolveCommand.swift
struct SolveCommand: ParsableCommand {
    @Argument(help: "Problem number")
    var number: String
    
    @OptionGroup var platformOption: PlatformOption
    
    func run() throws {
        let platform = try platformOption.requirePlatform()
        // ...
    }
}
```

**입력 분기 원칙**
- `looksLikeURL()`로 URL 형태 여부를 먼저 판단
- URL 형태면 `URLParser.parse()`를 `try`로 호출 (에러 그대로 전파)
- `try?` 사용 금지: unsupportedURL 에러가 삼켜지면 엉뚱한 에러 메시지 노출

**장점**
- 플래그 검증 로직 중복 제거
- 에러 처리 일관성 보장
- 새 명령어 추가 시 재사용 용이 (`open`, `list` 등)

## 4. 명령어 상세 스펙

### 4.1 `kps init`

```bash
kps init --author "Name" --source "AlgorithmStudy"
```

**옵션**

| 옵션 | 축약 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `--author` | `-a` | O | - | 작성자 이름 |
| `--source` | `-s` | X | `"Sources"` | 소스 폴더명 |
| `--force` | `-f` | X | `false` | 기존 설정 덮어쓰기 |

**처리 흐름**

```
1. 현재 디렉토리명 → projectName
2. .kps 존재 확인
   ├─ 존재 + force 없음 → 에러
   └─ 존재 + force 있음 → 덮어쓰기
3. .kps/config.json 생성
4. 성공 메시지 출력

※ git repo 여부 체크 안 함 (init은 git 없이도 동작)
```

**출력 예시**

```
✅ Config created!
   Author: Name
   Project: Swift_Algorithm
   Source: AlgorithmStudy
```

---

### 4.2 `kps new`

```bash
kps new "https://acmicpc.net/problem/1000"
kps new 1000 -b
kps new 12345 -p
```

**옵션**

| 옵션 | 축약 | 설명 |
|------|------|------|
| `--boj` | `-b` | BOJ 플랫폼 지정 |
| `--programmers` | `-p` | Programmers 플랫폼 지정 |

**입력 규칙**

| 입력 | 결과 |
|------|------|
| 번호만 (플래그 없음) | `platformRequired` 에러 |
| `-b -p` 둘 다 | `conflictingPlatformFlags` 에러 |
| URL + 플래그 | `urlWithPlatformFlag` 에러 |

**URL 파싱 규칙**

| 입력 패턴 | 플랫폼 | 추출 |
|----------|--------|------|
| `acmicpc.net/problem/{n}` | BOJ | n |
| `boj.kr/{n}` | BOJ | n |
| `school.programmers.co.kr/.../lessons/{n}` | Programmers | n |
| `programmers.co.kr/.../lessons/{n}` | Programmers | n (구버전 호환) |

**URL 정규화 정책**
- **입력 허용**: `programmers.co.kr`, `school.programmers.co.kr` 둘 다 허용 (구버전 링크 호환)
- **출력 통일**: 생성되는 파일의 URL은 항상 `school.programmers.co.kr`로 저장
- www 접두사 처리
- http/https 모두 지원
- query string 무시
- fragment 무시

**처리 흐름**

```
1. 입력 검증
   ├─ URL + 플래그 동시 사용 → 에러
   ├─ 플래그 충돌 (-b -p) → 에러
   └─ 번호만 입력 (플래그 없음) → 에러
2. 입력 파싱
   ├─ URL → 플랫폼 감지 + 번호 추출
   └─ 번호 + 플래그 → Problem 생성
3. ConfigLocator로 프로젝트 루트 찾기
4. Config 로드
5. 경로 계산: {projectRoot}/{sourceFolder}/{Platform}/{number}.swift
6. 디렉토리 생성 (없으면)
7. 파일 존재 확인 → 있으면 에러
8. 템플릿으로 파일 생성
9. 성공 메시지 + 링크 + 다음 행동 가이드 출력
```

**출력 예시**

```
✔ Platform: BOJ
✔ Problem: 1000
✔ File: AlgorithmStudy/BOJ/1000.swift
🔗 https://acmicpc.net/problem/1000
💡 Next: solve with 'kps solve 1000 -b'
```

---

### 4.3 `kps solve`

```bash
kps solve 1000 -b
kps solve 1000 -b --no-push
kps solve 1000 -b -m "refactor solution"
```

**옵션**

| 옵션 | 축약 | 기본값 | 설명 |
|------|------|--------|------|
| `--boj` | `-b` | - | BOJ 플랫폼 |
| `--programmers` | `-p` | - | Programmers 플랫폼 |
| `--no-push` | - | `false` | commit만 수행 |
| `--message` | `-m` | 자동생성 | 커밋 메시지 커스텀 |

**기본 커밋 메시지**

```
solve: [BOJ] 1000
solve: [Programmers] 12345
```

**처리 흐름**

```
1. Problem 생성 (번호 + 플랫폼)
2. ConfigLocator로 프로젝트 루트 찾기
3. 파일 경로 계산
4. 파일 존재 확인 → 없으면 에러
5. Git preflight check (solve에서만)
   ├─ git 실행 가능 확인
   └─ git repo 확인
6. git add {파일}
   └─ 실패 → 에러 + 즉시 종료
7. git commit -m "{메시지}"
   ├─ 성공 시 commit hash 출력
   └─ 실패 → 에러 + 즉시 종료
8. (no-push 아니면) git push
   └─ 실패 → 경고 메시지 + exit code 1
9. 완료 메시지
```

**Git 명령 실행 원칙**

| 원칙 | 설명 |
|------|------|
| working directory | `projectRoot`로 고정 |
| arguments | 배열로 전달 (shell 문자열 금지) |
| `--` 사용 | 옵션 파싱 종료, 파일명 안전 처리 |

**Git 실패 처리**

| 단계 | 실패 시 동작 |
|------|-------------|
| preflight (git 미설치) | 에러 메시지 + 설치 안내 + exit 1 |
| preflight (non-repo) | 에러 메시지 + `git init` 안내 + exit 1 |
| add 실패 | 에러 메시지 + exit 1 |
| commit 실패 (nothing to commit) | 친절한 에러 + exit 1 |
| commit 실패 (기타) | 에러 메시지 + exit 1 |
| push 실패 | 경고 메시지 + 상세 힌트 + exit 1 |

**"nothing to commit" 감지 (2단계 방어)**

```
1차: stderr에서 "nothing to commit" 문자열 확인
2차: `git status --porcelain` 결과가 비어있는지 확인
   ├─ 비어 있음 → nothingToCommit 확정
   └─ 비어 있지 않음 → 일반 gitFailed
```

**출력 예시**

```
# 완전 성공
📦 Adding: AlgorithmStudy/BOJ/1000.swift
💾 Committing: solve: [BOJ] 1000
✔ Commit: a1b2c3d
🚀 Pushing to origin...
✅ Done!

# --no-push 성공
📦 Adding: AlgorithmStudy/BOJ/1000.swift
💾 Committing: solve: [BOJ] 1000
✔ Commit: a1b2c3d
✅ Done! (push skipped)

# push 실패 (Done! 없음)
📦 Adding: AlgorithmStudy/BOJ/1000.swift
💾 Committing: solve: [BOJ] 1000
✔ Commit: a1b2c3d
🚀 Pushing to origin...

⚠️ Commit succeeded, but push failed.
   Possible causes:
     • No remote configured: run 'git remote -v'
     • Authentication issue: check your credentials or SSH key
   To complete: run 'git push' manually
```

> **원칙**: 성공 메시지는 완전 성공일 때만 출력한다.

---

### 4.4 `kps config`

```bash
kps config                     # 전체 조회
kps config author              # 특정 값 조회
kps config author "NewName"    # 값 수정
```

**처리 흐름**

```
1. ConfigLocator로 config 찾기 → 없으면 에러
2. Config 로드
3. 인자 개수 분기
   ├─ 0개 → 전체 출력
   ├─ 1개 → ConfigKey 검증 → 값 출력
   └─ 2개 → ConfigKey 검증 → 값 수정 → 저장

※ git repo 여부 체크 안 함
```

**ConfigKey 검증**

```swift
guard let key = ConfigKey(rawValue: input) else {
    throw KPSError.invalidConfigKey(input, validKeys: ConfigKey.allCases)
}
```

**출력 예시**

```
# 전체 조회
author: Horang
sourceFolder: AlgorithmStudy
projectName: Swift_Algorithm

# 잘못된 키
❌ Invalid config key: 'auther'
   Valid keys: author, sourceFolder, projectName
```

## 5. 파일 템플릿

```swift
//
//  {number}.swift
//  {projectName}
//
//  Created by {author} on {date}.
//  {url}
//

func _{number}() {
    
}
```

**변수 치환**

| 변수 | 소스 |
|------|------|
| `{number}` | Problem.number |
| `{projectName}` | Config.projectName |
| `{author}` | Config.author |
| `{date}` | 현재 날짜 (yyyy/M/d) |
| `{url}` | Problem.url |

**날짜 포맷 설정**
- Locale: `Locale(identifier: "en_US_POSIX")`
- TimeZone: `TimeZone.current` (local time)

## 6. 에러 처리

### 6.1 에러 타입

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

**NSError 매핑 정책**

| NSError | KPSError |
|---------|----------|
| `NSFileWriteNoPermissionError` | permissionDenied |
| `NSFileReadNoPermissionError` | permissionDenied |
| 그 외 | fileIOError |

### 6.2 에러 메시지 형식

```
❌ {에러 타입}
   {상세 설명}
   {해결 힌트}
```

### 6.3 에러별 메시지

| 에러 | 메시지 |
|------|--------|
| configNotFound | `Config not found. Run 'kps init' first.` |
| configNotFoundInGitRepo | `Config not found in this git repository.`<br>`Run 'kps init' in your project root.` |
| configParseError | `Config file is corrupted.`<br>`Delete .kps/config.json and run 'kps init' again.` |
| unsupportedURL | `Unsupported URL: {url}`<br>`Supported: acmicpc.net, school.programmers.co.kr` |
| platformRequired | `Platform required. Use -b (BOJ) or -p (Programmers)` |
| conflictingPlatformFlags | `Cannot use both -b and -p flags.` |
| urlWithPlatformFlag | `URL already contains platform info. Remove -b/-p flag.` |
| invalidConfigKey | `Invalid config key: '{key}'`<br>`Valid keys: {list}` |
| fileNotFound | `File not found: {path}`<br>`Run 'kps new {number} -{flag}' first.` |
| gitNotAvailable | `Git is not installed or not in PATH.`<br>`Install: https://git-scm.com/downloads` |
| notGitRepository | `Not a git repository.`<br>`Run 'git init' first.` |
| nothingToCommit | `No changes to commit.`<br>`Did you save your solution file?` |
| gitPushFailed | `Commit succeeded, but push failed.`<br>`Possible causes:`<br>`  • No remote configured: run 'git remote -v'`<br>`  • Authentication issue: check your credentials or SSH key`<br>`To complete: run 'git push' manually` |

## 7. Console 출력 정책

| 레벨 | 아이콘 | 출력 대상 | 용도 |
|------|--------|-----------|------|
| success | ✅ | stdout | 완전 성공 |
| info | ✔ 📦 💾 🚀 🔗 💡 | stdout | 진행 상황, 안내 |
| warning | ⚠️ | **stderr** | 부분 실패 (push 실패 등) |
| error | ❌ | **stderr** | 실패 |

> CI/스크립트 연동 시 stderr로 에러/경고 감지 가능

## 8. 테스트 전략

### 8.1 단위 테스트 (필수)

| 대상 | 테스트 케이스 |
|------|--------------|
| URLParser | BOJ URL, Programmers URL, boj.kr 단축, www 접두사, http URL, query string, fragment, 잘못된 URL |
| Config | JSON 인코딩/디코딩, 파일 저장/로드, ConfigKey 검증 |
| ConfigLocator | 현재 디렉토리, 상위 디렉토리, config 없음, .git만 있음, 모노레포, ProjectRoot 구조 검증 |
| Template | 변수 치환, 날짜 포맷 |

### 8.2 Smoke Test (Command)

전체 워크플로우 수동 실행:

```bash
# git 없이 기본 동작
kps init -a "Test" -s "Sources"
kps new 1000 -b
kps config

# git 있는 환경에서 전체 흐름
git init
kps new 1001 -b
# 파일에 코드 작성
kps solve 1001 -b --no-push
```

### 8.3 테스트하지 않는 것

- ArgumentParser 옵션 파싱 (라이브러리 책임)
- Git 명령어 자체 동작 (외부 의존성)
- 파일 시스템 권한 문제 (환경 의존적)

## 9. 개발 일정

### Week 1: 기반 구축

| 작업 | 산출물 |
|------|--------|
| SPM 프로젝트 생성 | Package.swift |
| Config 모델 + ConfigKey | Config.swift, ConfigKey.swift |
| ConfigLocator 구현 | ConfigLocator.swift |
| Platform, Problem 모델 | Platform.swift |
| URLParser 구현 | URLParser.swift |
| Console 유틸리티 | Console.swift |
| DateFormatter 유틸리티 | DateFormatter.swift |
| 단위 테스트 | URLParserTests, ConfigTests, ConfigLocatorTests |

**Week 1 완료 조건**
- [ ] URLParser가 다양한 형식의 BOJ, Programmers URL을 정확히 파싱
- [ ] ConfigLocator가 하위 폴더에서도 프로젝트 루트를 찾음
- [ ] ConfigLocator가 모노레포 구조에서도 정상 동작
- [ ] ConfigLocator가 .git만 있는 경우 적절한 메시지 제공
- [ ] Config JSON 저장/로드 동작 확인
- [ ] 모든 단위 테스트 통과

---

### Week 2: 명령어 구현

| 작업 | 산출물 |
|------|--------|
| KPSError 전체 정의 | KPSError.swift |
| `kps init` 구현 | InitCommand.swift |
| `kps new` 구현 | NewCommand.swift, Template.swift |
| `kps config` 구현 | ConfigCommand.swift |
| 에러 메시지 정리 | Console 에러 출력 연동 |

**Week 2 완료 조건**
- [ ] `kps init` → `kps new` 워크플로우 동작 (git 없이도)
- [ ] 하위 폴더에서 `kps new` 실행해도 정상 동작
- [ ] URL과 번호+플래그 두 방식 모두 동작
- [ ] 플래그 충돌 / URL+플래그 시 명확한 에러 메시지
- [ ] `kps new` 성공 후 다음 행동 가이드 출력
- [ ] 모든 에러 케이스에서 친절한 메시지 출력

---

### Week 3: Git 연동 및 릴리즈

| 작업 | 산출물 |
|------|--------|
| GitExecutor 구현 (preflight + commands) | GitExecutor.swift |
| `kps solve` 구현 | SolveCommand.swift |
| Git 실패 처리 완성 | 에러 핸들링 |
| README 작성 | README.md |
| GitHub 릴리즈 | v0.1.0 |

**Week 3 완료 조건**
- [ ] Git preflight check가 미설치/non-repo 상황에서 친절한 안내 제공
- [ ] init/new/config가 git 없이도 정상 동작
- [ ] `kps solve`가 모든 Git 실패 케이스에서 적절한 에러/경고 반환
- [ ] `--no-push` 성공 시 `Done! (push skipped)` 메시지 출력
- [ ] push 실패 시 exit code 1 + remote 힌트 (Done! 없음)
- [ ] 파일명 공백/특수문자에서도 git 명령 정상 동작
- [ ] README에 폴더 구조 예시 포함
- [ ] README에 설치 → 첫 사용까지 3분 내 완료 가능한 가이드 포함

## 10. Exit Code 정책

| 상황 | Exit Code |
|------|-----------|
| 성공 (모든 단계 완료) | 0 |
| `--no-push` 성공 | 0 |
| 에러 (설정 없음, 파일 없음 등) | 1 |
| Git 실패 (add, commit) | 1 |
| Git push 실패 | 1 |

> push 실패도 1로 처리. "기록 완성"이 목표이므로 push 실패는 미완성 상태.

## 11. 배포 계획

### v0.1.0 (MVP)

**배포 방식**: GitHub Release

```bash
git clone https://github.com/{user}/KPS.git
cd KPS
swift build -c release
cp .build/release/kps /usr/local/bin/
```

**릴리즈 체크리스트**
- [ ] 모든 테스트 통과
- [ ] README 완성 (Roadmap + Exit Code 정책 포함)
- [ ] LICENSE 파일 추가
- [ ] GitHub Release 태그

**README 필수 섹션**

```markdown
## Generated Structure

```
YourProject/
├── .kps/
│   └── config.json
└── Sources/
    ├── BOJ/
    │   └── 1000.swift
    └── Programmers/
        └── 12345.swift
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Failure (including push failure) |

## Roadmap

KPS is designed to grow into a **developer learning log**.  
Future versions will track solve history, retry counts, and problem metadata  
to help you prove your growth over time.
```

### v0.2.0 (Homebrew)

```bash
brew tap {user}/kps
brew install kps
```

## 12. 리스크 및 대응

| 리스크 | 대응 |
|--------|------|
| URL 구조 변경 | URLParser 모듈화로 빠른 수정 |
| Git 환경 다양성 | 명확한 에러 메시지, preflight check |
| push 실패 혼란 | 경고 메시지 + exit code 1 + 상세 힌트 |
| 하위 폴더 실행 | ConfigLocator로 프로젝트 루트 자동 탐색 |
| 모노레포 환경 | .git 발견해도 탐색 계속, .kps 우선 |

## 13. v0.2 이후 고려사항

**구조적 변경 (필요 시)**
- GitExecutor를 protocol로 추상화 (mock 테스트 필요 시)
- Platform에 행동 차이 생기면 protocol 전환

**기능 추가**
- `kps open`: 브라우저에서 문제 페이지 열기
- `kps list`: 풀이 목록 조회
- `kps stats`: 통계

**데이터 축적**
- `.kps/history.json`에 풀이 기록 저장
- 통계 기능 기반 데이터

---

## 부록: 명령어 요약

```bash
# 초기화
kps init --author "Name" --source "AlgorithmStudy"
kps init -a "Name" -s "AlgorithmStudy" --force

# 파일 생성
kps new "https://acmicpc.net/problem/1000"
kps new "https://boj.kr/1000"
kps new 1000 -b
kps new 12345 -p

# 풀이 완료
kps solve 1000 -b
kps solve 1000 -b --no-push
kps solve 1000 -b -m "refactor: optimize solution"

# 설정 관리
kps config
kps config author
kps config author "NewName"
```
