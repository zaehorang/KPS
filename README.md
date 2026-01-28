# 🚀 KPS (Korean Problem Solving)

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+"></a>
  <a href="https://www.apple.com/macos"><img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+"></a>
  <a href="https://github.com/zaehorang/KPSTool/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
  <a href="https://github.com/zaehorang/KPSTool/releases"><img src="https://img.shields.io/github/v/release/zaehorang/KPSTool" alt="GitHub release"></a>
  <a href="https://github.com/zaehorang/KPSTool/issues"><img src="https://img.shields.io/github/issues/zaehorang/KPSTool" alt="GitHub issues"></a>
</p>

> 알고리즘 문제 풀이를 **정돈된 개발 기록**으로 남기게 해주는 Swift CLI 도구입니다.
> BOJ/Programmers 문제 링크(또는 번호) 하나로 **파일 생성부터 Git 커밋/푸시**까지의 반복 작업을 자동화하세요.

<!--
## 📺 데모

아래 GIF에서 KPS의 사용 흐름을 확인하세요:

![KPS Demo](docs/images/demo.gif)

*데모 이미지는 추후 추가 예정입니다.*
-->

---

## 💡 왜 KPS인가요?

알고리즘을 풀 때, 풀이 자체보다 **귀찮은 루틴**이 더 크게 느껴질 때가 있습니다.

- 문제 번호 확인 및 URL 복사
- 플랫폼별(BOJ/Programmers) 폴더 분류 및 파일 생성
- 기본 템플릿 작성 (헤더 주석 등)
- 커밋 메시지 양식 맞추기

KPS는 이 과정을 명령어 중심으로 표준화하여, 개발자가 오직 **문제 풀이 로직에만 집중**할 수 있도록 돕습니다.

---

## ✨ 핵심 특징

- 🚀 **빠른 파일 생성**: URL만 넣으면 플랫폼을 자동 인식해 파일을 생성합니다.
- 📁 **체계적인 구조 유지**: `Sources/BOJ/1000.swift` 같은 폴더링을 지원합니다.
- 🔄 **Git 자동 연동**: 풀이 완료 후 커밋과 푸시를 한 번에 처리합니다.
- 🌐 **다중 플랫폼 지원**: BOJ, Programmers
- 🛠️ **Swift 기반**: Swift 개발자에게 친숙하며, 커스터마이징이 용이합니다.

---

## 🌐 지원 플랫폼

| 플랫폼 | URL 형식 | 플래그 |
|--------|----------|--------|
| **BOJ** | `acmicpc.net/problem/{번호}` | `-b`, `--boj` |
| | `boj.kr/{번호}` | |
| **Programmers** | `school.programmers.co.kr/learn/courses/30/lessons/{번호}` | `-p`, `--programmers` |
| | `programmers.co.kr/learn/courses/30/lessons/{번호}` (구버전 호환) | |

---

## ✅ 요구 사항

- **macOS 13.0 (Ventura)** 이상
- **Swift 5.9** 이상 (소스 빌드 시)
- **Git** (선택, `kps solve` 사용 시 필요)

> **참고**:
> - Releases 바이너리는 별도 빌드 없이 실행할 수 있습니다.
> - 소스 빌드 시에는 Swift 5.9+ 개발 환경이 필요합니다.

---

## 📦 설치하기

### 1) Releases 다운로드 (권장)

[Releases 페이지](https://github.com/zaehorang/KPSTool/releases)에서 최신 버전을 다운로드하거나, 아래 명령어로 바로 설치할 수 있습니다.

#### 옵션 A) `/usr/local/bin` (일반적인 경로, sudo 필요)

```bash
# 최신 버전 다운로드 및 설치
curl -L -o kps https://github.com/zaehorang/KPSTool/releases/latest/download/kps
chmod +x kps
sudo install -m 0755 kps /usr/local/bin/kps
rm kps  # 다운로드한 파일 삭제

# 설치 확인
kps --version
```

#### 옵션 B) 홈 디렉토리 bin (sudo 없이 권장)

```bash
# 디렉토리 생성 및 최신 버전 다운로드
mkdir -p ~/.local/bin
curl -L -o ~/.local/bin/kps https://github.com/zaehorang/KPSTool/releases/latest/download/kps
chmod +x ~/.local/bin/kps

# zsh 사용 시 PATH 설정 (한 번만)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 설치 확인
kps --version
```

> **참고**: Homebrew 사용자라면 PATH는 보통 `/opt/homebrew/bin` (Apple Silicon) 또는 `/usr/local/bin` (Intel)에 이미 설정되어 있습니다.

### 2) Homebrew (권장)

```bash
brew tap zaehorang/tap
brew install kps
```

**업데이트:**
```bash
brew upgrade kps
```

### 3) 소스 빌드

```bash
git clone https://github.com/zaehorang/KPSTool.git
cd KPSTool
swift build -c release
sudo install -m 0755 .build/release/kps /usr/local/bin/kps
```

---

## 🏃 Quick Start

### 신규 프로젝트 시작하기

**1단계: Xcode 프로젝트 생성**
1. Xcode 실행
2. File > New > Project
3. macOS > Command Line Tool 선택
4. 원하는 위치에 저장 (예: `~/Documents/AlgorithmStudy`)

**2단계: KPS 초기화**
```bash
cd ~/Documents/AlgorithmStudy
kps init -a "Your Name" -s "Sources"
# 🔍 Detected Xcode project: AlgorithmStudy.xcodeproj
```

**3단계: 문제 풀이 시작**
```bash
kps new 1000 -b         # 문제 파일 생성
kps open 1000 -b        # Xcode에서 열기
# ... Xcode에서 문제 풀이 ...
kps solve 1000 -b       # 커밋 & 푸시
```

---

### 기존 프로젝트에 적용하기

이미 Xcode 프로젝트가 있는 경우:

```bash
cd ~/Documents/MyProject
kps config xcodeProjectPath "MyProject.xcodeproj"
# ✅ Config updated!

kps open  # Xcode에서 최근 파일 열기
```

---

## ⌨️ 명령어 상세 가이드

### 2) 문제 파일 생성

```bash
# URL로 생성 (추천)
kps new https://www.acmicpc.net/problem/1000

# 번호 + 플랫폼 플래그로 생성
kps new 1000 -b
kps new 340207 -p
```
> **설명**: BOJ, Programmers 등의 **문제 링크**를 붙여넣으면 자동으로 파일 생성

### 3) 코드 작성

생성된 파일에서 문제를 풀어보세요:
```swift
// Sources/BOJ/1000.swift
import Foundation

func _1000() {
    // Your solution here
}
```

### 4) 풀이 완료 후 커밋/푸시

```bash
kps solve 1000 -b
```
> **설명**: 자동으로 커밋 메시지 생성 후 Git push까지 완료

완료! 🎉

---

## 📂 폴더 구조 예시

```text
YourProject/
├── .kps/
│   └── config.json          # KPS 설정 파일
└── Sources/                 # 소스 폴더 (사용자 지정 가능)
    ├── BOJ/
    │   ├── 1000.swift
    │   ├── 1001.swift
    │   └── 2557.swift
    └── Programmers/
        ├── 340207.swift
        └── 340198.swift
```

---

## ⌨️ 명령어 레퍼런스

### `kps init`

프로젝트를 KPS로 초기화합니다.

```bash
kps init -a "Your Name" -s "Sources"
```

**옵션:**
- `-a, --author <name>`: 작성자 이름 (필수)
- `-s, --source <folder>`: 소스 폴더 이름 (기본값: Sources)
- `--force`: 기존 설정 덮어쓰기

**설정 항목:**

| 항목 | 설명 | 예시 |
|------|------|------|
| `author` | 작성자 이름 (파일 헤더에 사용됨) | "John Doe" |
| `sourceFolder` | 소스 파일을 저장할 폴더 이름 | "Sources", "src" |
| `projectName` | 프로젝트 이름 (자동 감지, 수동 변경 가능) | "MyAlgorithm" |

---

### `kps new`

문제 풀이 파일을 생성합니다.

```bash
# URL로 생성
kps new https://acmicpc.net/problem/1000

# 번호로 생성
kps new 1000 -b
kps new 340207 -p
```

**옵션:**
- `-b, --boj`: BOJ 플랫폼 선택
- `-p, --programmers`: Programmers 플랫폼 선택

**참고:**
- URL 사용 시 플래그 불필요
- 번호 사용 시 플래그 필수
- 두 플래그 동시 사용 불가

---

### `kps open`

문제 파일을 Xcode에서 엽니다.

```bash
# 최근 파일 열기
kps open

# 특정 문제 열기
kps open 1000 -b
kps open 340207 -p
```

**동작 방식:**
- Xcode 프로젝트가 설정되어 있으면 `xed -p`로 프로젝트와 함께 파일 열기
- 프로젝트가 없으면 시스템 기본 에디터로 열기
- xed 없으면 자동으로 기본 에디터로 fallback

**옵션:**
- `-b, --boj`: BOJ 플랫폼
- `-p, --programmers`: Programmers 플랫폼

**요구사항:**
- Xcode 프로젝트 사용 시: Xcode Command Line Tools 필요

---

### `kps solve`

문제 풀이를 Git에 커밋하고 푸시합니다.

```bash
# 커밋 & 푸시
kps solve 1000 -b

# 커밋만 (푸시 안 함)
kps solve 1000 -b --no-push

# 커스텀 커밋 메시지
kps solve 1000 -b -m "feat: solve BOJ 1000 with binary search"
```

**옵션:**
- `-b, --boj`: BOJ 플랫폼
- `-p, --programmers`: Programmers 플랫폼
- `--no-push`: 푸시 생략
- `-m, --message <msg>`: 커밋 메시지 지정 (기본값: `solve: [Platform] {number}`)

**요구사항:**
- Git 저장소여야 함 (`git init` 필요)
- 파일이 이미 생성되어 있어야 함

---

### `kps config`

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

---

## 🔧 Workflow 예시

<details>
<summary><b>일반적인 사용 흐름</b></summary>

```bash
# 1. 프로젝트 초기화 (최초 1회)
git init
kps init -a "zaehorang" -s "Sources"

# 2. 문제 풀이 루프
kps new https://acmicpc.net/problem/1000
# ... 코드 작성 ...
kps solve 1000 -b

kps new https://school.programmers.co.kr/learn/courses/30/lessons/340207
# ... 코드 작성 ...
kps solve 340207 -p
```

</details>

<details>
<summary><b>하위 폴더에서 작업</b></summary>

```bash
cd Sources/BOJ
kps new 2557 -b              # 상위 폴더에서 설정 자동 탐색
kps solve 2557 -b            # 프로젝트 루트에서 Git 명령 실행
```

</details>

---

## 📋 Exit Code 정책

<details>
<summary><b>Exit Code 정책 보기</b></summary>

| 상황 | Exit Code |
|------|-----------|
| 성공 (모든 단계 완료) | 0 |
| 에러 (설정 없음, 파일 없음 등) | 1 |
| Git 실패 (add, commit) | 1 |
| Git push 실패 | 1 |

**참고:** Push 실패도 exit code 1로 처리합니다. "기록 완성"이 목표이므로 push 실패는 미완성 상태로 간주합니다.

</details>

---

## ❓ FAQ & Troubleshooting

<details>
<summary><b>Q: Git 없이 사용할 수 있나요?</b></summary>

A: 네, <code>init</code>, <code>new</code>, <code>config</code>는 Git 없이도 작동합니다.
다만 <code>solve</code> 기능은 Git 저장소가 필요합니다.

</details>

<details>
<summary><b>Q: 다른 폴더 이름을 사용할 수 있나요?</b></summary>

A: 네, <code>kps init -s "src"</code> 또는 <code>kps config sourceFolder "src"</code>로 변경 가능합니다.

</details>

<details>
<summary><b>Q: 여러 플랫폼의 문제를 한 프로젝트에서 관리할 수 있나요?</b></summary>

A: 네, BOJ와 Programmers 문제를 하나의 프로젝트에서 모두 관리할 수 있습니다.

</details>

<details>
<summary><b>Q: 모노레포에서 사용할 수 있나요?</b></summary>

A: 네, 상위 디렉토리에 <code>.git</code>이 있고 하위 디렉토리에 <code>.kps</code>가 있는 구조를 지원합니다.

</details>

<details>
<summary><b>Error: Config not found</b></summary>

```
Error: Config not found. Run 'kps init' first.
```
→ <code>kps init</code>으로 프로젝트 초기화 필요

</details>

<details>
<summary><b>Error: Platform required</b></summary>

```
Error: Platform not specified. Use -b for BOJ or -p for Programmers.
```
→ 번호만 입력했을 때 <code>-b</code> 또는 <code>-p</code> 플래그 필요

</details>

<details>
<summary><b>Error: Not a git repository</b></summary>

```
Error: Not a git repository. Run 'git init' first.
```
→ <code>kps solve</code>는 Git 저장소에서만 동작

</details>

<details>
<summary><b>Error: No changes to commit</b></summary>

```
Error: No changes to commit. Did you save your solution file?
```
→ 파일 수정 후 저장했는지 확인

</details>

<details>
<summary><b>⚠️ Push failed 메시지가 떠요.</b></summary>

```
⚠️ Commit succeeded, but push failed.
Possible causes:
  • No remote configured: run 'git remote -v'
  • Authentication issue: check your credentials or SSH key
To complete: run 'git push' manually
```

A: 커밋은 성공했지만 원격 저장소(Remote) 설정 문제나 권한 이슈로 푸시만 실패한 상태입니다.
<code>git push</code>를 수동으로 입력해 확인해 보세요.

</details>

<details>
<summary><b>Q: kps open이 기본 에디터로 열려요 (Xcode가 아닌)</b></summary>

A: Xcode 프로젝트 경로가 설정되지 않았습니다. 다음 명령어로 설정하세요:

```bash
kps config xcodeProjectPath "YourProject.xcodeproj"
```

또는 `kps init --force`로 재초기화하면 자동 감지됩니다.

</details>

<details>
<summary><b>Q: Xcode Command Line Tools가 없다는 경고가 떠요</b></summary>

```
⚠️ xed not available. Install Xcode Command Line Tools.
✔ Falling back to default editor...
```

A: Xcode Command Line Tools를 설치하세요:

```bash
xcode-select --install
```

설치 후 `kps open` 명령어가 Xcode에서 정상 작동합니다.

</details>

---

## 🤝 기여하기

이슈와 PR은 언제나 환영합니다!

---

## 📄 라이선스

[MIT License](https://github.com/zaehorang/KPSTool/blob/main/LICENSE)
