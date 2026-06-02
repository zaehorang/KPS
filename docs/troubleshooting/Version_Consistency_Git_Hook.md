# Git Hook으로 버전 불일치 방지하기

> pre-push hook을 통한 릴리즈 자동화 - "자동화의 자동화"

---

## 1. 문제 상황: 버전 불일치로 인한 재배포

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

## 2. 근본 원인 분석

### 2.1 왜 발견이 늦었나?

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

### 2.2 왜 자동 검증이 필요한가?

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

## 3. 해결 선택지 분석

### 옵션 A: 버전을 한 곳에서만 관리

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

### 옵션 B: CI에서 검증

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

### 옵션 C: Git Hook으로 사전 검증 (선택)

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

## 4. 구현: pre-push Hook

### 4.1 요구사항 정의

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

### 4.2 코드 구현

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

### 4.3 구현 포인트

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

## 5. 설치 자동화

### 5.1 문제: Hook은 Git에 포함되지 않음

`.git/hooks/`는 `.git/` 디렉토리 안에 있어서 Git 추적이 안 됨.

**즉:**
- Hook을 만들어도 다른 개발자에게 전달되지 않음
- 새로운 환경에서 `git clone` 후 수동 설치 필요

### 5.2 해결: 설치 스크립트 제공

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

## 6. 검증 및 테스트

### 6.1 테스트 시나리오

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

### 6.2 테스트 스크립트

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

## 7. 문서화

### 7.1 DEVELOPMENT_GUIDE.md 업데이트

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

### 7.2 README에 온보딩 가이드 추가 (선택)

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

## 8. 실제 효과: v0.2.0 재배포에서 검증

Hook을 설치한 후 실제로 효과를 확인했다.

### 8.1 첫 번째 v0.2.0 배포 (실패)

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

### 8.2 Hook 설치 후 재배포

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

## 9. 추가 고려사항

### 9.1 Hook 우회가 필요한 경우

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

### 9.2 CI에서도 검증 추가 (방어적 프로그래밍)

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

### 9.3 다른 Hook 추가 가능성

**pre-commit hook:**
- SwiftLint 자동 실행
- Trailing whitespace 제거
- 파일 끝 newline 확인

**commit-msg hook:**
- 커밋 메시지 형식 검증 (Conventional Commits)
- 이슈 번호 자동 추가

---

## 10. 결론: "작은 자동화가 큰 안정성을 만든다"

### 10.1 투자 vs 수익

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

### 10.2 핵심 교훈

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

## 참고 자료

### 코드 저장소
- KPS: https://github.com/zaehorang/KPS
- scripts/hooks/pre-push: Git Hook 구현 코드
- scripts/install-hooks.sh: 설치 스크립트

### 관련 문서
- [CHANGELOG.md](../CHANGELOG.md) - v0.2.0 변경 내역
- [DEVELOPMENT_GUIDE.md](../DEVELOPMENT_GUIDE.md) - Git Hooks 사용법
- [release.yml](../../.github/workflows/release.yml) - CI 검증 로직

### Git Hooks 공식 문서
- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [pre-push Hook Specification](https://git-scm.com/docs/githooks#_pre_push)
