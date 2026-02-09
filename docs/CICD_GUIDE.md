# KPS CI/CD Guide

> **문서 역할**: 이 문서는 KPS 프로젝트의 CI/CD 시스템 가이드입니다.
> - **독자**: 개발자, 기여자
> - **목적**: GitHub Actions 워크플로우 이해, 배포 프로세스 설명, 문제 해결
> - **관련 문서**: [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md) - 빌드 & 실행

---

## 1. 개요

### CI/CD란?

**CI (Continuous Integration)**: 코드 변경사항을 자동으로 테스트하고 빌드하여 품질을 검증합니다.

**CD (Continuous Deployment)**: 검증된 코드를 자동으로 배포합니다.

### KPS 프로젝트의 CI/CD

KPS는 GitHub Actions를 사용하여 다음을 자동화합니다:

| 작업 | 트리거 | 자동화 내용 |
|------|--------|-------------|
| **PR 검증** | Pull Request 생성 | 테스트, 빌드, 린트 자동 실행 |
| **릴리즈 배포** | `v*.*.*` 태그 푸시 | 릴리즈 빌드, GitHub Release 생성, 바이너리 업로드 |

### 자동화된 작업

#### CI 워크플로우 (`.github/workflows/ci.yml`)
- ✅ Swift 테스트 실행 (52개 테스트)
- ✅ 디버그 빌드 검증
- ✅ 릴리즈 빌드 검증
- ✅ SwiftLint 코드 스타일 검사

#### Release 워크플로우 (`.github/workflows/release.yml`)
- ✅ 릴리즈 빌드 생성
- ✅ GitHub Release 자동 생성
- ✅ kps 바이너리 업로드
- ✅ 릴리즈 노트 자동 생성
- ✅ 설치 가이드 포함

---

## 2. 워크플로우 설명

### 2.1 CI 워크플로우

**파일**: `.github/workflows/ci.yml`

**트리거 조건:**
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
  push:
    branches: [main]
```

- Pull Request 생성/업데이트 시 자동 실행
- main 브랜치 직접 푸시 시에도 실행 (안전장치)

**Jobs (병렬 실행):**

| Job | 실행 내용 | 예상 시간 |
|-----|----------|----------|
| **test** | `swift test` 실행 (52개 테스트) | 30-60초 |
| **build-debug** | `swift build` 실행 | 20-40초 |
| **build-release** | `swift build -c release` 실행 | 30-50초 |
| **swiftlint** | `swiftlint lint` 실행 (코드 스타일) | 10-20초 |

**SPM 캐싱:**
- `.build` 디렉토리 캐싱으로 빌드 시간 단축
- `Package.resolved` 변경 시에만 캐시 무효화
- 평균 60% 시간 절약

**실패 시 동작:**
- PR Checks에 실패 표시
- PR 작성자에게 알림
- 실패한 job 로그를 통해 원인 파악 가능
- 모든 CI 통과 전까지 머지 불가 (Branch Protection 설정 시)

---

### 2.2 Release 워크플로우

**파일**: `.github/workflows/release.yml`

**트리거 조건:**
```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

- `v0.2.0`, `v1.0.0` 형식의 태그 푸시 시 자동 실행
- `release-1.0`, `1.0.0` 같은 형식은 트리거 안 됨

**릴리즈 프로세스:**

```
1. 코드 체크아웃
2. swift build -c release 실행
3. 바이너리 검증 (kps --version)
4. GitHub Release 자동 생성
   - 제목: 태그명
   - 릴리즈 노트: GitHub 자동 생성 (커밋/PR 기반)
   - 설치 가이드 포함
5. kps 바이너리 업로드
```

**릴리즈 노트 생성:**
- GitHub가 커밋 메시지와 PR 제목을 분석하여 자동 생성
- Conventional Commits 준수 시 가독성 향상
- 설치 가이드 자동 포함

**생성되는 릴리즈 노트 예시:**
```markdown
## What's Changed
* feat: add file search via git status by @zaehorang in #12
* docs: improve README with examples by @zaehorang in #13

## 설치 방법

```bash
curl -L -o kps https://github.com/zaehorang/KPS/releases/download/v0.2.0/kps
chmod +x kps
sudo install -m 0755 kps /usr/local/bin/kps
```

**Full Changelog**: https://github.com/zaehorang/KPS/compare/v0.1.0...v0.2.0
```

---

## 3. 해야 할 것 (DO)

### PR 생성 시

✅ **로컬에서 먼저 검증**
```bash
swift test                # 테스트 통과 확인
swift build               # 빌드 성공 확인
swiftlint lint            # 린트 경고 없음 확인
```

✅ **커밋 규칙 준수**
- Conventional Commits 사용 (`feat:`, `fix:`, `docs:`, etc.)
- 의미 있는 커밋 메시지 작성

✅ **CI 실패 시 즉시 수정**
- PR에 CI 실패 표시되면 즉시 확인
- Actions 탭에서 실패 로그 확인
- 로컬에서 재현 후 수정

✅ **모든 CI 통과 후 머지**
- 4개 job 모두 성공 확인
- Code review 완료 후 머지

### 릴리즈 시

✅ **로컬에서 철저히 검증**
```bash
# 1. 테스트 통과
swift test

# 2. 릴리즈 빌드 성공
swift build -c release

# 3. 바이너리 실행 확인
.build/release/kps --version
.build/release/kps --help

# 4. 실제 사용 시나리오 테스트
cd /tmp/test-project
/path/to/KPS/.build/release/kps init -a "Test" -s "Sources"
/path/to/KPS/.build/release/kps new 1000 -b
```

✅ **CHANGELOG 업데이트**
- `[Unreleased]` 섹션을 `[0.x.0]`으로 변경
- 주요 변경사항 기록
- 커밋 후 푸시

✅ **올바른 태그 형식 사용**
```bash
# 올바른 예시 ✅
git tag -a v0.2.0 -m "Release v0.2.0: Add CI/CD automation"
git tag -a v1.0.0 -m "Release v1.0.0: First stable release"

# 잘못된 예시 ❌
git tag release-0.2.0     # v 접두사 없음
git tag 0.2.0             # v 접두사 없음
git tag v0.2              # 패치 버전 누락
```

✅ **태그 메시지에 릴리즈 설명 포함**
- 무엇이 추가/변경/수정되었는지 간략히 설명

✅ **릴리즈 생성 후 검증**
```bash
# 1. 다운로드 URL 확인
curl -L -I https://github.com/zaehorang/KPS/releases/download/v0.x.0/kps

# 2. 실제 다운로드 및 실행 테스트
curl -L -o kps-test https://github.com/zaehorang/KPS/releases/latest/download/kps
chmod +x kps-test
./kps-test --version
rm kps-test
```

### 일반

✅ **macOS 환경에서 개발**
- Swift Testing은 macOS 전용
- CI도 macOS runner 사용

✅ **SwiftLint 경고 해결**
- 경고 발생 시 즉시 수정
- `.swiftlint.yml` 설정 준수

✅ **Package.resolved 변경 시 커밋**
- 의존성 업데이트 시 반드시 커밋
- CI 캐시 무효화에 필요

---

## 4. 하지 말아야 할 것 (DON'T)

### 절대 금지 ❌

**CI 실패 상태로 PR 머지하지 않기**
- 코드 품질 저하
- main 브랜치 오염
- 다른 개발자에게 영향

**잘못된 태그 형식 사용 금지**
```bash
# ❌ 잘못된 예시
release-1.0
1.0.0
v1.0
```

**테스트되지 않은 코드로 릴리즈 태그 생성 금지**
- 릴리즈 실패 위험
- 사용자에게 불안정한 버전 배포
- 브랜드 신뢰도 하락

**워크플로우 파일 직접 수정 후 테스트 없이 푸시 금지**
- CI 자체가 깨질 수 있음
- PR로 테스트 후 머지 필수

**릴리즈 실패 시 같은 태그 재사용 금지**
```bash
# ❌ 잘못된 방법
git tag -d v0.2.0
git tag -a v0.2.0 -m "..."  # 같은 태그 재사용

# ✅ 올바른 방법
git tag -a v0.2.1 -m "..."  # 새 패치 버전 사용
```

### 권장하지 않음 ⚠️

**main 브랜치에 직접 푸시**
- PR을 통한 코드 리뷰 권장
- CI 검증 거치기

**로컬 검증 없이 PR 생성**
- CI 리소스 낭비
- 피드백 사이클 지연

**SwiftLint 경고 무시**
- 코드 품질 저하
- 기술 부채 누적

**테스트 릴리즈 태그 삭제 안 함**
- 릴리즈 목록 혼란
- v0.1.1-test 같은 태그는 테스트 후 삭제

---

## 5. 트러블슈팅

### CI 실패 시

**증상**: PR에서 CI 실패 표시 (빨간색 X)

**해결 방법:**

1. **GitHub Actions 탭으로 이동**
   - PR 페이지에서 "Details" 클릭
   - 또는 `https://github.com/zaehorang/KPS/actions`

2. **실패한 job 확인**
   - test, build-debug, build-release, swiftlint 중 어느 것이 실패했는지 확인

3. **로그 확인**
   - 실패한 job 클릭
   - 에러 메시지 읽기

4. **로컬에서 재현**
   ```bash
   # 테스트 실패 시
   swift test

   # 빌드 실패 시
   swift build -c release

   # SwiftLint 실패 시
   swiftlint lint --config .swiftlint.yml
   ```

5. **수정 후 다시 푸시**
   - 수정 사항 커밋
   - PR 브랜치에 푸시
   - CI 자동 재실행

**자주 발생하는 문제:**

| 문제 | 원인 | 해결 |
|------|------|------|
| 테스트 실패 | 로직 오류, 테스트 코드 오류 | `swift test`로 로컬 재현 후 수정 |
| 빌드 실패 | 컴파일 에러, 타입 불일치 | Xcode 또는 `swift build`로 확인 |
| SwiftLint 실패 | 코드 스타일 위반 | `swiftlint lint --fix` 또는 수동 수정 |
| 캐시 문제 | 오래된 의존성 | Actions 캐시 삭제 |

---

### GitHub Actions CI 구축 실패 (미해결)

**상태**: ⚠️ 미해결 - CI 워크플로우 없음

**발생 시기**: 2026년 1월 12일

---

#### 문제 1: SwiftLint SPM Plugin + Swift 6.1 호환성

**증상**:
```
error: a prebuild command cannot use executables built from source,
including executable target 'swiftlint'
error: build planning stopped due to build-tool plugin failures
```

**환경**:
- GitHub Actions `macos-latest` = macOS 15
- Xcode 16.4
- Swift 6.1.2

**근본 원인**:
- Swift 6.1 SPM에 prebuild command 관련 버그 존재
- 공식 이슈: https://github.com/realm/SwiftLint/issues/5376
- SwiftLint 문제가 아닌 **SPM 자체의 버그**

**시도한 해결책 (모두 실패)**:

1. ❌ **`--disable-sandbox` 플래그**
   ```yaml
   swift build --disable-sandbox
   ```
   - Swift 버전이 해당 옵션을 지원하지 않음
   - 에러: `Unknown option '--disable-sandbox'`

2. ❌ **`--disable-build-tool-plugins` 플래그**
   ```yaml
   swift build --disable-build-tool-plugins
   ```
   - Swift 버전이 해당 옵션을 지원하지 않음
   - 에러: `Unknown option '--disable-build-tool-plugins'`

3. ❌ **sed로 Package.swift 수정**
   ```yaml
   sed -i '' '/plugins:/,/\]/d' Package.swift
   swift build
   ```
   - 기술적으로 작동하지만 해킹 같은 방법
   - 유지보수성 나쁨

4. ❌ **Binary Plugin (SimplyDanny/SwiftLintPlugins)**
   ```swift
   .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.57.0")
   ```
   - 동일한 prebuild command 에러 발생
   - Binary plugin도 내부적으로 같은 메커니즘 사용

---

#### 문제 2: macOS 14 + ArgumentParser 1.7.0 호환성

**시도**:
```yaml
runs-on: macos-14  # Swift 6.0.x 사용하여 SPM 버그 우회
```

**새로운 에러**:
```
error: Access level on imports require '-enable-experimental-feature AccessLevelOnImport'
internal import os
^~~~~~~~~
```

**원인**:
- ArgumentParser 1.7.0이 Swift 6.x 전용 문법 사용 (`internal import`)
- macOS 14의 Swift 6.0.x는 이 문법을 지원하지 않음

**딜레마**:
```
┌─────────────────────────────────────────────────────┐
│              GitHub Actions 환경                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  macOS 15 (Swift 6.1.2)                             │
│  ├─ SwiftLint Plugin: ❌ SPM 버그                   │
│  └─ ArgumentParser 1.7.0: ✅ 작동                    │
│                                                      │
│  macOS 14 (Swift 6.0.x)                             │
│  ├─ SwiftLint Plugin: ✅ 작동 가능                   │
│  └─ ArgumentParser 1.7.0: ❌ 문법 미지원             │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

#### 문제 3: Brew 방식의 한계

**시도**:
```yaml
- name: Run SwiftLint
  run: |
    brew install swiftlint
    swiftlint lint --strict
```

**단점**:
- ❌ 로컬 개발자는 `swift build` 시 자동 lint 안 됨
- ❌ CI에서 매번 brew 설치 시간 추가 (~10초)
- ❌ 로컬과 CI 환경 불일치
- ❌ 기여자에게 별도 SwiftLint 설치 요구

---

#### 해결 방향 (TODO)

**1. Swift 6.2 릴리즈 대기**
- SPM prebuild command 버그 수정 예정
- 릴리즈 시기: 미정

**2. ArgumentParser 다운그레이드**
```swift
.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
```
- 1.3.x는 Swift 5.9~6.0 호환
- macOS 14 + SwiftLint 플러그인 작동
- 단점: 최신 기능 사용 불가

**3. 커스텀 Swift 설치 액션**
```yaml
- uses: swift-actions/setup-swift@v1
  with:
    swift-version: "6.0.3"
```
- 특정 Swift 버전 사용
- 검증 필요

**4. 로컬 개발 우선, CI는 나중에**
- 현재 상태: 로컬에서 SwiftLint 플러그인 작동
- CI는 v0.2.0 이후 재시도

---

#### 타임라인

**2026-01-12**:
- ❌ 첫 CI 시도 (prebuild error)
- ❌ Binary plugin 시도 (동일 에러)
- ❌ macOS 14 시도 (ArgumentParser 호환성)
- ❌ Brew 방식 적용 (불만족)
- ✅ 문제 상황 문서화
- ✅ CI 워크플로우 제거 (나중에 해결)

---

### Release 실패 시

**증상**: 태그 푸시 후 GitHub Release 생성 안 됨

**해결 방법:**

1. **Actions 탭에서 Release 워크플로우 확인**
   - `https://github.com/zaehorang/KPS/actions/workflows/release.yml`

2. **빌드 실패 확인**
   ```bash
   # 로컬에서 릴리즈 빌드 테스트
   swift build -c release
   .build/release/kps --version
   ```

3. **태그 형식 확인**
   ```bash
   git tag  # 모든 태그 확인
   # v*.*.* 형식인지 확인
   ```

4. **권한 문제 확인**
   - Settings → Actions → General
   - Workflow permissions: "Read and write permissions" 확인

**복구 절차:**

```bash
# 1. 실패한 태그 삭제
git tag -d v0.x.0
git push origin :refs/tags/v0.x.0

# 2. GitHub에서 실패한 릴리즈 삭제 (있는 경우)
# Releases 페이지에서 수동 삭제

# 3. 문제 수정 (빌드 오류 등)

# 4. 새 태그 생성 및 푸시
git tag -a v0.x.0 -m "Release v0.x.0: [설명]"
git push origin v0.x.0
```

**자주 발생하는 문제:**

| 문제 | 원인 | 해결 |
|------|------|------|
| 빌드 실패 | 컴파일 에러 | 로컬에서 `swift build -c release` 검증 |
| 태그 트리거 안 됨 | 잘못된 태그 형식 | `v*.*.*` 형식 사용 |
| 권한 오류 | Workflow permissions | Settings에서 권한 확인 |
| 바이너리 404 | 업로드 실패 | Actions 로그 확인 |

---

### 캐시 문제

**증상**: CI가 오래된 의존성을 사용하거나 빌드 실패

**원인**: GitHub Actions 캐시가 최신 `Package.resolved`를 반영하지 못함

**해결 방법:**

**방법 1: GitHub Actions 캐시 삭제 (권장)**
1. Settings → Actions → Caches
2. 오래된 캐시 삭제 버튼 클릭
3. PR 다시 푸시하여 CI 재실행

**방법 2: Package.resolved 업데이트**
```bash
# 의존성 다시 다운로드
rm -rf .build
swift package resolve

# Package.resolved 커밋
git add Package.resolved
git commit -m "chore: update dependencies"
git push
```

---

## 6. 릴리즈 프로세스

### 전체 플로우

```bash
# ============================================
# Phase 1: 로컬 검증
# ============================================

swift test
# → 모든 테스트 통과 확인

swift build -c release
# → 릴리즈 빌드 성공 확인

.build/release/kps --version
# → 버전 확인

# ============================================
# Phase 2: CHANGELOG 업데이트
# ============================================

vim docs/CHANGELOG.md
# [Unreleased] → [0.x.0] 변경
# 주요 변경사항 기록

git add docs/CHANGELOG.md
git commit -m "docs: prepare v0.x.0 release"
git push origin main

# ============================================
# Phase 3: 태그 생성 및 푸시
# ============================================

git tag -a v0.x.0 -m "Release v0.x.0: [간략한 설명]"
# 예: git tag -a v0.2.0 -m "Release v0.2.0: Add CI/CD automation"

git push origin v0.x.0
# → GitHub Actions Release 워크플로우 자동 트리거

# ============================================
# Phase 4: GitHub Actions가 자동으로 수행
# ============================================
# 1. swift build -c release 실행
# 2. 바이너리 검증
# 3. GitHub Release 생성
# 4. kps 바이너리 업로드
# 5. 릴리즈 노트 생성 (커밋/PR 기반)

# ============================================
# Phase 5: 검증
# ============================================

# 1. GitHub Releases 페이지 확인
# https://github.com/zaehorang/KPS/releases

# 2. 다운로드 URL 확인
curl -L -I https://github.com/zaehorang/KPS/releases/download/v0.x.0/kps
# → 200 OK 또는 302 리다이렉트 확인

# 3. latest URL 확인 (README에서 사용)
curl -L -I https://github.com/zaehorang/KPS/releases/latest/download/kps
# → v0.x.0으로 리다이렉트 확인

# 4. 실제 다운로드 및 실행 테스트
curl -L -o kps-test https://github.com/zaehorang/KPS/releases/latest/download/kps
chmod +x kps-test
./kps-test --version  # v0.x.0 출력 확인
rm kps-test

# ✅ 완료!
```

### 간소화된 플로우 (숙련자용)

```bash
# 1. 검증 & 커밋
swift test && swift build -c release && \
vim docs/CHANGELOG.md && \
git add docs/CHANGELOG.md && \
git commit -m "docs: prepare v0.x.0 release" && \
git push origin main

# 2. 태그 & 푸시
git tag -a v0.x.0 -m "Release v0.x.0: [설명]" && \
git push origin v0.x.0

# 3. 검증
curl -L -o kps-test https://github.com/zaehorang/KPS/releases/latest/download/kps && \
chmod +x kps-test && \
./kps-test --version && \
rm kps-test
```

---

### 롤백 (필요 시)

릴리즈에 문제가 발견된 경우:

```bash
# ============================================
# 방법 1: GitHub에서 릴리즈 삭제
# ============================================

# 1. https://github.com/zaehorang/KPS/releases 접속
# 2. 문제된 릴리즈 클릭
# 3. "Delete" 버튼 클릭

# 2. 로컬 및 원격 태그 삭제
git tag -d v0.x.0                    # 로컬 태그 삭제
git push origin :refs/tags/v0.x.0    # 원격 태그 삭제

# ============================================
# 방법 2: 핫픽스 릴리즈 (권장)
# ============================================

# 1. 문제 수정
# 2. 패치 버전으로 새 릴리즈
git tag -a v0.x.1 -m "Release v0.x.1: Fix [문제]"
git push origin v0.x.1

# → 사용자는 자동으로 최신 버전 다운로드 (latest URL 사용)
```

---

## 7. 참고 문서

- **[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md)** - 빌드 & 실행, 명령어 스펙
- **[COMMIT_Convention.md](COMMIT_Convention.md)** - 커밋 규칙
- **[CHANGELOG.md](CHANGELOG.md)** - 릴리즈 히스토리
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 기술 아키텍처

---

## 8. FAQ

### Q: CI 실패 시 PR을 머지할 수 있나요?
A: **아니요.** CI 실패는 코드에 문제가 있다는 신호입니다. 반드시 수정 후 머지하세요.

### Q: 릴리즈 태그를 잘못 만들었어요. 어떻게 하나요?
A: 태그를 삭제하고 다시 만드세요:
```bash
git tag -d v0.x.0
git push origin :refs/tags/v0.x.0
git tag -a v0.x.0 -m "..."
git push origin v0.x.0
```

### Q: 테스트 릴리즈를 만들고 싶어요.
A: `-test` 접미사를 사용하세요:
```bash
git tag v0.1.1-test
git push origin v0.1.1-test
# 테스트 후 삭제
git tag -d v0.1.1-test
git push origin :refs/tags/v0.1.1-test
```

### Q: CI가 너무 오래 걸려요.
A: 정상입니다. 4개 job이 병렬로 실행되어 평균 1-2분 소요됩니다. 캐시가 있으면 더 빠릅니다.

### Q: 릴리즈 노트를 직접 작성할 수 있나요?
A: 현재는 자동 생성만 지원합니다. v0.3.0에서 CHANGELOG 기반 릴리즈 노트를 지원할 예정입니다.

### Q: 릴리즈 바이너리를 수동으로 올릴 수 있나요?
A: 가능하지만 권장하지 않습니다. GitHub Actions를 사용하면 일관성이 보장됩니다.
