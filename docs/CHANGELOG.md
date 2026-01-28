# KPS Changelog

> **문서 역할**: 이 문서는 KPS 프로젝트의 개발 히스토리를 기록합니다.
> - **독자**: 모든 독자 (AI 에이전트, 개발자, 협업자, 미래의 나)
> - **목적**: 버전별 완료 기능과 개발 진행 상황 추적
> - **관련 문서**: GitHub Issues - 현재 진행 중인 작업

---

## [Unreleased]

---

## v0.1.1 (2026-01-28)

### Homebrew 배포 지원

**완료:**
- Homebrew 배포 인프라 구축
  - homebrew-tap 저장소 생성 (`zaehorang/homebrew-tap`)
  - Formula/kps.rb 작성 (Multi-arch 지원)
  - Formula 테스트 워크플로우 추가 (macOS 13/14)
  - homebrew-tap README 작성 (설치 가이드)
- GitHub Actions 릴리즈 자동화
  - .github/workflows/release.yml 추가
  - Intel (x86_64) + Apple Silicon (arm64) 빌드
  - tar.gz 압축 및 SHA256 계산
  - GitHub Release 자동 생성
  - homebrew-tap에 자동 PR 생성 (Formula 업데이트)
- 문서 업데이트
  - README.md Homebrew 섹션 활성화
  - Plan/2026-01-28_homebrew-deployment.md 작성 (배포 계획)
  - 버전 0.1.1로 업데이트

**설치 방법:**
```bash
brew tap zaehorang/tap
brew install kps
```

---

### Week 3: Git 연동 및 릴리즈 (완료) ✅

**완료:**
- Git preflight checks 구현
  - git 실행 가능 여부 확인 (`git --version`)
  - git repository 여부 확인
  - 친절한 에러 메시지 (설치 안내, `git init` 안내)
- Git 명령 실행 구현
  - Process API 기반 git 명령 실행
  - working directory를 projectRoot로 고정
  - arguments 배열 전달 (shell injection 방지)
  - `--` 사용으로 파일명 안전 처리
  - commit hash 반환 및 출력
- `kps solve` 명령어 구현
  - Git add, commit, push 자동화
  - `--no-push` 옵션 지원
  - `--message` 옵션으로 커스텀 커밋 메시지
  - 기본 커밋 메시지: `solve: [Platform] {number}`
  - push 실패 시 상세 힌트 제공
- README 작성
  - 설치 가이드 (Releases, Homebrew, 소스 빌드)
  - Quick Start (3분 완성)
  - 명령어 레퍼런스
  - FAQ & Troubleshooting
  - Exit Code 정책
- **v0.1.0 릴리즈 완료** 🎉
  - 릴리즈 빌드 성공 (1.7MB)
  - 모든 단위 테스트 통과 (52개)
  - SwiftLint 린터 검증 완료
  - Git 태그 v0.1.0 생성 및 푸시
  - GitHub Release 생성 (바이너리 업로드)
  - 저장소 Public 전환
  - 다운로드 URL 검증 완료
- 하위 디렉토리 지원 강화
  - `kps solve`에서 git status 기반 파일 검색
  - 플랫폼/번호 없이 현재 디렉토리에서 수정된 파일 자동 탐지
  - 다중 파일 매칭 감지 및 에러 처리
  - `kps open`에서 하위 폴더 재귀 탐색
  - FileManager.subpaths() 기반 패턴 매칭
  - 폴더 구조 자유도 향상 (예: BOJ/Floyd/1719.swift)
- History 풀이 상태 추적
  - HistoryEntry에 `solved: Bool` 필드 추가
  - `markAsSolved()` 메서드 구현
  - 하위 호환성 지원 (decodeIfPresent)
  - SolveCommand에서 커밋 성공 시 자동 업데이트
  - 향후 `kps list` 명령어 준비
  - 테스트 추가 (5개, 총 70개 테스트 통과)
- Xcode 프로젝트 통합
  - Config에 `xcodeProjectPath` 필드 추가
  - `kps init`에서 Xcode 프로젝트 자동 감지
  - `kps open` 명령어 구현 (최근/특정 파일 열기)
  - xed 명령으로 프로젝트와 파일 함께 열기
  - xed 미지원 시 시스템 기본 에디터로 폴백
  - History 기반 최근 파일 추적
  - xcodeProjectPath 미설정 시 설정 안내 메시지 추가
  - `kps open` (최근 파일 모드) 하위 폴더 재귀 탐색 지원
  - 파일 이동 감지 및 경로 변경 안내
  - KPSError.history, KPSError.open 에러 케이스 추가
  - README에 Getting Started 가이드 추가
- 문서 재구성 완료
  - ARCHITECTURE.md 생성 (프로젝트 정의, 기술 설계)
  - DEVELOPMENT_GUIDE.md 생성 (명령어 스펙, 릴리즈 가이드)
  - CHANGELOG.md 생성 (개발 히스토리)
  - CLAUDE.md 슬림화 및 참조 링크 업데이트
  - README 배포 상태 업데이트 (다운로드 URL 포함)
- 코드 품질 개선
  - SwiftLint 경고 전체 해결 (0 violations)
  - Console 시맨틱 헬퍼 추가
  - Process 헬퍼 추출 (GitExecutor)
  - Problem 파일 경로 헬퍼 추가
  - Command 책임 분리 (Init, New, Solve)

---

## v0.1.0-dev

### Week 2: 명령어 구현 (완료)

**핵심 기능:**
- 에러 시스템 구축
  - `KPSError` enum 정의 (17개 케이스)
  - NSError → KPSError 매핑 정책
  - 모든 에러에 해결 힌트 포함
  - Console 에러 출력 포맷 연동
- `PlatformOption` OptionGroup 구현
  - `-b`, `-p` 플래그 정의
  - `resolve()` 메서드 (충돌 감지)
  - `requirePlatform()` 메서드 (필수 검증)
- `kps init` 명령어
  - 프로젝트 초기화 (`--author`, `--source`)
  - `.kps/config.json` 생성
  - `--force` 옵션으로 덮어쓰기
  - git 없이도 동작
- `kps new` 명령어
  - URL/번호 기반 파일 생성
  - 입력 분기 로직 (`looksLikeURL()` 헬퍼)
  - 플랫폼 자동 감지 (BOJ, Programmers)
  - 템플릿 기반 파일 생성
  - 다음 행동 가이드 출력
- `kps config` 명령어
  - 전체 설정 조회
  - 특정 값 조회/수정
  - ConfigKey 검증
- 템플릿 시스템
  - Swift 파일 템플릿 정의
  - 변수 치환 로직 ({number}, {author}, {date}, {url})
  - 날짜 포맷 (POSIX locale)
- FileManager 확장
  - 디렉토리 생성
  - 파일 존재 확인
  - 안전한 파일 쓰기

**품질:**
- TemplateTests 추가
- 에러 메시지 문구 다듬기
- Smoke test: init → new 워크플로우
- 플래그 충돌/URL+플래그 에러 처리
- 입력 분기 로직 검증 (에러 삼킴 방지)

**설계 개선:**
- URL 파싱 에러 명확화 (unsupportedURL vs platformRequired)
- 다음 행동 가이드 추가 (`💡 Next: solve with 'kps solve ...'`)

---

### Week 1: 기반 구축 (완료)

**핵심 기능:**
- SPM 프로젝트 생성
  - ArgumentParser 통합
  - 폴더 구조 정의 (Commands, Core, Utils)
  - `main.swift` 엔트리포인트
  - `--version` 지원 (v0.1.0)
- Config 모델
  - `KPSConfig` struct (JSON 인코딩/디코딩)
  - Atomic write 지원
  - `ConfigKey` enum (author, sourceFolder, projectName)
  - `ConfigLocator` (상위 디렉토리 탐색)
  - `ProjectRoot` 구조체 (경로 관계 보장)
  - 모노레포 지원
- Platform & Problem 모델
  - `Platform` enum (boj, programmers)
  - baseURL 프로퍼티 (`school.programmers.co.kr` 정규화)
  - `Problem` struct (url, fileName, functionName)
- URLParser
  - BOJ URL 파싱 (`acmicpc.net/problem/{n}`, `boj.kr/{n}`)
  - Programmers URL 파싱 (canonical + 구버전 호환)
  - URL 정규화 (www, http/https, query, fragment)
  - 에러 처리 (unsupportedURL)
- Console Utils
  - stdout/stderr 분리
  - 출력 레벨 정의 (success, info, warning, error)
  - 아이콘 기반 메시지
- DateFormatter Utils
  - POSIX locale (일관성 보장)
  - yyyy/M/d 포맷
  - 로컬 타임존 사용

**품질:**
- 단위 테스트 22/22 통과
  - URLParserTests (BOJ, Programmers, 정규화, 에러)
  - ConfigTests (JSON 인코딩/디코딩, 파일 I/O)
  - ConfigLocatorTests (경로 탐색, 모노레포, ProjectRoot 검증)
- SwiftLint 통합 (SPM Plugin)
  - `.swiftlint.yml` 설정
  - `swift build` 시 자동 lint
  - 0 violations
- Swift Style Guide 문서화 (StyleShare 기반)
- Commit Convention 정립 (Conventional Commits)
- 문서화 주석 개선
  - URLParser helper 메서드
  - Config save/load 메서드
  - ConfigLocator locate 메서드

**설계 원칙 확립:**
- ConfigLocator 책임 분리 (파일 탐색 vs JSON 파싱)
- Result 타입 활용 (ConfigLocator)
- URL 정규화 정책 (입력 허용 vs 출력 통일)
- .git 발견 시 플래그만 설정, 탐색 계속 (모노레포)
- ProjectRoot 경로 관계 구조적 보장

---

## 참고

- **기술 아키텍처**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **개발자 가이드**: [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)
- **코드 스타일**: [SWIFT_STYLE_GUIDE.md](SWIFT_STYLE_GUIDE.md)
- **커밋 규칙**: [COMMIT_Convention.md](COMMIT_Convention.md)
