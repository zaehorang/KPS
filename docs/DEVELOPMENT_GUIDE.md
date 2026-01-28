# KPS Development Guide

> **문서 역할**: 이 문서는 KPS 프로젝트의 개발자 가이드입니다.
> - **독자**: 개발자, 기여자
> - **목적**: 빌드 방법, 명령어 상세 스펙, 테스트 전략, 릴리즈 계획 제공
> - **관련 문서**: [ARCHITECTURE.md](ARCHITECTURE.md) - 기술 아키텍처 및 설계 원칙

---

## 1. 빌드 & 실행

### 빌드

```bash
# 개발 빌드
swift build

# 릴리즈 빌드
swift build -c release
```

### 테스트

```bash
# 모든 테스트 실행
swift test

# 특정 테스트만 실행
swift test --filter URLParserTests
```

### 실행

```bash
# 개발 빌드 실행
.build/debug/kps --help

# 릴리즈 빌드 실행
.build/release/kps --help
```

---

## 2. 명령어 상세 스펙

### 2.1 `kps init`

프로젝트를 KPS로 초기화합니다.

```bash
kps init --author "Name" --source "AlgorithmStudy"
kps init -a "Name" -s "Sources"
```

**옵션:**

| 옵션 | 축약 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `--author` | `-a` | O | - | 작성자 이름 |
| `--source` | `-s` | X | `"Sources"` | 소스 폴더명 |
| `--force` | `-f` | X | `false` | 기존 설정 덮어쓰기 |

**처리 흐름:**

```
1. 현재 디렉토리명 → projectName
2. .kps 존재 확인
   ├─ 존재 + force 없음 → 에러
   └─ 존재 + force 있음 → 덮어쓰기
3. .kps/config.json 생성
4. 성공 메시지 출력

※ git repo 여부 체크 안 함 (init은 git 없이도 동작)
```

**출력 예시:**

```
✅ Config created!
   Author: Name
   Project: Swift_Algorithm
   Source: AlgorithmStudy
```

---

### 2.2 `kps new`

문제 풀이 파일을 생성합니다.

```bash
# URL로 생성
kps new "https://acmicpc.net/problem/1000"
kps new "https://school.programmers.co.kr/learn/courses/30/lessons/340207"

# 번호로 생성
kps new 1000 -b
kps new 12345 -p
```

**옵션:**

| 옵션 | 축약 | 설명 |
|------|------|------|
| `--boj` | `-b` | BOJ 플랫폼 지정 |
| `--programmers` | `-p` | Programmers 플랫폼 지정 |

**입력 규칙:**

| 입력 | 결과 |
|------|------|
| 번호만 (플래그 없음) | `platformRequired` 에러 |
| `-b -p` 둘 다 | `conflictingPlatformFlags` 에러 |
| URL + 플래그 | `urlWithPlatformFlag` 에러 |

**URL 파싱 규칙:**

| 입력 패턴 | 플랫폼 | 추출 |
|----------|--------|------|
| `acmicpc.net/problem/{n}` | BOJ | n |
| `boj.kr/{n}` | BOJ | n |
| `school.programmers.co.kr/.../lessons/{n}` | Programmers | n |
| `programmers.co.kr/.../lessons/{n}` | Programmers | n (구버전 호환) |

**URL 정규화 정책:**
- **입력 허용**: `programmers.co.kr`, `school.programmers.co.kr` 둘 다
- **출력 통일**: 생성되는 파일의 URL은 항상 `school.programmers.co.kr`로 저장
- www 접두사 처리
- http/https 모두 지원
- query string 무시
- fragment 무시

**처리 흐름:**

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

**출력 예시:**

```
✔ Platform: BOJ
✔ Problem: 1000
✔ File: AlgorithmStudy/BOJ/1000.swift
🔗 https://acmicpc.net/problem/1000
💡 Next: solve with 'kps solve 1000 -b'
```

---

### 2.3 `kps solve`

문제 풀이를 Git에 커밋하고 푸시합니다.

```bash
# 커밋 & 푸시
kps solve 1000 -b

# 커밋만 (푸시 안 함)
kps solve 1000 -b --no-push

# 커스텀 커밋 메시지
kps solve 1000 -b -m "refactor solution"
```

**옵션:**

| 옵션 | 축약 | 기본값 | 설명 |
|------|------|--------|------|
| `--boj` | `-b` | - | BOJ 플랫폼 |
| `--programmers` | `-p` | - | Programmers 플랫폼 |
| `--no-push` | - | `false` | commit만 수행 |
| `--message` | `-m` | 자동생성 | 커밋 메시지 커스텀 |

**기본 커밋 메시지:**

```
solve: [BOJ] 1000
solve: [Programmers] 12345
```

**처리 흐름:**

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

**Git 명령 실행 원칙:**

| 원칙 | 설명 |
|------|------|
| working directory | `projectRoot`로 고정 |
| arguments | 배열로 전달 (shell 문자열 금지) |
| `--` 사용 | 옵션 파싱 종료, 파일명 안전 처리 |

**Git 실패 처리:**

| 단계 | 실패 시 동작 |
|------|-------------|
| preflight (git 미설치) | 에러 메시지 + 설치 안내 + exit 1 |
| preflight (non-repo) | 에러 메시지 + `git init` 안내 + exit 1 |
| add 실패 | 에러 메시지 + exit 1 |
| commit 실패 (nothing to commit) | 친절한 에러 + exit 1 |
| commit 실패 (기타) | 에러 메시지 + exit 1 |
| push 실패 | 경고 메시지 + 상세 힌트 + exit 1 |

**출력 예시:**

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

---

### 2.4 `kps config`

설정을 조회하거나 수정합니다.

```bash
# 전체 설정 조회
kps config

# 특정 값 조회
kps config author

# 값 수정
kps config author "New Name"
```

**설정 키:**
- `author`: 작성자 이름
- `sourceFolder`: 소스 폴더 경로
- `projectName`: 프로젝트 이름
- `xcodeProjectPath`: Xcode 프로젝트 경로 (선택 사항)

**처리 흐름:**

```
1. ConfigLocator로 프로젝트 루트 찾기
2. Config 로드
3. 인자 개수에 따라 분기
   ├─ 0개: 전체 설정 출력
   ├─ 1개: 특정 키 값 조회
   └─ 2개: 키 값 수정 후 저장
```

---

### 2.5 `kps open`

문제 파일을 Xcode에서 엽니다.

```bash
# 최근 파일 열기 (history 기반)
kps open

# 특정 문제 파일 열기
kps open 1000 -b
kps open 340207 -p
```

**옵션:**

| 옵션 | 축약 | 필수 | 설명 |
|------|------|------|------|
| `--boj` | `-b` | X | BOJ 플랫폼 (번호 지정 시 필수) |
| `--programmers` | `-p` | X | Programmers 플랫폼 (번호 지정 시 필수) |

**처리 흐름:**

```
1. ConfigLocator로 프로젝트 루트 찾기
2. Config 로드

3. 파일 경로 결정
   ├─ 번호 지정됨: platform + number → filePath
   └─ 번호 없음: history.json에서 mostRecent() → filePath

4. 파일 열기
   ├─ xcodeProjectPath 설정됨
   │  ├─ 프로젝트 파일 존재 확인
   │  └─ xed -p project.xcodeproj file.swift
   └─ xcodeProjectPath 없음
      └─ open file.swift (시스템 기본 에디터)

5. xed 실패 시 fallback
   ├─ xed not found → 경고 + open으로 fallback
   └─ 기타 오류 → 에러 throw
```

**Xcode 통합 동작:**

```bash
# Xcode 프로젝트 경로가 설정되어 있으면:
$ kps open 1000 -b

# 실행되는 명령어:
xed -p AlgorithmStudy.xcodeproj AlgorithmStudy/BOJ/1000.swift

# 결과:
# - Xcode에서 AlgorithmStudy.xcodeproj 열림
# - 1000.swift가 프로젝트 네비게이터에서 활성화됨
# - 빌드/실행 가능한 상태
```

**-p 플래그 필요성:**

`xed -p`의 `-p` 플래그는 **프로젝트 컨텍스트**에서 파일을 열기 위해 필수입니다:
- `-p` 있음: 파일이 프로젝트 네비게이터 안에서 열림
- `-p` 없음: 파일이 별도 창으로 열림 (빌드 불가)

**History 기반 최근 파일:**

`kps open` (인자 없음) 실행 시:

1. `.kps/history.json` 로드
2. `mostRecent()` 호출 → 가장 최근 `HistoryEntry` 반환
3. `entry.filePath`로 파일 열기

**에러 처리:**

| 상황 | 처리 |
|------|------|
| History 없음 | `KPSError.history(.noRecentFile)` |
| 최근 파일 삭제됨 | `KPSError.history(.fileDeleted(path))` |
| Xcode 프로젝트 없음 | 경고 + `open` fallback |
| xed 미설치 | 경고 + `open` fallback |
| 파일 없음 | `KPSError.file(.notFound(path))` |

**출력 예시:**

```bash
# 성공
$ kps open 1000 -b
✅ Opened: /Users/user/Project/Sources/BOJ/1000.swift

# Xcode 프로젝트 없음 (fallback)
$ kps open
⚠️ Xcode project not found: AlgorithmStudy.xcodeproj
💡 Run 'kps init --force' to re-detect Xcode project
✔ Falling back to default editor...
✅ Opened: /Users/user/Project/Sources/BOJ/1000.swift

# xed 없음 (fallback)
$ kps open
⚠️ xed not available. Install Xcode Command Line Tools.
✔ Falling back to default editor...
✅ Opened: /Users/user/Project/Sources/BOJ/1000.swift
```

**요구사항:**

- Xcode 프로젝트 사용 시: Xcode Command Line Tools 필요
  ```bash
  xcode-select --install
  ```
- History 기능: `kps new` 명령어로 파일 생성 시 자동 기록

---

## 3. 테스트 전략

### 3.1 단위 테스트 (필수)

| 대상 | 테스트 케이스 |
|------|--------------|
| **URLParser** | BOJ URL, Programmers URL, boj.kr 단축, www 접두사, http URL, query string, fragment, 잘못된 URL |
| **Config** | JSON 인코딩/디코딩, 파일 저장/로드, ConfigKey 검증, xcodeProjectPath 인코딩/디코딩 |
| **ConfigLocator** | 현재 디렉토리, 상위 디렉토리, config 없음, .git만 있음, 모노레포, ProjectRoot 구조 검증 |
| **Template** | 변수 치환, 날짜 포맷 |
| **History** | JSON 인코딩/디코딩, addEntry 순서 보존, mostRecent 반환, atomic write, 파일 로드 실패 처리 |

**실행:**
```bash
swift test
```

### 3.2 Smoke Test (수동)

전체 워크플로우 수동 실행:

```bash
# git 없이 기본 동작
kps init -a "Test" -s "Sources"
kps new 1000 -b
kps config

# git 있는 환경에서 전체 흐름
git init
kps new 1001 -b
kps open 1001 -b  # Xcode에서 파일 열기
# 파일에 코드 작성
kps solve 1001 -b --no-push

# Xcode 통합 테스트
kps config xcodeProjectPath "MyProject.xcodeproj"
kps new 9999 -b
kps open 9999 -b  # Xcode 프로젝트와 함께 열려야 함
kps open  # 최근 파일 (9999.swift) 열기
```

### 3.3 테스트하지 않는 것

- ArgumentParser 옵션 파싱 (라이브러리 책임)
- Git 명령어 자체 동작 (외부 의존성)
- 파일 시스템 권한 문제 (환경 의존적)

---

## 4. 릴리즈 체크리스트

### v0.1.0 출시 전 최종 확인

#### 기능 검증
- [ ] 모든 단위 테스트 통과
- [ ] init → new → solve 전체 워크플로우 동작
- [ ] git 없이 init → new → config 동작
- [ ] 하위 폴더에서 모든 명령 정상 동작
- [ ] 모든 에러 메시지에 해결 힌트 포함
- [ ] push 실패 시 성공 메시지 없음 확인
- [ ] `--no-push` 성공 시 `Done! (push skipped)` 출력 확인
- [ ] `kps new` 후 다음 행동 가이드 출력 확인
- [ ] 잘못된 URL 입력 시 올바른 에러 출력 확인 (에러 삼킴 없음)

#### URL 파싱 검증
- [ ] `school.programmers.co.kr` URL 파싱 동작
- [ ] `programmers.co.kr` URL 파싱 동작 (구버전 호환)
- [ ] 생성된 파일의 URL이 `school.programmers.co.kr`로 통일되는지 확인

#### 품질 체크
- [ ] `kps --version` 출력 확인
- [ ] `kps --help` 출력 점검 (예시 포함 여부)
- [ ] `kps init --help`, `kps new --help` 등 서브커맨드 help 점검
- [ ] 실행 파일명 일관성 확인 (`kps`)
- [ ] 파일명에 공백/특수문자 있을 때 동작
- [ ] 쓰기 권한 실패 시 메시지 (권한/경로 안내)

#### 문서 & 배포
- [ ] README 완성 (설치 가이드, 명령어, FAQ)
- [ ] LICENSE 파일 존재
- [ ] GitHub Release 태그 생성

---

## 5. 배포 계획

### v0.1.0 (MVP) ✅ 완료

**배포 방식**: GitHub Release

```bash
git clone https://github.com/zaehorang/kps.git
cd kps
swift build -c release
sudo cp .build/release/kps /usr/local/bin/
```

**릴리즈 태그:**
```bash
git tag -a v0.1.0 -m "Release v0.1.0: MVP"
git push origin v0.1.0
```

---

### v0.1.1 (Homebrew 배포) ✅ 완료

**배포 방식**: Homebrew tap + GitHub Release

```bash
brew tap zaehorang/tap
brew install kps
```

**완료 항목:**
- ✅ Formula 작성 (Multi-arch 지원)
- ✅ homebrew-tap 저장소 생성
- ✅ 바이너리 자동 빌드 (GitHub Actions)
- ✅ GitHub Release 자동화
- ✅ Formula 자동 업데이트 (PR)

**배포 결과:**
- homebrew-tap: https://github.com/zaehorang/homebrew-tap
- Release: https://github.com/zaehorang/KPSTool/releases/tag/v0.1.1

---

### v0.2.0 (향후 계획)

**목표**: 사용자 경험 개선 및 기능 확장

---

## 6. v0.2 이후 고려사항

### 구조적 변경
- **Protocol 기반 아키텍처**: `PlatformProvider`, `FileGenerator` 등으로 확장성 개선
- **의존성 주입**: 테스트 용이성 향상

### 기능 추가

| 기능 | 설명 | 명령어 |
|------|------|--------|
| 문제 페이지 열기 | 브라우저에서 문제 페이지 오픈 | `kps open` |
| 풀이 목록 | 풀이한 문제 목록 조회 | `kps list` |
| 풀이 통계 | 플랫폼별, 기간별 통계 | `kps stats` |

### 데이터 축적
- **학습 로그**: `.kps/history.json`에 풀이 기록 저장
- **재도전 추적**: 같은 문제를 여러 번 푼 기록
- **난이도 메타데이터**: 백준 티어, 프로그래머스 레벨 자동 수집

---

## 참고

- **기술 아키텍처**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **릴리즈 가이드**: [RELEASE_GUIDE.md](RELEASE_GUIDE.md) - 버전 배포 프로세스
- **CI/CD 가이드**: [CICD_GUIDE.md](CICD_GUIDE.md)
- **에이전트 워크플로우**: [../CLAUDE.md](../CLAUDE.md)
- **코드 스타일**: [SWIFT_STYLE_GUIDE.md](SWIFT_STYLE_GUIDE.md)
- **커밋 규칙**: [COMMIT_Convention.md](COMMIT_Convention.md)
