# GitHub Actions로 Homebrew 자동 배포를 만들면서 겪은 문제와 해결 과정

> KPS(Korean Problem Solving) CLI 도구를 개발하면서 Homebrew 자동 배포와 버전 관리 자동화를 구현한 이야기

---

## Part 1: Universal Binary 전환 - "사용자 최우선"에서 "엔지니어링 균형"으로

### 1. 목표: "릴리즈하면 Homebrew까지 자동으로 따라오게"

우리가 만들고 싶었던 흐름은 다음과 같다.

1. GitHub에서 태그(`vX.Y.Z`)를 푸시한다.
2. GitHub Actions가 태그를 기준으로 빌드를 수행한다.
3. 빌드 산출물을 GitHub Release에 업로드한다.
4. `homebrew-tap` 레포의 `Formula/kps.rb`를 **새 릴리즈 버전에 맞게 업데이트**하는 PR을 자동 생성한다.
5. 사용자는 아래로 설치한다.

```bash
brew tap zaehorang/tap
brew install kps
```

이 자동화를 만들려면 결국 "Release에 올라간 빌드 산출물과 Formula가 100% 일치"해야 한다.

특히 Formula에는 다운로드 URL과 무결성 검증용 SHA256이 들어가기 때문에, **새 릴리즈가 나올 때마다 Formula도 같이 업데이트**되어야 한다.

---

### 2. 처음 택한 배포 방식: 아키텍처별 2개 바이너리

초기 설계는 사용자 설치 UX(다운로드 용량)를 최우선으로 두고, 빌드를 아키텍처별로 나누었다.

- `kps-arm64-v0.1.1.tar.gz`
- `kps-x86_64-v0.1.1.tar.gz`

**선택 근거:**
- Universal(arm64+x86_64) 하나로 묶으면 파일이 커져서 다운로드/디스크 부담이 늘 수 있다.
- 사용자는 자신의 아키텍처에 맞는 파일만 받으면 되므로 불필요한 용량 낭비가 없다.
- 우리는 엔지니어링 복잡도를 감수하는 쪽을 선택했다.

**Homebrew Formula 구조:**

```ruby
class Kps < Formula
  desc "Algorithm problem-solving tracker"
  homepage "https://github.com/zaehorang/KPS"
  version "0.1.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/.../kps-arm64-v0.1.1.tar.gz"
      sha256 "arm64_hash_here"
    end
    if Hardware::CPU.intel?
      url "https://github.com/.../kps-x86_64-v0.1.1.tar.gz"
      sha256 "intel_hash_here"
    end
  end

  def install
    if Hardware::CPU.arm?
      bin.install "kps-arm64" => "kps"
    elsif Hardware::CPU.intel?
      bin.install "kps-x86_64" => "kps"
    end
  end
end
```

다만 이 선택은 Formula 업데이트 측면에서 바로 비용으로 돌아왔다.

---

### 3. 문제: Formula에 "수정해야 하는 값이 2배로 늘어났다"

아키텍처별로 파일을 2개 배포하면 Formula에서 업데이트해야 하는 값이 늘어난다.

- `version`: 1곳
- `url`: 2곳 (arm64 / x86_64)
- `sha256`: 2곳 (arm64 / x86_64)

여기서 `url`과 `version`은 단순 치환(sed)으로 비교적 쉽게 해결 가능했다.

```bash
sed 's/version ".*"/version "0.2.0"/'
sed 's|url "https://github.com/.*/kps-arm64-.*"|url "https://github.com/.../kps-arm64-v0.2.0.tar.gz"|'
```

하지만 **sha256은 단순 치환으로 해결이 어려웠다.**

---

### 4. 핵심 문제: sha256이 2개인데 "둘 다 서로 다른 값"이어야 한다

Homebrew는 다운로드한 파일이 예상한 파일인지 확인하기 위해 SHA256을 체크한다.

- ARM tar.gz는 ARM tar.gz 내용으로 계산된 SHA256을 가져야 한다.
- Intel tar.gz는 Intel tar.gz 내용으로 계산된 SHA256을 가져야 한다.

즉, Formula의 sha256은 "같은 항목 2개"가 아니라 **"서로 다른 파일의 지문 2개"**다.

그런데 sed 같은 단순 치환 도구는 문맥을 모르기 때문에, 아래처럼 작성하면:

```bash
sed 's/sha256 ".*"/sha256 "NEW_HASH"/'
```

sha256 두 줄이 **모두 같은 값으로 덮이는 위험**이 있다.

그렇게 되면 한쪽 아키텍처에서 `brew install kps`가 체크섬 불일치로 실패한다.

---

### 5. 해결 시도 1: awk로 "문맥 기반 치환(상태 머신)" 구현

그래서 우리는 sha256 업데이트에 awk를 사용했다.

**핵심 아이디어:**
- 파일을 위에서 아래로 한 줄씩 읽는다.
- 지금 읽는 위치가 ARM 블록인지 Intel 블록인지 상태로 기억한다.
- sha256 줄을 만나면 현재 상태에 맞는 해시로 교체한다.

**GitHub Actions 워크플로우:**

```yaml
- name: Update Formula (awk 버전)
  run: |
    cd homebrew-tap

    # awk 상태 머신으로 sha256 치환 (18줄)
    awk -v arm_sha="$ARM_SHA" -v intel_sha="$INTEL_SHA" '
    /if Hardware::CPU\.arm\?/ { in_arm=1; in_intel=0 }
    /if Hardware::CPU\.intel\?/ { in_arm=0; in_intel=1 }
    /sha256/ {
      if (in_arm) {
        print "      sha256 \"" arm_sha "\""
        next
      }
      if (in_intel) {
        print "      sha256 \"" intel_sha "\""
        next
      }
    }
    { print }
    ' Formula/kps.rb > Formula/kps.rb.tmp

    mv Formula/kps.rb.tmp Formula/kps.rb
```

이 방식은 "sha256 2개를 서로 다르게" 업데이트하는 요구사항을 만족시킨다.

**하지만 문제가 있었다:**
- 복잡도: awk 상태 머신 18줄 + 임시 파일 관리
- 가독성: 새로운 개발자가 이해하기 어려움
- 유지보수: Formula 구조가 바뀌면 awk 로직도 수정 필요
- 디버깅: 실패 시 어디가 문제인지 파악하기 어려움

**실제 release.yml 크기:**
- 전체: 39줄
- Formula 업데이트 로직: 18줄 (약 46%)

---

### 6. 근본적 질문: "왜 이렇게 복잡한가?"

여기서 한 발 물러나서 근본적인 질문을 했다.

> "우리가 해결하려는 문제는 'sha256 2개를 서로 다르게 치환'인데,
> 왜 이 문제가 발생했을까?"

답은 간단했다. **"배포 산출물이 2개여서"**

그렇다면 선택지는 두 가지다:

### 옵션 A: 아키텍처별 2개 배포 (초기 선택)

**장점:**
- ✅ 사용자가 자신의 아키텍처만 다운로드 → 용량 최소화
- ✅ 불필요한 바이너리 포함 안 됨

**단점:**
- ❌ Formula에 url/sha256이 2쌍 필요
- ❌ 업데이트 자동화 복잡도 증가 (awk 18줄 상태 머신)
- ❌ Formula 구조가 복잡함 (on_macos, if Hardware::CPU)
- ❌ 유지보수 비용 증가

### 옵션 B: Universal Binary 1개 배포

**장점:**
- ✅ Formula가 단일 url/sha256 1쌍 → 자동화 단순화
- ✅ awk 제거 가능 → sed 3줄로 충분
- ✅ Formula 구조 단순화
- ✅ macOS 표준 방식 (Apple 공식 권장)
- ✅ 배포 파이프라인 실패 지점 감소

**단점:**
- ❌ 다운로드/디스크 크기 증가 (arm64 + x86_64)

우리는 처음엔 옵션 A를 "사용자 최우선"이라는 기준으로 택했지만,
실제 파일 크기를 확인하면서 기준이 바뀌었다.

---

### 7. 전환 계기: 데이터 기반 의사결정

결정을 내리기 전에 **실제로 측정**해보기로 했다.

#### 7.1 측정 방법

```bash
# ARM64 빌드
swift build -c release --arch arm64
tar -czf kps-arm64.tar.gz .build/arm64-apple-macosx/release/kps
ls -lh kps-arm64.tar.gz

# x86_64 빌드
swift build -c release --arch x86_64
tar -czf kps-x86_64.tar.gz .build/x86_64-apple-macosx/release/kps
ls -lh kps-x86_64.tar.gz

# Universal Binary 빌드
lipo -create \
  .build/arm64-apple-macosx/release/kps \
  .build/x86_64-apple-macosx/release/kps \
  -output kps-universal
tar -czf kps-universal.tar.gz kps-universal
ls -lh kps-universal.tar.gz
```

#### 7.2 측정 결과

| 항목 | 크기 | 비고 |
|------|------|------|
| ARM64 tar.gz | **506 KB** | Apple Silicon 전용 |
| x86_64 tar.gz | **516 KB** | Intel Mac 전용 |
| **합계** | **1,022 KB** | 2개 파일 총합 |
| Universal tar.gz | **1,021 KB** | 단일 파일 |
| **압축 효율** | **99.93%** | 거의 합과 동일 |

**핵심 발견:**
- Universal binary를 tar.gz로 압축하면 두 개를 따로 압축한 것과 **크기가 거의 같다** (99.93%)
- 이는 tar.gz의 압축 효율이 좋아서 중복 제거가 잘 되기 때문

#### 7.3 사용자 영향 분석

**다운로드 시간 비교 (10 Mbps 기준):**

| 방식 | 다운로드 크기 | 예상 시간 |
|------|------------|----------|
| Split (ARM64) | 506 KB | **약 0.4초** |
| Split (Intel) | 516 KB | **약 0.4초** |
| Universal | 1,021 KB | **약 0.8초** |

**차이: 약 0.4초** (사용자가 체감하기 어려운 수준)

**디스크 공간:**
- 절대값이 1MB 수준으로 매우 작음
- 현대 macOS에서 무시할 수 있는 크기

**결론:**
> 파일 크기가 **1MB 내외**로 매우 작아서,
> Universal로 전환해도 **사용자가 체감할 수 있는 UX 손해가 없다.**

---

### 8. 트레이드오프 재평가: "엔지니어링 복잡도 vs 사용자 UX"

이제 데이터를 기반으로 트레이드오프를 재평가할 수 있다.

#### 8.1 Split 방식의 실제 비용

**엔지니어링 복잡도:**
- release.yml: 39줄 (awk 로직 18줄)
- Formula: 24줄 (on_macos 블록, 아키텍처 분기)
- 총 63줄의 자동화 코드

**유지보수 리스크:**
- awk 상태 머신이 Formula 구조에 의존적
- Formula 포맷 변경 시 awk 로직도 수정 필요
- 디버깅 어려움 (실패 시 어느 부분이 문제인지 파악 힘듦)
- 새로운 팀원의 학습 비용

**실제 겪은 문제:**
1. sed로 Formula 구조를 바꾸려다 실패 (sed는 구조 변경 불가)
2. 첫 릴리즈 테스트에서 Formula가 잘못 업데이트됨
3. 수동으로 PR 브랜치를 체크아웃해서 수정 필요

#### 8.2 Universal 방식의 실제 이득

**엔지니어링 단순화:**

```yaml
# 이전 (awk 18줄)
awk -v arm_sha="$ARM_SHA" -v intel_sha="$INTEL_SHA" '
/if Hardware::CPU\.arm\?/ { in_arm=1; in_intel=0 }
/if Hardware::CPU\.intel\?/ { in_arm=0; in_intel=1 }
/sha256/ {
  if (in_arm) {
    print "      sha256 \"" arm_sha "\""
    next
  }
  ...
' Formula/kps.rb > Formula/kps.rb.tmp

# 이후 (sed 3줄)
sed -i '' 's/version ".*"/version "$VERSION"/' Formula/kps.rb
sed -i '' 's|url "https://github.com/.*/kps-.*\.tar\.gz"|url "$NEW_URL"|' Formula/kps.rb
sed -i '' 's/sha256 ".*"/sha256 "$SHA256"/' Formula/kps.rb
```

**복잡도 감소 측정:**

| 항목 | Before | After | 감소율 |
|------|--------|-------|--------|
| release.yml | 39줄 | 26줄 | **33% ↓** |
| Formula/kps.rb | 24줄 | 15줄 | **38% ↓** |
| Formula 업데이트 로직 | 18줄 (awk) | 3줄 (sed) | **83% ↓** |
| 총 라인 수 | 63줄 | 41줄 | **35% ↓** |

**안정성 향상:**
- 단순한 sed 치환 → 실패 지점 감소
- Formula 구조 변경에 강건함
- 디버깅 용이 (한 줄씩 독립적으로 실행 가능)

---

### 9. 최종 결정: Universal Binary로 전환

#### 9.1 의사결정 근거

**정량적 근거:**
1. 파일 크기 차이가 **0.4초** 수준으로 체감 불가
2. 절대 크기가 **1MB**로 디스크 부담 무시 가능
3. 자동화 복잡도 **83% 감소**
4. 총 코드 라인 **35% 감소**

**정성적 근거:**
1. macOS 표준 방식 (Apple 공식 권장)
2. 유지보수 비용 대폭 감소
3. 팀 온보딩 난이도 감소
4. 배포 실패 리스크 감소 → **사용자 설치 안정성 향상**

**핵심 통찰:**
> "사용자 최우선"을 엄격하게 적용해도,
> 다운로드 크기 증가로 인한 **UX 손해가 거의 없고**
> 자동화 단순화로 인해 **"설치 실패" 리스크가 줄어드는 UX 이득이 더 크다**

#### 9.2 구현

**Universal Binary 빌드:**

```yaml
- name: Build Universal Binary
  run: |
    # Build for both architectures
    swift build -c release --arch arm64
    swift build -c release --arch x86_64

    # Create Universal binary
    lipo -create \
      .build/arm64-apple-macosx/release/kps \
      .build/x86_64-apple-macosx/release/kps \
      -output kps

    # Verify
    lipo -info kps
    file kps

- name: Create Archive
  run: |
    tar -czf kps-${{ steps.version.outputs.version }}.tar.gz kps

- name: Calculate SHA256
  id: sha
  run: |
    SHA256=$(shasum -a 256 kps-${{ steps.version.outputs.version }}.tar.gz | cut -d ' ' -f 1)
    echo "sha256=$SHA256" >> $GITHUB_OUTPUT
```

**단순화된 Formula:**

```ruby
class Kps < Formula
  desc "Algorithm problem-solving tracker for BOJ & Programmers"
  homepage "https://github.com/zaehorang/KPS"
  version "0.2.0"
  license "MIT"

  url "https://github.com/zaehorang/KPS/releases/download/v0.2.0/kps-v0.2.0.tar.gz"
  sha256 "6679a23199cc1bfd3fda32b8df55d9c9ed3dc15e8b514109d62135da4969e807"

  def install
    bin.install "kps"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kps --version")
  end
end
```

#### 9.3 검증

**v0.2.0-test 태그로 사전 검증:**

1. Universal binary 빌드 성공
2. GitHub Release 생성 성공
3. homebrew-tap PR 자동 생성 성공
4. Formula sed 치환 성공
5. `brew install kps` 설치 검증 성공

**문제 발견 및 해결:**
- 첫 테스트에서 Formula 구조가 완전히 전환되지 않음 (on_macos 블록 잔존)
- sed는 구조 변경 불가 → 수동으로 PR 브랜치 체크아웃해서 수정
- **중요:** 이는 일회성 마이그레이션 문제, 이후 릴리즈는 자동화 정상 작동

---

### 10. 결과: "엔지니어링 복잡도를 줄여서 사용자 경험을 향상시킨다"

#### 10.1 Before & After 비교

**Before (Split 방식):**
```
릴리즈 프로세스:
1. ARM64 빌드
2. x86_64 빌드
3. 2개 tar.gz 생성
4. 2개 SHA256 계산
5. GitHub Release 업로드 (2개 파일)
6. awk 상태 머신으로 Formula 업데이트
   - ARM 블록 진입 감지
   - Intel 블록 진입 감지
   - 각각 다른 sha256 치환
7. homebrew-tap PR 생성

복잡도: 39줄 (awk 18줄)
실패 지점: 7곳
```

**After (Universal 방식):**
```
릴리즈 프로세스:
1. ARM64 빌드
2. x86_64 빌드
3. lipo로 Universal binary 생성
4. 1개 tar.gz 생성
5. 1개 SHA256 계산
6. GitHub Release 업로드 (1개 파일)
7. sed로 Formula 단순 치환
8. homebrew-tap PR 생성

복잡도: 26줄 (sed 3줄)
실패 지점: 4곳
```

#### 10.2 장기적 이점

**유지보수:**
- 새로운 팀원이 이해하기 쉬운 구조
- Formula 포맷 변경에 강건함
- 디버깅 시간 단축

**확장성:**
- 다른 플랫폼(Linux 등) 추가 시 패턴 재사용 가능
- 복잡도가 선형적으로 증가 (지수적 X)

**안정성:**
- 실패 지점 감소 → 사용자 설치 성공률 향상
- 간단한 로직 → 예측 가능한 동작

---

### 11. 교훈: "측정 없이 최적화하지 말라"

이 경험에서 얻은 가장 큰 교훈:

#### 11.1 가정을 검증하라

**초기 가정:**
> "Universal은 2배 커져서 다운로드 부담이 클 것이다"

**실제 측정:**
> "1MB 수준에서 0.4초 차이는 체감 불가"

만약 측정 없이 "Universal은 크니까 안 돼"라고 판단했다면,
불필요한 복잡도를 계속 유지했을 것이다.

#### 11.2 절대값과 상대값을 함께 봐라

**상대값:**
- Universal이 Split보다 약 2배 크다 (1021KB vs 506KB)

**절대값:**
- 하지만 절대값은 1MB 수준으로 매우 작다
- 이 범위에서는 "2배"가 의미 없다

상대값만 보면 "2배나 증가!"로 보이지만,
절대값을 같이 보면 "1MB vs 0.5MB"라는 현실이 보인다.

#### 11.3 엔지니어링 복잡도도 UX다

**기존 관점:**
- 엔지니어링 복잡도 = 개발팀 비용
- 사용자 UX = 다운로드 크기, 속도

**새로운 관점:**
- 엔지니어링 복잡도 ↓ = 배포 안정성 ↑
- 배포 안정성 ↑ = 사용자 설치 성공률 ↑
- **즉, 엔지니어링 단순화도 사용자 UX 향상이다**

---

## Part 2: Git Hook으로 버전 불일치 방지 - "자동화의 자동화"

### 1. 문제 상황: 버전 불일치로 인한 재배포

v0.2.0 릴리즈를 진행하면서 발생한 문제:

```bash
# 1. v0.2.0 태그 푸시
git tag v0.2.0
git push origin v0.2.0

# 2. GitHub Actions가 빌드 및 배포 완료
# 3. Homebrew에서 설치 테스트
brew install kps
kps --version
# 출력: 0.1.1  ← 엥???
```

**원인:**
- 태그는 `v0.2.0`으로 푸시했지만
- `Sources/kps/KPS.swift`의 `version:` 필드는 `"0.1.1"`로 하드코딩되어 있었음

**결과:**
1. 바이너리는 정상 빌드됨
2. GitHub Release 생성됨
3. Formula 업데이트됨
4. 하지만 설치 후 `kps --version`은 `0.1.1` 출력
5. **전체 릴리즈 프로세스를 다시 실행해야 함**

---

### 2. 근본 원인 분석

#### 2.1 왜 발견이 늦었나?

**릴리즈 프로세스:**
```
1. 코드 수정
2. CHANGELOG.md 업데이트
3. git commit
4. git tag v0.2.0
5. git push origin v0.2.0
6. GitHub Actions 빌드 (2~3분)
7. 설치 테스트 ← 여기서 발견
```

**문제:**
- 버전 불일치 검증이 프로세스의 **마지막 단계**에서만 가능
- 이미 태그를 푸시한 상태 → 되돌리려면 태그 삭제 및 재생성 필요
- GitHub Actions 빌드 시간 낭비 (2~3분 × 재시도 횟수)

#### 2.2 왜 자동 검증이 필요한가?

**인간의 기억력 한계:**
- 릴리즈는 자주 하지 않는 작업 (주/월 단위)
- 매번 "버전을 2곳에서 수정해야 한다"를 기억하기 어려움
- 특히 급하게 hotfix를 배포할 때 실수 가능성 ↑

**수동 체크리스트의 한계:**
```markdown
## 릴리즈 체크리스트
- [ ] CHANGELOG.md 업데이트
- [ ] Sources/kps/KPS.swift version 수정  ← 체크리스트에 있어도 까먹음
- [ ] git tag 생성
```

**해결책: 자동화**
> 사람이 실수할 수 있는 부분은 기계가 검증하게 만든다

---

### 3. 해결 선택지 분석

#### 옵션 A: 버전을 한 곳에서만 관리

**아이디어:**
- `Sources/kps/KPS.swift`에서 버전을 읽어서 태그 생성
- 또는 태그에서 버전을 읽어서 빌드 시 주입

**장점:**
- Single Source of Truth
- 불일치 원천 차단

**단점:**
- Swift Package Manager는 버전 주입 기능이 없음
- 빌드 시 파일 수정 필요 → 복잡도 증가
- 또는 태그 생성을 자동화해야 함 → 릴리즈 워크플로우 변경

**결론: 구현 복잡도가 너무 높음**

#### 옵션 B: CI에서 검증

**아이디어:**
- GitHub Actions에서 빌드 전에 버전 일치 여부 확인
- 불일치 시 빌드 실패

**장점:**
- 구현 간단 (workflow에 step 추가)
- 모든 빌드에서 자동 검증

**단점:**
- 태그를 이미 푸시한 후에 검증
- 실패 시 태그 삭제 및 재푸시 필요
- GitHub Actions 빌드 시간 낭비 (2~3분)

**결론: 너무 늦은 시점에 검증**

#### 옵션 C: Git Hook으로 사전 검증 (선택)

**아이디어:**
- `pre-push` hook으로 태그 푸시 전에 검증
- 불일치 시 푸시 차단

**장점:**
- ✅ 가장 빠른 시점에 검증 (로컬에서, 푸시 전)
- ✅ GitHub Actions 시간 낭비 없음
- ✅ 태그를 remote에 푸시하지 않음 → 깔끔한 히스토리
- ✅ 구현 간단 (bash script)
- ✅ 즉각적인 피드백 (1초 이내)

**단점:**
- ⚠️ 로컬에 hook 설치 필요
- ⚠️ 새로운 팀원이 hook 설치를 까먹을 수 있음

**결론: 장점이 단점을 압도, 설치 자동화로 단점 완화**

---

### 4. 구현: pre-push Hook

#### 4.1 요구사항 정의

**검증 대상:**
- Git 태그 형식: `v*.*.*` (예: v0.2.0, v1.0.0)
- 코드 버전 위치: `Sources/kps/KPS.swift` 파일의 `version: "x.y.z"`

**검증 시나리오:**

| 태그 | 코드 버전 | 결과 |
|------|----------|------|
| v0.2.0 | 0.2.0 | ✅ 통과 |
| v0.2.0 | 0.1.1 | ❌ 차단 |
| v0.3.0 | 0.2.0 | ❌ 차단 |
| main 브랜치 | - | ✅ 통과 (태그가 아니므로 검증 안 함) |

**출력 요구사항:**
- 성공 시: 간단한 확인 메시지
- 실패 시: 명확한 에러 메시지 + 수정 방법 안내

#### 4.2 코드 구현

```bash
#!/bin/bash
# .git/hooks/pre-push

while read local_ref local_sha remote_ref remote_sha
do
  # 버전 태그인지 확인 (refs/tags/v*.*.*)
  if [[ $remote_ref =~ ^refs/tags/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    TAG_VERSION="${BASH_REMATCH[1]}"

    echo "🔍 Checking version consistency for tag v$TAG_VERSION..."

    # Sources/kps/KPS.swift에서 버전 추출
    CODE_VERSION=$(grep -E 'version: "[0-9]+\.[0-9]+\.[0-9]+"' Sources/kps/KPS.swift \
      | sed -E 's/.*version: "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

    if [[ -z "$CODE_VERSION" ]]; then
      echo "❌ Error: Could not extract version from Sources/kps/KPS.swift"
      exit 1
    fi

    if [[ "$TAG_VERSION" != "$CODE_VERSION" ]]; then
      echo ""
      echo "❌ Error: Version mismatch detected!"
      echo "   📌 Tag version:  v$TAG_VERSION"
      echo "   📝 Code version: $CODE_VERSION (Sources/kps/KPS.swift)"
      echo ""
      echo "💡 Fix: Update version in Sources/kps/KPS.swift to \"$TAG_VERSION\""
      echo ""
      exit 1
    fi

    echo "✅ Version check passed: v$TAG_VERSION matches code version"
    echo ""
  fi
done

exit 0
```

#### 4.3 구현 포인트

**1. stdin에서 ref 정보 읽기**
```bash
while read local_ref local_sha remote_ref remote_sha
```
- Git은 pre-push hook에 푸시할 ref 목록을 stdin으로 전달
- `remote_ref` 형식: `refs/tags/v0.2.0` 또는 `refs/heads/main`

**2. 정규식으로 버전 태그 감지**
```bash
if [[ $remote_ref =~ ^refs/tags/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
```
- `refs/tags/v0.2.0` → 매치, `TAG_VERSION="0.2.0"` 추출
- `refs/heads/main` → 매치 안 됨, 검증 스킵

**3. grep + sed로 코드에서 버전 추출**
```bash
CODE_VERSION=$(grep -E 'version: "[0-9]+\.[0-9]+\.[0-9]+"' Sources/kps/KPS.swift \
  | sed -E 's/.*version: "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
```
- `version: "0.2.0",` → `0.2.0` 추출

**4. 불일치 시 명확한 에러 메시지**
```
❌ Error: Version mismatch detected!
   📌 Tag version:  v0.3.0
   📝 Code version: 0.2.0 (Sources/kps/KPS.swift)

💡 Fix: Update version in Sources/kps/KPS.swift to "0.3.0"
```

---

### 5. 설치 자동화

#### 5.1 문제: Hook은 Git에 포함되지 않음

`.git/hooks/`는 `.git/` 디렉토리 안에 있어서 Git 추적이 안 됨.

**즉:**
- Hook을 만들어도 다른 개발자에게 전달되지 않음
- 새로운 환경에서 `git clone` 후 수동 설치 필요

#### 5.2 해결: 설치 스크립트 제공

**디렉토리 구조:**
```
KPS/
├── scripts/
│   ├── hooks/
│   │   └── pre-push          # Hook 파일 (Git 추적)
│   └── install-hooks.sh      # 설치 스크립트 (Git 추적)
└── .git/
    └── hooks/
        └── pre-push          # 여기로 복사됨 (Git 추적 X)
```

**install-hooks.sh:**
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "📦 Installing Git hooks..."

# pre-push hook 복사
cp "$SCRIPT_DIR/hooks/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"

echo "✅ pre-push hook installed"
echo ""
echo "🔍 This hook will:"
echo "   - Check version consistency when pushing tags"
echo "   - Prevent tag/code version mismatch"
echo ""
echo "✨ Installation complete!"
```

**사용법:**
```bash
# 프로젝트 루트에서
./scripts/install-hooks.sh
```

---

### 6. 검증 및 테스트

#### 6.1 테스트 시나리오

**시나리오 1: 버전 일치 (통과)**
```bash
# 코드 버전: 0.2.0
# 태그: v0.2.0
git tag v0.2.0
git push origin v0.2.0

# 출력:
# 🔍 Checking version consistency for tag v0.2.0...
# ✅ Version check passed: v0.2.0 matches code version
#
# 푸시 진행...
```

**시나리오 2: 버전 불일치 (차단)**
```bash
# 코드 버전: 0.2.0
# 태그: v0.3.0
git tag v0.3.0
git push origin v0.3.0

# 출력:
# 🔍 Checking version consistency for tag v0.3.0...
#
# ❌ Error: Version mismatch detected!
#    📌 Tag version:  v0.3.0
#    📝 Code version: 0.2.0 (Sources/kps/KPS.swift)
#
# 💡 Fix: Update version in Sources/kps/KPS.swift to "0.3.0"
#
# error: failed to push some refs to 'origin'
```

**시나리오 3: 일반 브랜치 푸시 (검증 스킵)**
```bash
git push origin main

# hook은 실행되지만 태그가 아니므로 검증 스킵
# 즉시 푸시 진행
```

#### 6.2 테스트 스크립트

```bash
#!/bin/bash
# 로컬에서 hook 테스트 (remote 푸시 없이)

# 버전 불일치 시뮬레이션
echo "Testing version mismatch..."
echo "refs/heads/main abc123 refs/tags/v0.3.0 def456" | .git/hooks/pre-push

# 버전 일치 시뮬레이션
echo ""
echo "Testing version match..."
echo "refs/heads/main abc123 refs/tags/v0.2.0 def456" | .git/hooks/pre-push
```

**테스트 결과:**
```
Testing version mismatch...
🔍 Checking version consistency for tag v0.3.0...

❌ Error: Version mismatch detected!
   📌 Tag version:  v0.3.0
   📝 Code version: 0.2.0 (Sources/kps/KPS.swift)

💡 Fix: Update version in Sources/kps/KPS.swift to "0.3.0"

Testing version match...
🔍 Checking version consistency for tag v0.2.0...
✅ Version check passed: v0.2.0 matches code version
```

---

### 7. 문서화

#### 7.1 DEVELOPMENT_GUIDE.md 업데이트

Hook 사용법을 개발 가이드에 추가:

```markdown
## 2. Git Hooks

### 2.1 설치

프로젝트 루트에서 실행:

\`\`\`bash
./scripts/install-hooks.sh
\`\`\`

### 2.2 pre-push Hook

**목적**: 버전 태그 푸시 시 코드 내 버전과 태그 버전 불일치 방지

**동작:**
- `v*.*.*` 형식의 태그를 푸시할 때 자동 실행
- `Sources/kps/KPS.swift`의 `version:` 필드와 태그 비교
- 불일치 시 푸시 차단 및 안내 메시지 출력

**우회 (권장하지 않음):**
\`\`\`bash
# 긴급 상황에만 사용
git push --no-verify origin v0.3.0
\`\`\`
```

#### 7.2 README에 온보딩 가이드 추가 (선택)

새로운 기여자를 위한 가이드:

```markdown
## 개발 환경 설정

\`\`\`bash
# 1. 저장소 클론
git clone https://github.com/zaehorang/KPS.git
cd KPS

# 2. Git hooks 설치
./scripts/install-hooks.sh

# 3. 빌드
swift build
\`\`\`
```

---

### 8. 실제 효과: v0.2.0 재배포에서 검증

Hook을 설치한 후 실제로 효과를 확인했다.

#### 8.1 첫 번째 v0.2.0 배포 (실패)

```bash
# 코드 버전을 업데이트 안 하고 태그 푸시
git tag v0.2.0
git push origin v0.2.0

# GitHub Actions 빌드 (2분 소요)
# 설치 테스트
brew install kps
kps --version  # 0.1.1 출력

# 😱 문제 발견!
```

**손실:**
- GitHub Actions 빌드 시간: 2분
- Release 생성 및 삭제: 수동 작업
- homebrew-tap PR 생성 및 정리: 수동 작업
- 전체 재작업 시간: 약 10분

#### 8.2 Hook 설치 후 재배포

```bash
# 코드 버전 수정 후 다시 태그 푸시 시도
git tag v0.2.0
git push origin v0.2.0

# Hook이 즉시 검증 (1초 이내)
# 🔍 Checking version consistency for tag v0.2.0...
# ✅ Version check passed: v0.2.0 matches code version

# GitHub Actions 빌드 진행
# 성공! 🎉
```

**이득:**
- 로컬에서 즉시 검증 (1초)
- 잘못된 배포 차단
- GitHub Actions 시간 낭비 없음
- 깔끔한 릴리즈 히스토리 유지

---

### 9. 추가 고려사항

#### 9.1 Hook 우회가 필요한 경우

**상황:**
- 긴급 hotfix인데 hook이 false positive로 차단
- 의도적으로 버전을 나중에 수정하려는 경우

**해결:**
```bash
git push --no-verify origin v0.2.0
```

**주의:**
- `--no-verify`는 모든 hook을 우회
- 정말 필요한 경우만 사용
- 사용 후 반드시 버전 수정 커밋

#### 9.2 CI에서도 검증 추가 (방어적 프로그래밍)

Hook은 로컬에서만 작동하므로, CI에서 한 번 더 검증:

```yaml
- name: Verify version consistency
  run: |
    TAG_VERSION=$(echo $GITHUB_REF | sed 's|refs/tags/v||')
    CODE_VERSION=$(grep -E 'version: "[0-9]+\.[0-9]+\.[0-9]+"' Sources/kps/KPS.swift \
      | sed -E 's/.*version: "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

    if [ "$TAG_VERSION" != "$CODE_VERSION" ]; then
      echo "Error: Version mismatch (tag: $TAG_VERSION, code: $CODE_VERSION)"
      exit 1
    fi
```

**이중 검증 전략:**
1. **로컬 (pre-push hook)**: 빠른 피드백, 개발자 편의
2. **CI (GitHub Actions)**: 최종 방어선, hook 우회 대응

#### 9.3 다른 Hook 추가 가능성

**pre-commit hook:**
- SwiftLint 자동 실행
- Trailing whitespace 제거
- 파일 끝 newline 확인

**commit-msg hook:**
- 커밋 메시지 형식 검증 (Conventional Commits)
- 이슈 번호 자동 추가

---

### 10. 결론: "작은 자동화가 큰 안정성을 만든다"

#### 10.1 투자 vs 수익

**투자:**
- Hook 구현: 약 1시간
- 테스트 및 문서화: 약 30분
- **총 1.5시간**

**수익 (1회 실수 방지):**
- GitHub Actions 재실행 시간 절약: 2~3분
- 수동 정리 작업 절약: 5~10분
- 스트레스 및 집중력 손실 방지: 무형

**Break-even:**
- 실수 2~3회 방지로 투자 회수
- 장기적으로 모든 릴리즈에서 검증 → 투자 대비 수익 ∞

#### 10.2 핵심 교훈

**1. 실수는 반복된다**
- 사람은 실수한다 (특히 자주 안 하는 작업)
- 체크리스트로는 부족하다
- 자동화가 답이다

**2. 가장 빠른 피드백이 가장 좋은 피드백**
```
피드백 시점별 비용:
- 로컬 (pre-push): 1초, 비용 0
- CI (GitHub Actions): 2분, 비용 중간
- 설치 테스트: 5분, 비용 높음
- 프로덕션: ∞, 비용 ∞
```

**3. 작은 스크립트가 큰 안정성을 만든다**
- 40줄짜리 bash script
- 1.5시간 투자
- 영구적인 안정성 향상

---

## 전체 요약: "데이터 기반 의사결정과 작은 자동화의 힘"

### Part 1: Universal Binary 전환

**문제:**
- 아키텍처별 2개 배포로 인한 자동화 복잡도 (awk 18줄)

**해결:**
1. 실제 파일 크기 측정 (506KB, 516KB, 1021KB)
2. 사용자 영향 분석 (0.4초 차이, 체감 불가)
3. Universal로 전환 결정 (복잡도 83% 감소)

**교훈:**
- 측정 없이 최적화하지 말라
- 절대값과 상대값을 함께 봐라
- 엔지니어링 단순화도 UX다

### Part 2: Git Hook 추가

**문제:**
- 버전 불일치로 인한 재배포 (10분 손실)

**해결:**
1. pre-push hook으로 사전 검증
2. 설치 스크립트로 팀 공유
3. 문서화로 온보딩 간소화

**교훈:**
- 실수는 반복된다, 자동화가 답이다
- 가장 빠른 피드백이 가장 좋은 피드백
- 작은 스크립트가 큰 안정성을 만든다

### 마지막 한 문장

**"완벽한 자동화는 존재하지 않지만, 측정과 검증을 통해 지속적으로 개선할 수 있다."**

---

## 참고 자료

### 코드 저장소
- KPS: https://github.com/zaehorang/KPS
- homebrew-tap: https://github.com/zaehorang/homebrew-tap

### 관련 문서
- [CHANGELOG.md](./CHANGELOG.md) - v0.2.0 변경 내역
- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - Git Hooks 사용법
- [release.yml](../.github/workflows/release.yml) - GitHub Actions 워크플로우

### 측정 데이터
```bash
# 재현 방법
swift build -c release --arch arm64
swift build -c release --arch x86_64
lipo -create \
  .build/arm64-apple-macosx/release/kps \
  .build/x86_64-apple-macosx/release/kps \
  -output kps-universal

tar -czf kps-arm64.tar.gz .build/arm64-apple-macosx/release/kps
tar -czf kps-x86_64.tar.gz .build/x86_64-apple-macosx/release/kps
tar -czf kps-universal.tar.gz kps-universal

ls -lh kps-*.tar.gz
```
