# GitHub Actions로 Homebrew 자동 배포를 만들면서 겪은 문제와 해결 과정

> Part 1: Universal Binary 전환 - "사용자 최우선"에서 "엔지니어링 균형"으로

---

## 1. 목표: "릴리즈하면 Homebrew까지 자동으로 따라오게"

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

## 2. 처음 택한 배포 방식: 아키텍처별 2개 바이너리

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

## 3. 문제: Formula에 "수정해야 하는 값이 2배로 늘어났다"

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

## 4. 핵심 문제: sha256이 2개인데 "둘 다 서로 다른 값"이어야 한다

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

## 5. 해결 시도 1: awk로 "문맥 기반 치환(상태 머신)" 구현

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

## 6. 근본적 질문: "왜 이렇게 복잡한가?"

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

## 7. 전환 계기: 데이터 기반 의사결정

결정을 내리기 전에 **실제로 측정**해보기로 했다.

### 7.1 측정 방법

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

### 7.2 측정 결과

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

### 7.3 사용자 영향 분석

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

## 8. 트레이드오프 재평가: "엔지니어링 복잡도 vs 사용자 UX"

이제 데이터를 기반으로 트레이드오프를 재평가할 수 있다.

### 8.1 Split 방식의 실제 비용

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

### 8.2 Universal 방식의 실제 이득

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

## 9. 최종 결정: Universal Binary로 전환

### 9.1 의사결정 근거

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

### 9.2 구현

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

### 9.3 검증

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

## 10. 결과: "엔지니어링 복잡도를 줄여서 사용자 경험을 향상시킨다"

### 10.1 Before & After 비교

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

### 10.2 장기적 이점

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

## 11. 교훈: "측정 없이 최적화하지 말라"

이 경험에서 얻은 가장 큰 교훈:

### 11.1 가정을 검증하라

**초기 가정:**
> "Universal은 2배 커져서 다운로드 부담이 클 것이다"

**실제 측정:**
> "1MB 수준에서 0.4초 차이는 체감 불가"

만약 측정 없이 "Universal은 크니까 안 돼"라고 판단했다면,
불필요한 복잡도를 계속 유지했을 것이다.

### 11.2 절대값과 상대값을 함께 봐라

**상대값:**
- Universal이 Split보다 약 2배 크다 (1021KB vs 506KB)

**절대값:**
- 하지만 절대값은 1MB 수준으로 매우 작다
- 이 범위에서는 "2배"가 의미 없다

상대값만 보면 "2배나 증가!"로 보이지만,
절대값을 같이 보면 "1MB vs 0.5MB"라는 현실이 보인다.

### 11.3 엔지니어링 복잡도도 UX다

**기존 관점:**
- 엔지니어링 복잡도 = 개발팀 비용
- 사용자 UX = 다운로드 크기, 속도

**새로운 관점:**
- 엔지니어링 복잡도 ↓ = 배포 안정성 ↑
- 배포 안정성 ↑ = 사용자 설치 성공률 ↑
- **즉, 엔지니어링 단순화도 사용자 UX 향상이다**

---

## 참고 자료

### 코드 저장소
- KPS: https://github.com/zaehorang/KPS
- homebrew-tap: https://github.com/zaehorang/homebrew-tap

### 관련 문서
- [CHANGELOG.md](../CHANGELOG.md) - v0.2.0 변경 내역
- [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md) - 개발 가이드
- [release.yml](../../.github/workflows/release.yml) - GitHub Actions 워크플로우

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
