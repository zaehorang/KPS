# KPS Release Guide

> **문서 역할**: 이 문서는 KPS 프로젝트의 릴리즈 프로세스를 정의합니다.
> - **독자**: 릴리즈 담당자, 유지보수자
> - **목적**: 일관되고 안전한 릴리즈 수행
> - **관련 문서**: [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md), [CHANGELOG.md](CHANGELOG.md)

---

## 목차

1. [릴리즈 워크플로우 개요](#릴리즈-워크플로우-개요)
2. [사전 준비](#사전-준비)
3. [단계별 실행 가이드](#단계별-실행-가이드)
4. [배포 방식 설계 결정](#배포-방식-설계-결정)
5. [트러블슈팅](#트러블슈팅)
6. [롤백 절차](#롤백-절차)

---

## 릴리즈 워크플로우 개요

### 전체 프로세스 다이어그램

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: 코드 준비 (수동)                                    │
├─────────────────────────────────────────────────────────────┤
│ 1. 새 브랜치 생성                                            │
│ 2. 버전 번호 변경 (Sources/kps/KPS.swift)                   │
│ 3. 문서 업데이트 (CHANGELOG.md, README.md)                  │
│ 4. 테스트 실행 (swift test)                                 │
│ 5. PR 생성 및 리뷰                                           │
│ 6. main 브랜치에 머지                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: 릴리즈 트리거 (수동)                                │
├─────────────────────────────────────────────────────────────┤
│ 7. main에서 Git 태그 생성 (vX.Y.Z)                          │
│ 8. 태그 푸시 → GitHub Actions 자동 트리거                   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: 자동 빌드 및 배포 (GitHub Actions)                 │
├─────────────────────────────────────────────────────────────┤
│ 9. Intel (x86_64) 바이너리 빌드                             │
│ 10. Apple Silicon (arm64) 바이너리 빌드                     │
│ 11. tar.gz 압축 생성                                         │
│ 12. SHA256 체크섬 계산                                       │
│ 13. GitHub Release 생성                                      │
│ 14. 바이너리 업로드                                          │
│ 15. homebrew-tap에 Formula 업데이트 PR 생성                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: Formula 배포 (수동)                                 │
├─────────────────────────────────────────────────────────────┤
│ 16. homebrew-tap PR 검토                                     │
│ 17. PR 머지 → Homebrew 배포 완료                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 5: 검증 (수동)                                         │
├─────────────────────────────────────────────────────────────┤
│ 18. Homebrew 설치 테스트                                     │
│ 19. 기능 동작 확인                                           │
│ 20. 문서 동기화 (CHANGELOG.md 업데이트)                     │
└─────────────────────────────────────────────────────────────┘
```

### 소요 시간

| Phase | 단계 | 소요 시간 |
|-------|------|----------|
| Phase 1 | 코드 준비 | 10-20분 |
| Phase 2 | 태그 생성 | 1분 |
| Phase 3 | CI 자동 실행 | 2-3분 (자동) |
| Phase 4 | Formula 머지 | 2-5분 |
| Phase 5 | 검증 | 5-10분 |
| **총계** | | **20-40분** |

---

## 사전 준비

### 필수 확인 사항

#### 1. 환경 설정
```bash
# Git 설정 확인
git config user.name
git config user.email

# GitHub CLI 인증 확인
gh auth status

# Homebrew 설치 확인 (테스트용)
brew --version
```

#### 2. 저장소 상태
```bash
# 최신 상태로 업데이트
git checkout main
git pull origin main

# 클린 상태 확인
git status  # "working tree clean" 확인

# 모든 테스트 통과 확인
swift test
```

#### 3. GitHub Secrets 확인

**필수 Secret:**
- `HOMEBREW_TAP_TOKEN`: homebrew-tap 저장소 접근 권한

**확인 방법:**
1. https://github.com/zaehorang/KPSTool/settings/secrets/actions
2. `HOMEBREW_TAP_TOKEN` 존재 확인
3. 만료되지 않았는지 확인 (Personal Access Token)

---

## 단계별 실행 가이드

### Phase 1: 코드 준비

#### Step 1: 새 브랜치 생성

```bash
# 버전 번호를 결정 (Semantic Versioning)
# - MAJOR: 하위 호환성 없는 변경
# - MINOR: 하위 호환성 있는 새 기능
# - PATCH: 버그 수정
NEW_VERSION="0.2.0"  # 예시

# 브랜치 생성
git checkout -b release/v$NEW_VERSION
```

#### Step 2: 버전 번호 변경

**파일: `Sources/kps/KPS.swift`**

```bash
# 현재 버전 확인
grep 'version:' Sources/kps/KPS.swift

# 에디터로 변경
vim Sources/kps/KPS.swift
```

**변경 내용:**
```swift
static let configuration = CommandConfiguration(
    commandName: "kps",
    abstract: "Korean Problem Solving - 알고리즘 문제 풀이 추적 CLI",
    version: "0.2.0",  // ← 여기 변경
    subcommands: [
        // ...
    ]
)
```

**중요:**
- `v` 접두사 없이 숫자만 (예: `"0.2.0"`, ~~`"v0.2.0"`~~)
- 큰따옴표 유지
- Git 태그와 동일한 버전 사용 예정

#### Step 3: CHANGELOG.md 업데이트

**파일: `docs/CHANGELOG.md`**

```bash
vim docs/CHANGELOG.md
```

**추가할 섹션:**
```markdown
## v0.2.0 (2026-XX-XX)

### 새로운 기능

**완료:**
- [추가된 기능 목록]
  - 상세 설명
  - 관련 커밋

### 버그 수정
- [수정된 버그]

### 개선 사항
- [개선 내용]

---
```

**참고:**
- 기존 CHANGELOG.md의 [Unreleased] 섹션 내용을 새 버전으로 이동
- 날짜는 실제 릴리즈 날짜로 업데이트

#### Step 4: README.md 확인

**변경이 필요한 경우만:**
- 새로운 명령어 추가된 경우
- 설치 가이드 변경
- 주요 기능 추가

대부분의 경우 변경 불필요.

#### Step 5: 테스트 실행

```bash
# 모든 테스트 실행
swift test

# 릴리즈 빌드 테스트
swift build -c release

# 버전 출력 확인
.build/release/kps --version
# 출력: 0.2.0 (변경한 버전과 일치해야 함)

# SwiftLint 검증
swift build  # SwiftLint가 자동 실행됨
```

**모든 테스트가 통과해야 다음 단계 진행 가능.**

#### Step 6: 커밋 및 PR 생성

```bash
# 변경 사항 확인
git status
git diff

# 스테이징
git add Sources/kps/KPS.swift docs/CHANGELOG.md

# 커밋 (Conventional Commits 형식)
git commit -m "chore: bump version to $NEW_VERSION

- Update version in KPS.swift
- Update CHANGELOG.md with v$NEW_VERSION changes

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 푸시
git push origin release/v$NEW_VERSION

# PR 생성
gh pr create \
  --title "chore: bump version to v$NEW_VERSION" \
  --body "## Release v$NEW_VERSION

See CHANGELOG.md for details.

**Checklist:**
- [x] Version updated in KPS.swift
- [x] CHANGELOG.md updated
- [x] All tests passing
- [ ] Ready to tag and release"
```

#### Step 7: PR 리뷰 및 머지

```bash
# PR 확인
gh pr view

# CI 통과 대기
gh pr checks

# 머지 (Squash)
gh pr merge --squash --delete-branch

# main 업데이트
git checkout main
git pull origin main
```

---

### Phase 2: 릴리즈 트리거

#### Step 8: Git 태그 생성 및 푸시

```bash
# main 브랜치에서 작업
git checkout main
git pull origin main

# 태그 생성 (annotated tag)
git tag -a v$NEW_VERSION -m "Release v$NEW_VERSION: [주요 변경 사항 요약]"

# 예시
git tag -a v0.2.0 -m "Release v0.2.0: Add kps list command and statistics"

# 태그 확인
git tag -l "v*"
git show v$NEW_VERSION

# 태그 푸시 → CI 트리거
git push origin v$NEW_VERSION
```

**⚠️ 중요:**
- 태그 푸시 전 반드시 main이 최신 상태인지 확인
- 태그 이름은 `v`로 시작 (예: `v0.2.0`)
- 코드의 버전 번호와 일치해야 함 (코드: `"0.2.0"`, 태그: `v0.2.0`)

#### Step 9: GitHub Actions 모니터링

```bash
# 워크플로우 실행 확인
gh run list --workflow=release.yml --limit 5

# 실시간 모니터링 (선택)
gh run watch
```

**예상 시간:** 2-3분

**진행 상황 확인:**
1. https://github.com/zaehorang/KPSTool/actions
2. "Release" 워크플로우 클릭
3. 각 단계 진행 상황 확인

---

### Phase 3: 자동 빌드 및 배포 (GitHub Actions)

**이 단계는 완전 자동으로 진행됩니다.**

#### 자동으로 실행되는 작업

1. **빌드:**
   ```bash
   swift build -c release --arch x86_64  # Intel
   swift build -c release --arch arm64   # Apple Silicon
   ```

2. **압축:**
   ```bash
   tar -czf kps-x86_64-v$VERSION.tar.gz kps-x86_64
   tar -czf kps-arm64-v$VERSION.tar.gz kps-arm64
   ```

3. **체크섬 계산:**
   ```bash
   shasum -a 256 kps-x86_64-v$VERSION.tar.gz
   shasum -a 256 kps-arm64-v$VERSION.tar.gz
   ```

4. **GitHub Release 생성:**
   - 릴리즈 노트 자동 생성
   - 바이너리 파일 업로드
   - SHA256 체크섬 포함

5. **Homebrew Formula 업데이트:**
   - homebrew-tap 저장소 체크아웃
   - `Formula/kps.rb` 업데이트 (버전, URL, SHA256)
   - PR 자동 생성

#### 실패 시나리오

**빌드 실패:**
```bash
# 로그 확인
gh run view --log-failed

# 일반적인 원인:
# - 코드 컴파일 에러
# - 테스트 실패
# - 의존성 문제
```

**Release 생성 실패 (403 에러):**
```bash
# 원인: GitHub Actions 권한 부족
# 해결: .github/workflows/release.yml에 권한 확인
permissions:
  contents: write
  pull-requests: write
```

**Formula PR 생성 실패:**
```bash
# 원인: HOMEBREW_TAP_TOKEN 만료 또는 권한 부족
# 해결: Token 재생성 및 Secrets 업데이트
```

---

### Phase 4: Formula 배포

#### Step 10: homebrew-tap PR 검토

```bash
# homebrew-tap 저장소로 이동
cd ../homebrew-tap
git pull origin main

# PR 목록 확인
gh pr list

# PR 상세 확인
gh pr view 1  # PR 번호는 자동 생성된 것
```

**검토 항목:**

1. **버전 번호:**
   ```ruby
   version "0.2.0"  # 올바른 버전인지 확인
   ```

2. **URL:**
   ```ruby
   url "https://github.com/zaehorang/KPSTool/releases/download/v0.2.0/kps-arm64-v0.2.0.tar.gz"
   # ↑ 버전이 올바른지, URL이 실제로 존재하는지
   ```

3. **SHA256:**
   ```ruby
   sha256 "abc123..."  # PLACEHOLDER가 아닌 실제 해시인지
   ```

4. **Diff 확인:**
   ```bash
   gh pr diff 1

   # 변경 사항이 예상과 일치하는지 확인:
   # - version 라인 1개
   # - url 라인 2개 (Intel + ARM)
   # - sha256 라인 2개
   ```

#### Step 11: Formula 테스트 (선택)

**로컬 테스트:**
```bash
# homebrew-tap 디렉토리에서
brew tap zaehorang/tap .
brew install --build-from-source kps

# 설치 확인
kps --version  # 새 버전 출력되어야 함

# 테스트 실행
brew test kps

# Formula 문법 검증
brew audit --strict kps

# 정리
brew uninstall kps
brew untap zaehorang/tap
```

#### Step 12: PR 머지

```bash
# PR 머지
gh pr merge 1 --squash --delete-branch

# 또는 GitHub UI에서 머지
```

**머지 후:**
- ✅ Homebrew Formula 배포 완료
- ✅ 사용자가 `brew install kps` 가능

---

### Phase 5: 검증

#### Step 13: 설치 테스트

```bash
# 기존 kps 제거 (있는 경우)
brew uninstall kps 2>/dev/null || true
brew untap zaehorang/tap 2>/dev/null || true

# 클린 설치
brew tap zaehorang/tap
brew install kps

# 버전 확인
kps --version
# 출력: 0.2.0 (새 버전)

# 기본 명령어 테스트
kps --help
kps init --help
```

#### Step 14: 기능 동작 확인

```bash
# 임시 디렉토리에서 테스트
cd $(mktemp -d)

# 전체 워크플로우
kps init -a "Test" -s "Sources"
kps new 1000 -b
kps config

# 파일 생성 확인
ls -la Sources/BOJ/
```

#### Step 15: 문서 동기화

```bash
# KPSTool 저장소로 돌아가기
cd /path/to/KPSTool

# CHANGELOG.md 최종 업데이트 (릴리즈 날짜 등)
vim docs/CHANGELOG.md

# 커밋
git add docs/CHANGELOG.md
git commit -m "docs: finalize CHANGELOG for v$NEW_VERSION"
git push origin main

# /pm sync 실행 (선택)
# Claude Code를 통해 실행
```

---

## 배포 방식 설계 결정

### 왜 이렇게 설계했는가?

#### 1. 수동 버전 관리

**결정:** 코드에 버전을 하드코딩하고 수동으로 변경

**고려한 대안:**
- Git 태그에서 자동 주입
- Package.swift 메타데이터 활용
- 별도 버전 파일

**선택 이유:**
- ✅ **단순성**: 한 줄만 수정하면 됨
- ✅ **로컬 개발 용이**: `swift build`가 항상 작동
- ✅ **디버깅 쉬움**: 버전이 코드에 명시
- ✅ **CI 의존성 없음**: 빌드 스크립트 불필요

**트레이드오프:**
- ❌ 버전을 2곳에 입력 (코드 + 태그)
- ❌ 불일치 가능성 (완화: Pre-release 체크)

**언제 재검토:**
- 릴리즈 빈도가 주 1회 이상
- 여러 파일에 버전 분산
- 나이틀리 빌드 필요

---

#### 2. PR 기반 릴리즈

**결정:** main에 직접 커밋하지 않고 PR을 통해 리뷰

**고려한 대안:**
- main에 직접 커밋 후 태그
- Release 브랜치 별도 관리

**선택 이유:**
- ✅ **코드 리뷰**: 버전 변경 검증
- ✅ **CI 테스트**: PR 시 자동 실행
- ✅ **히스토리 명확**: 릴리즈 의도 명시
- ✅ **롤백 용이**: PR 취소하면 됨

**트레이드오프:**
- ❌ 단계 추가 (PR 생성/머지)
- ✅ 하지만 안전성 > 편의성

---

#### 3. Git 태그 트리거

**결정:** PR 머지가 아닌 태그 푸시로 CI 트리거

**고려한 대안:**
- PR 머지 시 자동 릴리즈
- 수동 워크플로우 실행

**선택 이유:**
- ✅ **의도 명확화**: 태그 = 릴리즈 의도
- ✅ **실수 방지**: 모든 PR이 릴리즈는 아님
- ✅ **Semantic Versioning**: 태그가 버전 표준
- ✅ **Git History**: 영구 기록

**워크플로우:**
```yaml
on:
  push:
    tags:
      - 'v*'  # v로 시작하는 태그만
```

---

#### 4. Pre-built Binary 배포

**결정:** 소스 빌드가 아닌 pre-built 바이너리 제공

**고려한 대안:**
- Source-based build (사용자 머신에서 컴파일)
- Universal Binary (Intel + ARM 합침)

**선택 이유:**
- ✅ **빠른 설치**: 3초 (vs 2-3분)
- ✅ **의존성 없음**: Xcode 불필요
- ✅ **사용자 경험**: 다운로드만 하면 됨

**트레이드오프:**
- ❌ CI 복잡도: 두 아키텍처 빌드
- ❌ Formula 복잡도: 조건부 URL/SHA256
- ✅ 하지만 사용자 경험 > 개발 편의

---

#### 5. Auto-PR (not Auto-commit)

**결정:** Formula 업데이트를 자동 커밋이 아닌 PR 생성

**고려한 대안:**
- 자동 커밋 및 푸시
- 수동 Formula 업데이트

**선택 이유:**
- ✅ **안전장치**: 잘못된 SHA256 검증 가능
- ✅ **투명성**: 변경 히스토리 PR로 추적
- ✅ **롤백 용이**: PR 닫기만 하면 됨

**트레이드오프:**
- ❌ 수동 머지 필요 (1분 소요)
- ✅ 하지만 안전성 > 완전 자동화

---

#### 6. Multi-arch 별도 파일

**결정:** Universal Binary가 아닌 별도 파일 (x86_64, arm64)

**고려한 대안:**
- Universal Binary (lipo로 합침)
- Source-based (아키텍처 자동)

**선택 이유:**
- ✅ **파일 크기**: 1.8MB (vs 3.6MB)
- ✅ **다운로드 효율**: 필요한 것만
- ✅ **CI 단순**: 순차 빌드 가능

**트레이드오프:**
- ❌ Formula 복잡: 조건부 로직
- ✅ 하지만 Homebrew 표준 방식

---

## 트러블슈팅

### 문제: 태그 푸시 후 CI가 실행 안 됨

**증상:**
```bash
git push origin v0.2.0
# Actions 페이지에 워크플로우 없음
```

**원인:**
- 태그 이름이 `v*` 패턴과 불일치
- `.github/workflows/release.yml` 파일 누락
- 워크플로우 비활성화

**해결:**
```bash
# 1. 태그 확인
git tag -l "v*"

# 2. 워크플로우 파일 확인
ls -la .github/workflows/release.yml

# 3. GitHub Actions 활성화 확인
# Settings → Actions → General → Allow all actions
```

---

### 문제: 빌드 실패 (403 Permission Denied)

**증상:**
```
❌ GitHub release failed with status: 403
```

**원인:**
- `GITHUB_TOKEN` 권한 부족

**해결:**
```yaml
# .github/workflows/release.yml
permissions:
  contents: write        # Release 생성 권한
  pull-requests: write   # PR 생성 권한
```

---

### 문제: Formula PR이 생성되지 않음

**증상:**
- Release는 생성됨
- homebrew-tap에 PR 없음

**원인:**
- `HOMEBREW_TAP_TOKEN` 만료
- Token 권한 부족
- homebrew-tap 저장소 URL 오류

**해결:**
```bash
# 1. Token 재생성
# GitHub Settings → Developer settings → Personal access tokens
# Scope: repo (전체)

# 2. Secrets 업데이트
# https://github.com/zaehorang/KPSTool/settings/secrets/actions
# HOMEBREW_TAP_TOKEN 업데이트

# 3. 태그 재푸시 (필요 시)
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0
```

---

### 문제: 버전 불일치

**증상:**
```bash
kps --version
# 출력: 0.1.1 (예상: 0.2.0)
```

**원인:**
- 코드 버전 변경 누락
- 잘못된 바이너리 빌드

**예방:**
```bash
# Pre-release 체크 스크립트 (향후 추가 예정)
./scripts/pre-release.sh v0.2.0
# ❌ Version mismatch: Code=0.1.1, Tag=0.2.0
```

**해결:**
```bash
# 1. 코드 버전 수정
vim Sources/kps/KPS.swift

# 2. 커밋 및 푸시
git add Sources/kps/KPS.swift
git commit -m "fix: correct version to 0.2.0"
git push origin main

# 3. 태그 재생성
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0
```

---

### 문제: SHA256 체크섬 오류

**증상:**
```bash
brew install kps
# Error: SHA256 mismatch
```

**원인:**
- Formula의 SHA256이 실제 파일과 불일치
- CI에서 SHA256 계산 오류

**해결:**
```bash
# 1. 실제 SHA256 확인
curl -sL https://github.com/zaehorang/KPSTool/releases/download/v0.2.0/kps-arm64-v0.2.0.tar.gz \
  | shasum -a 256

# 2. Formula 수동 수정
cd ../homebrew-tap
vim Formula/kps.rb
# sha256을 올바른 값으로 수정

# 3. 커밋 및 푸시
git add Formula/kps.rb
git commit -m "fix: correct SHA256 for v0.2.0"
git push origin main
```

---

### 문제: Homebrew 설치 실패 (Formula not found)

**증상:**
```bash
brew install kps
# Error: No available formula with the name "kps"
```

**원인:**
- Tap이 제대로 클론되지 않음
- Homebrew 캐시 문제

**해결:**
```bash
# 1. Tap 제거 및 재추가
brew untap zaehorang/tap
brew tap zaehorang/tap https://github.com/zaehorang/homebrew-tap.git

# 2. Homebrew 업데이트
brew update

# 3. 재시도
brew install kps
```

---

## 롤백 절차

### 시나리오 1: 태그 푸시 전 (코드만 머지됨)

**상황:**
- PR을 머지했지만 아직 태그 푸시 안 함
- 문제 발견 (버그, 버전 오류 등)

**롤백:**
```bash
# 1. Revert 커밋 생성
git revert HEAD
git push origin main

# 2. 또는 새 PR로 수정
git checkout -b fix/version-correction
# 수정 작업
git push origin fix/version-correction
gh pr create
```

**영향:** 없음 (릴리즈 전)

---

### 시나리오 2: 태그 푸시 후 (CI 실행 중)

**상황:**
- 태그 푸시했지만 CI 아직 실행 중
- 문제 발견

**롤백:**
```bash
# 1. CI 취소
gh run cancel

# 2. 태그 삭제 (로컬 + 원격)
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0

# 3. GitHub Release 삭제 (생성된 경우)
gh release delete v0.2.0 --yes

# 4. 코드 수정 후 다시 시작
```

**영향:** 없음 (Release 생성 전)

---

### 시나리오 3: Release 생성 후 (Formula PR 전)

**상황:**
- GitHub Release 생성됨
- homebrew-tap PR 아직 머지 안 함
- 문제 발견

**롤백:**
```bash
# 1. homebrew-tap PR 닫기
gh pr close 1

# 2. GitHub Release 삭제
gh release delete v0.2.0 --yes

# 3. 태그 삭제
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0

# 4. 수정 후 다시 릴리즈
```

**영향:** 없음 (사용자 설치 불가능)

---

### 시나리오 4: Formula 배포 후 (사용자 설치 가능)

**상황:**
- Homebrew 배포 완료
- 사용자가 이미 설치 가능
- 심각한 버그 발견

**핫픽스 릴리즈 (권장):**
```bash
# 1. 긴급 수정
git checkout -b hotfix/v0.2.1
# 버그 수정
vim Sources/...

# 2. 버전 업데이트 (Patch 버전)
vim Sources/kps/KPS.swift
# version: "0.2.1"

# 3. 긴급 릴리즈
git commit -m "fix: critical bug in v0.2.0"
gh pr create
gh pr merge --squash

git tag -a v0.2.1 -m "Hotfix v0.2.1: Fix critical bug"
git push origin v0.2.1
```

**완전 롤백 (비권장):**
```bash
# ⚠️ 사용자 혼란 초래 가능

# 1. Formula 되돌리기
cd ../homebrew-tap
git revert HEAD  # Formula 업데이트 커밋 되돌림
git push origin main

# 2. Release 삭제
gh release delete v0.2.0 --yes

# 3. 태그 삭제
git tag -d v0.2.0
git push origin :refs/tags/v0.2.0

# 4. 사용자 공지
# GitHub Discussions 또는 README에 공지
```

**영향:**
- ❌ 이미 설치한 사용자 영향
- ❌ Git history 오염
- ✅ 핫픽스가 더 나은 방법

---

## 체크리스트

### Pre-release 체크리스트

릴리즈 시작 전 확인:

- [ ] Git 상태 클린 (`git status`)
- [ ] main 브랜치 최신 (`git pull origin main`)
- [ ] 모든 테스트 통과 (`swift test`)
- [ ] SwiftLint 경고 없음 (`swift build`)
- [ ] HOMEBREW_TAP_TOKEN 유효
- [ ] 릴리즈 노트 준비 (CHANGELOG.md)

### Release 체크리스트

릴리즈 진행 중 확인:

**Phase 1: 코드 준비**
- [ ] 새 브랜치 생성
- [ ] `Sources/kps/KPS.swift` 버전 변경
- [ ] `docs/CHANGELOG.md` 업데이트
- [ ] 테스트 통과 확인
- [ ] PR 생성 및 머지

**Phase 2: 태그 & CI**
- [ ] main에서 태그 생성 (`v0.X.Y`)
- [ ] 태그 푸시
- [ ] CI 실행 확인 (GitHub Actions)
- [ ] 빌드 성공 확인

**Phase 3: Formula**
- [ ] homebrew-tap PR 생성 확인
- [ ] PR 내용 검토 (버전, URL, SHA256)
- [ ] PR 머지

**Phase 4: 검증**
- [ ] `brew install kps` 테스트
- [ ] `kps --version` 확인
- [ ] 기본 명령어 동작 확인
- [ ] 문서 최종 업데이트

### Post-release 체크리스트

릴리즈 완료 후:

- [ ] GitHub Release notes 확인
- [ ] CHANGELOG.md 최종 업데이트
- [ ] `/pm sync` 실행
- [ ] 공지 (필요 시)
- [ ] 다음 버전 마일스톤 생성 (선택)

---

## 참고 자료

### 관련 문서
- [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) - 개발 가이드
- [CHANGELOG.md](CHANGELOG.md) - 변경 이력
- [Plan/2026-01-28_homebrew-deployment.md](../Plan/2026-01-28_homebrew-deployment.md) - Homebrew 배포 계획

### 외부 링크
- [Semantic Versioning](https://semver.org/) - 버전 관리 규칙
- [Conventional Commits](https://www.conventionalcommits.org/) - 커밋 메시지 규칙
- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook) - Formula 작성 가이드
- [GitHub Actions Documentation](https://docs.github.com/en/actions) - CI/CD 설정

---

**마지막 업데이트:** 2026-01-28
**버전:** 1.0
**관리자:** @zaehorang
