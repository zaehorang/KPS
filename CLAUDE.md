# KPS - Agent Guidelines

> **문서 역할**: 이 문서는 AI 에이전트(Claude)를 위한 개발 워크플로우 가이드입니다.
> - **독자**: AI 에이전트 (Claude)
> - **목적**: TDD, Tidy First, 커밋 규칙 등 개발 방법론과 작업 흐름 정의
> - **관련 문서**:
>   - [ARCHITECTURE.md](docs/ARCHITECTURE.md) - 기술 설계 및 구조
>   - [DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md) - 명령어 스펙 및 빌드
>   - [SWIFT_STYLE_GUIDE.md](docs/SWIFT_STYLE_GUIDE.md) - 코드 스타일
>   - [COMMIT_Convention.md](docs/COMMIT_Convention.md) - 커밋 규칙

---

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

---

## PM (Project Management) Skill 사용

**중요**: 문서 구조가 재편되었습니다. 이제 TODO 체크리스트는 없으며, 개발 히스토리는 CHANGELOG.md에 기록됩니다.

### 자동 실행 (Always)
- **커밋 완료 후**: `/pm sync` 실행하여 CHANGELOG.md 업데이트
- **작업 시작 전**: `/pm next` 실행하여 다음 작업 추천 (DEVELOPMENT_GUIDE.md 기준)

### 명시적 요청 시
- `/pm status` - 진행 상황 리포트 (CHANGELOG.md 기준)
- `/pm sync` - CHANGELOG.md 업데이트 (완료된 작업 기록)
- `/pm next` - 다음 작업 추천 (DEVELOPMENT_GUIDE.md 릴리즈 체크리스트 기준)
- `/pm check` - 문서 일관성 검증 (ARCHITECTURE.md ↔ DEVELOPMENT_GUIDE.md)

### 참조 문서 변경사항
- ~~docs/KPS_TODO.md~~ → **docs/CHANGELOG.md** (개발 히스토리)
- ~~docs/KPS_PRD.md~~ → **docs/ARCHITECTURE.md** (프로젝트 정의, 요구사항)
- ~~docs/KPS_Development_Plan.md~~ → **docs/DEVELOPMENT_GUIDE.md** (명령어 스펙, 릴리즈 체크리스트)

PM Skill 로직은 `.claude/skills/pm/SKILL.md`에 정의되어 있으며, 새 문서 구조에 맞게 업데이트가 필요합니다.

---

## 기술 스택

| 구성 요소 | 선택 |
|-----------|------|
| 언어 | Swift 5.9+ |
| CLI 프레임워크 | ArgumentParser |
| 테스트 프레임워크 | Swift Testing |
| 패키지 관리 | SPM |
| 코드 스타일 | SwiftLint (SPM Plugin) |
| Git 연동 | Process (shell) |

## 프로젝트 구조

**프로젝트 구조는 [ARCHITECTURE.md](docs/ARCHITECTURE.md#3-프로젝트-구조)를 참조하세요.**

계층별 책임:
- **Commands**: ArgumentParser 기반 명령어 구현
- **Core**: 비즈니스 로직 및 데이터 모델
- **Utils**: 재사용 가능한 유틸리티

## 코딩 컨벤션

**자세한 코드 스타일 가이드는 [SWIFT_STYLE_GUIDE.md](docs/SWIFT_STYLE_GUIDE.md)를 참조하세요.**

### 핵심 원칙
- Swift API Design Guidelines 준수
- `guard let` 적극 활용 (early return)
- `Result` 타입으로 에러 전파 (ConfigLocator)
- `throws`로 에러 전파 (Commands, Parsers)
- 모든 에러는 `KPSError`로 통일 (자세한 내용: [ARCHITECTURE.md](docs/ARCHITECTURE.md#6-에러-처리))

### Console 출력
```swift
Console.success("Done!")           // ✅ stdout
Console.info("File created")       // ✔ stdout
Console.warning("Push failed")     // ⚠️ stderr
Console.error("Config not found")  // ❌ stderr
```

### SwiftLint

SwiftLint는 SPM Plugin으로 통합되어 있어 `swift build`/`swift test` 시 자동 실행됩니다.

설정 파일: `.swiftlint.yml` (Line length: 120자, 들여쓰기: 4 spaces)

수동 실행 (optional):
```bash
swiftlint lint --config .swiftlint.yml
swiftlint --fix --config .swiftlint.yml
```

## 문서화 규칙

### 주석 작성 원칙
- 복잡한 로직, Public API에는 Swift 문서화 주석 (`///`) 필수
- 자명한 코드에는 주석 불필요 (코드 자체가 문서)
- 비자명한 설계 결정(POSIX locale, atomic write 등)에는 설명 추가

### Swift 문서화 주석 형식
```swift
/// Brief one-line summary
/// - Parameter name: Description
/// - Returns: Description
/// - Throws: Error conditions
func example(name: String) throws -> Result
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

**자세한 커밋 규칙은 [COMMIT_Convention.md](docs/COMMIT_Convention.md)를 참조하세요.**

**커밋 타이밍:**
- 하루 분량 TODO 완료 시 사용자 검사 요청
- 사용자 승인 후 커밋 진행 (모든 테스트 통과, 린터 경고 해결 필수)

**형식:** `feat:`, `test:`, `refactor:`, `fix:`, `docs:`, `chore:` 사용

**⚠️ 외부 이슈 참조 금지 (중요)**

커밋 메시지에 외부 오픈소스 프로젝트의 이슈 번호를 **절대 포함하지 마세요.**

**금지 예시:**
```
❌ fix: resolve SwiftLint#5376 prebuild error
❌ chore: workaround for realm/SwiftLint#5376
❌ References: https://github.com/realm/SwiftLint/issues/5376
```

**이유:**
- GitHub가 자동으로 해당 이슈에 커밋을 연결시킴
- 검증되지 않은 해결책이 외부 이슈 트래커를 오염시킴
- 오픈소스 프로젝트에 잘못된 정보를 제공할 수 있음

**허용:**
- 개인 레포 내 이슈 참조: `#123` (이 레포의 이슈)
- 문서(CICD_GUIDE.md 등)에 링크 작성

**외부 이슈 참조가 필요한 경우:**
1. 사용자에게 먼저 물어보기
2. 승인 후에만 커밋 메시지에 포함
3. CI 검증 완료 후에만 참조

**올바른 접근:**
```markdown
✅ 커밋 메시지: 외부 이슈 번호 제외
✅ CICD_GUIDE.md: 참고 자료로 링크 포함
✅ 사용자 승인 후: 이슈에 댓글 달기
```

### 작업 워크플로우

1. TODO에서 다음 미완료 항목 찾기
2. 실패하는 테스트 작성 (TDD Red)
3. 테스트 통과하는 최소 코드 구현 (TDD Green)
4. 필요시 구조 개선 (Refactor)
5. 복잡한 로직/Public API에 문서화 주석 추가
6. 하루 분량 완료 시 사용자 검사 요청 → 승인 후 커밋

### 테스트 작성 가이드 (Swift Testing)

```swift
import Testing
@testable import kps

@Test("parse should extract problem number from BOJ URL")
func parseExtractsProblemNumberFromBOJURL() throws {
    let url = "https://acmicpc.net/problem/1000"
    let problem = try URLParser.parse(url)

    #expect(problem.number == "1000")
    #expect(problem.platform == .boj)
}

// 에러 테스트
@Test("parse should throw unsupportedURL")
func parseThrowsUnsupportedURL() {
    #expect(throws: KPSError.unsupportedURL) {
        try URLParser.parse("https://leetcode.com/problems/two-sum")
    }
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

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - 기술 아키텍처, 프로젝트 구조, 에러 처리 정책
- **[DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)** - 명령어 스펙, 테스트 전략, 릴리즈 가이드
- **[SWIFT_STYLE_GUIDE.md](docs/SWIFT_STYLE_GUIDE.md)** - 코드 스타일 가이드
- **[COMMIT_Convention.md](docs/COMMIT_Convention.md)** - 커밋 규칙
- **[CHANGELOG.md](docs/CHANGELOG.md)** - 개발 히스토리
