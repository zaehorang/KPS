# KPS (Korean Problem Solving)

알고리즘 문제 풀이를 정돈된 개발 기록으로 남기게 해주는 Swift CLI 도구

## 특징

- 🚀 **빠른 파일 생성**: URL 하나로 문제 풀이 파일 자동 생성
- 📁 **체계적인 구조**: 플랫폼별로 자동 분류 및 정리
- 🔄 **Git 자동 연동**: 풀이 완료 후 커밋 & 푸시 자동화
- 🌐 **다중 플랫폼 지원**: BOJ, Programmers

## 지원 플랫폼

| 플랫폼 | URL 형식 | 플래그 |
|--------|----------|--------|
| **BOJ** | `acmicpc.net/problem/{번호}` | `-b`, `--boj` |
| | `boj.kr/{번호}` | |
| **Programmers** | `school.programmers.co.kr/learn/courses/30/lessons/{번호}` | `-p`, `--programmers` |
| | `programmers.co.kr/learn/courses/30/lessons/{번호}` (구버전 호환) | |

## 설치

### Homebrew (권장)
```bash
# Coming soon
brew install kps
```

### 수동 설치
```bash
git clone https://github.com/your-username/kps.git
cd kps
swift build -c release
cp .build/release/kps /usr/local/bin/
```

## Quick Start (3분 완성)

### 1. 프로젝트 초기화
```bash
cd YourAlgorithmProject
kps init -a "Your Name" -s "Sources"
```

### 2. 문제 파일 생성
```bash
# URL로 생성
kps new https://acmicpc.net/problem/1000

# 또는 번호로 생성
kps new 1000 -b
```

### 3. 코드 작성
생성된 파일에서 문제를 풀어보세요:
```swift
// Sources/BOJ/1000.swift
import Foundation

func solve1000() {
    // Your solution here
}
```

### 4. Git 커밋 & 푸시
```bash
kps solve 1000 -b
```

완료! 🎉

## 생성되는 폴더 구조

```
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

## 명령어 레퍼런스

### `kps init`
프로젝트를 KPS로 초기화합니다.

```bash
kps init -a "Your Name" -s "Sources"
```

**옵션:**
- `-a, --author <name>`: 작성자 이름 (필수)
- `-s, --source <folder>`: 소스 폴더 이름 (기본값: Sources)
- `--force`: 기존 설정 덮어쓰기

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

## Exit Code 정책

| 상황 | Exit Code |
|------|-----------|
| 성공 (모든 단계 완료) | 0 |
| 에러 (설정 없음, 파일 없음 등) | 1 |
| Git 실패 (add, commit) | 1 |
| Git push 실패 | 1 |

**참고:** Push 실패도 exit code 1로 처리합니다. "기록 완성"이 목표이므로 push 실패는 미완성 상태로 간주합니다.

## 에러 메시지 가이드

### Config not found
```
Error: Config not found. Run 'kps init' first.
```
→ `kps init`으로 프로젝트 초기화 필요

### Platform required
```
Error: Platform not specified. Use -b for BOJ or -p for Programmers.
```
→ 번호만 입력했을 때 `-b` 또는 `-p` 플래그 필요

### Not a git repository
```
Error: Not a git repository. Run 'git init' first.
```
→ `kps solve`는 Git 저장소에서만 동작

### No changes to commit
```
Error: No changes to commit. Did you save your solution file?
```
→ 파일 수정 후 저장했는지 확인

### Push failed
```
⚠️ Commit succeeded, but push failed.
Possible causes:
  • No remote configured: run 'git remote -v'
  • Authentication issue: check your credentials or SSH key
To complete: run 'git push' manually
```
→ 커밋은 성공, 수동으로 `git push` 필요

## Workflow 예시

### 일반적인 사용 흐름
```bash
# 1. 프로젝트 초기화 (최초 1회)
git init
kps init -a "John Doe" -s "Sources"

# 2. 문제 풀이 루프
kps new https://acmicpc.net/problem/1000
# ... 코드 작성 ...
kps solve 1000 -b

kps new https://school.programmers.co.kr/learn/courses/30/lessons/340207
# ... 코드 작성 ...
kps solve 340207 -p
```

### 하위 폴더에서 작업
```bash
cd Sources/BOJ
kps new 2557 -b              # 상위 폴더에서 설정 자동 탐색
kps solve 2557 -b            # 프로젝트 루트에서 Git 명령 실행
```

## FAQ

**Q: Git 없이 사용할 수 있나요?**
A: `init`, `new`, `config` 명령은 Git 없이 사용 가능합니다. `solve` 명령만 Git 저장소가 필요합니다.

**Q: 다른 폴더 이름을 사용할 수 있나요?**
A: 네, `kps init -s "src"` 또는 `kps config sourceFolder "src"`로 변경 가능합니다.

**Q: 여러 플랫폼의 문제를 한 프로젝트에서 관리할 수 있나요?**
A: 네, BOJ와 Programmers 문제를 하나의 프로젝트에서 모두 관리할 수 있습니다.

**Q: 모노레포에서 사용할 수 있나요?**
A: 네, 상위 디렉토리에 `.git`이 있고 하위 디렉토리에 `.kps`가 있는 구조를 지원합니다.

## Roadmap

### v0.2.0
- [ ] Homebrew 배포
- [ ] `kps open` - 브라우저에서 문제 페이지 열기
- [ ] `kps list` - 풀이 목록 조회
- [ ] `kps stats` - 통계

### v0.3.0
- [ ] 학습 로그 기능 (`.kps/history.json`)
- [ ] 재도전 추적
- [ ] 난이도 메타데이터

## 기여하기

이슈와 PR은 언제나 환영합니다!

## 라이선스

MIT License - 자유롭게 사용하세요.

## 개발자

Made with ❤️ by [Your Name]
