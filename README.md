# KPS (Korean Problem Solving)

백준(BOJ)과 프로그래머스 문제 풀이 워크플로우 자동화 CLI 도구

## 기능

- 🆕 `kps new` - 새 문제 파일 생성 (템플릿 포함)
- ✅ `kps solve` - 풀이 후 git add, commit, push 자동화
- ⚙️ `kps config` - 설정 확인 및 수정

## 설치
```bash
git clone https://github.com/YOUR_USERNAME/KPSTool.git
cd KPSTool
swift build -c release
cp .build/release/kps /usr/local/bin/
```

## 사용법

### 프로젝트 초기화

알고리즘 프로젝트 폴더로 이동 후 초기화:
```bash
cd your-algorithm-project
kps init
```

옵션 지정도 가능:
```bash
kps init --author YOUR_NAME --source SOURCE_FOLDER
```

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--author`, `-a` | 작성자 이름 | KPS |
| `--project`, `-p` | 프로젝트 이름 | 현재 폴더 이름 |
| `--source`, `-s` | 소스 폴더 경로 | 현재 폴더 이름 |

### 새 문제 파일 생성
```bash
# URL로 생성 (플랫폼 자동 감지)
kps new "https://acmicpc.net/problem/1000"
kps new "https://school.programmers.co.kr/learn/courses/30/lessons/389630"

# 문제 번호 + 플래그로 생성
kps new 1000 -b          # BOJ
kps new 389630 -p        # Programmers
```

### 문제 풀이 후
```bash
kps solve 1000 -b
kps solve 389630 -p

# commit만 (push 안함)
kps solve 1000 -b --no-push

# 커밋 메시지 prefix 변경 (기본: add)
kps solve 1000 -b --prefix feat
```

### 설정 관리
```bash
kps config --list                # 전체 설정 보기
kps config author                # author 값 보기
kps config author YOUR_NAME      # author 값 수정
```

## 폴더 구조
```
YourProject/
├── .kps/
│   └── config.json
├── SourceFolder/
│   ├── BOJ/
│   │   └── 1000.swift
│   └── Programmers/
│       └── 389630.swift
└── YourProject.xcodeproj
```

## 라이선스

MIT License
