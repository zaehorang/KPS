# Homebrew 배포 계획

**작성일:** 2026-01-28
**완료일:** 2026-01-28
**상태:** ✅ **완료**
**목표:** KPS를 Homebrew를 통해 배포하여 사용자 설치 경험 개선

## 배포 완료 요약

🎉 **v0.1.1 Homebrew 배포가 성공적으로 완료되었습니다!**

**배포 결과:**
- ✅ homebrew-tap 저장소: https://github.com/zaehorang/homebrew-tap
- ✅ GitHub Release: https://github.com/zaehorang/KPS/releases/tag/v0.1.1
- ✅ Homebrew 설치 검증 완료

**설치 명령어:**
```bash
brew tap zaehorang/tap
brew install kps
```

**릴리즈 통계:**
- Intel (x86_64) 바이너리: 1.8MB
- Apple Silicon (arm64) 바이너리: 1.8MB
- SHA256 체크섬: 검증 완료
- GitHub Actions 워크플로우: 2분 13초 소요

---

## 1. 의사결정 요약

### 배포 전략

| 항목 | 결정 사항 | 이유 |
|------|-----------|------|
| **배포 방식** | Personal Tap (`zaehorang/homebrew-tap`) | 빠른 시작 가능, 완전한 제어권 보유 |
| **바이너리 타입** | Pre-built Binary (Intel + Apple Silicon) | 사용자 설치 시간 최소화 (다운로드만) |
| **버전 관리** | Git 태그 기반 자동 생성 | 단일 진실 공급원, 일관성 보장 |
| **Formula 업데이트** | Auto-PR (Pull Request) | 안전한 릴리즈 검증, 수동 승인 |
| **압축 형식** | tar.gz | Homebrew 표준 형식, 호환성 우수 |
| **첫 배포 버전** | v0.1.1 | 최소 변경으로 빠른 Homebrew 지원 |

### CI/CD 자동화 범위

- ✅ Auto-build on Tag: Git 태그 푸시 시 자동 빌드
- ✅ Auto-update Formula: 새 릴리즈 시 Formula 자동 업데이트 (PR 생성)
- ✅ Multi-arch Build: Intel (x86_64) + Apple Silicon (arm64) 동시 빌드
- ✅ Formula Test: Formula 변경 시 자동 검증

---

## 2. 아키텍처 개요

### 저장소 구조

```
KPS (main repo)
├── .github/workflows/
│   └── release.yml          # 릴리즈 자동화
├── Sources/
├── Tests/
├── Package.swift
└── Plan/
    └── 2026-01-28_homebrew-deployment.md

homebrew-tap (new repo)
├── Formula/
│   └── kps.rb               # Homebrew Formula
├── README.md                # Tap 사용 가이드
└── .github/workflows/
    └── formula-test.yml     # Formula 검증
```

### 릴리즈 플로우

```
Developer                    GitHub Actions                 User
    |                              |                          |
    | git tag v0.1.1               |                          |
    | git push origin v0.1.1       |                          |
    |----------------------------->|                          |
    |                              |                          |
    |                         Build x86_64                    |
    |                         Build arm64                     |
    |                              |                          |
    |                    Create GitHub Release                |
    |                    Upload kps-x86_64.tar.gz             |
    |                    Upload kps-arm64.tar.gz              |
    |                              |                          |
    |                    Calculate SHA256                     |
    |                              |                          |
    |              Create PR to homebrew-tap                  |
    |              (Update Formula with new version)          |
    |                              |                          |
    | Review & Merge PR            |                          |
    |----------------------------->|                          |
    |                              |                          |
    |                              |  brew tap zaehorang/tap  |
    |                              |  brew install kps        |
    |                              |<-------------------------|
    |                              |                          |
    |                       Download tarball                  |
    |                       Extract binary                    |
    |                       Install to /usr/local/bin         |
    |                              |------------------------->|
    |                              |         kps ready!       |
```

---

## 3. 구현 체크리스트

### Phase 1: 인프라 구축

#### A. homebrew-tap 저장소 생성

- [ ] GitHub에서 `zaehorang/homebrew-tap` 저장소 생성
  - Public repository
  - Description: "Homebrew formulae for KPS"
  - Initialize with README
- [ ] 디렉토리 구조 생성
  ```bash
  mkdir -p Formula
  mkdir -p .github/workflows
  ```
- [ ] `Formula/kps.rb` 초안 작성
- [ ] `README.md` 작성 (설치 가이드)
- [ ] `.github/workflows/formula-test.yml` 작성

#### B. GitHub Personal Access Token 생성

- [ ] GitHub Settings → Developer settings → Personal access tokens → Generate new token
- [ ] Scope: `repo` (homebrew-tap 저장소 접근 권한)
- [ ] Token을 KPS 저장소 Secrets에 추가
  - Name: `HOMEBREW_TAP_TOKEN`
  - Value: [생성된 토큰]

#### C. KPS 저장소 업데이트

- [ ] `.github/workflows/release.yml` 작성
- [ ] 버전 출력 확인 (`kps --version`)
- [ ] README.md에 Homebrew 설치 가이드 추가
- [ ] 테스트 실행 확인 (`swift test`)

---

### Phase 2: GitHub Actions 워크플로우 구현

#### `.github/workflows/release.yml` 요구사항

**트리거:**
- Git 태그 푸시 (`v*` 패턴)

**Jobs:**

1. **build-x86_64**
   - macOS runner
   - Swift 빌드 (x86_64 아키텍처)
   - 바이너리를 `kps-x86_64`로 rename
   - tar.gz 압축
   - SHA256 계산

2. **build-arm64**
   - macOS runner
   - Swift 빌드 (arm64 아키텍처)
   - 바이너리를 `kps-arm64`로 rename
   - tar.gz 압축
   - SHA256 계산

3. **create-release**
   - GitHub Release 생성
   - 두 아키텍처 바이너리 업로드
   - Release notes 자동 생성

4. **update-formula**
   - homebrew-tap 저장소에 PR 생성
   - Formula 파일 업데이트 (버전, URL, SHA256)
   - PR 제목: `chore: update kps to v{version}`

**필요한 Actions:**
- `actions/checkout@v4`
- `softprops/action-gh-release@v1`
- `peter-evans/create-pull-request@v5` 또는 수동 스크립트

---

### Phase 3: Homebrew Formula 작성

#### `Formula/kps.rb` 구조

```ruby
class Kps < Formula
  desc "Algorithm problem-solving tracker for BOJ & Programmers"
  homepage "https://github.com/zaehorang/KPS"
  version "0.1.1"
  license "MIT"  # LICENSE 파일 확인 후 설정

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/zaehorang/KPS/releases/download/v0.1.1/kps-arm64-v0.1.1.tar.gz"
      sha256 "PLACEHOLDER_ARM64_SHA256"  # 실제 빌드 후 업데이트
    elsif Hardware::CPU.intel?
      url "https://github.com/zaehorang/KPS/releases/download/v0.1.1/kps-x86_64-v0.1.1.tar.gz"
      sha256 "PLACEHOLDER_X86_64_SHA256"  # 실제 빌드 후 업데이트
    end
  end

  def install
    bin.install Hardware::CPU.arm? ? "kps-arm64" : "kps-x86_64" => "kps"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kps --version")
  end
end
```

**주의사항:**
- SHA256은 실제 빌드 후 계산된 값으로 업데이트
- LICENSE 파일 확인 (없으면 추가 필요)
- `kps --version` 출력 형식 확인

---

### Phase 4: 테스트 자동화

#### `homebrew-tap/.github/workflows/formula-test.yml`

**트리거:**
- Pull Request (Formula 파일 변경 시)
- Push (Formula 파일 변경 시)

**Matrix Strategy:**
- macOS 13 (Intel)
- macOS 14 (Apple Silicon)

**테스트 단계:**
1. `brew tap zaehorang/tap .` - 로컬 tap 등록
2. `brew install kps` - 설치
3. `kps --version` - 실행 확인
4. `brew test kps` - Formula test 블록 실행
5. `brew audit --strict kps` - Formula 문법 검증

---

## 4. 릴리즈 프로세스 (v0.1.1)

### 사전 준비 체크리스트

- [ ] homebrew-tap 저장소 생성 완료
- [ ] GitHub Token 설정 완료
- [ ] release.yml 워크플로우 작성 완료
- [ ] Formula 초안 작성 완료
- [ ] 모든 단위 테스트 통과 (`swift test`)
- [ ] SwiftLint 경고 없음 (`swift build`)
- [ ] LICENSE 파일 존재 확인

### 릴리즈 실행 단계

#### 1. 코드 준비

```bash
# main 브랜치 최신화
git checkout main
git pull origin main

# 새 브랜치 생성
git checkout -b release/v0.1.1
```

#### 2. 변경 사항 커밋

**수정할 파일:**
- `README.md` - Homebrew 설치 가이드 추가
- `docs/CHANGELOG.md` - v0.1.1 변경사항 기록

**커밋:**
```bash
git add README.md docs/CHANGELOG.md
git commit -m "docs: add Homebrew installation guide for v0.1.1"
```

#### 3. PR 생성 및 머지

```bash
git push origin release/v0.1.1
# GitHub에서 PR 생성 → main으로 머지
```

#### 4. 태그 생성 및 푸시

```bash
git checkout main
git pull origin main

git tag -a v0.1.1 -m "Release v0.1.1: Homebrew support"
git push origin v0.1.1
```

#### 5. GitHub Actions 자동 실행 확인

**모니터링 항목:**
- [ ] release.yml 워크플로우 시작
- [ ] x86_64 빌드 성공
- [ ] arm64 빌드 성공
- [ ] GitHub Release 생성
- [ ] 바이너리 파일 업로드 (kps-x86_64-v0.1.1.tar.gz, kps-arm64-v0.1.1.tar.gz)
- [ ] homebrew-tap에 PR 생성

#### 6. Formula PR 리뷰 및 머지

**확인 사항:**
- [ ] 버전 번호 정확성
- [ ] URL 정확성
- [ ] SHA256 해시 정확성
- [ ] Formula 문법 오류 없음
- [ ] formula-test.yml 워크플로우 통과

**머지:**
```bash
# homebrew-tap 저장소에서 PR 승인 및 머지
```

#### 7. 설치 테스트

```bash
# Tap 추가
brew tap zaehorang/tap

# 설치
brew install kps

# 버전 확인
kps --version  # 출력: v0.1.1 또는 0.1.1

# 기본 동작 확인
kps --help
```

#### 8. 문서 업데이트

- [ ] GitHub Release notes 확인 및 수정
- [ ] README.md에 배포 안내 추가
- [ ] `/pm sync` 실행하여 CHANGELOG.md 업데이트

---

## 5. 기술적 고려사항

### A. 크로스 컴파일 이슈

**문제:**
- Swift는 크로스 컴파일을 공식 지원하지 않음
- 한 머신에서 Intel/ARM 바이너리를 모두 빌드하기 어려움

**해결책:**
- GitHub Actions에서 각 아키텍처별로 네이티브 빌드 수행
- 또는 Universal Binary 생성 (`lipo` 사용)

**현재 접근 방식:**
```bash
# x86_64 빌드
swift build -c release --arch x86_64

# arm64 빌드
swift build -c release --arch arm64
```

### B. 의존성 관리

**ArgumentParser:**
- 정적 링크됨 (Swift Package Manager 기본 동작)
- 바이너리에 포함되므로 별도 설치 불필요

**SwiftLint:**
- 빌드 타임 의존성 (Plugin)
- 최종 바이너리에 영향 없음

**런타임 요구사항:**
- macOS 13+ (Package.swift의 `platforms` 설정)
- Xcode Command Line Tools 불필요 (pre-built 바이너리)

### C. 버전 정보 관리

**현재 상태 확인 필요:**
- `kps --version` 출력이 어디에서 오는가?
- 하드코딩되어 있는가, 자동 생성되는가?

**개선 옵션:**

1. **수동 관리 (간단함)**
   - 릴리즈 시 `--version` 출력 수동 업데이트
   - Pros: 간단, 복잡성 없음
   - Cons: 실수 가능성, 여러 곳 수정 필요

2. **자동 주입 (일관성)**
   - 빌드 스크립트에서 Git 태그 주입
   - Pros: 단일 진실 공급원, 실수 방지
   - Cons: 빌드 프로세스 복잡도 증가

**v0.1.1 권장:**
- 수동 관리로 시작 (빠른 배포)
- v0.2.0에서 자동화 검토

### D. 바이너리 크기 최적화

**현재 빌드:**
```bash
swift build -c release
```

**최적화 옵션:**
```bash
# 디버그 심볼 제거
swift build -c release -Xswiftc -strip-debug-symbols

# LTO (Link Time Optimization)
swift build -c release -Xswiftc -lto=llvm-full
```

**v0.1.1 권장:**
- 기본 릴리즈 빌드로 시작
- 크기 문제 발견 시 최적화 적용

---

## 6. 리스크 및 대응 방안

### 잠재적 문제

| 문제 | 발생 가능성 | 영향도 | 대응 방안 |
|------|------------|--------|----------|
| **GitHub Actions 빌드 실패** | 중 | 고 | 로컬에서 사전 테스트, 에러 로그 상세히 확인 |
| **SHA256 불일치** | 중 | 고 | 자동 계산 스크립트 검증, 수동 재계산 |
| **Formula 문법 오류** | 저 | 중 | `brew audit --strict` 로컬 테스트 |
| **macOS 버전 호환성** | 저 | 중 | 지원 버전 명시 (macOS 13+) |
| **의존성 누락** | 저 | 고 | 로컬 클린 환경에서 바이너리 테스트 |
| **Token 권한 부족** | 중 | 중 | Token scope 재확인, 새 토큰 생성 |

### 롤백 계획

**시나리오: v0.1.1 릴리즈가 깨짐**

1. **즉시 조치:**
   ```bash
   # homebrew-tap에서 Formula 되돌리기
   git revert <commit-hash>
   git push origin main
   ```

2. **GitHub Release 수정:**
   - Release를 Draft로 변경하거나 삭제
   - 또는 v0.1.2로 핫픽스 릴리즈

3. **사용자 공지:**
   - README에 알려진 이슈 추가
   - GitHub Issue로 상황 공유

---

## 7. 향후 로드맵

### v0.1.1 (현재)
- ✅ Personal Tap 구축
- ✅ Pre-built 바이너리 배포
- ✅ CI/CD 자동화

### v0.2.0 (Post-MVP)
- [ ] Universal Binary 지원 (Intel + ARM in one file)
- [ ] 버전 정보 자동 주입
- [ ] 바이너리 크기 최적화
- [ ] 릴리즈 노트 자동 생성 (Conventional Commits)

### v1.0.0 (Stable)
- [ ] 충분한 사용자 피드백 수렴
- [ ] 안정성 검증 완료
- [ ] Homebrew Core 진입 검토
  - Notable 프로젝트 요구사항 충족
  - 30일 이상 활발한 유지보수 기록
  - 75+ stars, 30+ forks, 75+ watchers 권장

---

## 8. 참고 자료

### Homebrew 공식 문서
- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae)
- [Creating Taps](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)

### GitHub Actions
- [Softprops GH Release](https://github.com/softprops/action-gh-release)
- [Peter Evans Create PR](https://github.com/peter-evans/create-pull-request)

### Swift 빌드
- [Swift Package Manager](https://swift.org/package-manager/)
- [Building for Multiple Architectures](https://developer.apple.com/documentation/xcode/building-a-universal-macos-binary)

### 관련 프로젝트 (참고용)
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Homebrew Formula 예시
- [swiftlint](https://github.com/realm/SwiftLint) - Swift CLI 배포 사례

---

## 9. 체크리스트 요약

### 구현 전
- [ ] homebrew-tap 저장소 생성
- [ ] GitHub Token 발급 및 설정
- [ ] LICENSE 파일 확인
- [ ] 로컬 빌드 테스트 (x86_64, arm64)

### 구현 중
- [ ] release.yml 작성 및 테스트
- [ ] Formula 초안 작성
- [ ] formula-test.yml 작성
- [ ] README 업데이트

### 릴리즈 전
- [ ] 모든 단위 테스트 통과
- [ ] SwiftLint 경고 해결
- [ ] CHANGELOG.md 업데이트
- [ ] 로컬에서 Formula 테스트

### 릴리즈 후
- [ ] GitHub Release 확인
- [ ] Formula PR 머지
- [ ] 실제 설치 테스트 (`brew install`)
- [ ] `/pm sync` 실행

---

**작성자:** Claude (AI Assistant)
**최종 수정:** 2026-01-28
**버전:** 1.0
